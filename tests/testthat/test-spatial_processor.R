library(testthat)
library(dplyr)
library(sf)
library(arrow)

# Source the function to be tested
source("../../spatial_processor.R", local = TRUE)

test_that("join_indicators_with_spatial filters correctly for Estado", {
  # Mock indicator data for São Paulo (ID 35)
  mock_indicators <- data.frame(
    identificador_unidade_territorial = c("35"),
    valor_indicador = c(100),
    nome_unidade_territorial = c("São Paulo")
  )
  
  # Test with Level "Estado"
  if (file.exists("../../ibge_malhas/BR_UF_2024.parquet")) {
    result <- join_indicators_with_spatial(mock_indicators, "Estado", malhas_dir = "../../ibge_malhas")
    
    expect_s3_class(result, "sf")
    expect_equal(nrow(result), 1)
    expect_equal(result$identificador_unidade_territorial, "35")
    expect_true("geometry" %in% colnames(result))
    expect_false("geometry_wkb" %in% colnames(result))
  } else {
    skip("Parquet file for Estado not found")
  }
})

test_that("join_indicators_with_spatial filters correctly for Brasil", {
  mock_indicators <- data.frame(
    identificador_unidade_territorial = c("BR"),
    valor_indicador = c(100),
    nome_unidade_territorial = c("Brasil")
  )
  
  if (file.exists("../../ibge_malhas/BR_Brasil_2024.parquet")) {
    result <- join_indicators_with_spatial(mock_indicators, "Brasil", malhas_dir = "../../ibge_malhas")
    
    expect_s3_class(result, "sf")
    expect_equal(nrow(result), 1)
    expect_equal(result$identificador_unidade_territorial, "BR")
  } else {
    skip("Parquet file for Brasil not found")
  }
})

test_that("join_indicators_with_spatial handles multiple IDs", {
  mock_indicators <- data.frame(
    identificador_unidade_territorial = c("35", "15"), # SP and PA
    valor_indicador = c(100, 200)
  )
  
  if (file.exists("../../ibge_malhas/BR_UF_2024.parquet")) {
    result <- join_indicators_with_spatial(mock_indicators, "Estado", malhas_dir = "../../ibge_malhas")
    
    expect_s3_class(result, "sf")
    expect_equal(nrow(result), 2)
    expect_setequal(result$identificador_unidade_territorial, c("35", "15"))
  } else {
    skip("Parquet file for Estado not found")
  }
})

test_that("join_indicators_with_spatial returns NULL for missing IDs", {
  mock_indicators <- data.frame(
    identificador_unidade_territorial = c("999"), 
    valor_indicador = c(100)
  )
  
  if (file.exists("../../ibge_malhas/BR_UF_2024.parquet")) {
    expect_warning(result <- join_indicators_with_spatial(mock_indicators, "Estado", malhas_dir = "../../ibge_malhas"))
    expect_null(result)
  }
})

test_that("join_indicators_with_spatial handles non-existent files gracefully", {
  mock_indicators <- data.frame(
    identificador_unidade_territorial = c("35")
  )
  
  expect_warning(result <- join_indicators_with_spatial(mock_indicators, "Estado", malhas_dir = "invalid_dir"))
  expect_null(result)
})
