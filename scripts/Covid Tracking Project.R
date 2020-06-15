rm(list = ls())
library(httr)
library(jsonlite)
library(tidyverse)
library(lubridate)
library(janitor)
library(patchwork)
library(gghighlight)

theme_set(theme_light())

filepath_visual <- "~/R/Git/Project/TidyTuesday/Non-TT Visuals/COVID19/Deaths"
filepath_data <- "~/R/Git/Project/TidyTuesday/Non-TT Visuals/COVID19/data/"

# US Current by State (only goes up, not new cases)

resp <- GET("https://covidtracking.com/api/states.csv")
http_type(resp)
http_error(resp)
jsonRespParsed <- content(resp, as = "parsed")

state_data <- jsonRespParsed %>%
  replace_na(
    list(
      negative = 0,
      pending = 0,
      death = 0,
      hospitalized = 0,
      total = 0
    )
  )

state_data %>% group_by()

deaths <- state_data %>%
  filter(death > 0) %>%
  select(state, death) %>%
  adorn_totals("row") %>%
  ggplot(aes(reorder(state, death), death)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(x = "",
       y = "Deaths")

ggsave(paste0(filepath_visual, format(Sys.Date(), "%Y%m%d"),".png"), deaths, width = 16, height = 9, dpi = "retina")

daily <- GET("https://covidtracking.com/api/us/daily.csv")
http_type(daily)
http_error(daily)
dailyparsed <- content(daily, as = "parsed")

dailyparsed %>%
  mutate(date = ymd(date)) %>%
  ggplot(aes(date, positiveIncrease)) +
  geom_point() + 
  geom_line()

daily_death <- dailyparsed %>%
  replace_na(
    list(
      death = 0,
      hospitalized = 0
    )
  ) %>%
  mutate(
    date = ymd(date),
    death_rate = round(death/posNeg, 4),
    daily_death_change = (death - lag(death)),
    daily_death_pct = round(daily_death_change/lag(death),4)
  )

states_daily <- GET("https://covidtracking.com/api/states/daily.csv")
http_type(states_daily)
http_error(states_daily)
states_dailyparsed <- content(states_daily, as = "parsed")

states_dailyparsed %>%
  filter(date == 20200328) %>%
  View()
states_dailyparsed %>%
  replace_na(list(
    hospitalizedIncrease = 0,
    positiveIncrease = 0,
    deathIncrease = 0
  )) %>%
  mutate(date = ymd(date)) %>%
  ggplot(aes(date, positiveIncrease, color = state)) +
  geom_line() +
  theme(legend.position = "none") +
  gghighlight(max(positiveIncrease) > 1000) +
  theme_minimal() + 
  scale_y_log10()


# Look at three of the hardest hit states -----------------------------------------

states_daily_wa <- states_dailyparsed %>%
  mutate(date = ymd(date)) %>%
  filter(state == "WA") %>%
  ggplot(aes(date, positive)) +
  geom_bar(stat = "identity") +
  labs(x = "",
       y = "Positive Tests",
       title = "Positive COVID-19 Tests",
       subtitle = "Washington",
       caption = "")  +
  scale_y_continuous(limits = c(0,20000))

states_daily_ca <- states_dailyparsed %>%
  mutate(date = ymd(date)) %>%
  filter(state == "CA") %>%
  ggplot(aes(date, positive)) +
  geom_bar(stat = "identity") +
  labs(x = "",
       y = "",
       title = "",
       subtitle = "California",
       caption = "")  +
  scale_y_continuous(limits = c(0,20000))

states_daily_ny <- states_dailyparsed %>%
  mutate(date = ymd(date)) %>%
  filter(state == "NY") %>%
  ggplot(aes(date, positive)) +
  geom_bar(stat = "identity") +
  labs(x = "",
       y = "",
       title = "",
       subtitle = "New York",
       caption = "Source: Covid Tracking Project\nhttps://covidtracking.com") +
  scale_y_continuous(limits = c(0,20000))

three_problems <- states_daily_wa | states_daily_ca | states_daily_ny
three_problems

# death rates ------------------------------------------

total <- state_data %>%
  replace_na(list(hospitalized = 0, positive = 0)) %>%
  mutate(us = c("US")) %>%
  group_by(us) %>%
  summarise(hospitalized = sum(hospitalized),
            death = sum(death),
            positive = sum(positive),
            hospital_rate = (hospitalized/positive)*100,
            death_rate = (death/positive)*100) %>%
  View()
#

# death/hospital rates by state -------------------------

states_table <- state_data %>%
  mutate(total_pos_neg = positive + negative,
         infect_rate = (positive/total_pos_neg), 2,
         death_rate = (death/total_pos_neg), 2,
         hospital_rate = (hospitalized/total_pos_neg), 2,
         others_infect = if_else(infect_rate < 0.08, "All Others", state)) %>%
  select(state,
         others_infect,
         positive,
         negative,
         hospitalized,
         death,
         total_pos_neg,
         infect_rate,
         hospital_rate,
         death_rate
         )

infect_exclude <- c("VI","NJ","AL","MP","OH")

infect <- states_table %>%
  filter(infect_rate > 0,
         !(state %in% infect_exclude)) %>%
  group_by(others_infect) %>%
  summarise(positive = sum(positive),
            negative = sum(negative),
            total_pos_neg = positive + negative,
            infect_rate = round(positive/total_pos_neg, 4)) %>%
  ggplot(aes(reorder(others_infect, infect_rate), infect_rate)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = scales::percent(infect_rate, accuracy = 0.01)), hjust = -0.2, size = 3, color = "red", fontface = "bold") +
  coord_flip() + 
  labs(x = "Infection Rate",
       y = "",
       title = "State Infection Rates > 8%")
infect
# Excluded/Reason:
# VI -- 100% infection on 6 tests
# NJ -- not sure about removing right now. rate seems too high and site has notes to review
# AL -- old data for negatives so total is off
# MD -- has not reported negatives since 3/12
# OH -- has not reported negatives since 3/15
# DE -- has not reported negatives since 3/13

# daily change in deaths ------------------------------------

daily_death %>%
  filter(date > "2020-03-11") %>%
  ggplot(aes(date, daily_death_pct)) +
  geom_line(stat = "identity")
