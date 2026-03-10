# shiny-it
Prova de conceito de um aplicativo Shiny para servir de ferramenta de visualização para o INCT.

## Estrutura do Projeto

O projeto está organizado da seguinte forma:

- **Root**: Contém os arquivos principais do aplicativo Shiny (`app.R`, `ui.R`, `server.R`, `global.R`) e scripts de processamento compartilhado.
- **`components/`**: Módulos UI e Server que compõem a interface do aplicativo.
- **`generate_indicadores/`**: Scripts responsáveis pelo processamento e consolidação dos dados de indicadores.
  - `gen_indicadores.R`: Script mestre que consolida dados de múltiplas fontes.
  - `prepare_data.R`: Valida e converte os dados consolidados para o formato Parquet.
  - `data_processor.R`, `process_diego_data.R`, `process_trovao_data.R`: Scripts de processamento específico por fonte.
- **`ibge_malhas/`**: Contém as malhas espaciais do IBGE em formato Parquet para carregamento otimizado.
  - `download_ibge.R`: Script para baixar e processar malhas do IBGE.
  - `genparquet.sh`: Script auxiliar para conversão de formatos.
- **`dados_tro/`**: Diretório para armazenamento dos dados brutos (GPKG, XLSX) utilizados no processamento.
- **`tests/`**: Testes automatizados utilizando o framework `testthat`.
- **`www/`**: Ativos estáticos (CSS, imagens).

## Fluxo de Dados e Dependências

## Fluxo de Dados e Dependências

### 1. Geração e Padronização de Dados (Pipeline)

Este fluxo descreve a preparação das malhas espaciais e a consolidação dos dados de indicadores.

```mermaid
graph TD
    subgraph SG1 ["1. Referência Espacial (IBGE)"]
        D_IBGE["download_ibge.R: Baixa e otimiza malhas"]
        MALHAS["ibge_malhas/*.parquet: Base geométrica"]
        D_IBGE --> MALHAS
    end

    subgraph SG2 ["2. Processamento de Fontes"]
        GEN["gen_indicadores.R: Script mestre de consolidação"]
        P_DIEGO["process_diego_data.R: Processa dados TI (GeoPackage)"]
        P_TROVAO["process_trovao_data.R: Processa Socioeconômico (Excel)"]
        
        IN_TI["dados_tro/data_ti.gpkg"]
        IN_SOCIO["dados_tro/Dados_total_*.xlsx"]

        GEN --> P_DIEGO
        GEN --> P_TROVAO
        
        IN_TI --> P_DIEGO
        IN_SOCIO --> P_TROVAO
        MALHAS -.->|Valida IDs| P_TROVAO
    end

    subgraph SG3 ["3. Consolidação e Parquet"]
        XLSX["indicadores.xlsx: Tabela consolidada"]
        PREP["prepare_data.R: Valida e Enriquece nomes"]
        PARQUET["indicadores.parquet: Arquivo final otimizado"]

        P_DIEGO --> GEN
        P_TROVAO --> GEN
        GEN --> XLSX
        XLSX --> PREP
        MALHAS -.->|Enriquece Nomes| PREP
        PREP --> PARQUET
    end
```

**Descrição do Pipeline:**
1.  **IBGE:** O script `download_ibge.R` prepara malhas leves (simplificadas) em formato Parquet.
2.  **Processamento:** `gen_indicadores.R` coordena a leitura de dados brutos de TI e Socioeconômicos, utilizando as malhas para validar códigos territoriais.
3.  **Finalização:** `prepare_data.R` converte os resultados para Parquet, enriquecendo a tabela com nomes amigáveis (ex: transformando IDs em nomes de cidades).

---

### 2. Lógica do Aplicativo (Runtime)

O app carrega geometrias pesadas apenas sob demanda para manter a performance.

```mermaid
graph LR
    DB["indicadores.parquet: Dados tabulares"]
    MALHAS_DB["ibge_malhas/*.parquet: Geometrias"]

    subgraph Global ["global.R (Inicialização)"]
        LOAD["Carga de indicadores.parquet em memória"]
        SP["spatial_processor.R: Lógica espacial"]
        VIZ["visualizations.R: Lógica visual"]
    end

    DB --> LOAD
    LOAD -->|dados_indicadores| Server

    subgraph Server ["Server (Módulos)"]
        direction TB
        F1["Filtros em Cascata: Eixo > Indicador > Localidade"] --> F2["Gatilho de Renderização (Botão)"]
        
        subgraph Render ["Motor de Renderização"]
            direction LR
            G_LOGIC{Tipo Viz?}
            G_LOGIC -->|Gráfico| PLOT["Plotly: Gráfico dinâmico"]
            G_LOGIC -->|Mapa| MAP_JOIN["Join Espacial: Filtra geometrias no Parquet"]
            MAP_JOIN --> MAP_BUILD["Leaflet: Mapa interativo"]
        end
        F2 --> Render
    end

    VIZ --> PLOT
    VIZ --> MAP_BUILD
    SP --> MAP_JOIN
    MALHAS_DB -.->|On-demand| MAP_JOIN
```

**Descrição da Lógica:**
1.  **Carga Leve:** O app inicia apenas com os dados tabulares (`indicadores.parquet`).
2.  **Filtros:** A UI utiliza filtros em cascata para navegar pelos eixos e indicadores.
3.  **Renderização sob demanda:** Gráficos são gerados instantaneamente. Para mapas, o `spatial_processor.R` lê apenas as geometrias necessárias dos arquivos Parquet (otimização de I/O), unindo-as aos dados filtrados.

## Como Executar

### 1. Preparação dos Dados

Para baixar as malhas espaciais necessárias:
```bash
cd ibge_malhas
Rscript download_ibge.R
```

Para gerar os indicadores consolidados a partir dos dados brutos:
```bash
cd generate_indicadores
Rscript gen_indicadores.R
```
Isso gerará os arquivos `indicadores.xlsx` e `indicadores.parquet` na raiz do projeto.

### 2. Execução do Aplicativo

Para rodar o aplicativo Shiny, execute na raiz do projeto:
```bash
Rscript -e "shiny::runApp()"
```

## Testes

Os testes podem ser executados com o comando:
```bash
Rscript -e "testthat::test_dir('tests/testthat')"
```
