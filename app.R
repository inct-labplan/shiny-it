###################
# app.R
# 
# Main controller with modular structure
# Used to import your ui and server components; initializes the app.
###################



library(shiny)
library(dplyr)
library(leaflet)
library(htmlwidgets)
library(shinyscreenshot)
library(shinyjs)
# Carregar componentes globais
source('./global.R')

# Carregar componentes da interface
source('./ui.R')
source('./server.R')

# Inicializar aplicação
shinyApp(ui = ui, server = server)
