###################
# sidebar.R
# 
# Create the sidebar menu options for the ui.
###################

footer <- dashboardFooter(
  left = a(
    href = "https://ipp.ufrn.br/inctlabplan/sobre/",
    target = "_blank", 
    HTML("2026, &copy; INCT-LABPLAN")
  )
)
