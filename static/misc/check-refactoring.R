
library("tidyverse")
dir_post <- file.path("content", "post")
paths_post <-
  list.dirs(
    path = dir_post,
    full.names = TRUE,
    recursive = FALSE
  )
paths_post

paths_featured <-
  list.files(
    path = dir_post,
    pattern = "featured\\.jpg$",
    full.names = TRUE,
    recursive = TRUE
  )
paths_featured
