library(sf)
library(dplyr)

# Caminho para a pasta de dados
path <- "./data/diego"

# 1. Listar todos os arquivos com padrão .gpkg
files <- list.files(path, pattern = "\\.gpkg$", full.names = TRUE)

# Função para processar cada arquivo individualmente
process_file <- function(file_path) {
  
  # Ler o arquivo (quiet = TRUE para não poluir o console)
  geo_data <- st_read(file_path, quiet = TRUE) %>%
    mutate(across(!any_of(attr(., "sf_column")), as.character))
  
  # Converter para EPSG:4326 (WGS84)
  geo_data <- st_transform(geo_data, 4326)
  
  # Lógica para extrair o texto após o segundo underline "_"
  # 1. Pega apenas o nome do arquivo (remove o caminho "./data/")
  file_name <- basename(file_path)
  # 2. Remove a extensão .gpkg
  file_name_clean <- tools::file_path_sans_ext(file_name)
  
  # 3. Extrai tudo após o segundo "_" usando regex
  # ^           -> Início da linha
  # [^_]+_      -> Qualquer caractere que não seja "_" seguido de um "_" (Primeira parte)
  # [^_]+_      -> Repete para a segunda parte
  # (.*)$       -> Captura todo o resto até o fim (o que queremos)
  intensidade <- sub("^[^_]+_[^_]+_(.*)$", "\\1", file_name_clean)
  
  # Criar a coluna nova
  geo_data <- geo_data %>%
    mutate(categoria_intensidade_tecnologica = intensidade)
  print(geo_data %>% glimpse())
  return(geo_data)
}


dados_unificados <- lapply(files, process_file) %>%
  bind_rows()

dados_unificados <- dados_unificados %>% 
  filter(categoria_intensidade_tecnologica %in% 
           c("servicos_alta_tecnologia",
             "servicos_densidade_altatecnologia",
             "servicos_financeiro",
             "servicos_administracao_conhecimento",
             "servicos_mercado_menos",
             "servicos_diversos",
             "servicos_demais"))

sf::st_write(dados_unificados, "data_ti.gpkg", driver = "gpkg")
