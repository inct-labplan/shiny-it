# shiny-it
Prova de conceito de um aplicativo Shiny para servir de ferramenta de visualização para o INCT.

## Estrutura do Projeto

O projeto está organizado da seguinte forma:

- **Root**: Contém os arquivos principais do aplicativo Shiny (`app.R`, `ui.R`, `server.R`, `global.R`) e scripts de processamento compartilhado.
  - `indicadores.parquet`: Base de dados consolidada.
  - `diretorio_ibge.parquet`: Dicionário de hierarquias territoriais (Brasil > Estado > RM > Município).
  - `map_legend.parquet`: Metadados de classes e cores para as legendas dos mapas.
- **`components/`**: Módulos UI e Server que compõem a interface do aplicativo.
  - `mapa_module.R`: Módulo com filtragem hierárquica dinâmica.
  - `grafico_module.R`: Módulo para visualizações temporais.
  - `sidebar.R`, `header.R`, `body.R`, `footer.R`: Componentes estruturais do layout.
- **`generate_indicadores/`**: Scripts responsáveis pelo processamento e consolidação dos dados de indicadores.
  - `gen_indicadores.R`: Script mestre de consolidação.
  - `prepare_data.R`: Enriquece indicadores com nomes do diretório IBGE.
  - `gen_legend.R`: Calcula quebras de classes.
- **`ibge_malhas/`**: Contém as malhas espaciais do IBGE em formato Parquet.
- **`dados_tro/`**: Diretório para armazenamento dos dados brutos (GPKG, XLSX).
- **`tests/`**: Testes automatizados (`testthat`).
- **`www/`**: Ativos estáticos (CSS, imagens).

## Fluxo de Dados e Dependências

### 1. Geração e Padronização de Dados (Pipeline)

```mermaid
graph TD
    subgraph SG1 ["1. Referência Espacial (IBGE)"]
        D_IBGE["download_ibge.R: Baixa e Otimiza"]
        MALHAS["ibge_malhas/*.parquet: Geometrias"]
        DIR["diretorio_ibge.parquet: Hierarquia"]
        D_IBGE --> MALHAS
        D_IBGE --> DIR
    end

    subgraph SG2 ["2. Processamento de Fontes"]
        GEN["gen_indicadores.R: Consolidação"]
        P_DIEGO["process_diego_data.R: Dados TI"]
        P_TROVAO["process_trovao_data.R: Socioeconômicos"]
        
        IN_TI["dados_tro/data_ti.gpkg"]
        IN_SOCIO["dados_tro/Dados_total_*.xlsx"]

        GEN --> P_DIEGO
        GEN --> P_TROVAO
        IN_TI --> P_DIEGO
        IN_SOCIO --> P_TROVAO
        DIR -.->|Valida IDs| P_TROVAO
    end

    subgraph SG3 ["3. Consolidação e Parquet"]
        XLSX["indicadores.xlsx: Tabela Bruta"]
        PREP["prepare_data.R: Enriquece e Converte"]
        PARQUET["indicadores.parquet: Dados Finais"]
        LEG_GEN["gen_legend.R: Gera quebras"]
        LEG_PQ["map_legend.parquet: Metadados"]

        P_DIEGO --> GEN
        P_TROVAO --> GEN
        GEN --> XLSX
        XLSX --> PREP
        DIR -.->|Enriquece Nomes| PREP
        PREP --> PARQUET
        PREP --> LEG_GEN
        LEG_GEN --> LEG_PQ
    end
```

---

### 2. Lógica do Aplicativo (Runtime)

```mermaid
graph LR
    DB["indicadores.parquet"]
    DIR_DB["diretorio_ibge.parquet"]
    MALHAS_DB["ibge_malhas/*.parquet"]

    subgraph Global ["global.R (Inicialização)"]
        LOAD["Carga de Dados"]
        SP["spatial_processor.R: CRS 4326 + Make Valid"]
        VIZ["visualizations.R: Leaflet + Plotly"]
    end

    DB --> LOAD
    DIR_DB --> LOAD
    LOAD -->|Hierarquia| M_MAPA
    LOAD -->|Dados| M_MAPA
    LOAD -->|Dados| M_GRAFICO

    subgraph Server ["Server (App)"]
        M_MAPA["mapa_module.R: Filtro 6-passos"]
        M_GRAFICO["grafico_module.R: Filtros + Série"]
    end

    M_MAPA -->|Join| MAP_JOIN["Join + Polygons Only"]
    MAP_JOIN --> MAP_BUILD["Leaflet: Bordas Pretas"]
    
    SP --> MAP_JOIN
    VIZ --> MAP_BUILD
    MALHAS_DB -.->|On-demand| MAP_JOIN
```

**Descrição da Lógica:**
1.  **Filtragem Hierárquica:** O `mapa_module.R` utiliza um fluxo de 6 passos (Eixo > Indicador > Granularidade > Recorte > Unidade > Ano), onde o `diretorio_ibge.parquet` garante que apenas recortes válidos para a granularidade selecionada sejam exibidos.
2.  **Robustez Espacial:** O `spatial_processor.R` realiza o tratamento de geometrias usando `st_make_valid`, filtra apenas polígonos (`st_collection_extract`) e projeta para WGS84 (EPSG:4326), garantindo compatibilidade total com o Leaflet.
3.  **Clareza Visual:** Os mapas utilizam bordas pretas mais espessas nos municípios para facilitar a distinção entre unidades territoriais, eliminando a necessidade de camadas de silhueta redundantes.

## Como Executar

### 1. Preparação dos Dados

Para baixar malhas e gerar o diretório IBGE:
```bash
Rscript download_ibge.R
```

Para gerar os indicadores:
```bash
cd generate_indicadores
Rscript gen_indicadores.R
```

### 2. Execução do Aplicativo

Execute na raiz do projeto:
```bash
Rscript -e "shiny::runApp()"
```
