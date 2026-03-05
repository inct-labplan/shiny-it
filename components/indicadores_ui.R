###################
# indicadores_ui.R
# 
# UI module for the indicators explorer
###################

indicadores_tab_content <- function() {
  tabItem(
    tabName = "indicadores_explorador",
    shinyjs::useShinyjs(),
    tags$style(HTML("
      /* Reduzir o tamanho da fonte geral */
      .content-wrapper, .main-sidebar { font-size: 0.9rem; }
      .card-title { font-size: 1.1rem !important; }
      .control-label { font-size: 0.85rem !important; margin-bottom: 2px !important; }
      .form-group { margin-bottom: 0.5rem !important; }
      .selectize-input { padding: 4px 8px !important; min-height: 32px !important; font-size: 0.9rem !important; }
      .selectize-dropdown { font-size: 0.9rem !important; }
      .btn { padding: 4px 8px !important; font-size: 0.9rem !important; }
      /* Ajustar paddings dos cards */
      .card-body { padding: 0.75rem !important; }
    ")),
    fluidRow(
      # Coluna de Filtros
      bs4Card(
        title = "Filtros de Pesquisa",
        width = 3,
        status = "primary",
        solidHeader = TRUE,
        
        # Container de Filtros com Altura Fixa Reduzida
        div(id = "filters_container",
          style = "min-height: 480px; display: flex; flex-direction: column; justify-content: flex-start;",
          
          selectInput("eixo_sel", "1. Eixo", 
                      choices = c("Carregando..." = ""), 
                      multiple = FALSE),
          
          shinyjs::hidden(
            div(id = "step_indicador",
                selectInput("indicador_sel", "2. Indicador", 
                            choices = NULL, 
                            multiple = FALSE)
            )
          ),
          
          shinyjs::hidden(
            div(id = "step_viz_type",
                selectInput("viz_type", "3. Visualização", 
                            choices = NULL, 
                            multiple = FALSE)
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
                selectInput("nome_unidade_sel", "5. Unidade", 
                            choices = NULL, 
                            multiple = FALSE)
            )
          ),
          
          shinyjs::hidden(
            div(id = "step_ano",
                selectInput("ano_sel", "6. Ano", choices = NULL)
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
        minHeight = "550px", # Estabilidade visual reduzida
        
        div(id = "viz_placeholder",
            style = "height: 500px; display: flex; align-items: center; justify-content: center; border: 2px dashed #ddd; color: #999;",
            h5("Selecione os filtros e clique em 'Gerar Visualização'")),
        
        shinyjs::hidden(
          div(id = "viz_output_container",
            conditionalPanel(
              condition = "input.viz_type == 'Gráfico'",
              plotlyOutput("plot_indicador", height = "500px")
            ),
            
            conditionalPanel(
              condition = "input.viz_type == 'Mapa'",
              div(style = "height: 500px; display: flex; align-items: center; justify-content: center; background: #f8f9fa;",
               leafletOutput("mapa_indicador", height = "500px"))
            )
          )
        )
      )
    )
  )
}
