source("./it-components/it_functions.R")

empresas_server_logic <- function(input, output, session) {
  
  # Reactive: Filter Data
  filtered_data <- eventReactive(input$it_update_map_btn, {
    category <- input$it_category_select
    filter_it_data(df_intensidade_terciario, category)
  }, ignoreNULL = FALSE)
  
  # Render Map
  output$it_leaflet_map <- renderLeaflet({
    data <- filtered_data()
    pal <- generate_it_palette(data)
    render_it_map(data, pal)
  })
  
  # [NEW] Render Metadata Text
  # Update this immediately when selection changes (no button press needed for description)
  output$it_metadata_info <- renderUI({
    # Require that the input exists to prevent errors on startup
    req(input$it_category_select)
    
    # Get metadata based on the dropdown selection
    info <- get_it_metadata(input$it_category_select)
    
    # Build the UI
    tagList(
      h5(info$title, style = "font-weight: bold; margin-bottom: 10px; color: #007bff;"),
      p(info$desc, style = "font-size: 0.95rem; text-align: justify; color: #343a40;")
    )
  })
}
  

