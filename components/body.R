###################
# body.R
# 
# Create the body for the ui using modular components
###################

# Carregar novos módulos
source('./components/mapa_module.R')
source('./components/grafico_module.R')

body <- bs4DashBody(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "assets/custom.css")
  ),
  tabItems(
    # Tab de Mapa
    tabItem(
      tabName = "mapa",
      mapa_ui("mapa_mod")
    ),
    # Tab de Gráfico
    tabItem(
      tabName = "grafico",
      grafico_ui("grafico_mod")
    )
  )
)
