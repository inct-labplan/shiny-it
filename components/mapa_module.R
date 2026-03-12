###################
# mapa_module.R
# 
# Module for Map visualizations
###################

mapa_ui <- function(id) {
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
        title = "Filtros do Mapa",
        width = 3,
        status = "primary",
        solidHeader = TRUE,
        div(style = "min-height: 550px; display: flex; flex-direction: column;",
          selectInput(ns("eixo_sel"), "1. Eixo", 
                      choices = c("Carregando..." = ""), 
                      multiple = FALSE),
          
          shinyjs::hidden(
            div(id = ns("step_indicador"),
                selectInput(ns("indicador_sel"), "2. Indicador", 
                            choices = NULL, 
                            multiple = FALSE)
            )
          ),
          
          shinyjs::hidden(
            div(id = ns("step_unidade"),
                selectInput(ns("unidade_sel"), "3. Abrangência", 
                            choices = NULL, 
                            multiple = FALSE)
            )
          ),
          
          shinyjs::hidden(
            div(id = ns("step_nome_unidade"),
                selectInput(ns("nome_unidade_sel"), "4. Unidade", 
                            choices = NULL, 
                            multiple = FALSE)
            )
          ),
          
          shinyjs::hidden(
            div(id = ns("step_ano"),
                selectInput(ns("ano_sel"), "5. Ano", choices = NULL)
            )
          ),
          
          div(style = "flex-grow: 1;"),
          br(),
          shinyjs::hidden(
            actionButton(ns("gerar_viz"), "Gerar Mapa", 
                         class = "btn-primary btn-block",
                         icon = icon("play"))
          )
        )
      ),
      
      # Coluna de Visualização
      bs4Card(
        title = "Mapa de Indicadores",
        width = 9,
        status = "white",
        minHeight = "600px",
        
        div(id = ns("viz_placeholder"),
            style = "height: 550px; display: flex; align-items: center; justify-content: center; border: 2px dashed #ddd; color: #999;",
            h5("Selecione os filtros e clique em 'Gerar Mapa'")),
        
        shinyjs::hidden(
          div(id = ns("viz_output_container"),
              div(style = "margin-bottom: 10px; display: flex; justify-content: flex-end;",
                  shinyjs::hidden(
                    actionButton(ns("download_mapa"), "Baixar Mapa", 
                                 class = "btn-info btn-sm",
                                 icon = icon("camera"))
                  )
              ),
              leafletOutput(ns("mapa_indicador"), height = "550px")
          )
        )
      )
    )
  )
}

# mapa_sidebar_ui removido pois agora está integrado no mapa_ui

