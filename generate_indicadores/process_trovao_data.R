library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(writexl)
library(arrow)

# 1. Configurações e caminhos (Relativos à raiz do projeto)

dados_dir <- file.path("dados_tro")
malhas_dir <- file.path("ibge_malhas")

arquivos_tro <- list.files(dados_dir, pattern = "^Dados_total_.*\\.xlsx$", full.names = TRUE)
dicionario_path <- file.path(dados_dir, "Dicionário de variáveis Observatório ISM (2025).xlsx")

# 2. Carregar Tabelas de Referência (Malhas)
df_rm_ref <- read_parquet(file.path(malhas_dir, "BR_RegiaoMetropolitana_2024.parquet"))
df_muni_ref <- read_parquet(file.path(malhas_dir, "BR_Municipios_2024.parquet"))
df_uf_ref <- read_parquet(file.path(malhas_dir, "BR_UF_2024.parquet"))

# Mapeamento de nomes RM para os nomes no Parquet (conforme solicitado)
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
# Colunas: Variável, Apelido, Descrição
dict <- read_xlsx(dicionario_path) %>%
  rename(
    variavel = Variável,
    nome_indicador = Apelido,
    descricao_indicador = Descrição
  )

# 4. Função para processar cada planilha anual
processar_planilha <- function(caminho) {
  # Extrair ano do nome do arquivo
  ano_val <- as.numeric(str_extract(basename(caminho), "\\d{4}"))

  data <- read_xlsx(caminho)

  # Filtrar e Renomear níveis geográficos
  data_filtered <- data %>%
    filter(recorte_analise %in% c("UF", "Capital", "RM_RIDE", "#Total")) %>%
    mutate(unidade_territorial = case_when(
      recorte_analise == "UF" ~ "Estado",
      recorte_analise == "Capital" ~ "Município",
      recorte_analise == "RM_RIDE" ~ "Região Metropolitana",
      recorte_analise == "#Total" ~ "Brasil",
    ))

  # Atribuir identificadores corretos
  data_filtered <- data_filtered %>%
    mutate(
      nome_busca = case_when(
        recorte_analise == "UF" ~ conteudo,
        recorte_analise == "Capital" ~ str_replace(conteudo, "Município de ", "") %>% str_replace(" \\(..\\)$", ""),
        recorte_analise == "RM_RIDE" ~ recode(conteudo, !!!rm_mapping),
        recorte_analise == "#Total" ~ "Brasil"
      )
    )

  # Joins para pegar os IDs
  data_filtered <- data_filtered %>%
    left_join(df_uf_ref %>% select(nome_unidade_territorial, id_uf = identificador_unidade_territorial), 
              by = c("nome_busca" = "nome_unidade_territorial")) %>%
    left_join(df_rm_ref %>% select(nome_unidade_territorial, id_rm = identificador_unidade_territorial), 
              by = c("nome_busca" = "nome_unidade_territorial")) %>%
    mutate(identificador_unidade_territorial = case_when(
      recorte_analise == "UF" ~ id_uf,
      recorte_analise == "Capital" ~ recode(nome_busca, !!!capital_mapping),
      recorte_analise == "RM_RIDE" ~ id_rm,
      recorte_analise == "#Total" ~ "BR"
    ))

  # Converter para formato long
  # Encontrar a posição da primeira variável (MSII)
  cols_to_pivot <- names(data_filtered)[which(names(data_filtered) == "MSII"):ncol(data_filtered)]
  # Remover colunas auxiliares que não são indicadores se existirem
  cols_to_pivot <- setdiff(cols_to_pivot, c("unidade_territorial", "identificador_unidade_territorial", "nome_busca", "id_uf", "id_muni", "id_rm"))

  data_long <- data_filtered %>%
    pivot_longer(
      cols = all_of(cols_to_pivot),
      names_to = "variavel",
      values_to = "valor_indicador"
    ) %>%
    mutate(ano = ano_val)

  return(data_long)
}

# 5. Processar todos os anos e juntar
all_data <- lapply(arquivos_tro, processar_planilha) %>%
  bind_rows()

# 6. Join com Dicionário e formatação final
final_output <- all_data %>%
  left_join(dict, by = "variavel") %>%
  mutate(
    eixo = "Eixo 3", 
    projeto = "Indicadores ISM", 
    tipo_visualizacao = "Gráfico",
    unidade_medida = "Proporção/Índice", 
    valor_indicador = round(valor_indicador, 2),
    classe_indicador = "", 
    titulo_visualizacao = nome_indicador,
    fonte_dados = "IBGE;PNADC (2016-2024)",
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
message("Total de registros: ", nrow(final_output))
message("------------------------------------------")
