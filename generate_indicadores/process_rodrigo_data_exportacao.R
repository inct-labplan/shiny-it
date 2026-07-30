library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(writexl)
library(arrow)

# 1. Configurações e caminhos (Relativos à raiz do projeto)
dados_dir <- file.path("dados_rodrigo")
malhas_dir <- file.path("ibge_malhas")

arquivos_rodrigo <- list.files(dados_dir, pattern = "Eixo1_EXPORTACAO.xlsx", full.names = TRUE)
dicionario_path <- file.path(dados_dir, "Dicionário de variáveis Rodrigo.xlsx")

# 2. Carregar Tabelas de Referência (Malhas)
df_rm_ref <- read_parquet(file.path(malhas_dir, "BR_RegiaoMetropolitana_2024.parquet"))
df_muni_ref <- read_parquet(file.path(malhas_dir, "BR_Municipios_2024.parquet"))
df_uf_ref <- read_parquet(file.path(malhas_dir, "BR_UF_2024.parquet"))

# Mapeamento de nomes RM para os nomes no Parquet
rm_mapping <- c(
  "Região Metropolitana de Manaus (AM)" = "Recorte Metropolitano de Manaus",
  "Região Metropolitana de Belém (PA)" = "Recorte Metropolitano de Belém",
  "Região Metropolitana de Macapá (AP)" = "Recorte Metropolitano de Macapá", 
  "Região Metropolitana de Fortaleza (CE)" = "Recorte Metropolitano de Fortaleza",
  "Região Metropolitana de Natal (RN)" = "Recorte Metropolitano de Natal",
  "Região Metropolitana de João Pessoa (PB)" = "Recorte Metropolitano de João Pessoa",
  "Região Metropolitana de Recife (PE)" = "Recorte Metropolitano de Recife",
  "Região Metropolitana de Maceió (AL)" = "Recorte Metropolitano de Maceió",
  "Região Metropolitana de Aracaju (SE)" = "Recorte Metropolitano de Aracaju", 
  "Região Metropolitana de Salvador (BA)" = "Recorte Metropolitano de Salvador", 
  "Região Metropolitana de Belo Horizonte (MG)" = "Recorte Metropolitano de Belo Horizonte", 
  "Região Metropolitana de Grande Vitória (ES)" = "Recorte Metropolitano da Grande Vitória",
  "Região Metropolitana de Rio de Janeiro (RJ)" = "Recorte Metropolitano do Rio de Janeiro",
  "Região Metropolitana de São Paulo (SP)" = "Recorte Metropolitano de São Paulo",
  "Região Metropolitana de Curitiba (PR)" = "Recorte Metropolitano de Curitiba",
  "Região Metropolitana de Florianópolis (SC)" = "Recorte Metropolitano de Florianópolis",
  "Região Metropolitana de Porto Alegre (RS)" = "Recorte Metropolitano de Porto Alegre",
  "Região Metropolitana de Vale do Rio Cuiabá (MT)" = "Recorte Metropolitano do Vale do Rio Cuiabá",
  "Região Metropolitana de Goiânia (GO)" = "Recorte Metropolitano de Goiânia"
)

# Mapeamento de capitais para IDs IBGE (7 dígitos)
capital_mapping <- c(
  "Porto Velho" = "1100205",
  "Rio Branco" = "1200401",
  "Manaus" = "1302603",
  "Boa Vista" = "1400100",
  "Belém" = "1501402",
  "Macapá" = "1600303",
  "Palmas" = "1721000",
  "São Luís" = "2111300",
  "Teresina" = "2211001",
  "Fortaleza" = "2304400",
  "Natal" = "2408102",
  "João Pessoa" = "2507507",
  "Recife" = "2611606",
  "Maceió" = "2704302",
  "Aracaju" = "2800308",
  "Salvador" = "2927408",
  "Belo Horizonte" = "3106200",
  "Vitória" = "3205309",
  "Rio de Janeiro" = "3304557",
  "São Paulo" = "3550308",
  "Curitiba" = "4106902",
  "Florianópolis" = "4205407",
  "Porto Alegre" = "4314902",
  "Campo Grande" = "5002704",
  "Cuiabá" = "5103403",
  "Goiânia" = "5208707",
  "Brasília" = "5300108"
)

