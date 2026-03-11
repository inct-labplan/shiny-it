library(leaflet)
library(sf)
library(testthat)

# Source the function to be tested
source("spatial_processor.R", local = TRUE)
source("visualizations.R", local = TRUE)

# Create a dummy sf object
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

# Inspect calls
calls <- result$x$calls
call_methods <- sapply(calls, function(x) x$method)

print("Leaflet call methods:")
print(call_methods)

mock_sf_na <- st_sf(
  identificador_unidade_territorial = "1",
  nome_unidade_territorial = "Test Unit",
  valor_indicador = as.numeric(NA),
  geometry = sfc
)

result_na <- build_indicator_map(mock_sf_na, "Test Indicator")

# Inspect calls for NA
calls_na <- result_na$x$calls
call_methods_na <- sapply(calls_na, function(x) x$method)

print("Leaflet call methods (NA):")
print(call_methods_na)

if ("addLegend" %in% call_methods_na) {
  print("addLegend IS present in leaflet calls (NA).")
} else {
  print("addLegend IS NOT present in leaflet calls (NA).")
}
