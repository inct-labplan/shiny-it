###################
# server.R
# 
# Main server function that calls module logic
###################

# Import module server logic
source('./components/mapa_module.R')
source('./components/grafico_module.R')

server <- function(input, output, session) {
  
  # Inicializa a lógica dos módulos de Mapa e Gráfico
  mapa_server("mapa_mod", dados_indicadores)
  grafico_server("grafico_mod", dados_indicadores)
  
}
