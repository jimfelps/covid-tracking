
metro_counties_mo <- c("Platte", "Clay", "Jackson", "Cass", "Kansas City")
metro_counties_ks <- c("Wyandotte", "Johnson")

nytcovid_counties <- read_csv("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv")

mo_counties <- nytcovid_counties %>%
  filter(state == "Missouri")
ks_counties <- nytcovid_counties %>% 
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
  
