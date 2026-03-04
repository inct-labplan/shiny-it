###################
# server.R
# 
# Main server function that calls module logic
###################

# Import module server logic
source('./components/indicadores_server.R')

server <- function(input, output, session) {
  
  # Inicializa a lógica do explorador de indicadores
  indicadores_server_logic(input, output, session)
  
}
