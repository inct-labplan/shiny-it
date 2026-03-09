library(sf)
library(arrow)
library(dplyr)

# Desativa S2 para evitar erros com geometrias inválidas no processamento
sf_use_s2(FALSE)

# Configurações
output_dir <- "ibge_malhas"
if (!dir.exists(output_dir)) dir.create(output_dir)

# Lista de arquivos para processar com mapeamento de colunas
tasks <- list(
  list(
    name = "Municipios",
    url = "https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2024/Brasil/BR_Municipios_2024.zip",
    rename = c(identificador_unidade_territorial = "CD_MUN", nome_unidade_territorial = "NM_MUN", SIGLA_UF = "SIGLA_UF")
  ),
  list(
    name = "UF",
    url = "https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2024/Brasil/BR_UF_2024.zip",
    rename = c(identificador_unidade_territorial = "CD_UF", nome_unidade_territorial = "NM_UF", SIGLA_UF = "SIGLA_UF")
  ),
  list(
    name = "Brasil",
    url = "https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2024/Brasil/BR_Pais_2024.zip",
    rename = c(nome_unidade_territorial = "PAIS"),
    add_cols = list(identificador_unidade_territorial = "BR")
  ),
  list(
    name = "RegiaoMetropolitana",
    url = "https://geoservicos.ibge.gov.br/geoserver/CGMAT/wfs?service=WFS&version=2.0.0&request=GetFeature&typeNames=CGMAT:qg_2024_211_recortemetrop_agreg&outputFormat=application/json",
    rename = c(identificador_unidade_territorial = "cd_recmetrop", nome_unidade_territorial = "nm_recmetrop"),
    add_cols = list(unidade_territorial = "Região Metropolitana")
  )
)

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
  
  # 2. Optimization & Renaming
  cat("Otimizando geometrias e colunas...\n")
  
  # Renomeia e seleciona colunas do mapeamento
  sf_data <- sf_data %>% 
    rename(any_of(task$rename))
  
  # Adiciona colunas extras (constantes)
  if (!is.null(task$add_cols)) {
    for (col_name in names(task$add_cols)) {
      sf_data[[col_name]] <- task$add_cols[[col_name]]
    }
  }
  
  # Seleciona apenas o que foi definido (ou adicionado) + geometry
  all_cols <- c(names(task$rename), names(task$add_cols))
  sf_data <- sf_data %>% select(any_of(all_cols), geometry)
  
  # Simplificação (dTolerance de 0.001 ~ 100m)
  sf_data <- sf::st_simplify(sf_data, preserveTopology = TRUE, dTolerance = 0.001)
  
  # Arredondamento
  sf_data <- sf::st_set_precision(sf_data, 1e5)
  
  # 3. Conversion to WKB
  cat("Convertendo para WKB...\n")
  wkb_list <- sf::st_as_binary(sf::st_geometry(sf_data))
  
  # Remove a classe 'WKB' para que o arrow aceite como uma lista de raw bytes
  class(wkb_list) <- "list"
  
  sf_data$geometry_wkb <- wkb_list
  df_final <- sf::st_drop_geometry(sf_data)
  
  # 4. Save Parquet
  cat("Salvando em:", output_parquet, "\n")
  arrow::write_parquet(df_final, output_parquet, compression = "zstd", compression_level = 9)
}

cat("\nTodos os arquivos foram processados e salvos em:", output_dir, "\n")
