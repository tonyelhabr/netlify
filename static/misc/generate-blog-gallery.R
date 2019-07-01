
library(tidyverse)

paths_post_raw <-
  fs::dir_ls(
    'content/post',
    regexp = '\\/index.md',
    recursive = TRUE
  ) %>% 
  str_subset('unused|nba-rapm', negate = TRUE)
paths_post_raw

rgx_replace <- '(content\\/post\\/)(.*)(\\/)(.*)([.]png$)'
rgx_title <- '^title[:]\\s+'
rgx_date <- 'date[:]\\s+'
rgx_viz <- '(^[!][\\[][\\]].*)(viz.*png)(.*$)'

# path_post <- 'content/post/analysis-texas-high-school-academics-1-intro/index.md'
path_post <- 'content/post/nba-rapm-project-r-intro/index.md'
lines <- path_post %>% read_lines()
line_title <- lines %>% str_subset(rgx_title)
line_title %>% str_replace_all(rgx_title, '') %>% str_trim()
line_date <- lines %>% str_subset(rgx_date)
line_date %>% str_replace_all(rgx_date, '') %>% str_trim()
lines_viz <- lines %>% str_subset(rgx_viz)
lines_viz

paths_post <-
  paths_post_raw %>% 
  as.character() %>% 
  tibble(path_post = .) %>% 
  # filter(!fs::file_exists(path_viz)) %>% 
  mutate(
    lines = path_post %>% purrr::map(read_lines)
  ) %>% 
  mutate_at(vars(path_post), ~str_remove_all(., 'content|\\/index[.]md')) %>% 
  mutate(
    title =
      lines %>%
      purrr::map_chr(
        ~str_subset(.x, rgx_title) %>%
          str_replace_all(rgx_title, '') %>%
          str_trim()
      ),
    date = 
      lines %>% 
      purrr::map_chr(
        ~str_subset(.x, rgx_date) %>% 
          str_replace_all(rgx_date, '') %>% 
          str_trim()
      )
  ) %>% 
  mutate_at(vars(date), lubridate::ymd)
paths_post

paths_post_aug <-
  paths_post %>% 
  mutate(
    viz = 
      lines %>% 
      purrr::map(
        ~str_subset(.x, rgx_viz) %>% 
          str_replace_all(rgx_viz, '\\2') %>% 
          str_trim()
      )
  ) %>% 
  unnest(viz)
paths_post_aug

paths_post_md <-
  paths_post_aug %>% 
  mutate(
    # label_md = glue::glue('+ ![{viz}]({paste0(path_post, "/", viz)})') %>% as.character()
    label_md = sprintf('![%s](%s/%s)', viz, path_post, viz)
  ) %>% 
  select(title, date, path_post, label_md)
paths_post_md

content_gallery_raw <-
  paths_post_md %>%
  group_by(title, date, path_post) %>%
  do(add_row(., .before = 0)) %>% 
  ungroup() %>% 
  mutate_at(
    vars(label_md),
    ~case_when(
      # is.na(.) ~ sprintf('## [%s, %s](%s)', dplyr::lead(title), dplyr::lead(date), dplyr::lead(path_post)),
      is.na(.) ~ sprintf('## %s, [%s](%s)', dplyr::lead(date), dplyr::lead(title), dplyr::lead(path_post)),
      TRUE ~ .
    )
  ) %>% 
  fill(title, .direction = 'up') %>% 
  fill(date, .direction = 'up') %>% 
  arrange(date) %>% 
  mutate(idx_intragrp = dense_rank(sprintf('%s, %s', date, title))) %>%
  # mutate(idx_intragrp = dense_rank(label_md)) %>% 
  group_by(title, date) %>% 
  mutate(idx_intergrp = row_number()) %>% 
  ungroup() %>% 
  select(idx_intragrp, idx_intergrp, date, label_md) %>% 
  # arrange(desc(date))
  arrange(desc(idx_intragrp), idx_intergrp)
content_gallery_raw

content_gallery <-
  content_gallery_raw %>% 
  select(label_md) %>% 
  mutate(idx = row_number()) %>% 
  group_by(idx) %>% 
  do(add_row(., label_md = '', .before = 0)) %>% 
  ungroup() %>% 
  pull(label_md)
content_gallery
content_gallery %>% length()
content_gallery %>% clipr::write_clip()
