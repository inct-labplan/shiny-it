###################
# body.R
# 
# Create the body for the ui using modular components
###################

# Carregar módulos de interface
source('./it-components/it_body.R') 
source('./eixo2-components/eixo2_body.R') 
body <- bs4DashBody(
  tabItems(
    #------- Contéudo do dash it -----
    it_tab_content(),
    eixo2_tab_content()
  )
)