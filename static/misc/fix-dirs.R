
library("tidyverse")
dir_post <- file.path("content", "post")
paths_rmd <-
  list.files(
    path = dir_post,
    pattern = "Rmd",
    full.names = TRUE
  )
paths_rmd

paths <-
  paths_rmd %>%
  tibble(path_rmd = .) %>% 
  mutate(
    path_html =
      paths_rmd %>% str_replace("Rmd$", "html"),
    basename =
      paths_rmd %>% 
      basename() %>% 
      str_replace_all("^[0-9|-]+", "")
  ) %>% 
  mutate(
    basename_trunc = basename %>% tools::file_path_sans_ext()
  ) %>% 
  mutate(
    dir_tocreate = basename_trunc %>% file.path(dir_post, .)
  ) %>% 
  # select(-basename) %>% 
  mutate(
    # Note: `file.copy()` doesn't work(?) when renaming everything to index.md.
    path_rmd_new = file.path(dir_tocreate, basename),
    path_index = file.path(dir_tocreate, "index.md"),
    path_todo = file.path(dir_tocreate, "todo")
  )
paths

# paths %>% pull(dir_tocreate) %>% purrr::walk(dir.create)
paths %>% 
  mutate(
    dummy = purrr::walk(dir_tocreate, dir.create)
  )
paths %>% 
  mutate(
    dummy = 
      purrr::walk2(path_rmd, path_rmd_new, ~file.copy(from = .x, to = .y))
      # purrr::walk2(path_rmd, dir_tocreate, ~file.copy(from = .x, to = .y))
  )
paths %>% 
  mutate(
    dummy = purrr::walk2(path_rmd_new, path_index, ~file.rename(from = .x, to = .y))
  )
paths %>% 
  mutate(
    dummy = purrr::walk(path_todo, file.create)
  )
