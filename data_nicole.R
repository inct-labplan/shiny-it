library(dplyr)
library(readxl)
library(tidyr)
library(readr)

municipios <- read_csv('municipios.csv', col_types = cols(.default = col_character()))  %>% 
  select(id_municipio, sigla_uf)

path <- "./data/nicole/"

pib <- read_excel("data/nicole/Tabela de dados - ProjetoR(1).xlsx", sheet=1, skip=3)

pib <- pib %>%
  rename(id_municipio = `...1`, municipio = `...2`) %>%
  
  mutate(across(`2009`:`2021`, as.numeric)) %>%
  
  pivot_longer(
    cols = `2009`:`2021`,      
    names_to = "anos",         
    values_to = "valores"
  ) %>% 
  mutate(tipo_tabela = 'PIB - Preços Correntes')


taxa_crescimento <- read_excel("data/nicole/Taxa de crescimento(1).xlsx", skip=3)

taxa_crescimento <- taxa_crescimento %>%
  rename(id_municipio = `...1`, municipio = `...2`) %>%
  select(everything(),-`2021_2010`, ) %>% 
  
  mutate(across(`2009`:`2021`, as.numeric)) %>%
  
  pivot_longer(
    cols = `2009`:`2021`,      
    names_to = "anos",         
    values_to = "valores"
  ) %>% 
  mutate(tipo_tabela = 'PIB - Taxa de Crescimento')



data <- pib %>% 
  bind_rows(taxa_crescimento)  %>% 
  left_join(municipios,
            by='id_municipio')


write_csv(data, 'estatisticas_ibge.csv')

rm(list=ls())
