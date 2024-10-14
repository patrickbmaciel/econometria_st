# 0) Configurações iniciais -----------------------------------------------

# 0.1) Limpando RStudio: Environment e Console
rm(list = ls())
cat("\014")

# 0.2) Importando pacotes necessários
library(dplyr)
library(lubridate)
library(readxl)
library(writexl)
library(vars)
library(urca)
library(tidyverse)

# 1) Importando bases de dados --------------------------------------------

# 1.1) Exportação de Soja (Comex Stat)
exportacao <-
  readxl::read_xlsx("inputs/trabalho_final/exportacao_soja_comexstat.xlsx") %>%
  dplyr::mutate(data = format(dmy(paste("01", gsub("\\.", "", Mês), Ano, sep = "-")), "%d-%m-%Y")) %>%
  dplyr::select(data, exportacao = `Valor US$ FOB`) %>% 
  dplyr::mutate(data = as.Date(data, format = "%d-%m-%Y"),
                data = format(data, "%Y-%m-%d"),
                data = as.Date(data)) %>%
  dplyr::arrange(-desc(data))

# 1.2) Cotação de Soja Chicago Futuros (Investing)
cotacao <-
  utils::read.csv("inputs/trabalho_final/cotacao_soja_chicago_futuros_investing.csv") %>% 
  dplyr::mutate(data = gsub("\\.", "-", Data),
                # Removendo pontos dos milhares
                cotacao = gsub("\\.", "", Último),
                # Substituindo vírgulas por pontos
                cotacao = gsub(",", ".", cotacao),
                cotacao = as.numeric(cotacao)) %>% 
  dplyr::select(data, cotacao) %>% 
  dplyr::mutate(data = as.Date(data, format = "%d-%m-%Y"),
                data = format(data, "%Y-%m-%d"),
                data = as.Date(data)) %>%
  dplyr::arrange(-desc(data)) %>% 
  dplyr::filter(data >= "2012-01-01")

# 1.3) Taxa de Câmbio Nominal (IPEA Data)
cambio <- 
  readxl::read_xlsx("inputs/trabalho_final/taxa_cambio_nominal_ipeadata.xlsx") %>% 
  dplyr::mutate(data = format(ymd(paste0(data, "-01")), "%d-%m-%Y")) %>% 
  dplyr::mutate(data = as.Date(data, format = "%d-%m-%Y"),
                data = format(data, "%Y-%m-%d"),
                data = as.Date(data)) %>% 
  dplyr::filter(data >= "2012-01-01")

# 1.4) Índice Inflação Brasil (IPEA Data)

# 1.4.1) Mapeando os meses abreviados para números
mes_map <- c("JAN" = "01", "FEV" = "02", "MAR" = "03", "ABR" = "04", "MAI" = "05", "JUN" = "06", 
             "JUL" = "07", "AGO" = "08", "SET" = "09", "OUT" = "10", "NOV" = "11", "DEZ" = "12")

# 1.4.1) Obtendo dados e criando coluna de data numérica
ipca_bra <- 
  readxl::read_xlsx("inputs/trabalho_final/ipca_bra.xlsx") %>% 
  dplyr::mutate(mes_num = mes_map[mes],
                data = as.Date(paste(ano, mes_num, "01", sep = "-"))) %>%
  dplyr::select(data, indice_bra)

# 1.5) Índice Inflação EUA (US Bureau of Labor Statistics)
ipc_eua <- 
  readxl::read_xlsx("inputs/trabalho_final/ipc_eua.xlsx") %>% 
  dplyr::filter(grepl("^M\\d{2}$", mes)) %>%
  dplyr::mutate(mes_num = sub("M", "", mes),
                data = as.Date(paste(ano, mes_num, "01", sep = "-"))) %>%
  dplyr::select(data, indice_eua)

# 2) Deflacionando séries -------------------------------------------------

# 2.1) Definindo bases para o IPC dos EUA e do Brasil para o ano de 2012
base_indice_eua <- ipc_eua$indice_eua[ipc_eua$data == as.Date("2012-01-01")]
base_indice_bra <- ipca_bra$indice_bra[ipca_bra$data == as.Date("2012-01-01")]

# 2.2) Exportação de Soja
exportacao_def <- 
  exportacao %>% 
  dplyr::left_join(ipc_eua) %>% 
  dplyr::mutate(exportacao_def = exportacao / (indice_eua / base_indice_eua)) %>% 
  dplyr::select(data_periodo = data, exportacao_def)

# 2.3) Cotação de Soja Chicago Futuros
cotacao_def <- 
  cotacao %>% 
  dplyr::left_join(ipc_eua) %>% 
  dplyr::mutate(cotacao_def = cotacao / (indice_eua / base_indice_eua)) %>% 
  dplyr::select(data_periodo = data, cotacao_def)

