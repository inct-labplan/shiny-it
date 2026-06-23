library(readxl)
library(dplyr)
library(purrr)
library(writexl)

# 1. Configurações de caminhos
dados_dir <- "dados_rodrigo"
arquivo_original <- file.path(dados_dir, "Eixo1_Dados_Proagro_2019_2020_2021_2022_2023_2024.xlsx")

# 2. Carregar o arquivo completo
# (Ajuste o 'skip' ou 'sheet' se o seu arquivo precisar, como fizemos antes)
df_completo <- read_xlsx(arquivo_original)

# NOTA IMPORTANTE: 
# Se o seu arquivo original NÃO tiver uma coluna chamada "ano", mas você souber 
# que os anos estão especificados em alguma coluna (ex: "ano_referencia"), 
# ajuste o nome da coluna no 'group_by' abaixo.

# 3. Filtrar, dividir e salvar cada ano no piloto automático
df_completo %>%
  # Garante que estamos olhando apenas para os 3 anos desejados
  filter(ANO_EMISSAO %in% c(2019, 2020, 2021, 2022, 2023, 2024)) %>% 
  
  # Divide o dataframe em uma lista separada por ano
  group_split(ANO_EMISSAO) %>% 
  
  # Executa a função de salvar para cada um dos anos da lista
  walk(function(df_ano) {
    # Pega o valor do ano atual do sub-dataframe
    ano_atual <- unique(df_ano$ANO_EMISSAO)
    
    # Define o nome do novo arquivo conforme o seu padrão
    nome_arquivo <- paste0("Eixo1_Dados_Proagro_", ano_atual, ".xlsx")
    caminho_salvamento <- file.path(dados_dir, nome_arquivo)
    
    # Salva o arquivo Excel
    write_xlsx(df_ano, path = caminho_salvamento)
    
    # Mensagem de confirmação no console
    message("Arquivo salvo com sucesso: ", caminho_salvamento)
  })

message("------------------------------------------")
message("Divisão por anos concluída com sucesso!")
message("------------------------------------------")