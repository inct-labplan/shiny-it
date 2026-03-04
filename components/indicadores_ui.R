###################
# indicadores_ui.R
# 
# UI module for the indicators explorer
###################

indicadores_tab_content <- function() {
  tabItem(
    tabName = "indicadores_explorador",
    fluidRow(
      # Coluna de Filtros
      bs4Card(
        title = "Filtros de Pesquisa",
        width = 3,
        status = "primary",
        solidHeader = TRUE,
        
        selectInput("eixo_sel", "Selecione o Eixo", 
                    choices = c("Carregando..." = ""), 
                    multiple = FALSE),
        
        selectInput("indicador_sel", "Selecione o Indicador", 
                    choices = NULL, 
                    multiple = FALSE),
        
        selectInput("unidade_sel", "Abrangência (Unidade Territorial)", 
                    choices = NULL, 
                    multiple = TRUE), # Permite múltiplas p/ comparar no gráfico
        
        radioButtons("viz_type", "Visualizar como:", 
                     choices = c("Gráfico" = "Gráfico", "Mapa" = "Mapa")),
        
        conditionalPanel(
          condition = "input.viz_type == 'Mapa'",
          selectInput("ano_sel", "Selecione o Ano", choices = NULL)
        )
      ),
      
      # Coluna de Visualização
      bs4Card(
        title = "Visualização de Dados",
        width = 9,
        status = "white",
        
        conditionalPanel(
          condition = "input.viz_type == 'Gráfico'",
          plotlyOutput("plot_indicador", height = "600px")
        ),
        
        conditionalPanel(
          condition = "input.viz_type == 'Mapa'",
          h4("Visualização em Mapa (Em breve...)")
          # leafletOutput("mapa_indicador", height = "600px")
        )
      )
    )
  )
}
