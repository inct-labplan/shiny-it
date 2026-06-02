# gen_legend.R
# Script para gerar a tabela de metadados da legenda dos mapas (map_legend.parquet)

library(dplyr)
library(arrow)

message("=== Gerando Metadados de Legenda (map_legend.parquet) ===")

# Caminhos
root_dir <- ".."
input_file <- file.path(root_dir, "indicadores.parquet")
output_file <- file.path(root_dir, "map_legend.parquet")

if (!file.exists(input_file)) {
  stop("Erro: Arquivo ", input_file, " não encontrado.")
}

# 1. Carregar indicadores
df <- read_parquet(input_file)

# 2. Filtrar apenas indicadores de Mapa
df_mapa <- df %>%
  filter(tipo_visualizacao == "Mapa")

if (nrow(df_mapa) == 0) {
  message("Nenhum indicador do tipo 'Mapa' encontrado.")
  # Cria arquivo vazio com schema correto
  map_legend <- data.frame(
    nome_indicador = character(),
    classe_indicador = character(),
    ordem = integer(),
    min_valor = numeric(),
    max_valor = numeric()
  )
  write_parquet(map_legend, output_file)
  return()
}

# 3. Calcular metadados da legenda por indicador e classe
map_legend <- df_mapa %>%
  group_by(nome_indicador, classe_indicador) %>%
  summarize(
    min_valor = min(valor_indicador, na.rm = TRUE),
    max_valor = max(valor_indicador, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  # Ordenar por indicador e pelo valor mínimo da classe para garantir ordem lógica
  arrange(nome_indicador, min_valor) %>%
  group_by(nome_indicador) %>%
  mutate(ordem = row_number()) %>%
  ungroup()

# 4. Salvar em formato Parquet
message("Salvando metadados de legenda em: ", output_file)
write_parquet(map_legend, output_file)

message("GERAÇÃO DE LEGENDA CONCLUÍDA!")
