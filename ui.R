###################
# ui.R
# 
# Initializes the ui. 
# Used to load in your header, sidebar, and body components.
###################
source('./components/header.R')
source('./components/sidebar.R')
source('./components/body.R')
source('./components/footer.R')


ui <- dashboardPage(
  header = header,
  sidebar =  sidebar,
  body = body,
  footer = footer
  #preloader =  list(html = tagList(spin_1(), "Carregando ..."), color = "#343a40")
)