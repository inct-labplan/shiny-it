# Funções de Visualização - Shiny-IT
library(plotly)
library(leaflet)
library(htmltools)
library(dplyr)
library(base64enc)

#' Obtém o URI em base64 do logo LabPlan
#' @return Uma string URI de dados base64 ou NULL se o arquivo não existir
get_labplan_logo_uri <- function() {
  logo_path <- "www/inct-labplan.png"
  if (!file.exists(logo_path)) {
    # Tenta um nível acima para suportar execução dentro de tests/testthat
    logo_path <- "../../www/inct-labplan.png"
  }
  
  if (file.exists(logo_path)) {
    return(base64enc::dataURI(file = logo_path, mime = "image/png"))
  }
  return(NULL)
}

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
  
  # Logo base64
  logo_uri <- get_labplan_logo_uri()
  
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
    "<div style='background: rgba(255,255,255,0.7); padding: 8px; border-radius: 5px; text-align: center;'>",
    "<strong style='font-size: 14px;'>", map_title, "</strong>",
    "</div>"
  )

  # Renderização Leaflet
  m <- leaflet(sf_map) %>%
    addProviderTiles(providers$CartoDB.Positron) %>%
    addControl(
      html = title_html,
      position = "topleft",
      className = "leaflet-control-title"
    )

  if (!is.null(logo_uri)) {
    m <- m %>% addControl(
      html = sprintf("<img src='%s' style='height: 60px; opacity: 0.8;'>", logo_uri),
      position = "bottomleft",
      className = "leaflet-control-logo"
    )
  }

  m %>%
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
  
  logo_uri <- get_labplan_logo_uri()
  
  # Renderização baseada em ano (X) e valor (Y)
  p <- plot_ly(df_plot, 
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
          xanchor = 'right', yanchor = 'middle',
          font = list(size = 10, color = "gray")
        )
      )
    )

  if (!is.null(logo_uri)) {
    p <- p %>% layout(
      images = list(
        list(
          source = logo_uri,
          xref = "paper", yref = "paper",
          x = 0, y = -0.25,
          sizex = 0.20, sizey = 0.20,
          xanchor = "left", yanchor = "middle",
          opacity = 0.8
        )
      )
    )
  }

  p %>% config(
      displayModeBar = TRUE,
      displaylogo = FALSE,
      modeBarButtonsToRemove = c("zoom2d", "pan2d", "select2d", "lasso2d", "zoomIn2d", "zoomOut2d", "autoScale2d", "resetScale2d")
    )
}
