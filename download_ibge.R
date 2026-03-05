library(sf)
library(arrow)
library(dplyr)

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
    add_id = "BR"
  )
)

for (task in tasks) {
  cat("\n--- Processando:", task$name, "---\n")
  
  zip_file <- paste0(task$name, ".zip")
  temp_dir <- paste0("temp_", task$name)
  output_parquet <- file.path(output_dir, paste0("BR_", task$name, "_2024.parquet"))
  
  # 1. Download
  cat("Baixando:", task$url, "\n")
  download.file(task$url, zip_file, mode = "wb")
  
  # 2. Unzip
  cat("Extraindo...\n")
  unzip(zip_file, exdir = temp_dir)
  
  # 3. Read Data
  shp_file <- list.files(temp_dir, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
  if (length(shp_file) == 0) {
    warning("Nenhum arquivo .shp encontrado para ", task$name)
    next
  }
  
  cat("Lendo shapefile...\n")
  sf_data <- sf::st_read(shp_file[1], quiet = TRUE)
  
  # 4. Optimization & Renaming
  cat("Otimizando geometrias e colunas...\n")
  
  # Renomeia e seleciona colunas
  sf_data <- sf_data %>% 
    rename(any_of(task$rename)) %>%
    select(any_of(names(task$rename)), geometry)
  
  # Adiciona identificador fixo se necessário (ex: "BR" para Brasil)
  if (!is.null(task$add_id)) {
    sf_data$identificador_unidade_territorial <- task$add_id
  }
  
  # Simplificação (dTolerance de 0.001 ~ 100m)
  sf_data <- sf::st_simplify(sf_data, preserveTopology = TRUE, dTolerance = 0.001)
  
  # Arredondamento
  sf_data <- sf::st_set_precision(sf_data, 1e5)
  
  # 5. Conversion to WKB
  cat("Convertendo para WKB...\n")
  wkb_list <- sf::st_as_binary(sf::st_geometry(sf_data))
  
  # Remove a classe 'WKB' para que o arrow aceite como uma lista de raw bytes
  class(wkb_list) <- "list"
  
  sf_data$geometry_wkb <- wkb_list
  df_final <- sf::st_drop_geometry(sf_data)
  
  # 6. Save Parquet
  cat("Salvando em:", output_parquet, "\n")
  arrow::write_parquet(df_final, output_parquet, compression = "zstd", compression_level = 9)
  
  # 7. Cleanup
  cat("Limpando temporários...\n")
  unlink(zip_file)
  unlink(temp_dir, recursive = TRUE)
}

cat("\nTodos os arquivos foram processados e salvos em:", output_dir, "\n")
