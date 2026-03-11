library(sf)
library(bs4Dash)
library(readxl)
library(plotly)
library(dplyr)
library(arrow)
library(leaflet)
library(shiny)

# Mapear caminho de recursos para garantir carregamento de CSS e imagens
addResourcePath("assets", "www")

# Carrega lógica de visualização e processamento espacial
source('spatial_processor.R')
source('visualizations.R')

# Carrega os dados já pré-processados e validados (Parquet)
# A preparação (validação e enriquecimento) é feita via generate_indicadores/prepare_data.R
parquet_file <- "indicadores.parquet"
legend_file <- "map_legend.parquet"

if (!file.exists(parquet_file)) {
  stop("Erro: Arquivo ", parquet_file, " não encontrado. Execute generate_indicadores/gen_indicadores.R primeiro.")
}

if (!file.exists(legend_file)) {
  stop("Erro: Arquivo ", legend_file, " não encontrado. Execute generate_indicadores/gen_indicadores.R primeiro.")
}

dados_indicadores <- arrow::read_parquet(parquet_file)
map_legend_data <- arrow::read_parquet(legend_file)
