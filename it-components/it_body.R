library(shinycssloaders)
library(leaflet)

# Function that returns the body content for the 'it-mapa' tab
it_tab_content <- function() {
  tabItem(
    tabName = "it-mapa",
    
    # --- ROW 1: Header, Instructions & Sources ---
    fluidRow(
      bs4Card(
        title = "Distribuição Espacial do Setor Terciário por Intensidade de Conhecimento",
        width = 12,
        status = "white",
        solidHeader = TRUE, 
        collapsible = TRUE,
        elevation = 2,
        
        # 1. Instructions
        h5("Como usar o dashboard?", style = "font-weight: bold; color: #343a40; margin-top: 5px;"),
        h6("Selecione uma categoria de intensidade tecnológica no menu 'Filtros' à esquerda para atualizar a visualização.
           O mapa interativo exibe a distribuição espacial dos estabelecimentos nos municípios brasileiros. 
           Passe o mouse ou clique sobre um município para visualizar detalhes específicos.",
           style = "color: #6c757d; line-height: 1.4; margin-bottom: 15px;"),
        
        # 2. Sources (Moved from bottom)
        h5("Fontes e Referências", style = "font-weight: bold; color: #343a40;"),
        h6(HTML("
          <ul style='padding-left: 20px; color: #6c757d; margin-bottom: 15px;'>
            <li><b>BD.</b> Base dos dados. Censo Demográfico, 2022.</li>
            <li><b>RF.</b> Receita Federal. Cadastro Nacional de Pessoa Jurídica, 2025.</li>
            <li><b>Bibliografia:</b> MIOTO, B. T.; SUGIMOTO, T. N.; TROVÃO, C. J. B. M.. <i>Região Metropolitana de São Paulo: desempenho e inserção regional no período de 2006 a 2016.</i> In: RIBEIRO, M. G.; CLEMENTINO, M. L. M. (org.). Economia metropolitana e desenvolvimento regional: do experimento desenvolvimentista à inflexão ultraliberal. Rio de Janeiro: Letra Capital Editora, 2020.</li>
          </ul>
        ")),
        
        # 3. Data Link
        h5("Acesse o repositório de dados do INCT Labplan para baixar os dados", style = "font-weight: bold; color: #343a40;"),
        h6(
          tags$a(
            icon("database"), "Acesse o CKAN", 
            href = "https://ckan.ipp.ufrn.br/dataset/intensidade-tecnologica", 
            target = "_blank",
            style = "color: #007bff; font-weight: bold; text-decoration: none;"
          )
        )
      )
    ),
    
    # --- ROW 2: Filters/Metadata and Map ---
    fluidRow(
      # Left Column (Controls & Metadata)
      column(
        width = 3,
        
        # 1. Filter Card
        bs4Card(
          title = "Filtros",
          width = 12,
          status = "primary",
          solidHeader = TRUE,
          collapsible = TRUE,
          
          selectInput(
            inputId = "it_category_select",
            label = "Selecione a Categoria:",
            choices = unique(df_intensidade_terciario$categoria_intensidade_tecnologica),
            selected = unique(df_intensidade_terciario$categoria_intensidade_tecnologica)[1],
            multiple = FALSE
          ),
          
          actionButton(
            inputId = "it_update_map_btn",
            label = "Gerar Mapa",
            icon = icon("map-location-dot"),
            class = "btn-primary btn-block"
          )
        ),
        
        # 2. Metadata Box (Dynamic Description)
        bs4Card(
          title = "Sobre a Camada",
          width = 12,
          status = "info",
          solidHeader = TRUE,
          collapsible = TRUE,
          uiOutput("it_metadata_info") # Content rendered in it_server.R
        )
      ),
      
      # Right Column (Map)
      column(
        width = 9,
        bs4Card(
          title = "Mapa Interativo",
          width = 12,
          status = "info",
          solidHeader = TRUE,
          maximizable = TRUE,
          withSpinner(
            leafletOutput("it_leaflet_map", height = "600px"),
            type = 8,
            color = "#007bff",
            size = 0.5
          )
        )
      )
    )
    
  )
}