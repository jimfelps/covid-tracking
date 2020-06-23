
url <- "https://covid19-static.cdn-apple.com/covid19-mobility-data/2010HotfixDev25/v3/en-us/applemobilitytrends-"                 
date_data <- as.character(Sys.Date() - days(2))

apple_counties_mo <- c("Platte County", "Clay County", "Jackson County", "Cass County", "Kansas City")
apple_counties_ks <- c("Wyandotte County", "Johnson County")

amr <- read_csv(paste0(url, date_data, ".csv")) %>% 
  pivot_longer(
    cols = starts_with("2020"),
    names_to = "date",
    values_to = "index"
  ) %>% 
  clean_names()

mo_apple <- amr %>% 
  filter(sub_region == "Missouri",
         region %in% apple_counties_mo)

ks_apple <- amr %>% 
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
