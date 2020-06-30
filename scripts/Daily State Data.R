# data from COVID Tracking Project
get_uscovid_data <- function(url = "https://covidtracking.com/api/",
                             unit = c("states", "us"),
                             fname = "-",
                             date = lubridate::today(),
                             ext = "csv",
                             dest = "data-raw/data",
                             save_file = c("y", "n")) {
  unit <- match.arg(unit)
  target <-  paste0(url, unit, "/", "daily.", ext)
  message("target: ", target)
  
  destination <- fs::path(here::here("data-raw/data"),
                          paste0(unit, "_daily_", date), ext = ext)
  
  tf <- tempfile(fileext = ext)
  curl::curl_download(target, tf)
  
  switch(save_file,
         y = fs::file_copy(tf, destination),
         n = NULL)
  
  janitor::clean_names(read_csv(tf))
}

## US state data
cov_us_raw <- get_uscovid_data(url = "https://covidtracking.com/api/v1/", save_file = "n")

#resp <- GET("https://covidtracking.com/api/v1/states/daily.csv")
#http_type(resp)
#http_error(resp)
#jsonRespParsed <- content(resp, as = "parsed")



state_data <- cov_us_raw %>%
  select(
    -pos_neg,
    -check_time_et,
    -commercial_score,
    -date_checked,
    -date_checked,
    -date_modified,
    -death_increase,
    -grade,
    -hospitalized,
    -hospitalized_increase,
    -negative_increase,
    -negative_regular_score,
    -negative_score,
    -positive_increase,
    -positive_score,
    -score,
    -total,
    -total_test_results_increase
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
   new_tests = total_test_results - lead(total_test_results),
   new_pos = positive - lead(positive),
   death_rate = round(death / total_test_results, 4)
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

