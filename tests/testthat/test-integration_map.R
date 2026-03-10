library(testthat)
library(shiny)
library(leaflet)
library(dplyr)
library(sf)
library(arrow)
library(plotly)
library(shinyjs)

# Mock some shiny functions that are not available in testServer context or need isolation
withProgress <- function(expr, ...) { eval(expr) }
showNotification <- function(...) { invisible(NULL) }

# Set option for malhas_dir to be used by the module during test
options(shinyit.malhas_dir = "../../ibge_malhas")
options(shinyit.test_mode = TRUE)

# Source the function and server logic
source("../../spatial_processor.R", local = TRUE)
source("../../visualizations.R", local = TRUE)
source("../../components/indicadores_server.R", local = TRUE)

# The server logic uses 'dados_indicadores' from the global/calling environment
dados_indicadores <- data.frame(
  eixo = "Econômico",
  tags = "test",
  ano = 2024L,
  unidade_territorial = "Estado",
  nome_unidade_territorial = "São Paulo",
  identificador_unidade_territorial = "35",
  tipo_visualizacao = "Mapa",
  nome_indicador = "PIB",
  valor_indicador = 1500.5,
  classes_indicador = "Alta",
  stringsAsFactors = FALSE
)

test_that("Integration: Map generation from server logic", {
  malhas_path <- "../../ibge_malhas"
  
  if (!file.exists(file.path(malhas_path, "BR_UF_2024.parquet"))) {
    skip("Parquet file for integration test not found")
  }

  testServer(indicadores_server_logic, {
    # Step 1-6: Setup inputs
    session$setInputs(eixo_sel = "Econômico")
    session$setInputs(indicador_sel = "PIB")
    session$setInputs(viz_type = "Mapa")
    session$setInputs(unidade_sel = "Estado")
    session$setInputs(nome_unidade_sel = "São Paulo")
    session$setInputs(ano_sel = "2024")
    
    # Step 7: Click Generate
    session$setInputs(gerar_viz = 1)
    
    # 3. Verify Output
    map_out <- output$mapa_indicador
    
    expect_false(is.null(map_out))
    
    # Check if it's a list (which it often is in testServer for widgets)
    if (is.list(map_out)) {
       expect_true("x" %in% names(map_out))
    } else if (is.character(map_out)) {
       expect_true(grepl("CartoDB.Positron", map_out))
    }
  })
})
