###################
# server.R
# 
# Main server function that calls module logic
###################

# Import module server logic
source('./it-components/it_server.R')
source('./eixo2-components/eixo2_server.R')
server <- function(input, output, session) {
  
  # Initialize the logic for the "it" module (Empresas/Intensidade)
  empresas_server_logic(input, output, session)
  eixo2_server_logic(input, output, session)
  
}