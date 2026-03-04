**Objetivo do documento**

Este documento estabelece o **Modelo de Dados Padrão** que deve ser adotado por todos os eixos do INCT. A padronização permite que o aplicativo Shiny processe novos indicadores automaticamente, garantindo que a evolução do painel ocorra sem a necessidade de reescrita de código para cada novo dado inserido.

O aplicativo Shiny do INCT funcionará como um "tradutor automático": ele fará a leitura das tabelas enviadas pelos eixos e, a depender da seleção do usuário, desenhará os mapas e gráficos na tela. Para que essa tradução funcione sem erros, o aplicativo precisa que todas as tabelas falem a "mesma língua". Dessa forma, conforme os eixos produzem novos indicadores no formato proposto, a criação de novos mapas e gráficos no Shiny consistirá em apenas inserir as tabelas de indicadores no sistema. 

**Limitações de gráficos e mapas gerados de forma automática sem curadoria**

Os Gráficos e Mapas gerados automaticamente seguirão uma paleta de cores padrão. Casos específicos que exijam curadoria visual (ajuste de legendas, cores específicas de alerta, uso de escalas específicas) não serão considerados nessa implementação. 

Todavia, o Shiny será construído para possibilitar customizações futuras nas visualizações pela equipe que ficará responsável pelo painel.

**Divulgação das tabelas de indicadores no CKAN**

As tabelas de indicadores dos eixos serão unificadas e armazenadas em conjuntos de dados no CKAN

**Modelo de Dados**

O que cada eixo deve entregar?

- Os eixos poderão entregar tabelas com 1 ou mais indicadores e com diferentes níveis de abrangência territorial;   
- Caso um eixo entregue diferentes tabelas, elas serão unificadas pela equipe responsável pelo preenchimento de dados no CKAN e serão inseridas no shiny para gerar as visualizações.

| Nome da Coluna | Descrição e Instruções de Preenchimento | Valores Permitidos | Exemplo |
| :---- | :---- | :---- | ----- |
| **eixo** | Identifica qual grupo de pesquisa produziu o dado. | Eixo 1, Eixo 2, Eixo 3 ou Eixo 4 | \- |
| **tags** | Palavras-chave para busca no sistema. Se houver mais de uma, separe-as por ponto e vírgula (;). | Tags definidas no CKAN | Mercado Imobiliário |
| **ano** | O ano ao qual o dado se refere. | \- | 2023 |
| **unidade\_territorial** | Indica o nível de abrangência geográfica do dado. | Município, Região Metropolitana, Unidade da Federação ou País | \- |
| **identificador\_unidade\_territorial** | Código oficial que identifica o local. Para municípios, use sempre o código de 7 dígitos do IBGE. | Serão permitidos somente valores das tabelas de referência de códigos administrativos do IBGE | Ex: 1501406 (Código de Belém/PA) |
| **tipo\_visualizacao** | Define se o dado deve aparecer como um mapa ou como um gráfico no Shiny. | Mapa ou Gráfico |  |
| **nome\_indicador** | O nome do indicador que aparecerá para o usuário no painel. | \- | Definido pelo Eixo (Ex: PIB per capita) |
| **valor\_indicador** | O dado numérico propriamente dito. Não utilize letras ou símbolos aqui. | \- | Ex: 1500.50 (Use ponto para decimais) |
| **classes\_indicador** | Categorias ou faixas de valores usadas para colorir os mapas (ex: Baixo, Médio, Alto). | Definido pelo Eixo (Ex: Classe A) |  |
