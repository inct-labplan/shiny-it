###################
# sidebar.R
# 
# Create the sidebar menu options for the ui.
###################

sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem(
      text = "Indicadores", 
      icon = icon("chart-line"),
      tabName = "indicadores_explorador"
    )
  )
)