# 2.4) Taxa de Câmbio
cambio_def <- 
  cambio %>% 
  dplyr::left_join(ipca_bra) %>% 
  dplyr::left_join(ipc_eua) %>% 
  dplyr::mutate(cambio_def = cambio * ((indice_eua / base_indice_eua) / (indice_bra / base_indice_bra))) %>% 
  dplyr::select(data_periodo = data, cambio_def)

# 3) Plotando séries deflacionadas ----------------------------------------

# 3.1) Ajustando layout para 3 gráficos (1 coluna, 3 linhas)
par(mfrow = c(3, 1))

# 3.2) Exportação de Soja
plot(exportacao_def$data_periodo, exportacao_def$exportacao_def/10^9, 
     type = "l", col = "darkblue", lwd = 3, 
     xlab = "Data", ylab = "Exportação (Bilhões US$)", 
     main = "Exportações de Soja")

# 3.3) Cotação de Soja
plot(cotacao_def$data_periodo, cotacao_def$cotacao_def, 
     type = "l", col = "darkgreen", lwd = 3, 
     xlab = "Data", ylab = "Cotação (US$)", 
     main = "Cotação da Soja")

# 3.4) Câmbio Real
plot(cambio_def$data_periodo, cambio_def$cambio_def, 
     type = "l", col = "darkred", lwd = 3, 
     xlab = "Data", ylab = "Câmbio (R$/US$)", 
     main = "Taxa de Câmbio")

# 3.5) Voltando ao layout padrão (um gráfico por janela)
par(mfrow = c(1, 1))

# 4) Análise de estacionariedade ------------------------------------------

# Realiza-se o teste Dickey-Fuller Aumentado (ADF) para verificar a 
# estacionariedade das séries temporais.

# 4.1) Exportação de Soja
adf_exportacao <- urca::ur.df(exportacao_def$exportacao_def, type = "drift", selectlags = "AIC")
summary(adf_exportacao)

# 4.2) Cotação de Soja Chicago Futuros
adf_cotacao <- urca::ur.df(cotacao_def$cotacao_def, type = "drift", selectlags = "AIC")
summary(adf_cotacao)

# 4.3) Taxa de Câmbio
adf_cambio <- urca::ur.df(cambio_def$cambio_def, type = "drift", selectlags = "AIC")
summary(adf_cambio)

# Em conclusão, observa-se que a série de exportação de soja é estacionária, 
# enquanto as séries de cotação de soja e taxa de câmbio não são estacionárias 
# em nível.

# 5) Análise de cointegração ----------------------------------------------

# Utiliza-se o teste de Engle-Granger (EG), que é uma abordagem para verificar a
# cointegração entre variáveis.

# Etapas do teste:
# 1. Regressão entre as séries não estacionárias;
# 2. Aplicação de um teste ADF (Augmented Dickey-Fuller) nos resíduos da regressão. 
# Se os resíduos forem estacionários, então as variáveis são cointegradas.

# 5.1) Juntando séries temporais
df_series <- 
  exportacao_def %>% 
  dplyr::left_join(cotacao_def) %>% 
  dplyr::left_join(cambio_def)

# 5.2) Regressão entre as duas séries para obter os resíduos
modelo_eg <- stats::lm(exportacao_def ~ cotacao_def + cambio_def, data = df_series)

# 5.3) Extração dos resíduos da regressão
residuos <- stats::residuals(modelo_eg)

# 5.4) Aplicando o teste ADF nos resíduos
adf_residuos <- urca::ur.df(residuos, type = "none")
summary(adf_residuos)

# Os resultados indicam que há uma relação de cointegração entre as séries de 
# exportação, cotação e câmbio, já que os resíduos da regressão são estacionários.
# Isso implica que as séries não são todas não estacionárias em conjunto, sugerindo 
# que existe uma relação de longo prazo entre elas.

# 6) Estimando VAR --------------------------------------------------------

# O modelo VAR (Vector AutoRegression) é uma ferramenta econométrica para analisar
# séries temporais multivariadas, capturando as relações dinâmicas entre as variáveis.
# Ele trata todas as variáveis do sistema como endógenas, ou seja, cada uma é explicada 
# por suas próprias defasagens e pelas defasagens das outras variáveis.

# Principais características:
# 1. Equações simultâneas: cada variável é explicada pelos valores passados dela 
# e das outras;
# 2. Defasagens (lags): prevê o valor atual de uma variável com base nos valores 
# passados;
# 3. Simetria: todas as variáveis são consideradas interdependentes;
# 4. Usado para prever séries temporais e analisar relações entre variáveis.

# 6.1) Gerando séries em primeira diferença
diff_exportacao <- diff(exportacao_def$exportacao_def)
diff_cotacao <- diff(cotacao_def$cotacao_def)
diff_cambio <- diff(cambio_def$cambio_def)

# 6.2) Combinando as séries em um data frame
df_var <- data.frame(diff_exportacao, diff_cotacao, diff_cambio)

# 6.3) Estimando modelo VAR
var_model <- vars::VAR(df_var, p = 2, type = "const")
print(var_model)

