
google_mobility <- read_csv("https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv",
                            col_types = cols(
                              sub_region_2 = col_character()
                            ))

### CLEAN GOOGLE DATA, FILTER FOR KC METRO -----------------------------------------------------

mo_google <- google_mobility %>% 
  filter(sub_region_1 == "Missouri",
         sub_region_2 %in% apple_counties_mo)

ks_google <- google_mobility %>% 
  filter(sub_region_1 == "Kansas",
         sub_region_2 %in% apple_counties_ks)

bind_rows(mo_google,
          ks_google) %>% 
  rename(
    Retail = retail_and_recreation_percent_change_from_baseline,
    Grocery = grocery_and_pharmacy_percent_change_from_baseline,
    Parks = parks_percent_change_from_baseline,
    Transit = transit_stations_percent_change_from_baseline,
    Workplaces = workplaces_percent_change_from_baseline,
    Residential = residential_percent_change_from_baseline
  ) %>% 
  replace_na(
    list(
      Retail = 0,
      Grocery = 0,
      Parks = 0,
      Transit = 0,
      Workplaces = 0,
      Residential = 0
    )
  ) -> google_mobility_metro

### METRO AREA SUMMARY ------------------------------------------------------------------------

google_mobility_metro %>% 
  group_by(date) %>% 
  summarise(across(c("Retail", "Grocery", "Parks", "Transit", "Workplaces", "Residential"), mean)) %>% 
  ungroup() %>% 
  pivot_longer(
    cols = Retail:Residential,
    names_to = "type",
    values_to = "pct_change"
  ) -> metro_summary

### PLATTE COUNTY SUMMARY ----------------------------------------------------------------------

google_mobility_metro %>% 
  filter(sub_region_2 == "Platte County") %>% 
  group_by(date) %>% 
  summarise(across(c("Retail", "Grocery", "Parks", "Transit", "Workplaces", "Residential"), mean)) %>% 
  ungroup() %>% 
  pivot_longer(
    cols = Retail:Residential,
    names_to = "type",
    values_to = "pct_change"
  ) -> platte_summary

### JACKSON COUNTY SUMMARY ----------------------------------------------------------------------

google_mobility_metro %>% 
  filter(sub_region_2 == "Jackson County") %>% 
  group_by(date) %>% 
  summarise(across(c("Retail", "Grocery", "Parks", "Transit", "Workplaces", "Residential"), mean)) %>% 
  ungroup() %>% 
  pivot_longer(
    cols = Retail:Residential,
    names_to = "type",
    values_to = "pct_change"
  ) -> jackson_summary

### CLAY COUNTY SUMMARY ----------------------------------------------------------------------

google_mobility_metro %>% 
  filter(sub_region_2 == "Clay County") %>% 
  group_by(date) %>% 
  summarise(across(c("Retail", "Grocery", "Parks", "Transit", "Workplaces", "Residential"), mean)) %>% 
  ungroup() %>% 
  pivot_longer(
    cols = Retail:Residential,
    names_to = "type",
    values_to = "pct_change"
  ) -> clay_summary

### WORKPLACE MOVEMENT ----------------------------------------------------------------------

google_mobility_metro %>% 
  group_by(sub_region_2, date) %>% 
  summarise(across(c("Retail", "Grocery", "Parks", "Transit", "Workplaces", "Residential"), mean)) %>% 
  ungroup() %>% 
  pivot_longer(
    cols = Retail:Residential,
    names_to = "type",
    values_to = "pct_change"
  ) %>% 
  filter(type == "Workplaces")-> kc_work_counties

### PARKS MOVEMENT ----------------------------------------------------------------------

google_mobility_metro %>% 
  group_by(sub_region_2, date) %>% 
  summarise(across(c("Retail", "Grocery", "Parks", "Transit", "Workplaces", "Residential"), mean)) %>% 
  ungroup() %>% 
  pivot_longer(
    cols = Retail:Residential,
    names_to = "type",
    values_to = "pct_change"
  ) %>% 
  filter(type == "Parks")-> kc_parks_counties

#metro_summary %>% 
#  ggplot(aes(date, pct_change, group = type, color = type)) +
#  geom_line(size = 0.5, color = "gray80") +
#  geom_smooth(aes(color = type, group = type), se = FALSE) +
#  theme_minimal() +
#  facet_wrap(~ type, ncol = 3) +
#  labs(x = "Date",
#       y = "% Change from Baseline",
#       title = "Relative Trends in Mobility for Kinds of Location in the KC Metro",
#       subtitle = "Data relative to median activity from 1/3 to 2/6",
#       caption = paste0("Source: Google LLC 'Google COVID-19 Community Mobility Reports'\nhttps://www.google.com/covid19/mobility/ Accessed: ", Sys.Date())) +
#  theme(legend.position = "none")

#Google LLC "Google COVID-19 Community Mobility Reports".
#https://www.google.com/covid19/mobility/ Accessed: <date>.