# 3. Carregar Dicionário
dict <- read_xlsx(dicionario_path) %>%
  rename(
    variavel = Variável,
    nome_indicador = Apelido,
    descricao_indicador = Descrição
  )

# 4. Função para processar cada planilha anual
processar_planilha <- function(caminho) {
  data <- read_xlsx(caminho)
  
  # Filtrar e Renomear níveis geográficos
  data_filtered <- data %>%
    filter(recorte_analise %in% c("UF", "Região", "Capital", "RM_RIDE", "Município", "#Total")) %>%
    mutate(unidade_territorial = case_when(
      recorte_analise == "UF" ~ "Estado",
      recorte_analise == "Região" ~ "Região",
      recorte_analise == "Capital" ~ "Município",
      recorte_analise == "RM_RIDE" ~ "Região Metropolitana",
      recorte_analise == "Município" ~ "Município",
      recorte_analise == "#Total" ~ "Brasil",
    ))
  
  # Atribuir identificadores corretos
  data_filtered <- data_filtered %>%
    mutate(
      nome_busca = case_when(
        recorte_analise == "UF" ~ conteudo,
        recorte_analise == "Região" ~ conteudo, 
        recorte_analise == "Capital" ~ str_replace(conteudo, "Município de ", "") %>% str_replace(" \\(..\\)$", ""),
        recorte_analise == "RM_RIDE" ~ recode(conteudo, !!!rm_mapping),
        recorte_analise == "Município" ~ conteudo,
        recorte_analise == "#Total" ~ "Brasil"
      )
    )
  
  # Joins tradicionais para os demais níveis
  data_filtered <- data_filtered %>%
    left_join(df_uf_ref %>% select(nome_unidade_territorial, id_uf = identificador_unidade_territorial), 
              by = c("nome_busca" = "nome_unidade_territorial")) %>%
    left_join(df_rm_ref %>% select(nome_unidade_territorial, id_rm = identificador_unidade_territorial), 
              by = c("nome_busca" = "nome_unidade_territorial")) %>%
    mutate(identificador_unidade_territorial = case_when(
      recorte_analise == "UF" ~ id_uf,
      recorte_analise == "RM_RIDE" ~ id_rm,
      recorte_analise == "#Total" ~ "BR",
      recorte_analise %in% c("Município", "Capital") ~ as.character(cod_recorte),
      TRUE ~ as.character(cod_recorte)
    ))
  
  
  # Captura de colunas para o Pivot
  cols_to_pivot <- names(data_filtered)[which(names(data_filtered) == "SH4_0201"):ncol(data_filtered)]
  
  # Remoção das colunas de controle da lista do pivot
  cols_to_pivot <- setdiff(cols_to_pivot, c("unidade_territorial", "identificador_unidade_territorial", 
                                            "nome_busca", "id_uf", "id_muni", "id_rm", "ano"))
  
  data_long <- data_filtered %>%
    pivot_longer(
      cols = all_of(cols_to_pivot),
      names_to = "variavel",
      values_to = "valor_indicador"
    )
  
  return(data_long)
}

# 5. Processar todos os anos e juntar
all_data <- lapply(arquivos_rodrigo, processar_planilha) %>%
  bind_rows()

# 6. Join com Dicionário e formatação final
exportacao_output <- all_data %>%
  left_join(dict, by = "variavel") %>%
  mutate(
    eixo = "Eixo 1", 
    projeto = "Exportação de Produtos Agropecuários", 
    tipo_visualizacao = "Gráfico",
    unidade_medida = "Proporção/Índice", 
    valor_indicador = round(valor_indicador, 2),
    classe_indicador = "", 
    titulo_visualizacao = nome_indicador,
    fonte_dados = "IBGE;",
    link_ckan_dados = "https://ipp.ufrn.br/labplan"
  ) %>%
  select(
    eixo,
    projeto,
    ano,
    unidade_territorial,
    identificador_unidade_territorial,
    tipo_visualizacao,
    nome_indicador,
    descricao_indicador,
    valor_indicador,
    unidade_medida,
    classe_indicador,
    titulo_visualizacao,
    fonte_dados,
    link_ckan_dados
  )

# 7. Finalização
message("------------------------------------------")
message("Processamento Socioeconômico concluído!")
message("Total de registros: ", nrow(exportacao_output))
message("------------------------------------------")