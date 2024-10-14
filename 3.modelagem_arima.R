# 0) Configurações iniciais -----------------------------------------------

# 0.1) Limpando RStudio: Environment e Console
rm(list = ls())
cat("\014")

# 0.2) Importando pacotes necessários
library(dplyr)
library(purrr)
library(readxl)
library(forecast)
library(zoo)
library(ggplot2)
library(plotly)

# 0.3) Definindo o horizonte de previsão, isto é, quantidade de meses
n_previsao <- 36

# 0.4) Definindo configurações de gráficos
size_line <- 1.2
color_line <- "black"
size_title <- 16
size_axis_title <- 14
size_axis_text <- 12

# 1) Lendo base de dados --------------------------------------------------

# 1.1) Importando base de dados
df_acucar <- readxl::read_xlsx(path = "inputs/cepea_acucar.xlsx", 
                               sheet = "Plan 1",
                               skip = 3)

# 1.2) Tratando dataframes: transformação do formato da coluna de data e cáculo da cotação
# média mensal
df_acucar_final <- 
  df_acucar %>% 
  dplyr::select(data = Data, ind_acucar := `À vista R$`) %>% 
  dplyr::mutate(data = sub("^\\d{2}", "01", data),
                data = gsub("/", "-", data)) %>% 
  dplyr::mutate(data = format(as.Date(data, format = "%d-%m-%Y"), "%Y-%m-%d"),
                data = as.Date(data)) %>% 
  dplyr::group_by(data) %>% 
  dplyr::summarise(ind_acucar = mean(ind_acucar))

# 1.3) Plotando série temporal
ggplotly(
  ggplot(df_acucar_final, aes(x = data, y = ind_acucar)) +
    geom_line(color = color_line, size = size_line) +
    labs(x = "Data", 
         y = "Indicador Médio Mensal (R$)",
         title = "Indicador do Açúcar Cristal Branco Médio Mensal") +
    theme_minimal() +
    theme(
      plot.title = element_text(size = size_title, face = "bold"),
      axis.title.x = element_text(size = size_axis_title),
      axis.title.y = element_text(size = size_axis_title),
      axis.text.x = element_text(size = size_axis_text),
      axis.text.y = element_text(size = size_axis_text))
)

# 2) Decompondo série temporal --------------------------------------------

# 2.1) Convertendo data frame para série temporal
acucar_st <- stats::ts(df_acucar_final$ind_acucar, start = c(2003, 5), frequency = 12)

# 2.2) Realizando decomposição
acucar_dec <- stats::decompose(acucar_st)

# 2.3) Plotando decomposição
plot(acucar_dec)

# 3) Gerando previsões ----------------------------------------------------

# 3.1) Gerando ARIMA
arima_acucar <- forecast::auto.arima(acucar_st)

# 3.2) Realizando previsão
previsao_acucar <- forecast::forecast(arima_acucar, h = n_previsao)

# 3.3) Apresentando modelo
summary(arima_acucar)

# 3.4) Interpretação do resultado da modelagem

# 3.4.1) O modelo ARIMA ajustado tem a seguinte estrutura:

# (0,1,1):
# p = 0: Nenhum termo autoregressivo
# d = 1: A série foi diferenciada uma vez para torná-la estacionária
# q = 1: Um termo de média móvel

# (1,0,2)[12]:
# P = 1: Um termo autoregressivo sazonal
# D = 0: Nenhuma diferenciação sazonal
# Q = 2: Dois termos de média móvel sazonais
# [12]: Periodicidade sazonal de 12 (provavelmente mensal)

# 3.4.2) Os coeficientes estimados do modelo são:
# ma1 (termo de média móvel): 0.4684, com erro padrão de 0.0529
# sar1 (termo autoregressivo sazonal): 0.8568, com erro padrão de 0.0866
# sma1 (primeiro termo de média móvel sazonal): -0.7814, com erro padrão de 0.1113
# sma2 (segundo termo de média móvel sazonal): 0.0890, com erro padrão de 0.0696

# 3.5) Explicação da função auto.arima
# Retorna o melhor modelo ARIMA de acordo com o valor de AIC, AICc ou BIC. A função
# realiza uma busca entre os modelos possíveis dentro das restrições de ordem fornecidas.

# Em resumo, a função utiliza algoritmos de seleção de modelos que consideram várias 
# possíveis combinações de parâmetros e escolhem a melhor com base em critérios de informação.

# 4) Analisando previsões -------------------------------------------------

# 4.1) Convertendo as previsões para um dataframe
df_previsao_acucar <- 
  data.frame(
    data = as.Date(as.yearmon(time(previsao_acucar$mean))),
    mean = as.numeric(previsao_acucar$mean),
    lower_80 = as.numeric(previsao_acucar$lower[, 1]),
    upper_80 = as.numeric(previsao_acucar$upper[, 1]),
    lower_95 = as.numeric(previsao_acucar$lower[, 2]),
    upper_95 = as.numeric(previsao_acucar$upper[, 2])
  )

# 4.2) Plotando gráfico com projeção
ggplotly(
  ggplot() +
    geom_line(data = df_acucar_final, aes(x = data, y = ind_acucar, color = "Histórico"), size = size_line) +
    geom_line(data = df_previsao_acucar, aes(x = data, y = mean, color = "Previsão"), size = size_line, linetype = "dashed") +
    geom_ribbon(data = df_previsao_acucar, aes(x = data, ymin = lower_80, ymax = upper_80, fill = "Intervalo de 80%"), alpha = 0.3) +
    geom_ribbon(data = df_previsao_acucar, aes(x = data, ymin = lower_95, ymax = upper_95, fill = "Intervalo de 95%"), alpha = 0.3) +
    labs(x = "Data", 
         y = "Indicador Médio Mensal (R$)",
         title = "Indicador do Açúcar Cristal Branco Médio Mensal Projetado") +
    scale_color_manual(name = NULL, values = c("Histórico" = "black", "Previsão" = "darkgreen")) +
    scale_fill_manual(name = "Legenda", values = c("Intervalo de 80%" = "darkgray", "Intervalo de 95%" = "gray")) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = size_title, face = "bold", hjust = 0.5),
      axis.title.x = element_text(size = size_axis_title),
      axis.title.y = element_text(size = size_axis_title),
      legend.title = element_text(size = size_axis_title, face = "bold"),
      legend.text = element_text(size = size_axis_text),
      axis.text.x = element_text(size = size_axis_text),
      axis.text.y = element_text(size = size_axis_text))
)
