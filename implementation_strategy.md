# Estratégia de Refatoração: Modelo de Dados Padrão

Este documento estabelece o plano para migrar o Shiny-IT para um motor de visualização orientado a dados, utilizando o Excel como contrato único e validado.

## 1. Contrato de Dados (Excel)

O arquivo `indicadores.xlsx` é a fonte única de verdade.
- **Formato**: XLSX
- **Colunas Obrigatórias**: `eixo`, `tags`, `ano`, `unidade_territorial`, `identificador_unidade_territorial`, `tipo_visualizacao`, `nome_indicador`, `valor_indicador`, `classes_indicador`.
- **Validação Sugerida**: Utilizar o pacote `validate` ou `pointblank` para garantir a integridade antes do carregamento.

## 2. Refatoração da Interface (UI)

A estrutura atual de abas fixas (`menuSubItem("Eixo-1", ...), menuSubItem("Eixo-2", ...)`) será consolidada em uma única aba exploratória.

### Novo Fluxo de Filtros
No `components/body.R`, teremos um módulo único com os seguintes inputs reativos:
1. **Eixo**: `selectInput("eixo_sel", "Selecione o Eixo", choices = NULL)`
2. **Indicador**: `selectInput("indicador_sel", "Selecione o Indicador", choices = NULL)` (Dinâmico conforme Eixo)
3. **Unidade Territorial**: `selectInput("unidade_sel", "Abrangência", choices = NULL)` (Dinâmico conforme Indicador)
4. **Tipo de Visualização**: `radioButtons("viz_type", "Visualizar como:", choices = c("Mapa", "Gráfico"))`
5. **Ano (Condicional)**: `selectInput("ano_sel", "Selecione o Ano", choices = NULL)` (Aparece apenas se "Mapa" for selecionado)

## 3. Lógica de Validação e Processamento

A validação e o processamento dos dados serão realizados por um script R independente (ex: `data_processor.R` ou `utils.R`), contendo funções específicas para garantir a integridade do contrato de dados antes do carregamento no Shiny.

### Funções de Validação (Script Independente)
- **Check de Schema**: Verificar se todas as colunas obrigatórias estão presentes.
- **Limpeza de Dados**: Identificar e deletar automaticamente colunas que não pertencem ao contrato de dados padrão.
- **Tipagem**: Garantir que `valor_indicador` seja numérico e `ano` seja tratado corretamente.
- **Integridade de Domínio**: Validar se `tipo_visualizacao` contém apenas os valores permitidos (`Mapa` ou `Gráfico`).

### Fluxo de Carregamento
1. O script de validação lê o `indicadores.xlsx`.
2. Aplica as funções de limpeza e checagem.
3. Retorna um dataframe "limpo" para o `global.R` ou para o ambiente do Shiny.

## 4. Implementação Passo-a-Passo

### Fase 1: Data Engine & Validation
- Criar script de funções utilitárias para carga e validação.
- `global.R` apenas chama essas funções, mantendo o código limpo.
- Consolidar geometrias base em um objeto global.

### Fase 2: Unificação da UI
- Simplificar `sidebar.R` para remover as sub-abas de Eixos.
- Criar `components/indicadores_body.R` com o layout de filtros e outputs (Leaflet e Plotly).

### Fase 3: Motor de Renderização
- Implementar as funções genéricas de plotagem que aceitam qualquer subconjunto do modelo de dados padronizado.

## 5. Módulo de Malhas (API IBGE)

A construção da tabela de malhas (geometrias) deve ser tratada como um módulo externo ou demonstrativo para não sobrecarregar o tempo de inicialização do Shiny.

- **Estratégia**: Gerar um conjunto de dados pré-processado (RDS ou GeoJSON) contendo as malhas.
- **Escopo**:
  - Estados
  - Municípios
  - Regiões
- **Vantagem**: O Shiny consome apenas o dado final, sem depender de chamadas de API em tempo real para a estrutura base da malha.

## 6. Exemplo de Tabela de Teste (Implementado em `indicadores.xlsx`)