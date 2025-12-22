source("./eixo2-components/eixo2_functions.R")

eixo2_server_logic <- function(input, output, session) {
  
  # --- 1. Dynamic Municipality Filter (Hierarchical) ---
  observeEvent(input$eixo2_uf_select, {
    req(input$eixo2_uf_select)
    
    # Filter cities belonging to the selected UF
    cities_in_uf <- df_estatisticas_ibge %>%
      filter(sigla_uf == input$eixo2_uf_select) %>%
      pull(municipio) %>%
      unique() %>%
      sort()
    
    # Update the selectize input
    updateSelectizeInput(
      session,
      inputId = "eixo2_muni_select",
      choices = cities_in_uf,
      selected = cities_in_uf[1], # Default to the first city
      server = TRUE # Enable server-side processing for better performance
    )
  })
  
  # --- 2. Reactive Data Filtering ---
  filtered_data <- reactive({
    req(input$eixo2_muni_select, input$eixo2_var_select)
    
    filter_eixo2_data(
      df_estatisticas_ibge, 
      input$eixo2_muni_select, 
      input$eixo2_var_select
    )
  })
  
  # --- 3. Render Plotly ---
  output$eixo2_main_plot <- renderPlotly({
    data <- filtered_data()
    
    render_eixo2_plotly(data, input$eixo2_chart_type)
  })
  
}