mapa_server <- function(id, dados_indicadores) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Lógica permanece a mesma, mudando apenas referências visuais se necessário
    
    # 1. Inicializar Eixo
    observe({
      req(dados_indicadores)
      df_mapa <- dados_indicadores %>% filter(tipo_visualizacao == "Mapa")
      updateSelectInput(session, "eixo_sel", 
                        choices = c("Selecione..." = "", unique(df_mapa$eixo)))
    })
    
    # Resetar tudo quando mudar o eixo
    observeEvent(input$eixo_sel, {
      if(input$eixo_sel == "" || is.null(input$eixo_sel)) {
        shinyjs::hide("step_indicador")
        shinyjs::hide("step_unidade")
        shinyjs::hide("step_nome_unidade")
        shinyjs::hide("step_ano")
        shinyjs::hide("gerar_viz")
      } else {
        df_eixo <- dados_indicadores %>% 
          filter(eixo == input$eixo_sel, tipo_visualizacao == "Mapa")
        updateSelectInput(session, "indicador_sel", 
                          choices = c("Selecione..." = "", unique(df_eixo$nome_indicador)))
        shinyjs::show("step_indicador")
        shinyjs::hide("step_unidade")
        shinyjs::hide("step_nome_unidade")
        shinyjs::hide("step_ano")
        shinyjs::hide("gerar_viz")
      }
    })
    
    # 2. Filtrar Indicador
    observeEvent(input$indicador_sel, {
      req(input$eixo_sel)
      if(input$indicador_sel == "" || is.null(input$indicador_sel)) {
        shinyjs::hide("step_unidade")
        shinyjs::hide("step_nome_unidade")
        shinyjs::hide("step_ano")
        shinyjs::hide("gerar_viz")
      } else {
        df_unidade <- dados_indicadores %>% 
          filter(eixo == input$eixo_sel, 
                 nome_indicador == input$indicador_sel,
                 tipo_visualizacao == "Mapa")
        
        unidade_choices <- unique(df_unidade$unidade_territorial)
        updateSelectInput(session, "unidade_sel", 
                          choices = c("Selecione..." = "", unidade_choices))
        shinyjs::show("step_unidade")
        shinyjs::hide("step_nome_unidade")
        shinyjs::hide("step_ano")
        shinyjs::hide("gerar_viz")
      }
    })
    
    # 3. Filtrar Abrangência
    observeEvent(input$unidade_sel, {
      req(input$eixo_sel, input$indicador_sel)
      if(input$unidade_sel == "" || is.null(input$unidade_sel)) {
        shinyjs::hide("step_nome_unidade")
        shinyjs::hide("step_ano")
        shinyjs::hide("gerar_viz")
      } else {
        df_nome <- dados_indicadores %>% 
          filter(eixo == input$eixo_sel,
                 nome_indicador == input$indicador_sel,
                 tipo_visualizacao == "Mapa",
                 unidade_territorial == input$unidade_sel)
        
        new_label <- paste("4. Selecione o(a)", input$unidade_sel)
        nome_unidade_choices <- unique(df_nome$nome_unidade_territorial)
        
        updateSelectizeInput(session, "nome_unidade_sel", 
                          label = new_label,
                          choices = c("Selecione..." = "", nome_unidade_choices),
                          server = TRUE)
        shinyjs::show("step_nome_unidade")
        shinyjs::hide("step_ano")
        shinyjs::hide("gerar_viz")
      }
    })
    
    # 4. Filtrar Nome da Unidade e Ano
    observeEvent(input$nome_unidade_sel, {
      req(input$eixo_sel, input$indicador_sel, input$unidade_sel)
      if(input$nome_unidade_sel == "" || is.null(input$nome_unidade_sel)) {
        shinyjs::hide("step_ano")
        shinyjs::hide("gerar_viz")
      } else {
        df_ano <- dados_indicadores %>% 
          filter(eixo == input$eixo_sel,
                 nome_indicador == input$indicador_sel,
                 tipo_visualizacao == "Mapa",
                 unidade_territorial == input$unidade_sel,
                 nome_unidade_territorial == input$nome_unidade_sel)
        
        ano_choices <- sort(unique(df_ano$ano), decreasing = TRUE)
        updateSelectInput(session, "ano_sel", 
                          choices = c("Selecione..." = "", ano_choices))
        shinyjs::show("step_ano")
        shinyjs::hide("gerar_viz")
      }
    })
    
    # 5. Mostrar botão se Ano selecionado
    observeEvent(input$ano_sel, {
      if(!is.null(input$ano_sel) && input$ano_sel != "") {
        shinyjs::show("gerar_viz")
      } else {
        shinyjs::hide("gerar_viz")
      }
    })
    
    # Resetar visualização ao mudar qualquer filtro
    observeEvent(list(input$eixo_sel, input$indicador_sel, input$unidade_sel, input$nome_unidade_sel, input$ano_sel), {
      shinyjs::hide("viz_output_container")
      shinyjs::show("viz_placeholder")
    })
    
    # Trigger de Visualização
    observeEvent(input$gerar_viz, {
      shinyjs::hide("viz_placeholder")
      shinyjs::show("viz_output_container")
      shinyjs::show("download_mapa")
    })
    
    # Download
    observeEvent(input$download_mapa, {
      filename <- paste0("mapa_", gsub(" ", "_", input$indicador_sel), "_", input$ano_sel, ".png")
      shinyscreenshot::screenshot(selector = paste0("#", ns("mapa_indicador")), filename = filename)
    })
    
    # Renderização
    output$mapa_indicador <- renderLeaflet({
      input$gerar_viz
      isolate({
        req(input$indicador_sel, input$unidade_sel, input$nome_unidade_sel, input$ano_sel)
        df_filtered <- dados_indicadores %>%
          filter(eixo == input$eixo_sel,
                 nome_indicador == input$indicador_sel,
                 tipo_visualizacao == "Mapa",
                 unidade_territorial == input$unidade_sel,
                 nome_unidade_territorial == input$nome_unidade_sel,
                 ano == as.integer(input$ano_sel))
        
        if(nrow(df_filtered) == 0) return(NULL)
        
        sf_map <- withProgress(message = 'Buscando geometrias...', value = 0.5, {
          join_indicators_with_spatial(df_filtered, input$unidade_sel)
        })
        
        if(is.null(sf_map) || nrow(sf_map) == 0) return(NULL)
        build_indicator_map(sf_map, input$indicador_sel, input$nome_unidade_sel)
      })
    })
  })
}
