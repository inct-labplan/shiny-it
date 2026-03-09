# Script Mestre para Geração dos Indicadores
# Este script consolida os dados de TI e Socioeconômicos em um único arquivo indicadores.xlsx

library(dplyr)
library(writexl)

message("=== Iniciando Geração de Indicadores Consolidados ===")

# 1. Processar Dados de TI (Diego)
# O script cria o data frame 'df_processed' em memória
source("process_diego_data.R", local = TRUE)

# 2. Processar Dados Socioeconômicos (Trovão)
# O script cria o data frame 'final_output' em memória
source("process_trovao_data.R", local = TRUE)

# 3. Consolidação Final
message("\n--- Consolidando Tabelas ---")

indicadores_consolidado <- bind_rows(
  df_processed,
  final_output
)

output_final <- "indicadores.xlsx"
write_xlsx(indicadores_consolidado, output_final)

message("------------------------------------------")
message("CONSOLIDAÇÃO CONCLUÍDA COM SUCESSO!")
message("Arquivo gerado: ", output_final)
message("Total de registros processados: ", nrow(indicadores_consolidado))
message("------------------------------------------")
