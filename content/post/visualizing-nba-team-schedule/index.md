---
title: Visualizing an NBA Team's Schedule Using R
# slug: visualizing-nba-team-schedule
date: "2017-11-26"
categories:
  - r
  - nba
tags:
  - r
  - ggplot
  - nba
image:
  caption: ""
  focal_point: ""
  preview_only: false
header:
  caption: ""
  image: "featured.jpg"
---

If you're not completely new to the data science community
(specifically, the `#rstats` community), then you've probably seen a
version of the "famous" data science workflow diagram. [^1] 

![](data-science.png)

If one is fairly familiar with a certain topic, then one might not spend
much time with the initial "visualize" step of the workflow. Such is the
case with me and NBA data--as a relatively knowledgeable NBA follower, I
don't necessarily need to spend much of my time exploring raw NBA data
prior to modeling.

Anyways, as a break from experimenting with predictive models, I decided
to make a visualization just for the sake of trying something I hadn't
done before. [^2] In particular, I was inspired by the calendar heat map
visualization that I saw in the [Top 50 ggplot visualizations
post](https://r-statistics.co/Top50-Ggplot2-Visualizations-MasterList-R-Code.html)
on the [r-statistics.co](r-statisctics.co) website.

![](http://r-statistics.co/screenshots/ggplot_masterlist_42.png)

To implement a plot of this nature, I decided to look at how my hometown
team, the San Antonio Spurs, fared last season (2016) in terms of point
differential. In case it's not immediately obvious, lots of green is
good. (This is not surprising to those of us who follow the NBA--the
Spurs have been consistently good since the end of the 1990s.)

``` {.r}
library("dplyr")
library("ggplot2")

url <- "https://raw.githubusercontent.com/aelhabr/nba/master/data/game_results-prepared.csv"
results_prepared <- getURL(url)

colnames_base <- c("date", "season", "tm")
colnames_calc_dates <- c("yyyy", "mm", "dd", "wd", "mm_yyyy", "mm_w")
# Look at a couple of different metrics.
# Specifically, look at games played to date (g_td) and point differential (pd).
colnames_viz <- c("g_td", "pd")

results_calendar_tm <-
  results_prepared %>%
  filter(tm == "SAS") %>%
  mutate(
    yyyy = year(date),
    mm = lubridate::month(date),
    dd = lubridate::day(date),
    wd = lubridate::wday(date, label = TRUE, abbr = TRUE),
    mm_yyyy = zoo::as.yearmon(date)
  ) %>%
  group_by(mm_yyyy) %>%
  mutate(mm_w = ceiling(dd / 7)) %>%
  ungroup() %>%
  select(one_of(colnames_base, colnames_calc_dates, colnames_viz)) %>%
  arrange(season, g_td, tm)
results_calendar_tm

# Tidy up because I was experimenting with different metrics, not just point differential.
results_calendar_tm_tidy <-
  results_calendar_tm %>%
  # mutate_if(is.character, funs(as.factor)) %>%
  tidyr::gather(metric, value, colnames_viz)

season <- 2016
wd_labels <- levels(results_calendar_tm$wd)
wd_labels[2:6] <- ""
title <- str_c("San Antonio Spurs Point Differential in ", season, " NBA Season")

viz_pd_sas_2016 <-
  results_calendar_tm_tidy %>%
  filter(season %in% seasons) %>%
  filter(metric == "pd") %>%
  ggplot() +
  geom_tile(aes(x = wd, y = mm_w, fill = value), colour = "white") +
  scale_y_reverse() +
  scale_x_discrete(labels = wd_labels) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) +
  scale_fill_gradient2(low = "red", mid = "grey", high = "green") +
  theme(legend.position = "bottom") +
  labs(x = "", y = "", title = title) +
  facet_wrap( ~ mm_yyyy, nrow = 2)
viz_pd_sas_2016
```

![](viz_pd_sas_2016.png)

There are an infinite number of ways to visualize data like this, but I
thought this was interesting because of the temporal nature of the data.

[^1]: The figure shown here comes from the [introductory chapter of the *R
for Data Science* book](http://r4ds.had.co.nz/introduction.html)

[^2]: Here, I use the NBA data that I have already scraped and cleaned.
