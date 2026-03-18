# prepare_data.R
# Script para enriquecer, validar e converter os dados de indicadores para Parquet
library(dplyr)
library(arrow)

source("generate_indicadores/data_processor.R")

message("=== Iniciando Preparação de Dados (Validar e Converter) ===")

# Caminhos relativos à raiz do projeto (assumindo que o script é rodado de dentro de generate_indicadores/)
input_file <- file.path("indicadores.xlsx")
output_file <- file.path("indicadores.parquet")
ibge_dir <- file.path("ibge_malhas")

if (!file.exists(input_file)) {
  stop("Erro: Arquivo fonte ", input_file, " não encontrado.")
}

# 1. Enriquecer com nomes territoriais e Validar
message("Enriquecendo e validando dados...")
dados_processados <- enrich_with_territory_names(input_file, ibge_dir = ibge_dir) %>%
  load_and_validate_indicators()

# 2. Salvar como Parquet
message("Salvando em formato Parquet: ", output_file)
write_parquet(dados_processados, output_file)

# 3. Gerar metadados de legenda para Mapas
source("generate_indicadores/gen_legend.R")

message("PREPARAÇÃO CONCLUÍDA COM SUCESSO!")
