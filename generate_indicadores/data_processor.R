# Funções de Processamento e Validação de Dados - Shiny-IT

#' Carrega e Valida a Tabela de Indicadores
#' @param df_or_path Caminho para o arquivo Excel ou um dataframe já carregado
#' @return Um dataframe limpo e validado ou interrompe com erro
load_and_validate_indicators <- function(df_or_path) {
  # 1. Carregamento inicial (se necessário)
  if (is.character(df_or_path)) {
    if (!file.exists(df_or_path)) {
      stop("Erro: Arquivo não encontrado em: ", df_or_path)
    }
    df <- readxl::read_excel(df_or_path)
  } else {
    df <- df_or_path
  }

  # 2. Definição do Contrato de Dados (Colunas Obrigatórias)
  # Nota: nome_unidade_territorial é adicionado por enrich_with_territory_names
  cols_obrigatorias <- c(
    "eixo", "projeto", "ano", "unidade_territorial",
    "identificador_unidade_territorial", "tipo_visualizacao", 
    "nome_indicador","descricao_indicador", "valor_indicador", "titulo_visualizacao", 
    "fonte_dados", "classe_indicador", "link_ckan_dados"
  )

  # 3. Verificação de Schema (Colunas Faltantes)
  cols_faltantes <- setdiff(cols_obrigatorias, names(df))
  if (length(cols_faltantes) > 0) {
    stop("Erro: O dataframe está sem as seguintes colunas obrigatórias: ", 
         paste(cols_faltantes, collapse = ", "))
  }

  # 4. Limpeza: Deleta colunas que não pertencem ao contrato (mantendo nome_unidade_territorial se existir)
  cols_to_keep <- intersect(c(cols_obrigatorias, "nome_unidade_territorial"), names(df))
  df <- df[, cols_to_keep]

  # 5. Tipagem e Conversão
  df$valor_indicador <- as.numeric(df$valor_indicador)
  df$ano <- as.integer(df$ano)
  
  # 6. Validação de Domínio (tipo_visualizacao)
  valores_validos_viz <- c("Mapa", "Gráfico")
  invalid_viz <- setdiff(unique(df$tipo_visualizacao), valores_validos_viz)
  
  if (length(invalid_viz) > 0) {
    warning("Atenção: Valores de 'tipo_visualizacao' inválidos detectados: ", 
            paste(invalid_viz, collapse = ", "))
  }

  # 7. Verificação de NAs em colunas obrigatórias (EXCETO colunas que permitem NA)
  cols_na_permitido <- c("classe_indicador", "identificador_unidade_territorial", "valor_indicador")
  cols_strict_no_na <- setdiff(cols_obrigatorias, cols_na_permitido)
  
  # Verifica quais colunas possuem NA
  na_counts <- colSums(is.na(df[, cols_strict_no_na]))
  cols_with_na <- names(na_counts[na_counts > 0])
  
  if (length(cols_with_na) > 0) {
    stop("Erro: Foram detectados valores NA nas seguintes colunas obrigatórias: ", 
         paste(cols_with_na, collapse = ", "), 
         ". Corrija os dados no Excel e tente novamente.")
  }

  return(df)
}

#' Enriquece o dataframe de indicadores com os nomes das unidades territoriais
#' @param df_or_path Dataframe de indicadores ou caminho para o arquivo Excel
#' @param ibge_dir Diretório contendo os arquivos parquet do IBGE
#' @return Dataframe com a coluna nome_unidade_territorial preenchida
enrich_with_territory_names <- function(df_or_path, ibge_dir = "ibge_malhas") {
  # Carregamento inicial (se necessário)
  if (is.character(df_or_path)) {
    if (!file.exists(df_or_path)) {
      stop("Erro: Arquivo não encontrado em: ", df_or_path)
    }
    df <- readxl::read_excel(df_or_path)
  } else {
    df <- df_or_path
  }

  if (!dir.exists(ibge_dir)) {
    warning("Atenção: Diretório de malhas IBGE não encontrado: ", ibge_dir, ". Nomes territoriais não serão carregados.")
    df$nome_unidade_territorial <- NA_character_
    return(df)
  }

  # Mapeamento de tipos de unidade territorial para arquivos parquet
  mapping <- list(
    "Município" = "BR_Municipios_2024.parquet",
    "UF" = "BR_UF_2024.parquet",
    "Brasil" = "BR_Brasil_2024.parquet",
    "Região Metropolitana" = "BR_RegiaoMetropolitana_2024.parquet"
  )
  
  # Inicializa a coluna se não existir
  if (!"nome_unidade_territorial" %in% names(df)) {
    df$nome_unidade_territorial <- NA_character_
  }

  # Itera sobre os tipos presentes no dataframe
  tipos_presentes <- unique(df$unidade_territorial)
  
  for (tipo in tipos_presentes) {
    file_name <- mapping[[tipo]]
    
    # Fallback para variações de nomes
    if (is.null(file_name)) {
      if (grepl("Munici", tipo, ignore.case = TRUE)) file_name <- mapping[["Município"]]
      else if (grepl("UF|Estado", tipo, ignore.case = TRUE)) file_name <- mapping[["UF"]]
      else if (grepl("Brasil", tipo, ignore.case = TRUE)) file_name <- mapping[["Brasil"]]
      else if (grepl("Metro", tipo, ignore.case = TRUE)) file_name <- mapping[["Região Metropolitana"]]
    }
    
    # Caso especial: "Região" (SIN, macrorregião, etc.) não tem parquet IBGE.
    # Usa o próprio identificador_unidade_territorial como nome legível,
    # pois process_felipe_data já popula esse campo com nomes como "Norte", "Nordeste", etc.
    if (grepl("^Regi", tipo, ignore.case = TRUE) && !grepl("Metro", tipo, ignore.case = TRUE)) {
      mask <- df$unidade_territorial == tipo
      df$nome_unidade_territorial[mask] <- as.character(df$identificador_unidade_territorial[mask])
    } else if (!is.null(file_name)) {
      path <- file.path(ibge_dir, file_name)
      if (file.exists(path)) {
        lookup <- arrow::read_parquet(path) %>%
          select(identificador_unidade_territorial, nome_unidade_territorial_new = nome_unidade_territorial) %>%
          mutate(identificador_unidade_territorial = as.character(identificador_unidade_territorial)) %>%
          distinct()
        
        mask <- df$unidade_territorial == tipo
        
        df_sub <- df[mask, ] %>%
          mutate(identificador_unidade_territorial = as.character(identificador_unidade_territorial)) %>%
          left_join(lookup, by = "identificador_unidade_territorial")
        
        df$nome_unidade_territorial[mask] <- df_sub$nome_unidade_territorial_new
      }
    }
  }
  
  return(df)
}

