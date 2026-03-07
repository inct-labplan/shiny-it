###################
# indicadores_server.R
# 
# Server module for the indicators explorer
###################

indicadores_server_logic <- function(input, output, session) {
    
  # 1. Inicializar Eixo e Esconder Outros
  observe({
    req(dados_indicadores)
    updateSelectInput(session, "eixo_sel", 
                      choices = c("Selecione..." = "", unique(dados_indicadores$eixo)))
  })
  
  # Resetar tudo quando mudar o eixo
  observeEvent(input$eixo_sel, {
    if(input$eixo_sel == "") {
      shinyjs::hide("step_indicador")
      shinyjs::hide("step_viz_type")
      shinyjs::hide("step_unidade")
      shinyjs::hide("step_nome_unidade")
      shinyjs::hide("step_ano")
      shinyjs::hide("gerar_viz")
    } else {
      df_eixo <- dados_indicadores %>% filter(eixo == input$eixo_sel)
      updateSelectInput(session, "indicador_sel", 
                        choices = c("Selecione..." = "", unique(df_eixo$nome_indicador)))
      shinyjs::show("step_indicador")
      # Esconder os níveis abaixo se o eixo mudar
      shinyjs::hide("step_viz_type")
      shinyjs::hide("step_unidade")
      shinyjs::hide("step_nome_unidade")
      shinyjs::hide("step_ano")
      shinyjs::hide("gerar_viz")
    }
  })
  
  # 2. Filtrar Tipo de Visualização (e subsequentes cruzados)
  observeEvent(input$indicador_sel, {
    req(input$eixo_sel)
    if(input$indicador_sel == "") {
      shinyjs::hide("step_viz_type")
      shinyjs::hide("step_unidade")
      shinyjs::hide("step_nome_unidade")
      shinyjs::hide("step_ano")
      shinyjs::hide("gerar_viz")
    } else {
      # Dados filtrados pelo par Eixo + Indicador (Contrato de Filtros Cruzados)
      df_cross <- dados_indicadores %>% 
        filter(eixo == input$eixo_sel, nome_indicador == input$indicador_sel)
      
      # 3. Visualizar como: (SelectInput)
      viz_choices <- unique(df_cross$tipo_visualizacao)
      selected_viz <- if(length(viz_choices) == 1) viz_choices else ""
      
      updateSelectInput(session, "viz_type", 
                         choices = c("Selecione..." = "", viz_choices),
                         selected = selected_viz)
      shinyjs::show("step_viz_type")
      
      # Esconder níveis abaixo inicialmente
      shinyjs::hide("step_unidade")
      shinyjs::hide("step_nome_unidade")
      shinyjs::hide("step_ano")
      shinyjs::hide("gerar_viz")
    }
  })
  
  # 3. Filtrar Abrangência (Unidade Territorial)
  observeEvent(input$viz_type, {
    req(input$eixo_sel, input$indicador_sel)
    if(is.null(input$viz_type) || input$viz_type == "" || input$viz_type == "Selecione...") {
      shinyjs::hide("step_unidade")
      shinyjs::hide("step_nome_unidade")
      shinyjs::hide("step_ano")
      shinyjs::hide("gerar_viz")
    } else {
      df_unidade <- dados_indicadores %>% 
        filter(eixo == input$eixo_sel,
               nome_indicador == input$indicador_sel,
               tipo_visualizacao == input$viz_type)
      
      unidade_choices <- unique(df_unidade$unidade_territorial)
      selected_unidade <- if(length(unidade_choices) == 1) unidade_choices else ""
      
      updateSelectInput(session, "unidade_sel", 
                        choices = c("Selecione..." = "", unidade_choices),
                        selected = selected_unidade)
      shinyjs::show("step_unidade")
      
      # Esconder níveis abaixo
      shinyjs::hide("step_nome_unidade")
      shinyjs::hide("step_ano")
      shinyjs::hide("gerar_viz")
    }
  })
  
  # 4. Filtrar Nome da Unidade Territorial
  observeEvent(input$unidade_sel, {
    req(input$eixo_sel, input$indicador_sel, input$viz_type)
    if(input$unidade_sel == "") {
      shinyjs::hide("step_nome_unidade")
      shinyjs::hide("step_ano")
      shinyjs::hide("gerar_viz")
    } else {
      df_nome <- dados_indicadores %>% 
        filter(eixo == input$eixo_sel,
               nome_indicador == input$indicador_sel,
               tipo_visualizacao == input$viz_type,
               unidade_territorial == input$unidade_sel)
      
      new_label <- paste("5. Selecione o(a)", input$unidade_sel)
      nome_unidade_choices <- unique(df_nome$nome_unidade_territorial)
      selected_nome <- if(length(nome_unidade_choices) == 1) nome_unidade_choices else ""
      
      updateSelectInput(session, "nome_unidade_sel", 
                        label = new_label,
                        choices = c("Selecione..." = "", nome_unidade_choices),
                        selected = selected_nome)
      shinyjs::show("step_nome_unidade")
      
      # Esconder níveis abaixo
      shinyjs::hide("step_ano")
      shinyjs::hide("gerar_viz")
    }
  })
  
  # 5. Filtrar Ano (Se Mapa) ou Mostrar Botão
  observeEvent(input$nome_unidade_sel, {
    req(input$eixo_sel, input$indicador_sel, input$viz_type, input$unidade_sel)
    
    if(input$nome_unidade_sel == "") {
      shinyjs::hide("step_ano")
      shinyjs::hide("gerar_viz")
    } else {
      if(input$viz_type == "Mapa") {
        df_ano <- dados_indicadores %>% 
          filter(eixo == input$eixo_sel,
                 nome_indicador == input$indicador_sel,
                 tipo_visualizacao == input$viz_type,
                 unidade_territorial == input$unidade_sel,
                 nome_unidade_territorial == input$nome_unidade_sel)
        
        ano_choices <- sort(unique(df_ano$ano), decreasing = TRUE)
        selected_ano <- if(length(ano_choices) == 1) ano_choices else ""
        
        updateSelectInput(session, "ano_sel", 
                          choices = c("Selecione..." = "", ano_choices),
                          selected = selected_ano)
        shinyjs::show("step_ano")
        
        # Se só tiver um ano, já pode mostrar o botão
        if(selected_ano != "") {
          shinyjs::show("gerar_viz")
        } else {
          shinyjs::hide("gerar_viz")
        }
      } else {
        # Para Gráfico, já pode mostrar o botão
        shinyjs::hide("step_ano")
        shinyjs::show("gerar_viz")
      }
    }
  })
  
  # 6. Mostrar botão se Ano selecionado (para Mapas)
  observeEvent(input$ano_sel, {
    req(input$viz_type == "Mapa")
    if(input$ano_sel != "") {
      shinyjs::show("gerar_viz")
    } else {
      shinyjs::hide("gerar_viz")
    }
  })
  
  # --- LOGICA DE RENDERIZAÇÃO ---
  
  # Resetar visualização ao mudar qualquer filtro (limpar output anterior)
  observeEvent(list(input$eixo_sel, input$indicador_sel, input$viz_type, input$unidade_sel, input$nome_unidade_sel, input$ano_sel), {
    shinyjs::hide("viz_output_container")
    shinyjs::show("viz_placeholder")
  })
  
  # Trigger de Visualização
  observeEvent(input$gerar_viz, {
    shinyjs::hide("viz_placeholder")
    shinyjs::show("viz_output_container")
    
    # Mostrar/Esconder botão de download baseado no tipo
    if(input$viz_type == "Mapa") {
      shinyjs::show("download_mapa")
    } else {
      shinyjs::hide("download_mapa")
    }
  })
  
  # Logica de Download do Mapa (shinyscreenshot)
  observeEvent(input$download_mapa, {
    req(input$viz_type == "Mapa")
    
    filename <- paste0("mapa_", 
                       gsub(" ", "_", input$indicador_sel), "_", 
                       input$ano_sel, ".png")
    
    shinyscreenshot::screenshot(
      selector = "#mapa_indicador",
      filename = filename,
      id = "mapa_indicador"
    )
  })
  
  # Motor de Renderização do Gráfico (Plotly)
  output$plot_indicador <- renderPlotly({
    # Dependência explícita do botão
    input$gerar_viz
    
    # Isolar inputs para não reagir a mudanças neles sem o clique do botão
    isolate({
      req(input$viz_type == "Gráfico")
      req(input$indicador_sel, input$unidade_sel, input$nome_unidade_sel)
      
      # Filtragem dos dados p/ o gráfico
      df_plot <- dados_indicadores %>%
        filter(eixo == input$eixo_sel,
               nome_indicador == input$indicador_sel,
               tipo_visualizacao == "Gráfico",
               unidade_territorial == input$unidade_sel,
               nome_unidade_territorial == input$nome_unidade_sel) %>%
        arrange(ano)
      
      # Validação de dados para o gráfico
      if(nrow(df_plot) == 0) return(NULL)
      
      # Renderização baseada em ano (X) e valor (Y)
      plot_ly(df_plot, 
              x = ~as.integer(ano), 
              y = ~valor_indicador, 
              type = 'scatter', 
              mode = 'lines+markers',
              name = input$nome_unidade_sel,
              text = ~paste("Ano:", ano, "<br>Valor:", valor_indicador)) %>%
        layout(
          title = list(text = paste(df_plot$titulo_visualizacao[1], "<br><sup>", input$nome_unidade_sel, "</sup>"),
                       font = list(size = 14)),
          margin = list(t = 60, b = 100),
          xaxis = list(
            title = "Ano",
            tickmode = "linear",
            dtick = 1
          ),
          yaxis = list(title = "Valor"),
          showlegend = FALSE,
          annotations = list(
            list(
              x = 1, y = -0.25,
              text = paste("Fonte:", df_plot$fonte_dados[1]),
              showarrow = FALSE,
              xref = 'paper', yref = 'paper',
              xanchor = 'right', yanchor = 'auto',
              font = list(size = 10, color = "gray")
            )
          )
        ) %>%
        config(
          displayModeBar = TRUE,
          displaylogo = FALSE,
          modeBarButtonsToRemove = c("zoom2d", "pan2d", "select2d", "lasso2d", "zoomIn2d", "zoomOut2d", "autoScale2d", "resetScale2d")
        )

    })
  })

  # Motor de Renderização do Mapa (Leaflet)
  map_obj <- reactive({
    # Dependência explícita do botão
    input$gerar_viz
    
    # Isolar inputs para não reagir a mudanças neles sem o clique do botão
    isolate({
      req(input$viz_type == "Mapa")
      req(input$indicador_sel, input$unidade_sel, input$nome_unidade_sel, input$ano_sel)
      
      # 1. Filtra indicadores na memória
      df_filtered <- dados_indicadores %>%
        filter(eixo == input$eixo_sel,
               nome_indicador == input$indicador_sel,
               tipo_visualizacao == "Mapa",
               unidade_territorial == input$unidade_sel,
               nome_unidade_territorial == input$nome_unidade_sel,
               ano == as.integer(input$ano_sel))
      
      if(nrow(df_filtered) == 0) return(NULL)
      
      # 2. Busca Geometria Otimizada (Predicate Pushdown no Parquet)
      # Nota: Usando isolate para evitar reatividade indesejada
      sf_map <- withProgress(message = 'Buscando geometrias...', value = 0.5, {
        join_indicators_with_spatial(df_filtered, input$unidade_sel)
      })
      
      if(is.null(sf_map) || nrow(sf_map) == 0) {
        showNotification("Erro: Não foi possível carregar as geometrias para esta seleção.", type = "error")
        return(NULL)
      }
      
      # 3. Renderização Leaflet via Função Compartilhada
      build_indicator_map(sf_map, input$indicador_sel, input$nome_unidade_sel)
    })
  })

  output$mapa_indicador <- renderLeaflet({
    map_obj()
  })
}
