library(sf)
library(arrow)
library(dplyr)
library(jsonlite)

# Desativa S2 para evitar erros com geometrias inválidas no processamento
sf_use_s2(FALSE)

# Configurações
output_dir <- if (basename(getwd()) == "ibge_malhas") "." else "ibge_malhas"
if (!dir.exists(output_dir)) dir.create(output_dir)

# Lista de arquivos para processar
tasks <- list(
  list(
    name = "Municipios",
    url = "https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2024/Brasil/BR_Municipios_2024.zip",
    rename_geom = c(identificador_unidade_territorial = "CD_MUN", nome_unidade_territorial = "NM_MUN", SIGLA_UF = "SIGLA_UF"),
    rename_diretorio = c(id_municipio = "CD_MUN", nome_municipio = "NM_MUN", id_uf = "CD_UF", sigla_uf = "SIGLA_UF", nome_uf = "NM_UF")
  ),
  list(
    name = "UF",
    url = "https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2024/Brasil/BR_UF_2024.zip",
    rename = c(identificador_unidade_territorial = "CD_UF", nome_unidade_territorial = "NM_UF", SIGLA_UF = "SIGLA_UF")
  ),
  list(
    name = "Brasil",
    url = "https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2024/Brasil/BR_Pais_2024.zip",
    rename = character(0),
    add_cols = list(identificador_unidade_territorial = "BR", nome_unidade_territorial = "Brasil")
  ),
  list(
    name = "RegiaoMetropolitana",
    url = "https://geoservicos.ibge.gov.br/geoserver/CGMAT/wfs?service=WFS&version=2.0.0&request=GetFeature&typeNames=CGMAT:qg_2024_211_recortemetrop_agreg&outputFormat=application/json",
    rename = c(identificador_unidade_territorial = "cd_recmetrop", nome_unidade_territorial = "nm_recmetrop"),
    add_cols = list(unidade_territorial = "Região Metropolitana")
  ),
  list(
    name = "MunicipiosRM",
    url = "https://geoservicos.ibge.gov.br/geoserver/CGMAT/wfs?service=WFS&version=2.0.0&request=GetFeature&typeNames=CGMAT:qg_2024_211_recortemetrop&outputFormat=application/json",
    rename = c(id_municipio = "cd_mun", id_regiao_metropolitana = "cd_recmetrop", nome_regiao_metropolitana = "nm_recmetrop")
  )
)

# Lista para armazenar dados processados para uso posterior (ex: joins)
processed_results <- list()

for (task in tasks) {
  cat("\n--- Processando:", task$name, "---\n")
  
  is_zip <- grepl("\\.zip$", task$url, ignore.case = TRUE)
  temp_dir <- paste0("temp_", task$name)
  output_parquet <- file.path(output_dir, paste0("BR_", task$name, "_2024.parquet"))
  
  # 1. Download & Read
  if (is_zip) {
    zip_file <- paste0(task$name, ".zip")
    cat("Baixando e extraindo zip:", task$url, "\n")
    download.file(task$url, zip_file, mode = "wb")
    unzip(zip_file, exdir = temp_dir)
    
    shp_file <- list.files(temp_dir, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
    if (length(shp_file) == 0) {
      warning("Nenhum arquivo .shp encontrado para ", task$name)
      unlink(zip_file)
      unlink(temp_dir, recursive = TRUE)
      next
    }
    cat("Lendo shapefile...\n")
    sf_data <- sf::st_read(shp_file[1], quiet = TRUE)
    unlink(zip_file)
    unlink(temp_dir, recursive = TRUE)
  } else {
    cat("Lendo fonte direta (WFS/JSON):", task$url, "\n")
    sf_data <- sf::st_read(task$url, quiet = TRUE)
  }
  
  # 2. Optimization & Transformation
  cat("Otimizando geometrias e colunas...\n")
  
  # Adiciona colunas extras (constantes)
  if (!is.null(task$add_cols)) {
    for (col_name in names(task$add_cols)) {
      sf_data[[col_name]] <- task$add_cols[[col_name]]
    }
  }
  
  # Caso especial: Municipios gera duas tabelas
  if (task$name == "Municipios") {
    cat("Gerando diretorio_municipios (sem geometria)...\n")
    diretorio_municipios <- sf_data %>%
      sf::st_drop_geometry() %>%
      select(any_of(task$rename_diretorio))
    processed_results[["diretorio_municipios"]] <- diretorio_municipios
    
    # Prepara dados espaciais com rename_geom
    sf_data <- sf_data %>% rename(any_of(task$rename_geom))
    cols_to_keep <- c(names(task$rename_geom), names(task$add_cols))
    sf_data <- sf_data %>% select(any_of(cols_to_keep), geometry)
  } else if (!is.null(task$rename)) {
    sf_data <- sf_data %>% rename(any_of(task$rename))
    cols_to_keep <- c(names(task$rename), names(task$add_cols))
    sf_data <- sf_data %>% select(any_of(cols_to_keep), geometry)
  }
  
  # Armazena versão tabular para joins posteriores
  processed_results[[task$name]] <- sf::st_drop_geometry(sf_data)
  
  # Simplificação e Validação Espacial
  cat("Validando e corrigindo geometrias...\n")
  sf_data <- sf::st_simplify(sf_data, preserveTopology = TRUE, dTolerance = 0.001)
  sf_data <- sf::st_make_valid(sf_data)
  sf_data <- sf::st_collection_extract(sf_data, "POLYGON")
  sf_data <- sf::st_set_precision(sf_data, 1e5)
  
  # 3. Conversion to WKB
  cat("Convertendo para WKB...\n")
  wkb_list <- sf::st_as_binary(sf::st_geometry(sf_data))
  class(wkb_list) <- "list"
  
  sf_data_final <- sf::st_drop_geometry(sf_data)
  sf_data_final$geometry_wkb <- wkb_list
  
  # 4. Save Parquet
  cat("Salvando em:", output_parquet, "\n")
  arrow::write_parquet(sf_data_final, output_parquet, compression = "zstd", compression_level = 9)
}

# --- 5. Diretorio IBGE (Join: Municipios + MunicipiosRM) ---
cat("\n--- Gerando: diretorio_ibge.parquet ---\n")

if (!is.null(processed_results[["diretorio_municipios"]]) && !is.null(processed_results[["MunicipiosRM"]])) {
  diretorio_final <- processed_results[["diretorio_municipios"]] %>%
    left_join(processed_results[["MunicipiosRM"]], by = "id_municipio") %>%
    mutate(id_brasil = "BR", nome_brasil = "Brasil") %>%
    select(id_municipio, nome_municipio, sigla_uf, id_uf, nome_uf, id_regiao_metropolitana, nome_regiao_metropolitana, id_brasil, nome_brasil)
  
  output_diretorio <- file.path(output_dir, "diretorio_ibge.parquet")
  cat("Salvando diretorio final em:", output_diretorio, "\n")
  arrow::write_parquet(diretorio_final, output_diretorio, compression = "zstd", compression_level = 9)
} else {
  warning("Não foi possível gerar o diretorio_ibge.parquet: dados ausentes.")
}

cat("\nTodos os arquivos foram processados e salvos em:", output_dir, "\n")
