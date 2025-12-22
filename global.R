library(sf)
library(bs4Dash)
library(readr)

df_intensidade_terciario <- sf::read_sf("data_ti.gpkg")
df_estatisticas_ibge <- readr::read_csv('estatisticas_ibge.csv')
