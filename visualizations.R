# Funções de Visualização - Shiny-IT
library(plotly)
library(leaflet)
library(htmltools)
library(dplyr)
library(tidyr)
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
  
  # 1. Obter metadados da legenda para este indicador
  # Assume que map_legend_data está no global.R
  legend_meta <- if (exists("map_legend_data")) {
    map_legend_data %>% filter(nome_indicador == indicator_name) %>% arrange(ordem)
  } else {
    NULL
  }

  if (!is.null(legend_meta) && nrow(legend_meta) > 0) {
    # Caso tenhamos classes pré-definidas
    # Criamos uma paleta baseada nos intervalos (bins) das classes
    # O leaflet colorBin ou colorNumeric com domain fixo pode ser usado.
    # Para garantir que as cores correspondam às classes:
    
    # Criamos os breaks baseados nos min/max das classes
    breaks <- c(legend_meta$min_valor[1], legend_meta$max_valor)
    # Garante unicidade e ordenação
    breaks <- unique(sort(breaks))
    
    # Se tivermos apenas um break (ex: todos valores iguais), expandimos
    if(length(breaks) == 1) {
       breaks <- c(breaks - 1, breaks + 1)
    }

    pal <- colorBin(
      palette = "YlOrRd",
      domain = c(min(breaks), max(breaks)),
      bins = breaks,
      na.color = "#808080"
    )
    
    legend_values <- legend_meta$classe_indicador
    # Para addLegend com colorBin e labels customizados, usamos a paleta e os labels das classes
    # Mas o addLegend padrão do leaflet para colorBin gera intervalos. 
    # Para usar exatamente o texto de classe_indicador:
    
  } else {
    # Fallback para o comportamento anterior se não houver metadados
    vals <- sf_map$valor_indicador
    domain_range <- range(vals, na.rm = TRUE)
    if (domain_range[1] == domain_range[2]) {
      domain_range <- c(domain_range[1] * 0.9, domain_range[1] * 1.1)
      if(domain_range[1] == 0 && domain_range[2] == 0) domain_range <- c(-1, 1)
    }
    pal <- colorNumeric(palette = "YlOrRd", domain = domain_range, na.color = "#808080")
    legend_values <- sf_map$valor_indicador
  }
  
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
  
  # Novo padrão de título: Nome do indicador - unidade territorial - ano
  map_title <- paste0(indicator_name, " - ", sf_map$unidade_territorial[1], " - ", sf_map$ano[1])
  
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
    "  .info.legend.leaflet-control { ",
    "    background: rgba(255,255,255,0.9) !important; ",
    "    padding: 10px !important; ",
    "    border-radius: 5px !important; ",
    "    border: 1px solid #ccc !important; ",
    "    line-height: 18px !important; ",
    "    color: #333 !important; ", # Cor mais escura para contraste
    "    font-weight: bold !important; ",
    "    box-shadow: 0 0 15px rgba(0,0,0,0.2) !important; ",
    "  }",
    "  .info.legend i { ",
    "    width: 18px !important; ",
    "    height: 18px !important; ",
    "    float: left !important; ",
    "    margin-right: 8px !important; ",
    "    opacity: 0.7 !important; ",
    "  }",
    "</style>",
    "<div style='background: rgba(255,255,255,0.7); padding: 8px; border-radius: 5px; text-align: center;'>",
    "<strong style='font-size: 14px;'>", map_title, "</strong>",
    "</div>"
  )

  # Renderização Leaflet
  m <- leaflet(sf_map) %>%
    # Opções de camadas base
    addProviderTiles(providers$CartoDB.Positron, group = "Mapa Claro (Padrão)") %>%
    addProviderTiles(providers$OpenStreetMap, group = "OpenStreetMap") %>%
    addProviderTiles(providers$Esri.WorldImagery, group = "Satélite") %>%
    
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

  m <- m %>%
    addControl(
      html = paste0("<div class='sync-width' style='background: rgba(255,255,255,0.8); padding: 5px; font-size: 10px; color: #666; border: 1px solid #ccc; border-radius: 5px;'>", data_source, "</div>"),
      position = "bottomright",
      className = "leaflet-control-source"
    ) %>%
    # Camada de Polígonos de Dados
    addPolygons(
      fillColor = ~pal(valor_indicador),
      weight = 1.5,
      opacity = 1,
      color = "black",
      dashArray = "",
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
      ),
      group = "Indicadores"
    ) %>%
    # Controle de Camadas
    addLayersControl(
      baseGroups = c("Mapa Claro (Padrão)", "OpenStreetMap", "Satélite"),
      options = layersControlOptions(collapsed = TRUE)
    )

  # Adicionar legenda customizada se tivermos metadados, senão a padrão
  if (!is.null(legend_meta) && nrow(legend_meta) > 0) {
    # Para usar as labels de classe_indicador exatamente
    m <- m %>% addLegend(
      pal = pal,
      values = legend_meta$min_valor, # Usamos os valores mínimos para mapear as cores corretamente
      labFormat = function(type, cuts, p) { return(legend_meta$classe_indicador) },
      opacity = 0.7,
      title = NULL,
      position = "bottomright",
      layerId = "map-legend"
    )
  } else {
    m <- m %>% addLegend(
      pal = pal, 
      values = ~valor_indicador, 
      opacity = 0.7, 
      title = NULL,
      position = "bottomright",
      layerId = "map-legend"
    )
  }
  
  return(m)
}

