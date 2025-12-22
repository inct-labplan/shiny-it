library(plotly)
library(dplyr)

# 1. Function to filter data based on user input
filter_eixo2_data <- function(data, selected_muni, selected_type) {
  req(selected_muni, selected_type)
  
  data %>%
    filter(
      municipio == selected_muni,
      tipo_tabela == selected_type
    ) %>%
    arrange(anos) # Ensure chronological order for the line chart
}

# 2. Function to render the Plotly graph
render_eixo2_plotly <- function(data, chart_type) {
  req(nrow(data) > 0)
  
  # Base plot
  p <- plot_ly(data, x = ~anos, y = ~valores)
  
  # Formatting title based on variable type
  var_name <- unique(data$tipo_tabela)
  muni_name <- unique(data$municipio)
  
  # Chart logic
  if (chart_type == "bar") {
    p <- p %>% add_bars(
      name = var_name,
      marker = list(color = '#007bff') # Bootstrap Primary Color
    )
  } else {
    p <- p %>% add_trace(
      type = 'scatter', 
      mode = 'lines+markers',
      name = var_name,
      line = list(color = '#007bff', width = 3),
      marker = list(color = '#007bff', size = 8)
    )
  }
  
  # Layout styling
  p %>% layout(
    title = list(text = paste0(var_name, " - ", muni_name), x = 0.05),
    xaxis = list(title = "Ano", type = "category"), # "category" forces all years to show
    yaxis = list(title = "Valor"),
    hovermode = "x unified",
    showlegend = FALSE,
    margin = list(t = 50, b = 50, l = 50, r = 20)
  )
}