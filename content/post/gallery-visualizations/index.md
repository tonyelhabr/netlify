---
title: Generating a Gallery of Visualizations for a Static Website (using R)
date: "2019-07-20"
categories:
  - r
tags:
  - r
  - blogdown
  - portfolio
image:
  caption: ""
  focal_point: ""
  preview_only: true
header:
  caption: ""
  image: "featured.jpg"
---

While I was browsing [the website of fellow `R` blogger Ryo Nakagawara](https://ryo-n7.github.io/)[^1], I 
was intrigued by his ["Visualizations" page](https://ryo-n7.github.io/visualizations/).
The concept of creating an online "portfolio" is not novel [^2], but
I hadn't thought to make one as a compilation of my own work (from blog posts)...
until now :smile:.

[^1]: one of my favorite `R` bloggers, by the way

[^2]: in fact, many people dedicate website's exclusively to showing off work that they've done.

The code that follows shows how I generated the 
[body of my visualization portfolio page](/project/blog-gallery/).
The task is achieved in a couple of steps.

1. Identify the file path of each blog post in my local blog folder

2. For each post, extract the date and title of the blog post from the front matter, as well as the name and links to the image files.

3. Combine the extracted information into a character vector that can be copy-pasted to a gallery page.

I should state a couple of caveats/notes for anyone looking to emulate my approach.

  + I take advantage of the fact that I use the same prefix for (almost) all
  visualization that I generate with R---`viz_`---[^3], as well as the same file
  format---.png.
  
  + At the time of writing, my website---a [`{blogdown}`](https://bookdown.org/yihui/blogdown/)-based 
  website---uses [Hugo's page bundles](https://gohugo.io/content-management/page-bundles/)
  content organization system,
  as well as the with the popular [Academic theme for Hugo](https://sourcethemes.com/academic/).
  Thus, there's no guarantee that the following code will work for you "as is". [^4]
  (If it doesn't work as is, I think modifying the code should be fairly straightforward.)
  
  + I create headers and links from the titles of the blog posts
  (via something like `sprintf('## %s, [%s](%s)', ...)` and I order everything according
  to descending date and ascending line in the post.
  This may not be what you would like for your gallery format.

[^3]: I apologize if I've offended English speakers/readers who use/prefer "s" to "z" (for "viz"). I'm American, and nearly all Americans use "z"!

[^4]: Because Hugo websites follow a standard structure, I really don't think that the choice of theme shouldn't be the reason why this wouldn't work for someone else's website, but I figured I would mention the theme.

## The Code




```r
library(tidyverse)

paths_post_raw <-
  fs::dir_ls(
    'content/post/',
    regexp = 'index[.]R?md$',
    recurse = TRUE
  ) %>% 
  # Ignore the "_index.md" at the base of the content/post directory.
  # Would need to also ignore draft posts if there are draft posts.
  str_subset('_index', negate = TRUE)
paths_post_raw[1:10]
```




```
##  [1] "content/post/analysis-texas-high-school-academics-1-intro/index.md"        
##  [2] "content/post/analysis-texas-high-school-academics-2-competitions/index.md" 
##  [3] "content/post/analysis-texas-high-school-academics-3-individuals/index.md"  
##  [4] "content/post/analysis-texas-high-school-academics-4-schools/index.md"      
##  [5] "content/post/analysis-texas-high-school-academics-5-miscellaneous/index.md"
##  [6] "content/post/bayesian-statistics-english-premier-league/index.md"          
##  [7] "content/post/bayesian-statistics-english-premier-league/index.Rmd"         
##  [8] "content/post/cheat-sheet-rmarkdown/index.md"                               
##  [9] "content/post/data-science-podcasts/index.md"                               
## [10] "content/post/dry-principle-make-a-package/index.md"
```


```r
# Define some important regular expressions (or "regex"es).
# These regexes are probably applicable to most Hugo/blogdown setups.
rgx_replace <- '(content\\/post\\/)(.*)(\\/)(.*)([.]png$)'
rgx_title <- '^title[:]\\s+'
rgx_date <- 'date[:]\\s+'

# This regex is particular to the way that I name and save my ggplots.
rgx_viz <- '(^[!][\\[][\\]].*)(viz.*png)(.*$)'
```




```r
# Define a helper function for a common idiom that we will implement for extracting the ines of markdown that we 
# want---those containing the title, data, and visualization---and  trimming them just to the text that we want
# (i.e. removing "title:" and "date:" preceding the title and date in the YAML/TOML header, and
# removing the "![]" preceding an image).
str_pluck <- function(x, pattern, replacement = '') {
  x %>% 
    str_subset(pattern) %>% 
    str_replace_all(pattern = pattern, replacement = replacement) %>% 
    str_trim()
}
str_pluck_title <- purrr::partial(str_pluck, pattern = rgx_title)
str_pluck_date <- purrr::partial(str_pluck, pattern = rgx_date)
str_pluck_viz <- purrr::partial(str_pluck, pattern = rgx_viz, replacement = '\\2')

# Extract the title, date, and visualizations from each post.
# Note that there should be only one title and date pers post, but there are likely more than one visualization per post.
paths_post <-
  paths_post_raw %>% 
  as.character() %>% 
  tibble(path_post = .) %>% 
  mutate(
    lines = path_post %>% purrr::map(read_lines)
  ) %>% 
  mutate_at(vars(path_post), ~str_remove_all(., 'content|\\/index[.]md')) %>% 
  mutate_at(
    vars(lines),
    list(
      title = ~purrr::map_chr(., str_pluck_title),
      date = ~purrr::map_chr(., str_pluck_date),
      viz = ~purrr::map(., str_pluck_viz)
    )
  ) %>% 
  # `date` is NA for old tidy-text-analysis-google post.
  filter(!is.na(date)) %>% 
  mutate(date = date %>% lubridate::ymd()) %>% 
  # viz` is a list item (because there may be more than one per post), so we need to `unnest()` it to return a "tidy" data frame.
  unnest(viz) %>% 
  select(date, viz, title, path_post)
paths_post
```

```
## # A tibble: 71 x 4
##    date       viz            title              path_post          
##    <date>     <chr>          <chr>              <chr>              
##  1 2018-05-20 viz_map_bycom~ An Analysis of Te~ /post/analysis-tex~
##  2 2018-05-20 viz_map_bycom~ An Analysis of Te~ /post/analysis-tex~
##  3 2018-05-20 viz_n_bycompl~ An Analysis of Te~ /post/analysis-tex~
##  4 2018-05-20 viz_n_bycomp-~ An Analysis of Te~ /post/analysis-tex~
##  5 2018-05-20 viz_n_bycompc~ An Analysis of Te~ /post/analysis-tex~
##  6 2018-05-20 viz_n_bycompc~ An Analysis of Te~ /post/analysis-tex~
##  7 2018-05-20 viz_persons_s~ An Analysis of Te~ /post/analysis-tex~
##  8 2018-05-20 viz_persons_s~ An Analysis of Te~ /post/analysis-tex~
##  9 2018-05-20 viz_persons_s~ An Analysis of Te~ /post/analysis-tex~
## 10 2018-05-20 viz_persons_s~ An Analysis of Te~ /post/analysis-tex~
## # ... with 61 more rows
```

```r
# Create the markdown lines for images (visualizations) for our gallery markdown output.
paths_post_md <-
  paths_post %>% 
  mutate(
    label_md = sprintf('![%s](%s/%s)', viz, path_post, viz)
  ) %>% 
  select(title, date, path_post, label_md)
paths_post_md
```

```
## # A tibble: 71 x 4
##    title            date       path_post          label_md         
##    <chr>            <date>     <chr>              <chr>            
##  1 An Analysis of ~ 2018-05-20 /post/analysis-te~ ![viz_map_bycomp~
##  2 An Analysis of ~ 2018-05-20 /post/analysis-te~ ![viz_map_bycomp~
##  3 An Analysis of ~ 2018-05-20 /post/analysis-te~ ![viz_n_bycomplv~
##  4 An Analysis of ~ 2018-05-20 /post/analysis-te~ ![viz_n_bycomp-1~
##  5 An Analysis of ~ 2018-05-20 /post/analysis-te~ ![viz_n_bycompco~
##  6 An Analysis of ~ 2018-05-20 /post/analysis-te~ ![viz_n_bycompco~
##  7 An Analysis of ~ 2018-05-20 /post/analysis-te~ ![viz_persons_st~
##  8 An Analysis of ~ 2018-05-20 /post/analysis-te~ ![viz_persons_st~
##  9 An Analysis of ~ 2018-05-20 /post/analysis-te~ ![viz_persons_st~
## 10 An Analysis of ~ 2018-05-20 /post/analysis-te~ ![viz_persons_st~
## # ... with 61 more rows
```

```r
# Create the "main" data frame with the titles and dates in columns alongside the image column.
# In "tidy data" terminology, images are the "observations" *and `title` and `date` are separate variables).
content_gallery_raw <-
  paths_post_md %>%
  group_by(title, date, path_post) %>%
  # Add a "placeholder" line for the title of the post.
  do(add_row(., .before = 0)) %>% 
  ungroup() %>% 
  # In the first case, create the H2 markkdown heading line for the name of the post.
  # In the second case, use the image markdown line created above.
  mutate_at(
    vars(label_md),
    ~case_when(
      is.na(.) ~ sprintf('## %s, [%s](%s)', dplyr::lead(date), dplyr::lead(title), dplyr::lead(path_post)),
      TRUE ~ .
    )
  ) %>% 
  # Impute the `title` and `date` values to go with the image values.
  fill(title, .direction = 'up') %>% 
  fill(date, .direction = 'up') %>% 
  arrange(date) %>% 
  # Number the posts in order of descending date.
  mutate(idx_intragrp = dense_rank(sprintf('%s, %s', date, title))) %>%
  group_by(title, date) %>% 
  # Number the images within each post. (This isn't completely necessary. It's only used for sorting.)
  mutate(idx_intergrp = row_number()) %>% 
  ungroup() %>% 
  select(idx_intragrp, idx_intergrp, date, label_md) %>% 
  arrange(desc(idx_intragrp), idx_intergrp)
content_gallery_raw
```

```
## # A tibble: 90 x 4
##    idx_intragrp idx_intergrp date       label_md                   
##           <int>        <int> <date>     <chr>                      
##  1           19            1 2019-06-29 ## 2019-06-29, [Text Parsi~
##  2           19            2 2019-06-29 ![viz_toc_n_1yr_tree.png](~
##  3           19            3 2019-06-29 ![viz_content_section_n.pn~
##  4           19            4 2019-06-29 ![viz_toc_content_n1.png](~
##  5           19            5 2019-06-29 ![viz_sents_section_n.png]~
##  6           19            6 2019-06-29 ![viz_sents_section_n_yr.p~
##  7           19            7 2019-06-29 ![viz_sents_section_sim.pn~
##  8           19            8 2019-06-29 ![viz_words_section_tfidf.~
##  9           19            9 2019-06-29 ![viz_words_tfidf.png](/po~
## 10           18            1 2019-01-27 ## 2019-01-27, [Summarizin~
## # ... with 80 more rows
```

```r
# Create the final markdown output.
content_gallery <-
  content_gallery_raw %>% 
  select(label_md) %>% 
  mutate(idx = row_number()) %>% 
  # Add a blank line between the end of one section's last image
  # and the next sections H2 header.
  group_by(idx) %>% 
  do(add_row(., label_md = '', .before = 0)) %>% 
  ungroup()
content_gallery
```

```
## # A tibble: 180 x 2
##    label_md                                                     idx
##    <chr>                                                      <int>
##  1 ""                                                            NA
##  2 "## 2019-06-29, [Text Parsing and Text Analysis of a Peri~     1
##  3 ""                                                            NA
##  4 "![viz_toc_n_1yr_tree.png](/post/text-parsing-analysis-pe~     2
##  5 ""                                                            NA
##  6 "![viz_content_section_n.png](/post/text-parsing-analysis~     3
##  7 ""                                                            NA
##  8 "![viz_toc_content_n1.png](/post/text-parsing-analysis-pe~     4
##  9 ""                                                            NA
## 10 "![viz_sents_section_n.png](/post/text-parsing-analysis-p~     5
## # ... with 170 more rows
```


```r
content_copypaste <- content_gallery %>% pull(label_md)

# Copy paste this to the markdown file for the gallery page.
# It's probably possible to do this a bit more programmatically (i.e. without
# "manually" copying into a markdown file, but oh well
clipr::write_clip(content_copypaste)
```
