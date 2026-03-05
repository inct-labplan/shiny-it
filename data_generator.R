# Script para Gerar Dados de Teste - Shiny-IT
library(dplyr)
library(writexl)

# 1. Definição de Dimensões
anos <- 2020:2024
eixos <- c("Econômico", "Social", "Ambiental")

# Unidades Territoriais de Exemplo
territorios <- list(
  list(ut = "Brasil", nome = "Brasil", id = "BR"),
  list(ut = "Estado", nome = "Pará", id = "15"),
  list(ut = "Estado", nome = "Rio de Janeiro", id = "33"),
  list(ut = "Município", nome = "Belém", id = "1501402"),
  list(ut = "Município", nome = "Ananindeua", id = "1500800"),
  list(ut = "Município", nome = "Rio de Janeiro", id = "3304557")
)

# Indicadores (Mais de 7)
indicadores <- list(
  list(eixo = "Econômico", nome = "PIB per Capita", tags = "economia,riqueza"),
  list(eixo = "Econômico", nome = "Taxa de Desocupação", tags = "emprego,trabalho"),
  list(eixo = "Social", nome = "IDH Municipal", tags = "desenvolvimento,social"),
  list(eixo = "Social", nome = "Taxa de Alfabetização", tags = "educação"),
  list(eixo = "Social", nome = "Leitos por Mil Habitantes", tags = "saúde"),
  list(eixo = "Ambiental", nome = "Área Reflorestada (ha)", tags = "meio ambiente,floresta"),
  list(eixo = "Ambiental", nome = "Índice de Tratamento de Esgoto", tags = "saneamento"),
  list(eixo = "Ambiental", nome = "Emissões de CO2", tags = "clima,poluição")
)

# 2. Geração dos Dados
data_rows <- list()

for (ind in indicadores) {
  for (ter in territorios) {
    # Definir quais tipos de visualização este par aceita
    # Simulando que todos aceitam Gráfico e alguns aceitam Mapa
    tipos_viz <- c("Gráfico", "Mapa")
    
    for (viz in tipos_viz) {
      # Gerar série histórica
      base_val <- runif(1, 10, 100)
      for (ano in anos) {
        valor <- base_val + rnorm(1, 0, 5) # Flutuação aleatória
        
        data_rows[[length(data_rows) + 1]] <- data.frame(
          eixo = ind$eixo,
          tags = ind$tags,
          ano = ano,
          unidade_territorial = ter$ut,
          nome_unidade_territorial = ter$nome,
          identificador_unidade_territorial = ter$id,
          tipo_visualizacao = viz,
          nome_indicador = ind$nome,
          valor_indicador = round(valor, 2),
          classes_indicador = "Faixa A, Faixa B, Faixa C", # Placeholder para legenda de mapa
          stringsAsFactors = FALSE
        )
      }
    }
  }
}

df_final <- bind_rows(data_rows)

# 3. Exportação
write_xlsx(df_final, "indicadores.xlsx")
print(paste("Gerado indicadores.xlsx com", nrow(df_final), "linhas."))
