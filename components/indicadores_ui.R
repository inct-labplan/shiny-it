###################
# indicadores_ui.R
# 
# UI module for the indicators explorer
###################

indicadores_tab_content <- function() {
  tabItem(
    tabName = "indicadores_explorador",
    shinyjs::useShinyjs(),
    fluidRow(
      # Coluna de Filtros
      bs4Card(
        title = "Filtros de Pesquisa",
        width = 3,
        status = "primary",
        solidHeader = TRUE,
        
        # Container de Filtros com Altura Fixa para Estabilidade Visual (Item 3.2 da Estratégia)
        div(id = "filters_container",
          style = "min-height: 580px; display: flex; flex-direction: column; justify-content: flex-start;",
          
          selectInput("eixo_sel", "1. Selecione o Eixo", 
                      choices = c("Carregando..." = ""), 
                      multiple = FALSE),
          
          shinyjs::hidden(
            div(id = "step_indicador",
                selectInput("indicador_sel", "2. Selecione o Indicador", 
                            choices = NULL, 
                            multiple = FALSE)
            )
          ),
          
          shinyjs::hidden(
            div(id = "step_viz_type",
                radioButtons("viz_type", "3. Visualizar como:", 
                             choices = c("Aguardando..." = ""),
                             inline = TRUE)
            )
          ),
          
          shinyjs::hidden(
            div(id = "step_unidade",
                selectInput("unidade_sel", "4. Abrangência", 
                            choices = NULL, 
                            multiple = FALSE)
            )
          ),
          
          shinyjs::hidden(
            div(id = "step_nome_unidade",
                selectInput("nome_unidade_sel", "5. Selecione a Unidade", 
                            choices = NULL, 
                            multiple = FALSE)
            )
          ),
          
          shinyjs::hidden(
            div(id = "step_ano",
                selectInput("ano_sel", "6. Selecione o Ano", choices = NULL)
            )
          ),
          
          # Espaçador flexível para empurrar o botão para o final, se desejar manter o botão fixo
          div(style = "flex-grow: 1;"),
          
          br(),
          shinyjs::hidden(
            actionButton("gerar_viz", "Gerar Visualização", 
                         class = "btn-primary btn-block",
                         icon = icon("play"))
          )
        )
      ),
      
      # Coluna de Visualização
      bs4Card(
        title = "Visualização de Dados",
        width = 9,
        status = "white",
        minHeight = "650px", # Estabilidade visual
        
        div(id = "viz_placeholder",
            style = "height: 600px; display: flex; align-items: center; justify-content: center; border: 2px dashed #ddd; color: #999;",
            h4("Selecione os filtros e clique em 'Gerar Visualização'")),
        
        shinyjs::hidden(
          div(id = "viz_output_container",
            conditionalPanel(
              condition = "input.viz_type == 'Gráfico'",
              plotlyOutput("plot_indicador", height = "600px")
            ),
            
            conditionalPanel(
              condition = "input.viz_type == 'Mapa'",
              div(style = "height: 600px; display: flex; align-items: center; justify-content: center; background: #f8f9fa;",
                  h4("Visualização em Mapa (Em breve...)"))
              # leafletOutput("mapa_indicador", height = "600px")
            )
          )
        )
      )
    )
  )
}
