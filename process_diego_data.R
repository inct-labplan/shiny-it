# Script para Processamento de Dados de Tecnologia e Inovação (TI)
# Conforme especificações em data_wrang.md

library(sf)
library(dplyr)
library(writexl)

# Configurações de Caminhos
input_file <- "dados_tro/data_ti.gpkg"
output_file <- "indicadores_ti.xlsx"

if (!file.exists(input_file)) {
  stop(paste("Erro: Arquivo de entrada não encontrado:", input_file))
}

# 1. Leitura dos Dados Espaciais
message("Lendo camadas do GeoPackage: ", input_file)
df_raw <- st_read(input_file, layer = "data_ti", quiet = TRUE)

# 2. Transformação e Mapeamento (De-Para)
# Seguindo as regras de data_wrang.md e mantendo compatibilidade com a estrutura do app
message("Iniciando transformações de dados...")

df_processed <- df_raw %>%
  # Remove a geometria para exportação em Excel (conforme solicitado)
  st_drop_geometry() %>%
  # Aplica o de-para das colunas
  mutate(
    eixo = "Eixo 1",
    tags = "empresas;setor-produtivo",
    ano = 2025,
    unidade_territorial = "municipio",
    identificador_unidade_territorial = as.character(code_muni),
    tipo_visualizacao = "Mapa", # Padronizado para o que o app espera (indicadores_server.R)
    descricao_indicador = categoria_intensidade_tecnologica,
    # Extração das colunas originais
    nome_indicador = categoria_intensidade_tecnologica,
    valor_indicador = as.numeric(num_estabelecimentos),
    classes_indicador = num_estabelecimentos_bin, # Mapeado para o padrão do data_generator.R
    titulo_visualizacao = categoria_intensidade_tecnologica,
    
    # Metadados adicionais
    fonte_dados = "Cadastro de CNPJ da Receita Federal (2025)",
    unidade_medida = "empresas"
  ) %>%
  # Seleção e ordenação final das colunas para o Excel
  select(
    eixo,
    tags,
    ano,
    unidade_territorial,
    identificador_unidade_territorial,
    tipo_visualizacao,
    nome_indicador,
    descricao_indicador,
    valor_indicador,
    unidade_medida,
    classes_indicador,
    titulo_visualizacao,
    fonte_dados,
  )

# Resumo da operação
message("------------------------------------------")
message("Processamento de TI concluído!")
message("Total de registros: ", nrow(df_processed))
message("------------------------------------------")
