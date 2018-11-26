---
title: Converting nested JSON to a tidy data frame with R
slug: nested-json-to-tidy-data-frame-r
date: "2018-10-20"
categories:
  - r
tags:
  - r
  - json
  - dplyr
  - tidyr
  - nfl
image:
  caption: ""
header:
  caption: ""
  image: "nested-json-to-tidy-data-frame-r/json-everywhere-meme.png"
  preview: true
---

```{r setup, echo = FALSE}
knitr::opts_knit$set(root.dir = rprojroot::find_rstudio_root_file())
knitr::opts_chunk$set(
  echo = TRUE,
  # echo = FALSE,
  cache = FALSE,
  include = TRUE,
  # results = "markdown",
  # results = "hide",
  fig.align = "center",
  # fig.show = "asis",
  fig.width = 6,
  fig.height = 6,
  # out.width = 6,
  # out.height = 6,
  warning = FALSE,
  message = FALSE
)

```

In this "how-to" post, I want to detail an approach that others may find useful for
converting nested (nasty!) json to a [tidy](http://r4ds.had.co.nz/tidy-data.html)
(nice!) `data.frame`/`tibble` that is should be much easier to work with. [^tibble]

[^tibble]:
I use `data.frame` and `tibble` interchangeably. See 
[this chapter](http://r4ds.had.co.nz/tibbles.html) of the 
[___R for Data Science___](http://r4ds.had.co.nz/)
for more details about the differences/similarities
between the two.

For this demonstration, I'll start out by scraping 
[National Football League](https://www.nfl.com/) (NFL) 2018 
regular season week 1 score data from [ESPN](http://www.espn.com/), which
involves lots of nested data in its raw form. [^webpage]

Then,
I'll work towards getting the data in a workable format (a `data.frame`!).
(This is the crux of what I want to show.) Finally,
I'll filter and wrangle the data to generate a final, presentable format.

[^webpage]:
(See the webpage here: http://www.espn.com/nfl/scoreboard/_/year/2018/seasontype/2/week/1.
Note that we won't be scraping the html, but, instead, the underlying JSON from 
which the html is generated.)

Even if one does not care for sports and knows nothing about the NFL, I believe
that the techniques that I demonstrate are generalizable to a broad set of JSON-related
"problems".

## Getting the data

Let's being with importing the package(s) that we'll need.

```{r library, echo = FALSE}
library("tidyverse")
# Or, to be more specific...
# library("dplyr")
# library("purrr")
# library("tibble")
# library("tidyr")
# library("stringr")

# Also these..., but I'll just call their functions explicitly.
# library("httr")
# library("lubridate")
# library("jsonlite") 
```


```{r url_create, include = FALSE}
# url <- espn2::make_url_scores_nfl()
# url <- "http://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?lang=en&region=us&calendartype=blacklist&limit=100&dates=2018&seasontype=2&week=1"
```

Next, we'll create a variable for the url from which we will get the data. The url here will request the scores
for week 1 of the 2018 NFL season from 
[ESPN's "secret" API](https://gist.github.com/akeaswaran/b48b02f1c94f873c6655e7129910fc3b). [^secret]

[^secret]:
I say that it's a secret because it's API documentation is out of date.


```{r url}
url <- "http://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?&dates=2018&seasontype=2&week=1"
```

And now, the actual HTTP `GET` request for the data (using the 
[`{httr}`](https://cran.r-project.org/web/packages/httr/index.html) package's appropriately named `GET()` function).

```{r resp}
resp <- httr::GET(url)
resp
```

Everything seems to be going well. However, after using another handy `{httr}` 
function---`content()`---to extract the data, we see that the data is an nasty
nested format! (I only print out some of the top-level elements to avoid cluttering the page.)

```{r cont_raw}
cont_raw <- httr::content(resp)
str(cont_raw, max.level = 3, list.len = 4)
```

## Parsing the data

Given the nature of the data, we might hope that the 
[`{jsonlite}`](https://cran.r-project.org/web/packages/jsonlite/index.html) package will save us here.
However, straightforward usage of it's `fromJSON()` package only reduces the mess a bit.

```{r data_raw_ugly}
data_raw_ugly <- jsonlite::fromJSON(rawToChar(resp$content))
glimpse(data_raw_ugly, max.level = 3, list.len = 4)
```

One could go on and try some other functions from the `{jsonlite}` package
(or another JSON-related package), but, in my own attempts, I was
unable to figure out a nice way of getting a `data.frame()`.
(This is not to say that there is something wrong with the package---I simply could not figure
out how to use it to get the result that I wanted.)

So, what to do now? Well, after some struggling, I stumbled upon the following
solution to put me on the right path.

```{r data_raw}
data_raw <- enframe(unlist(cont_raw))
data_raw
```

Combining `unlist()` and `tibble::enframe()`, we are able to get a (very) long
data.frame without any nested elements!
Note that the would-have-been-nested elements are joined by "." in the "name" column,
and the values associated with these elements are in the "value" column.
(These are the default column names that `tibble::enframe()` assigns to the `tibble` that
it creates from a list.)

While this `tibble` is still not in a tidy format---there are variables implicitly stored
in the "name" column rather than in their own columns---it's in a much more user-friendly format (in my opinion).
(e.g. The variable
`"leagues.season.startDate"` implicitly encodes three
variables---`"leagues"`, `"season"`, and `"startDate"`---each
deserving of their own column.)

Given the format of the implicit variable sin the "name" column,
We can use `tidyr::separate()` to create columns for each.

```{r separate1, warning = TRUE}
data_raw %>% separate(name, into = c(paste0("x", 1:10)))
```

We get a warning indicating when using `separate()` because we have "over-estimated"
how many columns we will need to create. Note that, with my specification of (dummy) column 
names with the `into` argument,
I guessed that there we would need 10 columns. Why 10?
Because I expected that 10 would be more than I needed, and it's better to over-estimate
and remove the extra columns in a subsequent step than to under-estimate and lose data
because there are not enough columns to put the "separated" data in.

We can get rid of the warning by providing an appropriate value for `separate()`'s `fill` argument.
(Note that `"warn"` is the default value of the `fill` argument.)

```{r separate2, warning = TRUE}
data_raw %>% separate(name, into = c(paste0("x", 1:10)), fill = "right")
```

However, while this action gets rid of the warning, it does not actually resolve the underlying 
issue---specifying the correct number of columns to create with `separate()`.
We can do that by identifying the `name` with the most number of `.`s.

```{r n_cols_max}
rgx_split <- "\\."
n_cols_max <-
  data_raw %>%
  pull(name) %>% 
  str_split(rgx_split) %>% 
  map_dbl(~length(.)) %>% 
  max()
n_cols_max
```

With this number (`r n_cols_max`) identified, we can now choose the "correct" number
of columns to create with `separate()`. Note that we'll still be left with lots
of `NA` values (corresponding to rows that don't have the maximum number of variables).
This is expected.

```{r data_raw_sep}
nms_sep <- paste0("name", 1:n_cols_max)
data_sep <-
  data_raw %>% 
  separate(name, into = nms_sep, sep = rgx_split, fill = "right")
data_sep
```

By my interpretation, this `data_sep` variable is in tidy format.
Of course, it has

## "Post-processing" the data

Getting the raw data in the format that `data_sep` is what I primarily wanted to show.
Nonetheless, there's more to the story!
(Reminder: We're seeking to get the scores from the 16 games in week 1 of the 
NFL's 2018 regular season.)
How can we work with the `NA`s to get a final format that is actually presentable?

We continue by filter the `tibble` for only the rows that we will need.


```{r data_filt}
data_filt <-
  data_sep %>%
  filter(
    (
      name1 == "events" &
        name2 == "shortName"
    ) |
      (
        name1 == "events" &
          name2 == "competitions" &
          name3 == "date"
      ) | (
        name1 == "events" &
          name2 == "competitions" &
          name3 == "status" &
          name4 == "type" &
          name5 == "name"
      ) |
      (
        name1 == "events" &
          name2 == "competitions" &
          name3 == "competitors" &
          name4 == "score"
      )
  )
data_filt
```

Next, we'll create appropriately named columns for the values that we filtered for in the 
step above. [^naming]

[^naming]:
As a note to the reader, 
I don't recommend suffixing variable names with numbers  as I do in the next couple
of step (i.e. variables suffixed with `1`, `2`, ...) (It's ugly!)
In practice, you might do this during your exploratory phase of data scraping/analysis,
but you should come up with more informative names and combine actions in a logical manner
for your final script/package (in my opinion).


```{r data_clean1}
data_clean1 <-
  data_filt %>%
  select(name3, name4, name5, value) %>%
  mutate(status = if_else(name5 == "name", value, NA_character_)) %>%
  mutate(isscore = if_else(name4 == "score", TRUE, FALSE)) %>%
  mutate(datetime = if_else(
    name3 == "date",
    str_replace_all(value, "\\s?T\\s?", " ") %>% str_replace("Z$", ""),
    NA_character_
  )) %>%
  mutate(gm = if_else(
    is.na(isscore) &
      is.na(datetime) & is.na(status),
    value,
    NA_character_
  ))
data_clean1
```

With these columns created, we can use `tidyr::fill()` and `dplyr::filter()`
in a strategic manner to get rid of all the `NA`s cluttering our `tibble`.
Additionally, we can drop the dummy `name` columns that we created with the `tidyr::separate()`
call before.

```{r data_clean2}
data_clean2 <-
  data_clean1 %>% 
  fill(status, .direction = "up") %>%
  filter(status == "STATUS_FINAL") %>%
  fill(gm, .direction = "down") %>%
  fill(datetime, .direction = "down") %>%
  filter(name3 == "competitors") %>% 
  select(-matches("name[0-9]"))
data_clean2
```

Finally, we can use a chain of 
[`{dplyr}`](https://cran.r-project.org/web/packages/dplyr/index.html) 
actions to get a pretty output.
I should note that it is likely that
everything up to this point would have an analogous action
no matter what the data set is that you are working with.
However, these final actions are unique to this specific data.

```{r data_clean3}
data_clean3 <-
  data_clean2 %>% 
  group_by(gm) %>%
  mutate(rn = row_number()) %>%
  ungroup() %>%
  mutate(tm_dir = if_else(rn == 1, "pts_home", "pts_away")) %>%
  select(datetime, gm, tm_dir, value) %>%
  spread(tm_dir, value) %>%
  separate(gm, into = c("tm_away", "tm_home"), sep = "(\\s+\\@\\s+)|(\\s+vs.*\\s+)") %>% 
  mutate_at(vars(matches("pts")), funs(as.integer)) %>%
  mutate(date = datetime %>% str_remove("\\s.*$") %>% lubridate::ymd()) %>%
  mutate(time = datetime %>% lubridate::ymd_hm()) %>%
  select(date, time, tm_home, tm_away, pts_home, pts_away)
data_clean3
```

And there we have it! A nice, tidy `tibble` with the scores of the first week
of regular season games in the 2018 NFL regular season.

## Sign-off

Hopefully someone out there will find the technique(s) shown in this post to be useful
for an endeavor of their own.

Personally, I find web scraping to be fascinating, so I doubt this will be the last time
I write about something of this nature.
