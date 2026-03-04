# Funções de Processamento e Validação de Dados - Shiny-IT

#' Carrega e Valida a Tabela de Indicadores
#' @param file_path Caminho para o arquivo Excel (indicadores.xlsx)
#' @return Um dataframe limpo e validado ou interrompe com erro
load_and_validate_indicators <- function(file_path) {
  if (!file.exists(file_path)) {
    stop("Erro: Arquivo indicadores.xlsx não encontrado em: ", file_path)
  }

  # 1. Carregamento inicial
  df <- readxl::read_excel(file_path)

  # 2. Definição do Contrato de Dados (Colunas Obrigatórias)
  cols_obrigatorias <- c(
    "eixo", "tags", "ano", "unidade_territorial", "nome_unidade_territorial",
    "identificador_unidade_territorial", "tipo_visualizacao", 
    "nome_indicador", "valor_indicador", "classes_indicador"
  )

  # 3. Verificação de Schema (Colunas Faltantes)
  cols_faltantes <- setdiff(cols_obrigatorias, names(df))
  if (length(cols_faltantes) > 0) {
    stop("Erro: O arquivo Excel está sem as seguintes colunas obrigatórias: ", 
         paste(cols_faltantes, collapse = ", "))
  }

  # 4. Limpeza: Deleta colunas que não pertencem ao contrato
  df <- df[, cols_obrigatorias]

  # 5. Tipagem e Conversão
  df$valor_indicador <- as.numeric(df$valor_indicador)
  df$ano <- as.integer(df$ano)
  
  # 6. Validação de Domínio (tipo_visualizacao)
  valores_validos_viz <- c("Mapa", "Gráfico")
  invalid_viz <- setdiff(unique(df$tipo_visualizacao), valores_validos_viz)
  
  if (length(invalid_viz) > 0) {
    warning("Atenção: Valores de 'tipo_visualizacao' inválidos detectados: ", 
            paste(invalid_viz, collapse = ", "))
    # Opcional: filtrar ou tratar valores inválidos
  }

  # 7. Remoção de NAs críticos (ex: nome do indicador ou valor vazio)
  df <- df[!is.na(df$nome_indicador) & !is.na(df$valor_indicador), ]

  return(df)
}
