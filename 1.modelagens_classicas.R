# 0) Configurações iniciais -----------------------------------------------

# 0.1) Limpando RStudio: Environment e Console
rm(list = ls())
cat("\014")

# 0.2) Importando pacotes necessários
library(dplyr)
library(tidyr)
library(readxl)
library(ggplot2)

# 0.3) Importando base de dados
df <- readxl::read_excel("inputs/preco_leite_ipca.xlsx")

# 0.4) Tratando dados
df_tratado <- 
  df %>% 
  # Separando a coluna "col1" em "data" e "pl_ipca"
  tidyr::separate(col1, into = c("data", "pl_ipca"), sep = "     ") %>% 
  # Convertendo a coluna "data" para o formato de data, adicionando "-01" e 
  # formatando corretamente
  dplyr::mutate(data = as.Date(paste0(data, "-01"), format = "%Y:%m-%d")) %>% 
  # Convertendo a coluna "pl_ipca" para o tipo numérico, substituindo vírgulas 
  # por pontos
  dplyr::mutate(pl_ipca = as.numeric(gsub(",", ".", pl_ipca)))

# 0.5) Definindo configurações para os gráficos
size_line <- 1.2
size_title <- 16
size_axis_title <- 14
size_axis_text <- 12

# 1) Modelo Aditivo -------------------------------------------------------

# 1.1) Adicionando uma coluna de meses
df_tratado$time <- 1:nrow(df_tratado)

# 1.2) Gerando modelo de regressão quadrática
quadratic_model <- stats::lm(pl_ipca ~ poly(time, 2), data = df_tratado)

# 1.3) Obtendo valores da tendência quadrática
df_tratado$quadratic_trend <- stats::predict(quadratic_model)

# 1.4) Gerando série temporal
ts_data <- stats::ts(df_tratado$pl_ipca, start = c(1990, 1), frequency = 12)

# 1.5) Decompondo série temporal para obter a tendência e sazonalidade
ts_decomposed <- stats::stl(ts_data, s.window = "periodic")

# 1.6) Obtendo valores da sazonalidade
df_tratado$sazonalidade <- ts_decomposed$time.series[, "seasonal"]

# 1.7) Calculando tendência desazonalizada
df_tratado$tendencia_desazonalizada <- df_tratado$quadratic_trend - df_tratado$sazonalidade

# 1.8) Plotando a série temporal original, a tendência quadrática e a série desazonalizada
ggplot(df_tratado, aes(x = data)) +
  geom_line(aes(y = pl_ipca, color = "Série Temporal"), size = size_line) +
  geom_line(aes(y = quadratic_trend, color = "Tendência Quadrática"), size = size_line) +
  geom_line(aes(y = tendencia_desazonalizada, color = "Tendência Dessazonalizada"), size = size_line) +
  labs(title = "Análise Gráfica do Modelo Aditivo",
       x = "Data",
       y = "Valor",
       color = "Legenda") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = size_title, face = "bold", hjust = 0.5),
    axis.title.x = element_text(size = size_axis_title),
    axis.title.y = element_text(size = size_axis_title),
    legend.title = element_text(size = size_axis_title, face = "bold"),
    legend.text = element_text(size = size_axis_text),
    axis.text.x = element_text(size = size_axis_text),
    axis.text.y = element_text(size = size_axis_text)
    )

# 2) Modelo Multiplicativo ------------------------------------------------

# 2.1) Criando variáveis de preço e time em log
df_tratado_2 <- 
  df_tratado %>% 
  dplyr::mutate(log_pl_ipca = log(pl_ipca),
                log_time = log(time))

# 2.2) Gerando modelo de regressão quadrática
quadratic_model <- stats::lm(log_pl_ipca ~ log_time, data = df_tratado_2)

# 2.3) Obtendo valores da tendência quadrática
df_tratado_2$log_tendencia <- stats::predict(quadratic_model)

# 2.4) Extraindo o mês de cada data
df_tratado_2$mes <- format(df_tratado_2$data, "%m")

# 2.5) Convertendo os meses em fatores para gerar dummies sazonais
df_tratado_2$mes <- as.factor(df_tratado_2$mes)

# 2.6) Gerando variáveis de dummies sazonais
dummies <- stats::model.matrix(~ mes - 1, data = df_tratado_2)

# 2.7) Incluindo as dummies sazonais no dataframe
df_tratado_2 <- cbind(df_tratado_2, dummies)

# 2.8) Gerando modelo de regressão quadrática
sazonalidade_model <- lm(log_pl_ipca ~ 
                           mes01 + mes02 + mes03 + mes04 + mes05 + mes06 + 
                           mes07 + mes08 + mes09 + mes10 + mes11 + mes12, 
                         data = df_tratado_2)

# 2.9) Gerando valores da tendência quadrática
df_tratado_2$log_sazonalidade <- stats::predict(sazonalidade_model)

# 2.10) Gerando série temporal
ts_data <- stats::ts(df_tratado_2$log_pl_ipca, start = c(1990, 1), frequency = 12)

# 2.11) Decompondo série temporal usando STL para obter a tendência e sazonalidade
ts_decomposed <- stl(ts_data, s.window = "periodic")

# 2.12) Obtendo valores da sazonalidade
df_tratado_2$sazonalidade <- ts_decomposed$time.series[, "seasonal"]

# 2.13) Calculando tendência desazonalizada
df_tratado_2$tendencia_desazonalizada <- df_tratado_2$log_tendencia - df_tratado_2$log_sazonalidade

# 2.14) Plotando o logaritimo da temporal, o logaritimo da sazonalidade, o logaritimo
# da tendência e o logaritimo da tendência dessazonalizada
ggplot(df_tratado_2, aes(x = data)) +
  geom_line(aes(y = log_pl_ipca, color = "Logaritmo da Série"), size = size_line) +
  geom_line(aes(y = log_tendencia, color = "Logaritmo da Tendência"), size = size_line) +
  geom_line(aes(y = log_sazonalidade, color = "Logaritmo da Sazonalidade"), size = size_line) +
  geom_line(aes(y = tendencia_desazonalizada, color = "Logaritimo da Tendência Dessazonalizada"), size = size_line) +
  labs(title = "Análise Gráfica do Modelo Multiplicativo",
       x = "Data",
       y = "Valor",
       color = "Legenda") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = size_title, face = "bold", hjust = 0.5),
    axis.title.x = element_text(size = size_axis_title),
    axis.title.y = element_text(size = size_axis_title),
    legend.title = element_text(size = size_axis_title, face = "bold"),
    legend.text = element_text(size = size_axis_text),
    axis.text.x = element_text(size = size_axis_text),
    axis.text.y = element_text(size = size_axis_text)
  )
