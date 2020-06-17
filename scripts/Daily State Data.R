rm(list = ls())
library(httr)
library(jsonlite)
library(tidyverse)
library(lubridate)
library(janitor)
library(tidyquant)
library(hrbrthemes)
library(viridis)
library(paletteer)
library(covdata)
library(gghighlight)
library(ggrepel)

theme_set(theme_ipsum())

resp <- GET("https://covidtracking.com/api/v1/states/daily.csv")
http_type(resp)
http_error(resp)
jsonRespParsed <- content(resp, as = "parsed")

state_data <- jsonRespParsed %>%
  select(
    -posNeg,
    -checkTimeEt,
    -commercialScore,
    -dateChecked,
    -dateChecked,
    -dateModified,
    -deathIncrease,
    -grade,
    -hospitalized,
    -hospitalizedIncrease,
    -negativeIncrease,
    -negativeRegularScore,
    -negativeScore,
    -positiveIncrease,
    -positiveScore,
    -score,
    -total,
    -totalTestResultsIncrease
  ) %>%
  replace_na(
    list(
      negative = 0,
      pending = 0,
      death = 0,
      hospitalized = 0,
      total = 0
    )
  ) %>%
  mutate(
    date = ymd(date)
  ) %>%
  group_by(state) %>%
  arrange(desc(date)) %>% 
  mutate(
   new_tests = totalTestResults - lead(totalTestResults),
   new_pos = positive - lead(positive)
  ) %>% 
  tq_mutate(
    select = new_tests,
    mutate_fun = rollapply,
    width = 7,
    align = "right",
    FUN = mean,
    na.rm = TRUE,
    col_rename = "new_test_7dma"
  ) %>% 
  tq_mutate(
    select = new_pos,
    mutate_fun = rollapply,
    width = 7,
    align = "right",
    FUN = mean,
    na.rm = TRUE,
    col_rename = "new_pos_7dma"
  ) %>%
  mutate(
    pos_rate_7dma = round(new_pos_7dma/new_test_7dma, 4)
  ) %>%
  ungroup()
