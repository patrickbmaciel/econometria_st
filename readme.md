# Econometria - Séries Temporais

## Introdução

Este projeto, desenvolvido em R, visa aplicar procedimentos práticos com base na econometria de séries temporais. Sendo assim, desenvolveu-se três scripts, cada um focando em diferentes aspectos e métodos de modelagem. No primeiro script, `modelagens_classicas`, são aplicados modelos aditivos e multiplicativos para decompor e entender a série temporal de preços de leite no Brasil. No segundo script, `analise_econometrica`, realiza uma análise econométrica detalhada do índice de preços de imóveis residenciais, verificando a estacionariedade da série e aplicando diferenciações para tentar torná-la estacionária. Por fim, o terceiro script, `modelagem_arima`, utiliza modelo ARIMA para prever o indicador médio mensal do preço do açúcar cristal branco.

## Scripts

### modelagens_classicas

Este script é dividido em três seções principais: configurações iniciais, análise do modelo aditivo e análise do modelo multiplicativo. Na primeira seção, o ambiente de trabalho do RStudio é limpo e os pacotes necessários são carregados. Em seguida, a base de dados `preco_leite_ipca.xlsx` é importada e tratada, convertendo-as para formatos apropriados, além de definir configurações para os gráficos.

Na seção de análise do modelo aditivo, uma coluna de tempo é adicionada à base de dados tratada, e um modelo de regressão quadrática é ajustado para obter a tendência quadrática. A série temporal original é decomposta utilizando o método STL para extrair a sazonalidade, e uma tendência dessazonalizada é calculada. Posteriormente, gráficos são gerados para visualizar a série temporal original, a tendência quadrática e a série dessazonalizada.

A última seção aborda a análise do modelo multiplicativo, onde aplica-se o logaritimo nas variáveis de preço e tempo. Um modelo de regressão quadrática é ajustado para a tendência logarítmica, e dummies sazonais são criadas a partir dos meses da data. A série temporal logarítmica é decomposta novamente utilizando o método STL para obter a sazonalidade. A tendência dessazonalizada em logaritmo é calculada e, por fim, gráficos são gerados para visualizar a série logarítmica, a tendência, a sazonalidade e a tendência dessazonalizada em logaritmo.

### analise_econometrica

Este R Markdown realiza uma análise econométrica do índice de preços de imóveis residenciais no Brasil. Inicialmente, são importados os pacotes necessários e a base de dados é lida. A série temporal é tratada e plotada para visualizar o comportamento dos preços de imóveis de 2010 a 2023, evidenciando uma tendência de crescimento inicial, uma estagnação e uma retomada de crescimento a partir de 2020.

Em seguida, a estacionariedade da série é analisada. Uma variável defasada é criada para modelar a série e verificar a presença de raiz unitária, confirmando que a série não é estacionária. Um correlograma é plotado para visualizar a autocorrelação da série, reforçando a não estacionariedade observada.

Por fim, a série é diferenciada para tentar torná-la estacionária. A série diferenciada é plotada e seu correlograma é analisado, mas observa-se que, mesmo após a diferenciação, a série ainda não é estacionária.

### modelagem_arima

Este script realiza a previsão do indicador médio mensal do preço do açúcar cristal branco, obtido do CEPEA, utilizando técnicas de séries temporais em R. Inicialmente, pacotes necessários são importados, como também a base de dados é lida e tratada. A coluna de datas é formatada e a média mensal dos preços é calculada. A série temporal é então visualizada por meio de um gráfico.

Em seguida, a série temporal é convertida para um objeto `ts` e decomposta em seus componentes (tendência, sazonalidade e ruído), que são visualizados em um gráfico. Um modelo ARIMA é ajustado automaticamente à série utilizando a função `auto.arima`, que identifica os melhores parâmetros do modelo com base em critérios de informação. O modelo ajustado é utilizado para gerar previsões para os próximos 36 meses, e um resumo do modelo é apresentado, incluindo a interpretação dos coeficientes estimados.

Por fim, as previsões são convertidas para um dataframe e visualizadas em um gráfico que mostra tanto os valores históricos quanto as previsões, incluindo intervalos de confiança de 80% e 95%. O gráfico final apresenta as previsões com uma linha tracejada e os intervalos de confiança como áreas sombreadas, permitindo uma análise visual da incerteza associada às previsões.
