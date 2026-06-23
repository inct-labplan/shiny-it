# Script Mestre para Geração dos Indicadores
# Este script consolida os dados de TI e Socioeconômicos em um único arquivo indicadores.xlsx

library(dplyr)
library(writexl)

# Definir caminhos relativos à raiz do projeto
# Assume que o script é executado de dentro da pasta generate_indicadores/
output_xlsx <- file.path("indicadores.xlsx")

message("=== Iniciando Geração de Indicadores Consolidados ===")

# 1. Processar Dados de TI (Diego)
# O script cria o data frame 'df_processed' em memória
#source("generate_indicadores/process_diego_data.R", local = TRUE)

# 2. Processar Dados Socioeconômicos (Trovão)
# O script cria o data frame 'final_output' em memória
source("generate_indicadores/process_trovao_data.R", local = TRUE)

# 3. Processar Dados PIB municipal (Jaine)
# O script cria o data frame 'pib_output' em memória
source("generate_indicadores/process_jaine_data.R", local = TRUE)

# 4. Processar Dados Domiciliares municipal (Jaine)
# O script cria o data frame 'dom_output' em memória
source("generate_indicadores/process_jaine_data_dom.R", local = TRUE)

# 5. Processar Dados de indicadores demográficos (Jaine)
# O script cria o data frame 'ind_demo' em memória
source("generate_indicadores/process_jaine_data_indicadores_demo.R", local = TRUE)

# 5. Processar Dados de indicadores demográficos (Jaine)
# O script cria o data frame 'energy_output' em memória
source("generate_indicadores/process_felipe_data.R", local = TRUE)

# 6. Consolidação Final
message("\n--- Consolidando Tabelas ---")

indicadores_consolidado <- bind_rows(
  final_output,
  pib_output,
  dom_output,
  ind_demo,
  energy_output
) %>%
  # Transforma o ano em texto para limpar a linha do tempo do gráfico
  mutate(ano = as.character(ano))

# Salva na raiz do projeto
write_xlsx(indicadores_consolidado, output_xlsx)

# 4. Trigger de Validação e Conversão (Parquet)
source("generate_indicadores/prepare_data.R")

message("------------------------------------------")
message("CONSOLIDAÇÃO CONCLUÍDA COM SUCESSO!")
message("CONSOLIDAÇÃO CONCLUÍDA COM SUCESSO!")
message("Arquivo final na raiz: indicadores.parquet")
message("Total de registros processados: ", nrow(indicadores_consolidado))
message("------------------------------------------")
