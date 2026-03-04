###################
# indicadores_server.R
# 
# Server module for the indicators explorer
###################

indicadores_server_logic <- function(input, output, session) {
  
  # --- LOGICA DE PROGRESSIVE DISCLOSURE ---
  
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
  
  # 2. Filtrar Tipo de Visualização
  observeEvent(input$indicador_sel, {
    req(input$eixo_sel)
    if(input$indicador_sel == "") {
      shinyjs::hide("step_viz_type")
      shinyjs::hide("gerar_viz")
    } else {
      df_viz <- dados_indicadores %>% 
        filter(eixo == input$eixo_sel, nome_indicador == input$indicador_sel)
      
      updateRadioButtons(session, "viz_type", 
                         choices = c("Selecione..." = "", unique(df_viz$tipo_visualizacao)))
      shinyjs::show("step_viz_type")
      # Esconder níveis abaixo
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
      shinyjs::hide("gerar_viz")
    } else {
      df_unidade <- dados_indicadores %>% 
        filter(eixo == input$eixo_sel,
               nome_indicador == input$indicador_sel,
               tipo_visualizacao == input$viz_type)
      
      updateSelectInput(session, "unidade_sel", 
                        choices = c("Selecione..." = "", unique(df_unidade$unidade_territorial)))
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
      shinyjs::hide("gerar_viz")
    } else {
      df_nome <- dados_indicadores %>% 
        filter(eixo == input$eixo_sel,
               nome_indicador == input$indicador_sel,
               tipo_visualizacao == input$viz_type,
               unidade_territorial == input$unidade_sel)
      
      new_label <- paste("5. Selecione o(a)", input$unidade_sel)
      updateSelectInput(session, "nome_unidade_sel", 
                        label = new_label,
                        choices = c("Selecione..." = "", unique(df_nome$nome_unidade_territorial)))
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
        
        updateSelectInput(session, "ano_sel", 
                          choices = c("Selecione..." = "", sort(unique(df_ano$ano), decreasing = TRUE)))
        shinyjs::show("step_ano")
        shinyjs::hide("gerar_viz") # Só mostra o botão após selecionar o ano
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
              x = ~ano, 
              y = ~valor_indicador, 
              type = 'scatter', 
              mode = 'lines+markers',
              name = input$nome_unidade_sel,
              text = ~paste("Ano:", ano, "<br>Valor:", valor_indicador)) %>%
        layout(
          title = list(text = paste("Série Histórica:", input$indicador_sel, "<br><sup>", input$nome_unidade_sel, "</sup>"),
                       font = list(size = 14)),
          margin = list(t = 50),
          xaxis = list(title = "Ano"),
          yaxis = list(title = "Valor"),
          showlegend = FALSE
        ) %>%
        config(displayModeBar = FALSE)
    })
  })
}
