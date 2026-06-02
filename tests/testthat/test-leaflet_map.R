library(testthat)
library(leaflet)
library(sf)

# Source the function to be tested
source("../../spatial_processor.R", local = TRUE)
source("../../visualizations.R", local = TRUE)

test_that("build_indicator_map returns a leaflet object", {
  # Create a dummy sf object
  # Create a small polygon (square)
  p1 <- matrix(c(0,0, 1,0, 1,1, 0,1, 0,0), ncol=2, byrow=TRUE)
  poly <- st_polygon(list(p1))
  sfc <- st_sfc(poly, crs = 4674)
  
  mock_sf <- st_sf(
    identificador_unidade_territorial = "1",
    nome_unidade_territorial = "Test Unit",
    valor_indicador = 50,
    geometry = sfc
  )
  
  result <- build_indicator_map(mock_sf, "Test Indicator")
  
  expect_s3_class(result, "leaflet")
  expect_s3_class(result, "htmlwidget")
})

test_that("build_indicator_map returns NULL for empty data", {
  expect_null(build_indicator_map(NULL, "Test"))
  
  # Empty sf
  empty_sf <- st_sf(geometry = st_sfc(crs = 4674))[-1,]
  expect_null(build_indicator_map(empty_sf, "Test"))
})
