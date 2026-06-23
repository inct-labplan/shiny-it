library(readr)
library(openxlsx)

# Defina o diretório onde estão os arquivos CSV
pasta <- "dados_yohana"

# Lista todos os arquivos CSV da pasta
arquivos_csv <- list.files(
  path = pasta,
  pattern = "\\.csv$",
  full.names = TRUE
)

# Converte cada CSV para XLSX
for (arquivo in arquivos_csv) {
  
  cat("Convertendo:", basename(arquivo), "\n")
  
  # Lê o CSV
  dados <- read_csv(
    arquivo,
    show_col_types = FALSE,
    locale = locale(encoding = "UTF-8")
  )
  
  # Nome do arquivo XLSX
  arquivo_xlsx <- sub("\\.csv$", ".xlsx", arquivo)
  
  # Salva em XLSX
  write.xlsx(
    dados,
    arquivo_xlsx,
    overwrite = TRUE
  )
  
  cat("Salvo:", basename(arquivo_xlsx), "\n")
}

cat("Conversão concluída!\n")