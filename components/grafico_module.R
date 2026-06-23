###################
# grafico_module.R
# 
# Module for Graph visualizations
###################

grafico_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    shinyjs::useShinyjs(),
    tags$style(HTML(paste0("
      .content-wrapper, .main-sidebar { font-size: 0.9rem; }
      .card-title { font-size: 1.1rem !important; }
      .control-label { font-size: 0.85rem !important; margin-bottom: 2px !important; }
      .form-group { margin-bottom: 0.5rem !important; }
      .selectize-input { padding: 4px 8px !important; min-height: 32px !important; font-size: 0.9rem !important; }
      .selectize-dropdown { font-size: 0.9rem !important; }
      .btn { padding: 4px 8px !important; font-size: 0.9rem !important; }
      .card-body { padding: 0.75rem !important; }
    "))),
    fluidRow(
      # Coluna de Filtros (Padrão Anterior)
      bs4Card(
        title = "Filtros do Gráfico",
        width = 3,
        status = "primary",
        solidHeader = TRUE,
        div(style = "min-height: 550px; display: flex; flex-direction: column;",
          selectInput(ns("eixo_sel"), "1. Eixo", 
                      choices = c("Carregando..." = ""), 
                      multiple = FALSE),
          
          shinyjs::hidden(
            div(id = ns("step_projeto"),
                selectInput(ns("projeto_sel"), "2. Projeto", 
                            choices = NULL, 
                            multiple = FALSE)
            )
          ),
          
          shinyjs::hidden(
            div(id = ns("step_indicador"),
                selectInput(ns("indicador_sel"), "3. Indicador", 
                            choices = NULL, 
                            multiple = FALSE)
            )
          ),
          
          shinyjs::hidden(
            div(id = ns("step_unidade"),
                div(style = "display: flex; align-items: center; margin-bottom: 5px;",
                  tags$label("4. Abrangência", class = "control-label", style = "margin-bottom: 0; margin-right: 5px;"),
                  custom_tooltip("Você pode selecionar múltiplas abrangências para comparar diferentes recortes territoriais no gráfico.")
                ),
                selectInput(ns("unidade_sel"),
                            label = NULL,
                            choices = NULL,
                            multiple = TRUE)
            )
          ),
          shinyjs::hidden(
            div(id = ns("step_nome_unidade"),
                selectInput(ns("nome_unidade_sel"), "5. Unidade", 
                            choices = NULL, 
                            multiple = TRUE)
            )
          ),
          
          shinyjs::hidden(
            div(id = ns("step_tipo_grafico"),
                radioButtons(ns("tipo_grafico_sel"), "6. Tipo de Gráfico",
                             choices = c("Linhas" = "lines", "Barras" = "bar"),
                             selected = "lines",
                             inline = TRUE)
            )
          ),
          
          div(style = "flex-grow: 1;"),
          br(),
          shinyjs::hidden(
            actionButton(ns("gerar_viz"), "Gerar Gráfico", 
                         class = "btn-primary btn-block",
                         icon = icon("play"))
          ),
          shinyjs::hidden(
            div(id = ns("ckan_container"),
                uiOutput(ns("link_ckan"))
            )
          )
        )
      ),
      
      # Coluna de Visualização
      bs4Card(
        title = "Gráfico de Indicadores",
        width = 9,
        status = "white",
        minHeight = "600px",
        
        div(id = ns("viz_placeholder"),
            style = "height: 550px; display: flex; align-items: center; justify-content: center; border: 2px dashed #ddd; color: #999;",
            h5("Selecione os filtros e clique em 'Gerar Gráfico'")),
        
        shinyjs::hidden(
          div(id = ns("viz_output_container"),
              plotlyOutput(ns("plot_indicador"), height = "550px")
          )
        )
      )
    )
  )
}

# grafico_sidebar_ui removido pois agora está integrado no grafico_ui

grafico_server <- function(id, dados_indicadores) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # 1. Inicializar Eixo
    observe({
      req(dados_indicadores)
      df_grafico <- dados_indicadores %>% filter(tipo_visualizacao == "Gráfico")
      updateSelectInput(session, "eixo_sel", 
                        choices = c("Selecione..." = "", unique(df_grafico$eixo)))
    })
    
    # Resetar tudo quando mudar o eixo e carregar Projetos
    observeEvent(input$eixo_sel, {
      if(input$eixo_sel == "" || is.null(input$eixo_sel)) {
        shinyjs::hide("step_projeto")
        shinyjs::hide("step_indicador")
        shinyjs::hide("step_unidade")
        shinyjs::hide("step_nome_unidade")
        shinyjs::hide("step_tipo_grafico")
        shinyjs::hide("gerar_viz")
      } else {
        df_eixo <- dados_indicadores %>% 
          filter(eixo == input$eixo_sel, tipo_visualizacao == "Gráfico")
        
        updateSelectInput(session, "projeto_sel", 
                          choices = c("Selecione..." = "", unique(df_eixo$projeto)))
        
        shinyjs::show("step_projeto")
        shinyjs::hide("step_indicador")
        shinyjs::hide("step_unidade")
        shinyjs::hide("step_nome_unidade")
        shinyjs::hide("step_tipo_grafico")
        shinyjs::hide("gerar_viz")
      }
    })
    
    # 2. Filtrar Projeto e carregar Indicadores
    observeEvent(input$projeto_sel, {
      req(input$eixo_sel)
      if(input$projeto_sel == "" || is.null(input$projeto_sel)) {
        shinyjs::hide("step_indicador")
        shinyjs::hide("step_unidade")
        shinyjs::hide("step_nome_unidade")
        shinyjs::hide("step_tipo_grafico")
        shinyjs::hide("gerar_viz")
      } else {
        df_projeto <- dados_indicadores %>% 
          filter(eixo == input$eixo_sel, 
                 projeto == input$projeto_sel,
                 tipo_visualizacao == "Gráfico")
        
        updateSelectInput(session, "indicador_sel", 
                          choices = c("Selecione..." = "", unique(df_projeto$nome_indicador)))
        
        shinyjs::show("step_indicador")
        shinyjs::hide("step_unidade")
        shinyjs::hide("step_nome_unidade")
        shinyjs::hide("step_tipo_grafico")
        shinyjs::hide("gerar_viz")
      }
    })
    
    # 3. Filtrar Indicador
    observeEvent(input$indicador_sel, {
      req(input$eixo_sel, input$projeto_sel)
      if(input$indicador_sel == "" || is.null(input$indicador_sel)) {
        shinyjs::hide("step_unidade")
        shinyjs::hide("step_nome_unidade")
        shinyjs::hide("step_tipo_grafico")
        shinyjs::hide("gerar_viz")
      } else {
        df_unidade <- dados_indicadores %>% 
          filter(eixo == input$eixo_sel, 
                 projeto == input$projeto_sel,
                 nome_indicador == input$indicador_sel,
                 tipo_visualizacao == "Gráfico")
        
        unidade_choices <- unique(df_unidade$unidade_territorial)
        updateSelectInput(session, "unidade_sel", 
                          choices = c("Selecione..." = "", unidade_choices))
        shinyjs::show("step_unidade")
        shinyjs::hide("step_nome_unidade")
        shinyjs::hide("step_tipo_grafico")
        shinyjs::hide("gerar_viz")
      }
    })
    
    # 4. Filtrar Abrangência
    observeEvent(input$unidade_sel, {
      req(input$eixo_sel, input$projeto_sel, input$indicador_sel)
      if(is.null(input$unidade_sel) || length(input$unidade_sel) == 0 || (length(input$unidade_sel) == 1 && input$unidade_sel == "")) {
        shinyjs::hide("step_nome_unidade")
        shinyjs::hide("step_tipo_grafico")
        shinyjs::hide("gerar_viz")
      } else {
        df_nome <- dados_indicadores %>% 
          filter(eixo == input$eixo_sel,
                 projeto == input$projeto_sel,
                 nome_indicador == input$indicador_sel,
                 tipo_visualizacao == "Gráfico",
                 unidade_territorial %in% input$unidade_sel)
        
        # Refatorar geração de label para múltiplas unidades
        label_unidades <- paste(input$unidade_sel, collapse = " / ")
        new_label <- paste("5. Selecione o(a)", label_unidades)
        nome_unidade_choices <- unique(df_nome$nome_unidade_territorial)
        
        updateSelectizeInput(session, "nome_unidade_sel", 
                          label = new_label,
                          choices = nome_unidade_choices,
                          server = TRUE)
        shinyjs::show("step_nome_unidade")
        shinyjs::show("step_tipo_grafico")
        shinyjs::hide("gerar_viz")
      }
    })
    
    # 5. Mostrar botão se Nome da Unidade selecionado
    observeEvent(input$nome_unidade_sel, {
      if(!is.null(input$nome_unidade_sel) && length(input$nome_unidade_sel) > 0 && any(input$nome_unidade_sel != "")) {
        shinyjs::show("gerar_viz")
      } else {
        shinyjs::hide("gerar_viz")
      }
    })
    
    # Resetar visualização ao mudar qualquer filtro
    observeEvent(list(input$eixo_sel, input$projeto_sel, input$indicador_sel, input$unidade_sel, input$nome_unidade_sel, input$tipo_grafico_sel), {
      shinyjs::hide("viz_output_container")
      shinyjs::show("viz_placeholder")
      shinyjs::hide("ckan_container")
    })
    
    # Trigger de Visualização
    observeEvent(input$gerar_viz, {
      shinyjs::hide("viz_placeholder")
      shinyjs::show("viz_output_container")
      shinyjs::show("ckan_container")
    })
    
    # Link CKAN
    output$link_ckan <- renderUI({
      req(input$indicador_sel)
      df_link <- dados_indicadores %>%
        filter(eixo == input$eixo_sel,
               projeto == input$projeto_sel,
               nome_indicador == input$indicador_sel) %>%
        pull(link_ckan_dados) %>%
        unique()
      
      if (length(df_link) > 0 && !is.na(df_link) && df_link != "") {
        tags$div(
          style = "margin-top: 20px; font-size: 0.85rem;",
          tags$hr(),
          tags$p(
            tags$b("Acesse os dados da visualização no "),
            tags$a(href = df_link, target = "_blank", "CKAN", icon("external-link-alt"))
          )
        )
      }
    })
    
    # Renderização
    output$plot_indicador <- renderPlotly({
      input$gerar_viz
      isolate({
        req(input$projeto_sel, input$indicador_sel, input$unidade_sel, input$nome_unidade_sel)
        df_plot <- dados_indicadores %>%
          filter(eixo == input$eixo_sel,
                 projeto == input$projeto_sel,
                 nome_indicador == input$indicador_sel,
                 tipo_visualizacao == "Gráfico",
                 unidade_territorial %in% input$unidade_sel,
                 nome_unidade_territorial %in% input$nome_unidade_sel) %>%
          arrange(ano)
        
        build_indicator_graph(df_plot, input$indicador_sel, input$nome_unidade_sel, input$tipo_grafico_sel)
      })
    })
  })
}
