
metro_counties_mo <- c("Platte", "Clay", "Jackson", "Cass", "Kansas City")
metro_counties_ks <- c("Wyandotte", "Johnson")

get_nyt_data <- function(url = "https://github.com/nytimes/covid-19-data/raw/master/",
                        fname = "us-counties",
                        date = lubridate::today(),
                        ext = "csv",
                        dest = "data-raw/data",
                        save_file = c("n", "y"),
                        ...) {
  
  save_file <- match.arg(save_file)
  target <-  fs::path(url, fname, ext = ext)
  message("target: ", target)
  
  destination <- fs::path(here::here("data-raw/data"),
                          paste0(fname, "_", date), ext = ext)
  
  tf <- tempfile(fileext = ext)
  curl::curl_download(target, tf)
  
  switch(save_file,
         y = fs::file_copy(tf, destination),
         n = NULL)
  
  janitor::clean_names(read_csv(tf, ...))
  
}

# retrieve County data from NYT repo

nytcovcounty <- get_nyt_data(fname = "us-counties")
###--------------------------------------
### UNUSED SO FAR
###--------------------------------------

### NYT state data
#nytcovstate <- get_nyt_data(fname = "us-states")
#
### NYT national (US only) data
#nytcovus <- get_nyt_data(fname = "us")
#
### NYT excess deaths
#nytexcess <- get_nyt_data(fname = "excess-deaths/deaths",
#                          col_types = cols(
#                            country = "c",
#                            placename = "c",
#                            frequency = "c",
#                            start_date = "D",
#                            end_date = "D",
#                            year = "c", # sic
#                            month = "i",
#                            week = "i",
#                            deaths = "i",
#                            expected_deaths = "i",
#                            excess_deaths = "i",
#                            baseline = "c"))

mo_counties <- nytcovcounty %>%
  filter(state == "Missouri")
ks_counties <- nytcovcounty %>% 
  filter(state == "Kansas")

kc_counties_mo <- mo_counties %>%
  filter(county %in% metro_counties_mo)
kc_counties_ks <- ks_counties %>%
  filter(county %in% metro_counties_ks)

metro_kc <- bind_rows(
    list(
      kc_counties_mo,
      kc_counties_ks
        )
                      ) %>% 
    group_by(county) %>% 
    arrange(desc(date)) %>% 
    mutate(new_pos = cases - lead(cases),
           new_deaths = deaths - lead(deaths)) %>%
  tq_mutate(
    select = new_pos,
    mutate_fun = rollapply,
    width = 7,
    align = "right",
    FUN = mean,
    na.rm = TRUE,
    col_rename = "new_pos_7dma"
            ) %>% 
  tq_mutate(
    select = new_deaths,
    mutate_fun = rollapply,
    width = 7,
    align = "right",
    FUN = mean,
    na.rm = TRUE,
    col_rename = "new_deaths_7dma"
            ) %>% 
  ungroup() %>% 
  mutate(county = factor(county))
  
metro_kc_grouped <- bind_rows(
  list(
    kc_counties_mo,
    kc_counties_ks
  )
) %>% 
  group_by(date) %>% 
  summarise(
    cases = sum(cases),
    deaths = sum(deaths)
  ) %>% 
  arrange(desc(date)) %>% 
  mutate(new_pos = cases - lead(cases),
         new_deaths = deaths - lead(deaths),
         proj_new_pos = new_pos * 10) %>%
  tq_mutate(
    select = new_pos,
    mutate_fun = rollapply,
    width = 7,
    align = "right",
    FUN = mean,
    na.rm = TRUE,
    col_rename = "new_pos_7dma"
  ) %>% 
  tq_mutate(
    select = new_deaths,
    mutate_fun = rollapply,
    width = 7,
    align = "right",
    FUN = mean,
    na.rm = TRUE,
    col_rename = "new_deaths_7dma"
  ) %>% 
  mutate(
    infect_window = rolling_sum(new_pos),
    infect_pop = (infect_window/2000000),
    proj_infect_window = rolling_sum(proj_new_pos),
    proj_infect_pop = (proj_infect_window/2000000)
  ) %>% 
  ungroup()
