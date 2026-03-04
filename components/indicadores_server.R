###################
# indicadores_server.R
# 
# Server module for the indicators explorer
###################

indicadores_server_logic <- function(input, output, session) {
  
  # 1. Observador para Inicializar o Eixo
  observe({
    req(dados_indicadores)
    updateSelectInput(session, "eixo_sel", 
                      choices = unique(dados_indicadores$eixo))
  })
  
  # 2. Reativo para Filtrar Indicadores por Eixo
  observeEvent(input$eixo_sel, {
    req(input$eixo_sel)
    df_eixo <- dados_indicadores %>% filter(eixo == input$eixo_sel)
    
    updateSelectInput(session, "indicador_sel", 
                      choices = unique(df_eixo$nome_indicador))
  })
  
  # 3. Reativo para Filtrar Abrangência e Ano por Indicador
  observeEvent(input$indicador_sel, {
    req(input$indicador_sel)
    df_ind <- dados_indicadores %>% filter(nome_indicador == input$indicador_sel)
    
    updateSelectInput(session, "unidade_sel", 
                      choices = unique(df_ind$unidade_territorial))
    
    updateSelectInput(session, "ano_sel", 
                      choices = sort(unique(df_ind$ano), decreasing = TRUE))
  })
  
  # 4. Motor de Renderização do Gráfico (Plotly)
  output$plot_indicador <- renderPlotly({
    req(input$indicador_sel, input$unidade_sel)
    
    # Filtragem dos dados p/ o gráfico
    df_plot <- dados_indicadores %>%
      filter(nome_indicador == input$indicador_sel,
             unidade_territorial %in% input$unidade_sel) %>%
      arrange(ano)
    
    # Validação de dados para o gráfico
    if(nrow(df_plot) == 0) return(NULL)
    
    # Renderização baseada em ano (X) e valor (Y)
    # Se houver múltiplas unidades territoriais selecionadas, cria várias linhas
    p <- plot_ly(df_plot, 
                 x = ~ano, 
                 y = ~valor_indicador, 
                 color = ~unidade_territorial,
                 type = 'scatter', 
                 mode = 'lines+markers',
                 text = ~paste("Ano:", ano, "<br>Valor:", valor_indicador)) %>%
      layout(
        title = paste("Série Histórica -", input$indicador_sel),
        xaxis = list(title = "Ano"),
        yaxis = list(title = "Valor"),
        legend = list(orientation = 'h', y = -0.2)
      )
    
    return(p)
  })
}
