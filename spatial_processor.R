# Processamento Espacial Otimizado - Shiny-IT
library(sf)
library(arrow)
library(dplyr)
library(leaflet)
library(htmltools)

#' Une Indicadores com Dados Espaciais (Parquet/WKB) com Filtro na Leitura
#' @param indicators_df Dataframe de indicadores (já filtrado pelo usuário na memória)
#' @param level Nível territorial ("Brasil", "Estado", "Município")
#' @param malhas_dir Diretório contendo os arquivos .parquet
#' @return Um objeto sf (Simple Features) com os indicadores unidos à geometria ou NULL se não houver dados
join_indicators_with_spatial <- function(indicators_df, level, malhas_dir = getOption("shinyit.malhas_dir", "ibge_malhas")) {
  
  # 1. Mapeamento de Arquivos (Baseado nos nomes gerados pelo download_ibge.R)
  file_map <- c(
    "Município" = "BR_Municipios_2024.parquet",
    "Estado"    = "BR_UF_2024.parquet",
    "Brasil"    = "BR_Brasil_2024.parquet"
  )
  
  parquet_file <- file.path(malhas_dir, file_map[level])
  
  if (!file.exists(parquet_file)) {
    warning("Aviso: Arquivo de malha não encontrado: ", parquet_file)
    return(NULL)
  }
  
  # 2. Identifica os IDs necessários para evitar carregar o arquivo todo (Pushdown)
  target_ids <- unique(as.character(indicators_df$identificador_unidade_territorial))
  
  if (length(target_ids) == 0) {
    warning("Nenhum identificador encontrado nos indicadores fornecidos.")
    return(NULL)
  }
  
  # 3. Leitura Otimizada (Predicate Pushdown)
  # Usamos open_dataset para filtrar no nível do arquivo antes de carregar no R
  spatial_df <- tryCatch({
    arrow::open_dataset(parquet_file) %>%
      dplyr::filter(identificador_unidade_territorial %in% target_ids) %>%
      dplyr::collect()
  }, error = function(e) {
    warning("Erro ao ler arquivo Parquet: ", e$message)
    return(NULL)
  })
  
  if (is.null(spatial_df) || nrow(spatial_df) == 0) {
    warning("Nenhuma geometria encontrada para os IDs fornecidos no nível: ", level)
    return(NULL)
  }
  
  # 4. Reconstrução da Geometria (WKB -> sfc)
  # st_as_sfc reconstrói a geometria a partir da lista de raw bytes
  spatial_df$geometry <- sf::st_as_sfc(spatial_df$geometry_wkb, crs = 4674)
  spatial_sf <- sf::st_as_sf(spatial_df)
  
  # Remove a coluna WKB original para economizar memória
  spatial_sf$geometry_wkb <- NULL
  
  # 5. Join Final com os Indicadores da Memória
  # Usamos inner_join para garantir que o objeto SF final contenha apenas
  # registros que possuam tanto geometria quanto dados de indicadores.
  
  # Garante que não haja duplicidade de colunas que causariam sufixos .x/.y
  # Queremos as colunas do indicators_df prioritariamente para os dados,
  # mas a geometria e identificadores do spatial_sf.
  
  # Remove colunas duplicadas de spatial_sf antes do join, exceto o ID
  cols_to_keep <- setdiff(colnames(spatial_sf), colnames(indicators_df))
  spatial_sf_clean <- spatial_sf[, c("identificador_unidade_territorial", cols_to_keep)]
  
  final_sf <- spatial_sf_clean %>%
    dplyr::inner_join(indicators_df, by = "identificador_unidade_territorial")
  
  return(final_sf)
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
