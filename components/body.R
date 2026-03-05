###################
# body.R
# 
# Create the body for the ui using modular components
###################

# Carregar módulos de interface unificados
source('./components/indicadores_ui.R') 

body <- bs4DashBody(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "assets/custom.css")
  ),
  tabItems(
    # Conteúdo unificado do explorador de indicadores
    indicadores_tab_content()
  )
)
