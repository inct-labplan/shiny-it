library(testthat)
library(leaflet)
library(plotly)
library(htmlwidgets)
library(dplyr)
library(sf)
library(shiny)
library(webshot2)

# Define a mock for addResourcePath since we are in a test environment
if (!exists("addResourcePath")) {
  addResourcePath <- function(prefix, directoryPath) {
    message("Mocking addResourcePath: ", prefix, " -> ", directoryPath)
  }
}

# Note: We use relative paths assuming the test is run from within the package or with testthat
# Since testthat sets the directory to tests/testthat, we need to go up two levels.
# We temporarily change the working directory so global.R finds its files.
old_wd <- getwd()
setwd("../../")
source("global.R", local = FALSE)
setwd(old_wd)

# Check if indicators.xlsx exists, if not generate it
if (!file.exists("../../indicadores.xlsx")) {
  message("Generating indicators.xlsx for testing...")
  old_wd_gen <- getwd()
  setwd("../../generate_indicadores")
  source("gen_indicadores.R", local = TRUE)
  setwd(old_wd_gen)
}

# Create output directory
dir.create("debug_outputs", showWarnings = FALSE)

test_that("A random map can be rendered and saved as PNG for debugging", {
  # Pick a random indicator that supports Map
  df_map_choices <- dados_indicadores %>% filter(tipo_visualizacao == "Mapa")
  
  if (nrow(df_map_choices) == 0) {
    skip("No indicators for Map available in the dataset.")
  }
  
  # Select a random row
  random_row <- df_map_choices[sample(nrow(df_map_choices), 1), ]
  
  # Replicate the filtering logic from indicadores_server.R
  df_filtered <- dados_indicadores %>%
    filter(eixo == random_row$eixo,
           nome_indicador == random_row$nome_indicador,
           tipo_visualizacao == "Mapa",
           unidade_territorial == random_row$unidade_territorial,
           nome_unidade_territorial == random_row$nome_unidade_territorial,
           ano == random_row$ano)
  
  # Override options to find parquet files
  options(shinyit.malhas_dir = "../../ibge_malhas")
  
  # Join with spatial data
  sf_map <- join_indicators_with_spatial(df_filtered, random_row$unidade_territorial)
  
  expect_s3_class(sf_map, "sf")
  expect_gt(nrow(sf_map), 0)
  
  # Transform to WGS84 for Leaflet
  sf_map <- st_transform(sf_map, 4326)
  
  # Build map
  map <- build_indicator_map(sf_map, random_row$nome_indicador, random_row$nome_unidade_territorial)
  
  expect_s3_class(map, "leaflet")
  
  # Save PNG for debug
  output_png <- "debug_outputs/debug_map.png"
  temp_html <- tempfile(fileext = ".html")
  saveWidget(map, temp_html, selfcontained = FALSE)
  # Added delay to ensure all controls and tiles are rendered
  webshot(temp_html, file = output_png, vwidth = 1200, vheight = 900, delay = 1)
  
  expect_true(file.exists(output_png))
  message("Debug map image saved to: ", output_png)
})

test_that("A random plotly graph can be rendered and saved as PNG for debugging", {
  # Pick a random indicator that supports Graph
  df_plot_choices <- dados_indicadores %>% filter(tipo_visualizacao == "Gráfico")
  
  if (nrow(df_plot_choices) == 0) {
    skip("No indicators for Graph available in the dataset.")
  }
  
  # Select a random row
  random_row <- df_plot_choices[sample(nrow(df_plot_choices), 1), ]
  
  # Filtragem dos dados p/ o gráfico (histórico temporal)
  df_plot <- dados_indicadores %>%
    filter(eixo == random_row$eixo,
           nome_indicador == random_row$nome_indicador,
           tipo_visualizacao == "Gráfico",
           unidade_territorial == random_row$unidade_territorial,
           nome_unidade_territorial == random_row$nome_unidade_territorial) %>%
    arrange(ano)
  
  expect_gt(nrow(df_plot), 0)
  
  # Renderização Plotly via Função Compartilhada
  p <- build_indicator_graph(df_plot, random_row$nome_indicador, random_row$nome_unidade_territorial)
  
  expect_s3_class(p, "plotly")
  
  # Save PNG for debug
  output_png <- "debug_outputs/debug_graph.png"
  temp_html <- tempfile(fileext = ".html")
  saveWidget(p, temp_html, selfcontained = FALSE)
  # Added delay and increased height to capture annotations
  webshot(temp_html, file = output_png, vwidth = 1200, vheight = 1000, delay = 2)
  
  expect_true(file.exists(output_png))
  message("Debug graph image saved to: ", output_png)
})
