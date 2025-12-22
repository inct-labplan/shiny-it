###################
# sidebar.R
# 
# Create the sidebar menu options for the ui.
###################

sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem(
      text = "Painéis", 
      icon = icon("dashboard"),
      tabName = "uiro_bi", # Parent tabName for main menu item
      startExpanded = FALSE,
      menuSubItem(
        text = "Eixo-1",
        tabName = "it-mapa"  # Sub tab for "Empresas"
      ),
      menuSubItem(text = "Eixo-2", tabName = "eixo2-graficos")
    )
    )
  )


