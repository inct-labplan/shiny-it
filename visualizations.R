# Funções de Visualização - Shiny-IT
library(plotly)
library(leaflet)
library(htmltools)
library(dplyr)

#' Constrói o Mapa Leaflet para um Indicador
#' @param sf_map Objeto sf resultante de join_indicators_with_spatial
#' @param indicator_name Nome do indicador para legendas e popups
#' @param subtitle Nome da unidade territorial para o subtítulo
#' @return Um objeto leaflet
build_indicator_map <- function(sf_map, indicator_name, subtitle = NULL) {
  if (is.null(sf_map) || nrow(sf_map) == 0) return(NULL)
  
  # Define cores baseadas no valor_indicador
  pal <- colorNumeric(
    palette = "YlOrRd",
    domain = sf_map$valor_indicador
  )
  
  # HTML do Popup
  is_test <- !is.null(getOption("shinyit.test_mode"))
  
  raw_labels <- sprintf(
    "<strong>%s</strong><br/>%s: %g",
    sf_map$nome_unidade_territorial, indicator_name, sf_map$valor_indicador
  )
  
  labels <- if (is_test) {
    as.list(raw_labels)
  } else {
    lapply(raw_labels, htmltools::HTML)
  }
  
  # Metadados: Título e Fonte
  data_source <- if("fonte_dados" %in% names(sf_map)) sf_map$fonte_dados[1] else "Fonte: LabPlan"
  map_title <- if("titulo_visualizacao" %in% names(sf_map)) sf_map$titulo_visualizacao[1] else indicator_name
  
  # HTML do Título com CSS embutido para garantir centralização e larguras consistentes
  title_html <- paste0(
    "<style>",
    "  .leaflet-top.leaflet-left { width: 100% !important; pointer-events: none !important; }",
    "  .leaflet-control-title { ",
    "    position: absolute !important; ",
    "    left: 50% !important; ",
    "    transform: translateX(-50%) !important; ",
    "    margin: 0 !important; ",
    "    pointer-events: auto !important; ",
    "    float: none !important; ",
    "  }",
    "  .sync-width { width: 230px !important; box-sizing: border-box; }",
    "  .leaflet-control-source { margin-bottom: 10px !important; }",
    "  .info.legend.leaflet-control { width: 230px !important; box-sizing: border-box; white-space: normal !important; }",
    "</style>",
    "<div style='background: rgba(255,255,255,0.9); padding: 8px; border-radius: 5px; border: 1px solid #ccc; text-align: center;'>",
    "<strong style='font-size: 14px;'>", map_title, "</strong>",
    if(!is.null(subtitle)) paste0("<br/><span style='font-size: 11px; color: #666;'>", subtitle, "</span>") else "",
    "</div>"
  )

  # Renderização Leaflet
  leaflet(sf_map) %>%
    addProviderTiles(providers$CartoDB.Positron) %>%
    addControl(
      html = title_html,
      position = "topleft",
      className = "leaflet-control-title"
    ) %>%
    addControl(
      html = paste0("<div class='sync-width' style='background: rgba(255,255,255,0.8); padding: 5px; font-size: 10px; color: #666; border: 1px solid #ccc; border-radius: 5px;'>", data_source, "</div>"),
      position = "bottomright",
      className = "leaflet-control-source"
    ) %>%
    addPolygons(
      fillColor = ~pal(valor_indicador),
      weight = 1,
      opacity = 1,
      color = "white",
      dashArray = "3",
      fillOpacity = 0.7,
      highlightOptions = highlightOptions(
        weight = 3,
        color = "#666",
        dashArray = "",
        fillOpacity = 0.7,
        bringToFront = TRUE
      ),
      label = labels,
      labelOptions = labelOptions(
        style = list("font-weight" = "normal", padding = "3px 8px"),
        textsize = "15px",
        direction = "auto"
      )
    ) %>%
    addLegend(
      pal = pal, 
      values = ~valor_indicador, 
      opacity = 0.7, 
      title = indicator_name,
      position = "bottomright"
    )
}

#' Constrói o Gráfico Plotly para um Indicador (Série Temporal)
#' @param df_plot Dataframe de indicadores filtrado e ordenado por ano
#' @param indicator_name Nome do indicador para legendas
#' @param unit_name Nome da unidade territorial
#' @return Um objeto plotly
build_indicator_graph <- function(df_plot, indicator_name, unit_name) {
  if (is.null(df_plot) || nrow(df_plot) == 0) return(NULL)
  
  # Renderização baseada em ano (X) e valor (Y)
  plot_ly(df_plot, 
          x = ~as.integer(ano), 
          y = ~valor_indicador, 
          type = 'scatter', 
          mode = 'lines+markers',
          name = unit_name,
          text = ~paste("Ano:", ano, "<br>Valor:", valor_indicador)) %>%
    layout(
      title = list(text = paste(df_plot$titulo_visualizacao[1], "<br><sup>", unit_name, "</sup>"),
                   font = list(size = 14)),
      margin = list(t = 60, b = 100),
      xaxis = list(
        title = "Ano",
        tickmode = "linear",
        dtick = 1
      ),
      yaxis = list(title = "Valor"),
      showlegend = FALSE,
      annotations = list(
        list(
          x = 1, y = -0.25,
          text = paste("Fonte:", df_plot$fonte_dados[1]),
          showarrow = FALSE,
          xref = 'paper', yref = 'paper',
          xanchor = 'right', yanchor = 'auto',
          font = list(size = 10, color = "gray")
        )
      )
    ) %>%
    config(
      displayModeBar = TRUE,
      displaylogo = FALSE,
      modeBarButtonsToRemove = c("zoom2d", "pan2d", "select2d", "lasso2d", "zoomIn2d", "zoomOut2d", "autoScale2d", "resetScale2d")
    )
}
