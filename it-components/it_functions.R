library(leaflet)
library(leaflet.providers)
library(dplyr)
get_bin_levels <- function(category) {
  # Define the standard levels for your "Absolute" maps (based on analise_diego.R and your snippet)
  levels_absolute <- c(
    "0", "1-100", "101-500", "501-2K", "2K-10K", "10K-100K", "100K+"
  )
  
  # Define levels for "Density" maps (based on your snippet)
  levels_density <- c(
    "0-10", "11-25", "26-50", "51-100", "101-200", "201-500", "500+"
  )
  
  # Logic to pick the right set based on the category name
  if (grepl("densidade", category)) {
    return(levels_density)
  } else {
    return(levels_absolute)
  }
}

# --- 2. Function to filter data ---
filter_it_data <- function(data, selected_category) {
  req(selected_category)
  
  filtered <- data %>% 
    dplyr::filter(categoria_intensidade_tecnologica == selected_category)
  
  # This ensures the map and legend respect the logical order, not alphabetical
  correct_levels <- get_bin_levels(selected_category)
  
  filtered$num_estabelecimentos_bin <- factor(
    filtered$num_estabelecimentos_bin,
    levels = correct_levels,
    ordered = TRUE
  )
  
  return(filtered)
}

# --- 3. Function to generate palette ---
generate_it_palette <- function(data) {
  colorFactor(
    palette = "RdYlBu", 
    domain = data$num_estabelecimentos_bin,
    reverse = TRUE 
  )
}

# --- 4. Function to render map ---
render_it_map <- function(data, pal) {
  leaflet(data = data) %>% 
    addTiles() %>%
    addProviderTiles("CartoDB.Positron", group = "CartoDB.Positron") %>%
    addPolygons(
      fillColor = ~pal(num_estabelecimentos_bin),
      fillOpacity = 0.8,
      color = "white",
      weight = 1,
      highlight = highlightOptions(
        weight = 3, 
        color = "black", 
        bringToFront = TRUE
      ),
      label = ~paste0(name_muni, ": ", num_estabelecimentos_bin),
      labelOptions = labelOptions(
        style = list("font-size" = "15px", "font-weight" = "bold"),
        direction = 'auto'
      ),
      popup = ~paste0(
        '<div style="font-size: 16px;">',
        "<b>Estado: </b>", name_state, "<br>",
        "<b>Município: </b>", name_muni, "<br>",
        "<hr style='margin: 5px 0;'>",
        "<b>Nº Estabelecimentos: </b>", num_estabelecimentos, "<br>",
        "<b>Classificação: </b>", num_estabelecimentos_bin,
        "</div>"
      )
    ) %>%
    addLegend(
      pal = pal,
      values = ~num_estabelecimentos_bin,
      opacity = 0.7,
      title = "Classificação",
      position = "bottomright"
    )
}

# 4. [NEW] Function to get metadata text based on category
get_it_metadata <- function(category) {
  # FORCE as.character to ensure switch works
  clean_cat <- as.character(category)
  
  switch(clean_cat,
         "servicos_alta_tecnologia" = list(
           title = "Serviços de Mercado Intensivos em Conhecimento",
           desc = "Engloba serviços de transporte aquático e aéreo, além de serviços técnico-profissionais especializados. Inclui atividades jurídicas, contabilidade, consultoria em gestão, arquitetura, engenharia, publicidade e pesquisa de mercado."
         ),
         "servicos_densidade_altatecnologia" = list(
           title = "Serviços de Conhecimento de Alta Tecnologia",
           desc = "Refere-se a atividades audiovisuais, telecomunicações e desenvolvimento tecnológico. Inclui produção de vídeos, rádio e TV, desenvolvimento de software (TI), pesquisa e desenvolvimento científico (P&D)."
         ),
         "servicos_financeiro" = list(
           title = "Serviços Financeiros Intensivos em Conhecimento",
           desc = "Concentra atividades do setor financeiro e de seguros. Inclui bancos, gestão de fundos, seguros, resseguros, previdência complementar, planos de saúde e aluguéis não-imobiliários (gestão de ativos intangíveis)."
         ),
         "servicos_administracao_conhecimento" = list(
           title = "Serviços Intensivos: Adm. Pública, Saúde e Educação",
           desc = "Abrange serviços essenciais e atividades culturais. Inclui administração pública, defesa, seguridade social, educação, saúde humana, assistência social, atividades veterinárias, artísticas, criativas e de espetáculos."
         ),
         "servicos_mercado_menos" = list(
           title = "Serviços de Mercado Menos Intensivos (Comércio)",
           desc = "Focado no setor comercial tradicional e moderno. Inclui comércio e reparação de veículos automotores, comércio por atacado e comércio varejista de bens diversos."
         ),
         "servicos_diversos" = list(
           title = "Serviços de Mercado Menos Intensivos (Diversos)",
           desc = "Serviços de apoio e logística terrestre. Inclui transporte terrestre, alojamento (hotéis), alimentação (restaurantes), atividades imobiliárias, agenciamento de mão-de-obra, segurança, vigilância e limpeza."
         ),
         "servicos_demais" = list(
           title = "Demais Serviços Menos Intensivos",
           desc = "Outras atividades de serviços pessoais e associativos. Inclui correios e entregas, serviços domésticos, organizações associativas (sindicatos, ONGs), organismos internacionais e serviços pessoais diversos."
         ),
         # Default case if no match found
         list(title = "Informação", 
              desc = paste("Descrição não disponível para a categoria:", clean_cat))
  )
}