#' Constrói o Gráfico Plotly para um Indicador (Série Temporal)
#' @param df_plot Dataframe de indicadores filtrado e ordenado por ano
#' @param indicator_name Nome do indicador para legendas
#' @param unit_names Nomes das unidades territoriais (vetor)
#' @param chart_type Tipo de gráfico ("lines" ou "bar")
#' @return Um objeto plotly
build_indicator_graph <- function(df_plot, indicator_name, unit_names, chart_type = "lines") {
  if (is.null(df_plot) || nrow(df_plot) == 0) return(NULL)
  
  # Garantir que ano seja um fator ordenado (categorias)
  df_plot <- df_plot %>%
    mutate(ano = factor(ano, levels = sort(unique(as.integer(ano)))))
  
  # (Removido o bloco complete/seq)
  
  logo_uri <- get_labplan_logo_uri()
  years_label <- paste(levels(df_plot$ano), collapse = "-")  # Ex: "2010-2021-2023"
  territorial_unit_label <- paste(unique(df_plot$unidade_territorial), collapse = " / ")
  chart_title <- paste0(indicator_name, " - ", territorial_unit_label, " - ", years_label)
  
  p <- plot_ly(df_plot, 
               x = ~ano, 
               y = ~valor_indicador, 
               color = ~nome_unidade_territorial,
               type = if(chart_type == "bar") "bar" else "scatter",
               mode = if(chart_type == "bar") NULL else "lines+markers",
               width = if(chart_type == "bar") 0.6 else NULL,
               text = ~paste("Unidade:", nome_unidade_territorial, 
                             "<br>Ano:", ano, 
                             "<br>Valor:", valor_indicador),
               hoverinfo = "text") %>%
    layout(
      title = list(text = chart_title, font = list(size = 14), y = 0.95),
      margin = list(t = 120, b = 150),
      xaxis = list(
        title = "Ano",
        type = "category",
        categoryorder = "array",
        categoryarray = levels(df_plot$ano)
      ),
      yaxis = list(title = "", rangemode = "tozero"),
      showlegend = TRUE,
      legend = list(orientation = "h", x = 0.5, xanchor = "center", y = 1.02, yanchor = "bottom"),
      annotations = list(
        list(x = 1, y = -0.3, 
             text = paste("Fonte:", df_plot$fonte_dados[1]),
             showarrow = FALSE,
             xref = 'paper', yref = 'paper',
             xanchor = 'right', yanchor = 'bottom',
             font = list(size = 10, color = "gray"))
      )
    )
    

  if (!is.null(logo_uri)) {
    p <- p %>% layout(
      images = list(
        list(
          source = logo_uri,
          xref = "paper", yref = "paper",
          x = 0, y = -0.3,
          sizex = 0.15, sizey = 0.15,
          xanchor = "left", yanchor = "bottom",
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
