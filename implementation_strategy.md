# Estratégia de Refatoração: Modelo de Dados Padrão

Este documento estabelece o plano para migrar o Shiny-IT para um motor de visualização orientado a dados, utilizando o Excel como contrato único e validado.

## 1. Contrato de Dados (Excel)

O arquivo `indicadores.xlsx` é a fonte única de verdade.
- **Formato**: XLSX
- **Colunas Obrigatórias**: `eixo`, `tags`, `ano`, `unidade_territorial`, `nome_unidade_territorial`, `identificador_unidade_territorial`, `tipo_visualizacao`, `nome_indicador`, `valor_indicador`, `classes_indicador`.
- **Validação Sugerida**: Utilizar o pacote `validate` ou `pointblank` para garantir a integridade antes do carregamento.

## 2. Refatoração da Interface (UI)

A estrutura atual de abas fixas (`menuSubItem("Eixo-1", ...), menuSubItem("Eixo-2", ...)`) será consolidada em uma única aba exploratória.

### Novo Fluxo de Filtros (Ordenação Reativa e Cruzada)
No `components/body.R`, teremos um módulo único com a seguinte lógica de dependência:

1.  **Eixo**: `selectInput("eixo_sel", "Selecione o Eixo", choices = NULL)`
2.  **Indicador**: `selectInput("indicador_sel", "Selecione o Indicador", choices = NULL)` (Filtrado pelo Eixo)
3.  **Lógica de Filtros Cruzados**: Após a seleção do Indicador, todas as opções subsequentes (`viz_type`, `unidade_sel`, `nome_unidade_sel` e `ano_sel`) devem ser limitadas estritamente às combinações existentes no banco de dados para o par **Eixo + Indicador** selecionado.
4.  **Tipo de Visualização**: `radioButtons("viz_type", "3. Visualizar como:", choices = NULL, inline = TRUE)`
    - **Display Horizontal**: Exibição lado a lado para economizar espaço vertical.
    - **Seleção Inteligente**: Se o Indicador permitir apenas um tipo (ex: apenas "Gráfico"), esta opção deve vir pré-selecionada e o filtro pode ser desativado/ocultado conforme a relevância.
5.  **Abrangência (Unidade Territorial)**: `selectInput("unidade_sel", "4. Abrangência", choices = NULL)`
6.  **Nome da Unidade Territorial**: `selectInput("nome_unidade_sel", label = ..., choices = NULL)` 
    - O usuário seleciona um nome específico para filtrar o mapa ou gráfico.
7.  **Ano (Condicional se Mapa)**: `selectInput("ano_sel", "Selecione o Ano", choices = NULL)` (Apenas para Mapas).
8.  **Botão de Ação**: `actionButton("gerar_viz", "Gerar Visualização")`

## 3. Princípios de Design para Filtros (UX)

Para garantir uma experiência fluida e evitar confusão no preenchimento do fluxo reativo:

### 3.1 "Gray out" (Desativar) vs. "Ocultar"
- **Ocultar (`conditionalPanel` ou `uiOutput`)**: Use quando a escolha anterior torna o filtro irrelevante. *Exemplo: se o usuário escolhe "Brasil" em Abrangência, o filtro de Estado deve sumir.*
- **Desativar (`shinyjs::disable`)**: Use quando o filtro é obrigatório, mas ainda não tem dados disponíveis. Isso mantém o layout estável e informa ao usuário que existe um próximo passo.

### 3.2 Estabilidade Visual (Evite o "Layout Shift")
- **Placeholders de altura fixa**: Evite que o botão "Gerar Visualização" suba e desça na tela ao inserir elementos dinamicamente. Envolva `uiOutput` em uma `div` com altura mínima ou use o pacote `shinycssloaders`.
- **Skeleton Screens**: Se possível, mostre a estrutura do filtro em cinza antes dos dados carregarem.

### 3.3 Exposição Progressiva (Progressive Disclosure)
- **Fluxo Sequencial**: Em vez de mostrar 6 filtros vazios, mostre apenas o primeiro. Conforme o usuário seleciona, o próximo aparece. Isso reduz a carga cognitiva e foca a decisão em um passo por vez.
- **Transições**: Utilize o pacote `shinyjs` para dar um `show()` suave com animação quando o input anterior for preenchido.

## 4. Lógica de Validação e Processamento

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

## 5. Implementação Passo-a-Passo

### Fase 1: Data Engine & Validation
- Criar script de funções utilitárias para carga e validação.
- `global.R` apenas chama essas funções, mantendo o código limpo.
- Consolidar geometrias base em um objeto global.

### Fase 2: Unificação da UI
- Simplificar `sidebar.R` para remover as sub-abas de Eixos.
- Criar `components/indicadores_body.R` com o layout de filtros e outputs (Leaflet e Plotly).

### Fase 3: Motor de Renderização
- Implementar as funções genéricas de plotagem que aceitam qualquer subconjunto do modelo de dados padronizado.

## 6. Módulo de Malhas (API IBGE)

A construção da tabela de malhas (geometrias) deve ser tratada como um módulo externo ou demonstrativo para não sobrecarregar o tempo de inicialização do Shiny.

- **Estratégia**: Gerar um conjunto de dados pré-processado (RDS ou GeoJSON) contendo as malhas.
- **Escopo**:
  - Estados
  - Municípios
  - Regiões
- **Vantagem**: O Shiny consome apenas o dado final, sem depender de chamadas de API em tempo real para a estrutura base da malha.

## 7. Exemplo de Tabela de Teste (Implementado em `indicadores.xlsx`)
