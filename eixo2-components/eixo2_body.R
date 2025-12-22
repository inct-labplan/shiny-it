library(plotly)
library(bs4Dash)
library(shinycssloaders)

# Function that returns the body content for the 'eixo2-graficos' tab
eixo2_tab_content <- function() {
  tabItem(
    tabName = "eixo2-graficos",
    
    # --- ROW 1: Header ---
    fluidRow(
      bs4Card(
        title = "Evolução dos Indicadores Econômicos Municipais",
        width = 12,
        status = "white",
        solidHeader = TRUE, 
        collapsible = TRUE,
        elevation = 2,
        
        # Instructions
        h4("Como usar o dashboard?", style = "font-weight: bold; color: #343a40; margin-top: 5px;"),
        h6("1. Selecione o Estado (UF) para filtrar a lista de municípios.",
           style = "color: #6c757d; line-height: 1.4;"),
        h6("2. Escolha o Município e a Variável Econômica (ex: PIB) para visualizar o gráfico.",
           style = "color: #6c757d; line-height: 1.4; margin-bottom: 15px;"),
        
        # Sources
        h4("Fontes e Referências", style = "font-weight: bold; color: #343a40;"),
        h6(HTML("
          <ul style='padding-left: 20px; color: #6c757d; margin-bottom: 15px;'>
            <li><b>IBGE.</b> Produto Interno Bruto dos Municípios.</li>
            <li><b>Base de Dados.</b> Séries históricas padronizadas (2009-2021).</li>
          </ul>
        ")),
        
        # Data Link
        h4("Acesso aos Dados", style = "font-weight: bold; color: #343a40;"),
        h6(
          tags$a(
            icon("database"), "Acessar Fonte de Dados", 
            href = "https://www.ibge.gov.br/", 
            target = "_blank",
            style = "color: #007bff; font-weight: bold; text-decoration: none;"
          )
        )
      )
    ),
    
    # --- ROW 2: Controls and Chart ---
    fluidRow(
      # Left Column (Controls)
      column(
        width = 3,
        
        bs4Card(
          title = "Parâmetros",
          width = 12,
          status = "primary",
          solidHeader = TRUE,
          collapsible = FALSE,
          
          # 1. [NEW] Select State (UF)
          selectInput(
            inputId = "eixo2_uf_select",
            label = "Selecione o Estado (UF):",
            choices = sort(unique(df_estatisticas_ibge$sigla_uf)),
            selected = sort(unique(df_estatisticas_ibge$sigla_uf))[1]
          ),
          
          # 2. Select Municipality (Updated dynamically)
          selectizeInput( 
            inputId = "eixo2_muni_select",
            label = "Selecione ou Busque o Município:",
            choices = NULL, # Initialized empty, populated by server
            multiple = FALSE,
            options = list(placeholder = 'Aguardando seleção de UF...')
          ),
          
          # 3. Select Variable
          selectInput(
            inputId = "eixo2_var_select",
            label = "Selecione a Variável:",
            choices = unique(df_estatisticas_ibge$tipo_tabela),
            selected = unique(df_estatisticas_ibge$tipo_tabela)[1]
          ),
          
          # 4. Select Chart Type
          radioButtons(
            inputId = "eixo2_chart_type",
            label = "Tipo de Gráfico:",
            choices = c("Linha" = "line", "Barra" = "bar"),
            selected = "line",
            inline = TRUE
          )
        )
      ),
      
      # Right Column (Plotly Graph)
      column(
        width = 9,
        bs4Card(
          title = "Série Histórica",
          width = 12,
          status = "primary",
          solidHeader = TRUE,
          maximizable = TRUE,
          
          withSpinner(
            plotlyOutput("eixo2_main_plot", height = "500px"),
            type = 8,
            color = "#007bff",
            size = 0.5
          )
        )
      )
    )
  )
}