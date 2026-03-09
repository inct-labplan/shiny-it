# Processamento Espacial Otimizado - Shiny-IT
library(sf)
library(arrow)
library(dplyr)
library(leaflet)
library(htmltools)

#' Resolve o caminho do diretório de malhas de forma robusta
#' @return O caminho do diretório ou o default "ibge_malhas"
get_malhas_dir <- function() {
  # 1. Verifica se a opção foi setada manualmente
  opt_path <- getOption("shinyit.malhas_dir")
  if (!is.null(opt_path) && dir.exists(opt_path)) {
    return(opt_path)
  }
  
  # 2. Caminho padrão relativo à raiz do projeto
  default_path <- "ibge_malhas"
  if (dir.exists(default_path)) {
    return(default_path)
  }
  
  # 3. Fallback para execução dentro de tests/testthat/
  test_path <- "../../ibge_malhas"
  if (dir.exists(test_path)) {
    return(test_path)
  }
  
  return(default_path)
}

#' Une Indicadores com Dados Espaciais (Parquet/WKB) com Filtro na Leitura
#' @param indicators_df Dataframe de indicadores (já filtrado pelo usuário na memória)
#' @param level Nível territorial ("Brasil", "Estado", "Município")
#' @param malhas_dir Diretório contendo os arquivos .parquet (opcional)
#' @return Um objeto sf (Simple Features) com os indicadores unidos à geometria ou NULL se não houver dados
join_indicators_with_spatial <- function(indicators_df, level, malhas_dir = NULL) {
  
  if (is.null(malhas_dir)) {
    malhas_dir <- get_malhas_dir()
  }
  
  # 1. Mapeamento de Arquivos (Baseado nos nomes gerados pelo download_ibge.R)
  file_map <- list(
    "Município" = "BR_Municipios_2024.parquet",
    "Estado"    = "BR_UF_2024.parquet",
    "Brasil"    = "BR_Brasil_2024.parquet",
    "Região Metropolitana" = "BR_RegiaoMetropolitana_2024.parquet"
  )
  
  # 1.1 Resolução Robusta do Nível (Fuzzy Matching)
  target_file <- file_map[[level]]
  
  if (is.null(target_file)) {
    if (grepl("Munici", level, ignore.case = TRUE)) target_file <- file_map[["Município"]]
    else if (grepl("UF|Estado", level, ignore.case = TRUE)) target_file <- file_map[["Estado"]]
    else if (grepl("Brasil", level, ignore.case = TRUE)) target_file <- file_map[["Brasil"]]
    else if (grepl("Metro", level, ignore.case = TRUE)) target_file <- file_map[["Região Metropolitana"]]
  }
  
  if (is.null(target_file)) {
    warning("Aviso: Nível territorial não mapeado: ", level)
    return(NULL)
  }
  
  parquet_file <- file.path(malhas_dir, target_file)
  
  if (!file.exists(parquet_file)) {
    warning("Aviso: Arquivo de malha não encontrado: ", parquet_file)
    return(NULL)
  }
  
  # 2. Identifica os IDs necessários para evitar carregar o arquivo todo (Pushdown)
  # Garante que os IDs sejam strings para comparação consistente
  target_ids <- unique(as.character(indicators_df$identificador_unidade_territorial))
  
  if (length(target_ids) == 0) {
    warning("Nenhum identificador encontrado nos indicadores fornecidos.")
    return(NULL)
  }
  
  # 3. Leitura Otimizada (Predicate Pushdown)
  # Usamos open_dataset para filtrar no nível do arquivo antes de carregar no R
  # Nota: Convertemos identificador_unidade_territorial para character no filter
  # se o arrow suportar, ou garantimos que a coluna lida seja tratada adequadamente.
  spatial_df <- tryCatch({
    ds <- arrow::open_dataset(parquet_file)
    
    # Verifica o tipo da coluna no schema para decidir se precisa cast
    schema <- ds$schema
    is_numeric_id <- schema$GetFieldByName("identificador_unidade_territorial")$type$id %in% c(2, 3, 4, 5, 6) # Int types
    
    if (is_numeric_id) {
        ds %>%
          dplyr::filter(identificador_unidade_territorial %in% as.numeric(target_ids)) %>%
          dplyr::collect() %>%
          dplyr::mutate(identificador_unidade_territorial = as.character(identificador_unidade_territorial))
    } else {
        ds %>%
          dplyr::filter(identificador_unidade_territorial %in% target_ids) %>%
          dplyr::collect()
    }
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
  
  # Garante que o ID no indicators_df também seja character
  indicators_df$identificador_unidade_territorial <- as.character(indicators_df$identificador_unidade_territorial)
  
  # Remove colunas duplicadas de spatial_sf antes do join, exceto o ID
  cols_to_keep <- setdiff(colnames(spatial_sf), colnames(indicators_df))
  spatial_sf_clean <- spatial_sf[, c("identificador_unidade_territorial", cols_to_keep)]
  
  final_sf <- spatial_sf_clean %>%
    dplyr::inner_join(indicators_df, by = "identificador_unidade_territorial")
  
  return(final_sf)
}
