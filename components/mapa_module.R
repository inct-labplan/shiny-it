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
            div(id = ns("step_granularidade"),
                selectInput(ns("granularidade_sel"), "3. Granularidade", 
                            choices = NULL, 
                            multiple = FALSE)
            )
          ),
          
          shinyjs::hidden(
            div(id = ns("step_recorte"),
                selectInput(ns("recorte_sel"), "4. Recorte Territorial", 
                            choices = NULL, 
                            multiple = FALSE)
            )
          ),
          
          shinyjs::hidden(
            div(id = ns("step_unidade_recorte"),
                selectInput(ns("unidade_recorte_sel"), "5. Selecione a Unidade", 
                            choices = NULL, 
                            multiple = FALSE)
            )
          ),
          
          shinyjs::hidden(
            div(id = ns("step_ano"),
                selectInput(ns("ano_sel"), "6. Ano", choices = NULL)
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
        shinyjs::hide("step_granularidade")
        shinyjs::hide("step_recorte")
        shinyjs::hide("step_unidade_recorte")
        shinyjs::hide("step_ano")
        shinyjs::hide("gerar_viz")
      } else {
        df_eixo <- dados_indicadores %>% 
          filter(eixo == input$eixo_sel, tipo_visualizacao == "Mapa")
        updateSelectInput(session, "indicador_sel", 
                          choices = c("Selecione..." = "", unique(df_eixo$nome_indicador)),
                          selected = "")
        shinyjs::show("step_indicador")
        shinyjs::hide("step_granularidade")
        shinyjs::hide("step_recorte")
        shinyjs::hide("step_unidade_recorte")
        shinyjs::hide("step_ano")
      }
    })
    
    # 2. Filtrar Indicador e mostrar Granularidade
    observeEvent(input$indicador_sel, {
      req(input$eixo_sel)
      if(input$indicador_sel == "" || is.null(input$indicador_sel)) {
        shinyjs::hide("step_granularidade")
        shinyjs::hide("step_recorte")
        shinyjs::hide("step_unidade_recorte")
        shinyjs::hide("step_ano")
        shinyjs::hide("gerar_viz")
      } else {
        df_ind <- dados_indicadores %>% 
          filter(eixo == input$eixo_sel, 
                 nome_indicador == input$indicador_sel,
                 tipo_visualizacao == "Mapa")
        
        gran_choices <- unique(df_ind$unidade_territorial)
        updateSelectInput(session, "granularidade_sel", 
                          choices = c("Selecione..." = "", gran_choices),
                          selected = "")
        shinyjs::show("step_granularidade")
        shinyjs::hide("step_recorte")
        shinyjs::hide("step_unidade_recorte")
        shinyjs::hide("step_ano")
      }
    })
    
    # 3. Filtrar Granularidade e mostrar Recorte Territorial
    observeEvent(input$granularidade_sel, {
      req(input$indicador_sel, input$granularidade_sel)
      if(input$granularidade_sel == "" || is.null(input$granularidade_sel)) {
        shinyjs::hide("step_recorte")
        shinyjs::hide("step_unidade_recorte")
        shinyjs::hide("step_ano")
        shinyjs::hide("gerar_viz")
      } else {
        # Identificar IDs presentes nos indicadores para este nível
        df_filtro <- dados_indicadores %>%
          filter(eixo == input$eixo_sel,
                 nome_indicador == input$indicador_sel,
                 unidade_territorial == input$granularidade_sel)
        
        ids_presentes <- unique(as.character(df_filtro$identificador_unidade_territorial))
        
        # Mapeamento Granularidade -> Coluna do Diretorio
        col_id <- switch(input$granularidade_sel,
          "Município" = "id_municipio",
          "Estado" = "id_uf",
          "Região Metropolitana" = "id_regiao_metropolitana",
          "Brasil" = "id_brasil"
        )
        
        # Filtrar diretório pelos IDs que temos nos dados
        df_dir_subset <- diretorio_ibge %>% 
          filter(!!sym(col_id) %in% ids_presentes)
        
        # Determinar quais recortes são possíveis
        recorte_choices <- c()
        if (any(!is.na(df_dir_subset$id_brasil))) recorte_choices <- c(recorte_choices, "Brasil")
        if (any(!is.na(df_dir_subset$id_uf))) recorte_choices <- c(recorte_choices, "Estado")
        if (any(!is.na(df_dir_subset$id_regiao_metropolitana))) recorte_choices <- c(recorte_choices, "Região Metropolitana")
        if (any(!is.na(df_dir_subset$id_municipio))) recorte_choices <- c(recorte_choices, "Município")
        
        # Filtrar recortes permitidos baseado na hierarquia
        niveis <- c("Brasil", "Estado", "Região Metropolitana", "Município")
        idx_gran <- which(niveis == input$granularidade_sel)
        recorte_choices <- intersect(recorte_choices, niveis[1:idx_gran])
        
        updateSelectInput(session, "recorte_sel", 
                          choices = c("Selecione..." = "", recorte_choices),
                          selected = "")
        shinyjs::show("step_recorte")
        shinyjs::hide("step_unidade_recorte")
        shinyjs::hide("step_ano")
      }
    })
    
    # 4. Filtrar Recorte Territorial e mostrar Unidade do Recorte
    observeEvent(input$recorte_sel, {
      req(input$indicador_sel, input$granularidade_sel, input$recorte_sel)
      if(input$recorte_sel == "" || is.null(input$recorte_sel)) {
        shinyjs::hide("step_unidade_recorte")
        shinyjs::hide("step_ano")
        shinyjs::hide("gerar_viz")
      } else {
        # Identificar IDs presentes nos indicadores para este nível de granularidade
        df_filtro <- dados_indicadores %>%
          filter(eixo == input$eixo_sel,
                 nome_indicador == input$indicador_sel,
                 unidade_territorial == input$granularidade_sel)
        
        ids_presentes <- unique(as.character(df_filtro$identificador_unidade_territorial))
        
        col_gran_id <- switch(input$granularidade_sel,
          "Município" = "id_municipio",
          "Estado" = "id_uf",
          "Região Metropolitana" = "id_regiao_metropolitana",
          "Brasil" = "id_brasil"
        )
        
        # Filtrar diretorório pelos IDs disponíveis
        df_dir_subset <- diretorio_ibge %>% 
          filter(!!sym(col_gran_id) %in% ids_presentes)
        
        # Identificar coluna de nomes do Recorte selecionado
        col_rec_nome <- switch(input$recorte_sel,
          "Brasil" = "nome_brasil",
          "Estado" = "nome_uf",
          "Região Metropolitana" = "nome_regiao_metropolitana",
          "Município" = "nome_municipio"
        )
        
        unidades_choices <- unique(df_dir_subset[[col_rec_nome]])
        unidades_choices <- unidades_choices[!is.na(unidades_choices)]
        
        new_label <- paste("5. Selecione o(a)", input$recorte_sel)
        updateSelectInput(session, "unidade_recorte_sel", 
                          label = new_label,
                          choices = c("Selecione..." = "", sort(unidades_choices)),
                          selected = "")
        
        shinyjs::show("step_unidade_recorte")
        shinyjs::hide("step_ano")
      }
    })
    
    # 5. Filtrar Unidade do Recorte e mostrar Ano
    observeEvent(input$unidade_recorte_sel, {
      req(input$indicador_sel, input$granularidade_sel, input$recorte_sel, input$unidade_recorte_sel)
      if(input$unidade_recorte_sel == "" || is.null(input$unidade_recorte_sel)) {
        shinyjs::hide("step_ano")
        shinyjs::hide("gerar_viz")
      } else {
        # Para saber quais anos mostrar, precisamos saber quais registros do indicador estão nessa unidade
        # 1. Identificar quais IDs de granularidade pertencem à unidade de recorte selecionada
        col_rec_nome <- switch(input$recorte_sel,
          "Brasil" = "nome_brasil",
          "Estado" = "nome_uf",
          "Região Metropolitana" = "nome_regiao_metropolitana",
          "Município" = "nome_municipio"
        )
        
        col_gran_id <- switch(input$granularidade_sel,
          "Município" = "id_municipio",
          "Estado" = "id_uf",
          "Região Metropolitana" = "id_regiao_metropolitana",
          "Brasil" = "id_brasil"
        )
        
        ids_na_unidade <- diretorio_ibge %>%
          filter(!!sym(col_rec_nome) == input$unidade_recorte_sel) %>%
          pull(!!sym(col_gran_id)) %>%
          unique() %>%
          as.character()
          
        df_ano <- dados_indicadores %>% 
          filter(eixo == input$eixo_sel,
                 nome_indicador == input$indicador_sel,
                 unidade_territorial == input$granularidade_sel,
                 identificador_unidade_territorial %in% ids_na_unidade)
        
        ano_choices <- sort(unique(df_ano$ano), decreasing = TRUE)
        updateSelectInput(session, "ano_sel", 
                          choices = c("Selecione..." = "", ano_choices),
                          selected = "")
        shinyjs::show("step_ano")
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
    observeEvent(list(input$eixo_sel, input$indicador_sel, input$granularidade_sel, input$recorte_sel, input$unidade_recorte_sel, input$ano_sel), {
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
        req(input$indicador_sel, input$granularidade_sel, input$recorte_sel, input$unidade_recorte_sel, input$ano_sel)
        
        # 1. Identificar quais IDs de granularidade pertencem à unidade de recorte selecionada
        col_rec_nome <- switch(input$recorte_sel,
          "Brasil" = "nome_brasil",
          "Estado" = "nome_uf",
          "Região Metropolitana" = "nome_regiao_metropolitana",
          "Município" = "nome_municipio"
        )
        
        col_gran_id <- switch(input$granularidade_sel,
          "Município" = "id_municipio",
          "Estado" = "id_uf",
          "Região Metropolitana" = "id_regiao_metropolitana",
          "Brasil" = "id_brasil"
        )
        
        ids_na_unidade <- diretorio_ibge %>%
          filter(!!sym(col_rec_nome) == input$unidade_recorte_sel) %>%
          pull(!!sym(col_gran_id)) %>%
          unique() %>%
          as.character()
          
        df_filtered <- dados_indicadores %>%
          filter(eixo == input$eixo_sel,
                 nome_indicador == input$indicador_sel,
                 tipo_visualizacao == "Mapa",
                 unidade_territorial == input$granularidade_sel,
                 identificador_unidade_territorial %in% ids_na_unidade,
                 ano == as.integer(input$ano_sel))
        
        if(nrow(df_filtered) == 0) return(NULL)
        
        sf_map <- withProgress(message = 'Buscando geometrias...', value = 0.5, {
          join_indicators_with_spatial(df_filtered, input$granularidade_sel)
        })
        
        if(is.null(sf_map) || nrow(sf_map) == 0) return(NULL)
        
        # O título do mapa pode usar o nome da unidade selecionada
        build_indicator_map(sf_map, input$indicador_sel, input$unidade_recorte_sel)
      })
    })
  })
}
