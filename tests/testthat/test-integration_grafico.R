library(testthat)
library(shiny)
library(plotly)
library(dplyr)
library(shinyjs)

# Mock some shiny functions
withProgress <- function(expr, ...) { eval(expr) }

# Source the function and server logic
source("../../visualizations.R", local = TRUE)
source("../../components/grafico_module.R", local = TRUE)

# The server logic uses 'dados_indicadores'
dados_indicadores <- data.frame(
  eixo = "Econômico",
  tags = "test",
  ano = c(2023L, 2024L),
  unidade_territorial = "Estado",
  nome_unidade_territorial = "São Paulo",
  identificador_unidade_territorial = "35",
  tipo_visualizacao = "Gráfico",
  nome_indicador = "PIB",
  valor_indicador = c(1400, 1500.5),
  classes_indicador = "Alta",
  stringsAsFactors = FALSE
)

test_that("Integration: Graph generation from server logic", {
  testServer(grafico_server, args = list(dados_indicadores = dados_indicadores), {
    # Setup inputs
    session$setInputs(eixo_sel = "Econômico")
    session$setInputs(indicador_sel = "PIB")
    session$setInputs(unidade_sel = "Estado")
    session$setInputs(nome_unidade_sel = "São Paulo")
    
    # Click Generate
    session$setInputs(gerar_viz = 1)
    
    # Verify Output
    plot_out <- output$plot_indicador
    
    expect_false(is.null(plot_out))
    
    if (is.list(plot_out)) {
       expect_true("x" %in% names(plot_out))
    }
  })
})
