


## Get Apple data
## 1. Find today's URL
get_apple_target <- function(cdn_url = "https://covid19-static.cdn-apple.com",
                             json_file = "covid19-mobility-data/current/v3/index.json") {
  tf <- tempfile(fileext = ".json")
  curl::curl_download(paste0(cdn_url, "/", json_file), tf)
  json_data <- jsonlite::fromJSON(tf)
  paste0(cdn_url, json_data$basePath, json_data$regions$`en-us`$csvPath)
}

## 2. Get the data and return a tibble
get_apple_data <- function(url = get_apple_target(),
                           fname = "applemobilitytrends-",
                           date = stringr::str_extract(get_apple_target(), "\\d{4}-\\d{2}-\\d{2}"),
                           ext = "csv",
                           dest = "data-raw/data",
                           save_file = c("n", "y")) {
  
  save_file <- match.arg(save_file)
  message("target: ", url)
  
  destination <- fs::path(here::here("data-raw/data"),
                          paste0("apple_mobility", "_daily_", date), ext = ext)
  
  tf <- tempfile(fileext = ext)
  curl::curl_download(url, tf)
  
  ## We don't save the file by default
  switch(save_file,
         y = fs::file_copy(tf, destination),
         n = NULL)
  
  janitor::clean_names(readr::read_csv(tf))
}

apple_mobility <- get_apple_data() %>%
  pivot_longer(cols = starts_with("x"), names_to = "date", values_to = "index") %>%
  mutate(
    date = stringr::str_remove(date, "x"),
    date = stringr::str_replace_all(date, "_", "-"),
    date = as_date(date))


apple_counties_mo <- c("Platte County", "Clay County", "Jackson County", "Cass County", "Kansas City")
apple_counties_ks <- c("Wyandotte County", "Johnson County")


mo_apple <- apple_mobility %>% 
  filter(sub_region == "Missouri",
         region %in% apple_counties_mo)

ks_apple <- apple_mobility %>% 
  filter(sub_region == "Kansas",
         region %in% apple_counties_ks)

bind_rows(mo_apple,
          ks_apple) %>% 
  mutate(date = as.Date(date),
         over_under = index < 100,
         index = index - 100) -> apple_mobility_metro

apple_mobility_metro$region <- factor(apple_mobility_metro$region, 
                                      levels = c("Kansas City",
                                                 "Jackson County",
                                                 "Clay County",
                                                 "Platte County",
                                                 "Cass County",
                                                 "Johnson County",
                                                 "Wyandotte County"))

apple_mobility_metro %>% 
  filter(transportation_type == "driving") -> metro_driving

writexl::write_xlsx(metro_driving, "output/metro_driving.xlsx")
writexl::write_xlsx(apple_mobility_metro, "output/apple_mobility_metro.xlsx")
