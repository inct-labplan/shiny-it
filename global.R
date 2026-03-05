library(sf)
library(bs4Dash)
library(readxl)
library(plotly)
library(dplyr)
library(arrow)
library(leaflet)
library(leaflet.extras2)

# Mapear caminho de recursos para garantir carregamento de CSS e imagens
addResourcePath("assets", "www")

# Carrega lógica de processamento de dados
source('data_processor.R')
source('spatial_processor.R')

# Carrega e valida os dados (Contrato de Dados)
# Se houver erro no Excel, o app interrompe aqui com a mensagem de erro da função
dados_indicadores <- load_and_validate_indicators("indicadores.xlsx")

# Geometrias base (serão integradas na fase de mapas)
# df_intensidade_terciario <- sf::read_sf("data_ti.gpkg")
