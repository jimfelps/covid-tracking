select_counties <- c("St. Louis", "Kansas City", "McDonald")

mo_counties %>% 
  filter(county != "Ozark",
         county != "Wayne",
         county != "Dade") %>% 
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
  mutate(county = factor(county)) -> mo_counties_7ma



