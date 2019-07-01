

# NOTE: Probably create a "awesome-r-bloggers" GitHub page from this.
library(tidyverse)

path_raw <- 'static/misc/bookmarks_6_29_19.html' # Exported Chrome bookmarks.
# file.exists(path_raw)

html <- path_raw %>% xml2::read_html()

nodes <-
  html %>% 
  rvest::html_nodes('dl') %>%
  rvest::html_nodes('dt') %>%
  rvest::html_children()
nodes

links <-
  tibble(
    label =  nodes %>% rvest::html_text(trim = TRUE),
    href = nodes %>% rvest::html_attr('href')
  ) %>% 
  drop_na() %>% 
  mutate(idx = row_number()) %>% 
  select(idx, everything())
idx_first <- links %>% filter(label %>% str_detect('Flowing')) %>% pull(idx)
idx_last <- links %>% filter(label %>% str_detect('Luis D')) %>% pull(idx)

links_filt <-
  links %>% 
  filter(idx >= idx_first, idx <= idx_last)
links_filt

links_filt_pretty <-
  links_filt %>% 
  mutate(
    # label_md =  sprintf('+ [%s](%s)', label, href)
    label_md =  glue::glue('+ [{label}]({href})
                           
                           ')
  )
links_filt_pretty

links_copy_paste <-
  links_filt_pretty %>% 
  pull(label_md)
links_copy_paste %>% clipr::write_clip()
