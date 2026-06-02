###################
# sidebar.R
# 
# Create the sidebar menu options for the ui.
###################

sidebar <- dashboardSidebar(
  sidebarMenu(
    id = "sidebarmenu",
    menuItem(
      text = "Mapa", 
      icon = icon("map"),
      tabName = "mapa"
    ),
    menuItem(
      text = "Gráfico", 
      icon = icon("chart-bar"),
      tabName = "grafico"
    )
  )
)