# As equações do modelo VAR mostram as interações entre as diferenças das exportações 
# de soja, da cotação da soja e do câmbio real. As exportações são impulsionadas 
# positivamente por suas próprias defasadas e pela cotação, mas prejudicadas pela 
# apreciação do câmbio. A cotação é impactada positivamente por sua defasada, com 
# efeitos quase nulos das exportações e um impacto negativo do câmbio real. Por 
# sua vez, o câmbio real é positivamente afetado por sua variável defasada, enquanto 
# as exportações e a cotação têm efeitos negativos e insignificantes. Essas dinâmicas 
# evidenciam a interconexão entre as variáveis ao longo do tempo.

# 7) Decompondo a variância -----------------------------------------------

# 7.1) Calculando a decomposição da variância do erro de previsão do VAR estimado
decomposicao <- vars::fevd(var_model, n.ahead = 10)
print(decomposicao)

# A decomposição da variância indica que as diferenças nas exportações de soja 
# são predominantemente explicadas por suas próprias inovações, mostrando forte 
# autocorrelação. A cotação da soja, embora inicialmente autocorrelacionada, passa 
# a ser levemente influenciada pelas exportações ao longo do tempo. O câmbio real 
# também é majoritariamente autocorrelacionado, mas suas dinâmicas são afetadas 
# pelas exportações de soja e pela cotação.

# 7.2) Extraindo a decomposição para a exportação de soja em primeira diferença
exportacao_decomp <- as.data.frame(decomposicao[["diff_exportacao"]])

# 7.3) Gerando gráfico de barras para a decomposição da variância de exportação 
# de soja em primeira diferença
barplot(
  t(as.matrix(exportacao_decomp)),
  beside = TRUE,
  names.arg = 1:10,
  col = c("darkblue", "darkred", "darkgreen"),
  legend.text = c("Exportacao", "Cotacao", "Cambio"),
  args.legend = list(x = "right", cex = 0.8, x.intersp = 0.1),
  xlab = "Períodos de Previsão",
  ylab = "Contribuição (%)",
  main = "Decomposição da Variância de Exportação de Soja (em 1ª diferença)"
  )

# Infere-se que a baixa influência do câmbio na exportação de soja se deve à 
# forte demanda internacional, contratos de longo prazo que protegem contra 
# flutuações cambiais, e ao fato de a soja ser precificada em dólares no mercado 
# global. Além disso, os preços internacionais da commodity e fatores como oferta 
# e demanda globais são mais determinantes para as exportações, enquanto o câmbio 
# afeta mais os lucros em moeda local do que os volumes exportados. Por isso, o 
# impacto direto do câmbio nas exportações de soja é limitado.

# 8) Gerando funções de Impulso-Resposta ----------------------------------

# 8.1) Choque do câmbio na exportação
fir_cambio <- vars::irf(var_model, impulse = "diff_cambio", response = "diff_exportacao", n.ahead = 12, boot = TRUE)
plot(fir_cambio, lwd = 3)

# Conclui-se que uma valorização do real (apreciação da taxa de câmbio) leva a 
# uma queda nas exportações de soja, pelo menos no curto prazo. Isso ocorre 
# porque os produtos brasileiros se tornam mais caros no mercado internacional, 
# perdendo competitividade. No entanto, esse efeito não parece ser permanente, 
# e outros fatores, como a demanda global por soja, podem influenciar as exportações 
# a longo prazo. Além disso, a análise mostra que há uma margem de incerteza 
# considerável sobre a magnitude e a duração desse impacto da taxa de câmbio.

# 8.2) Choque da cotação na exportação
fir_cotacao <- vars::irf(var_model, impulse = "diff_cotacao", response = "diff_exportacao", n.ahead = 12, boot = TRUE)
plot(fir_cotacao, lwd = 3)

# Nota-se que um aumento no preço internacional da soja geralmente impulsiona as
# exportações brasileiras desse grão, tornando a produção mais atrativa para os 
# agricultores. No entanto, esse efeito positivo tende a ser temporário, e outros
# fatores, como a demanda global e os custos de produção, podem influenciar a 
# quantidade exportada a longo prazo. Além disso, existe uma certa incerteza sobre
# a intensidade e a duração desse impacto, como evidenciado pelos intervalos de 
# confiança do modelo.

# Por fim, enquanto uma valorização da moeda nacional tende a reduzir as 
# exportações, um aumento no preço internacional da soja impulsiona as vendas 
# externas. No entanto, ambos os efeitos são temporários e influenciados por 
# diversos outros fatores, como a demanda mundial, condições climáticas e 
# políticas governamentais. A magnitude e a persistência desses efeitos podem 
# variar, e a análise econômica envolve incertezas. Em resumo, as exportações de 
# soja são sensíveis tanto às variações cambiais quanto aos preços internacionais, 
# mas a direção e a intensidade desses impactos dependem de um conjunto complexo 
# de fatores. Essas informações são cruciais para a formulação de políticas 
# públicas que visam estimular o setor agrícola e para a gestão de riscos por 
# parte dos produtores e exportadores de soja.
