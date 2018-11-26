---
title: Converting nested JSON to a tidy data frame with R
# slug: nested-json-to-tidy-data-frame-r
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
  focal_point: ""
  preview_only: false
header:
  caption: ""
  image: "featured.jpg"
---

In this “how-to” post, I want to detail an approach that others may find
useful for converting nested (nasty!) json to a
[tidy](http://r4ds.had.co.nz/tidy-data.html) (nice!)
`data.frame`/`tibble` that is should be much easier to work with. [^1]

For this demonstration, I’ll start out by scraping [National Football
League](https://www.nfl.com/) (NFL) 2018 regular season week 1 score
data from [ESPN](http://www.espn.com/), which involves lots of nested
data in its raw form. [^2]

Then, I’ll work towards getting the data in a workable format (a
`data.frame`!). (This is the crux of what I want to show.) Finally, I’ll
filter and wrangle the data to generate a final, presentable format.

Even if one does not care for sports and knows nothing about the NFL, I
believe that the techniques that I demonstrate are generalizable to a
broad set of JSON-related “problems”.


Getting the data
----------------

Let’s being with importing the package(s) that we’ll need.

Next, we’ll create a variable for the url from which we will get the
data. The url here will request the scores for week 1 of the 2018 NFL
season from [ESPN’s “secret”
API](https://gist.github.com/akeaswaran/b48b02f1c94f873c6655e7129910fc3b). [^3]

``` {.r}
url <- "http://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?&dates=2018&seasontype=2&week=1"
```

And now, the actual HTTP `GET` request for the data (using the
[`{httr}`](https://cran.r-project.org/web/packages/httr/index.html)
package’s appropriately named `GET()` function).

``` {.r}
resp <- httr::GET(url)
resp
```

    ## Response [http://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?&dates=2018&seasontype=2&week=1]
    ##   Date: 2018-10-24 18:41
    ##   Status: 200
    ##   Content-Type: application/json;charset=UTF-8
    ##   Size: 189 kB

Everything seems to be going well. However, after using another handy
`{httr}` function—`content()`—to extract the data, we see that the data
is an nasty nested format! (I only print out some of the top-level
elements to avoid cluttering the page.)

``` {.r}
cont_raw <- httr::content(resp)
str(cont_raw, max.level = 3, list.len = 4)
```

    ## List of 4
    ##  $ leagues:List of 1
    ##   ..$ :List of 11
    ##   .. ..$ id                 : chr "28"
    ##   .. ..$ uid                : chr "s:20~l:28"
    ##   .. ..$ name               : chr "National Football League"
    ##   .. ..$ abbreviation       : chr "NFL"
    ##   .. .. [list output truncated]
    ##  $ season :List of 2
    ##   ..$ type: int 2
    ##   ..$ year: int 2018
    ##  $ week   :List of 1
    ##   ..$ number: int 1
    ##  $ events :List of 16
    ##   ..$ :List of 9
    ##   .. ..$ id          : chr "401030710"
    ##   .. ..$ uid         : chr "s:20~l:28~e:401030710"
    ##   .. ..$ date        : chr "2018-09-07T00:55Z"
    ##   .. ..$ name        : chr "Atlanta Falcons at Philadelphia Eagles"
    ##   .. .. [list output truncated]
    ##   ..$ :List of 9
    ##   .. ..$ id          : chr "401030718"
    ##   .. ..$ uid         : chr "s:20~l:28~e:401030718"
    ##   .. ..$ date        : chr "2018-09-09T17:00Z"
    ##   .. ..$ name        : chr "Pittsburgh Steelers at Cleveland Browns"
    ##   .. .. [list output truncated]
    ##   ..$ :List of 9
    ##   .. ..$ id          : chr "401030717"
    ##   .. ..$ uid         : chr "s:20~l:28~e:401030717"
    ##   .. ..$ date        : chr "2018-09-09T17:00Z"
    ##   .. ..$ name        : chr "Cincinnati Bengals at Indianapolis Colts"
    ##   .. .. [list output truncated]
    ##   ..$ :List of 9
    ##   .. ..$ id          : chr "401030716"
    ##   .. ..$ uid         : chr "s:20~l:28~e:401030716"
    ##   .. ..$ date        : chr "2018-09-09T17:00Z"
    ##   .. ..$ name        : chr "Tennessee Titans at Miami Dolphins"
    ##   .. .. [list output truncated]
    ##   .. [list output truncated]



Parsing the data
----------------

Given the nature of the data, we might hope that the
[`{jsonlite}`](https://cran.r-project.org/web/packages/jsonlite/index.html)
package will save us here. However, straightforward usage of it’s
`fromJSON()` package only reduces the mess a bit.

``` {.r}
data_raw_ugly <- jsonlite::fromJSON(rawToChar(resp$content))
glimpse(data_raw_ugly, max.level = 3, list.len = 4)
```

    ## List of 4
    ##  $ leagues:'data.frame': 1 obs. of  11 variables:
    ##   ..$ id                 : chr "28"
    ##   ..$ uid                : chr "s:20~l:28"
    ##   ..$ name               : chr "National Football League"
    ##   ..$ abbreviation       : chr "NFL"
    ##   .. [list output truncated]
    ##  $ season :List of 2
    ##   ..$ type: int 2
    ##   ..$ year: int 2018
    ##  $ week   :List of 1
    ##   ..$ number: int 1
    ##  $ events :'data.frame': 16 obs. of  9 variables:
    ##   ..$ id          : chr [1:16] "401030710" "401030718" "401030717" "401030716" ...
    ##   ..$ uid         : chr [1:16] "s:20~l:28~e:401030710" "s:20~l:28~e:401030718" "s:20~l:28~e:401030717" "s:20~l:28~e:401030716" ...
    ##   ..$ date        : chr [1:16] "2018-09-07T00:55Z" "2018-09-09T17:00Z" "2018-09-09T17:00Z" "2018-09-09T17:00Z" ...
    ##   ..$ name        : chr [1:16] "Atlanta Falcons at Philadelphia Eagles" "Pittsburgh Steelers at Cleveland Browns" "Cincinnati Bengals at Indianapolis Colts" "Tennessee Titans at Miami Dolphins" ...
    ##   .. [list output truncated]

One could go on and try some other functions from the `{jsonlite}`
package (or another JSON-related package), but, in my own attempts, I
was unable to figure out a nice way of getting a `data.frame()`. (This
is not to say that there is something wrong with the package—I simply
could not figure out how to use it to get the result that I wanted.)

So, what to do now? Well, after some struggling, I stumbled upon the
following solution to put me on the right path.

``` {.r}
data_raw <- enframe(unlist(cont_raw))
data_raw
```

    ## # A tibble: 6,629 x 2
    ##    name                     value                   
    ##    <chr>                    <chr>                   
    ##  1 leagues.id               28                      
    ##  2 leagues.uid              s:20~l:28               
    ##  3 leagues.name             National Football League
    ##  4 leagues.abbreviation     NFL                     
    ##  5 leagues.slug             nfl                     
    ##  6 leagues.season.year      2018                    
    ##  7 leagues.season.startDate 2018-08-02T07:00Z       
    ##  8 leagues.season.endDate   2019-02-06T07:59Z       
    ##  9 leagues.season.type.id   2                       
    ## 10 leagues.season.type.type 2                       
    ## # ... with 6,619 more rows

Combining `unlist()` and `tibble::enframe()`, we are able to get a
(very) long data.frame without any nested elements! Note that the
would-have-been-nested elements are joined by “.” in the “name” column,
and the values associated with these elements are in the “value” column.
(These are the default column names that `tibble::enframe()` assigns to
the `tibble` that it creates from a list.)

While this `tibble` is still not in a tidy format—there are variables
implicitly stored in the “name” column rather than in their own
columns—it’s in a much more user-friendly format (in my opinion).
(e.g. The variable `"leagues.season.startDate"` implicitly encodes three
variables—`"leagues"`, `"season"`, and `"startDate"`—each deserving of
their own column.)

Given the format of the implicit variable sin the “name” column, We can
use `tidyr::separate()` to create columns for each.

``` {.r}
data_raw %>% separate(name, into = c(paste0("x", 1:10)))
```

    ## Warning: Expected 10 pieces. Missing pieces filled with `NA` in 6629
    ## rows [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
    ## 20, ...].

    ## # A tibble: 6,629 x 11
    ##    x1     x2      x3    x4    x5    x6    x7    x8    x9    x10   value   
    ##    <chr>  <chr>   <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr>   
    ##  1 leagu~ id      <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  28      
    ##  2 leagu~ uid     <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  s:20~l:~
    ##  3 leagu~ name    <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  Nationa~
    ##  4 leagu~ abbrev~ <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  NFL     
    ##  5 leagu~ slug    <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  nfl     
    ##  6 leagu~ season  year  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  2018    
    ##  7 leagu~ season  star~ <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  2018-08~
    ##  8 leagu~ season  endD~ <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  2019-02~
    ##  9 leagu~ season  type  id    <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  2       
    ## 10 leagu~ season  type  type  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  2       
    ## # ... with 6,619 more rows

We get a warning indicating when using `separate()` because we have
“over-estimated” how many columns we will need to create. Note that,
with my specification of (dummy) column names with the `into` argument,
I guessed that there we would need 10 columns. Why 10? Because I
expected that 10 would be more than I needed, and it’s better to
over-estimate and remove the extra columns in a subsequent step than to
under-estimate and lose data because there are not enough columns to put
the “separated” data in.

We can get rid of the warning by providing an appropriate value for
`separate()`’s `fill` argument. (Note that `"warn"` is the default value
of the `fill` argument.)

``` {.r}
data_raw %>% separate(name, into = c(paste0("x", 1:10)), fill = "right")
```

    ## # A tibble: 6,629 x 11
    ##    x1     x2      x3    x4    x5    x6    x7    x8    x9    x10   value   
    ##    <chr>  <chr>   <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr>   
    ##  1 leagu~ id      <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  28      
    ##  2 leagu~ uid     <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  s:20~l:~
    ##  3 leagu~ name    <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  Nationa~
    ##  4 leagu~ abbrev~ <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  NFL     
    ##  5 leagu~ slug    <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  nfl     
    ##  6 leagu~ season  year  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  2018    
    ##  7 leagu~ season  star~ <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  2018-08~
    ##  8 leagu~ season  endD~ <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  2019-02~
    ##  9 leagu~ season  type  id    <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  2       
    ## 10 leagu~ season  type  type  <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  2       
    ## # ... with 6,619 more rows

However, while this action gets rid of the warning, it does not actually
resolve the underlying issue—specifying the correct number of columns to
create with `separate()`. We can do that by identifying the `name` with
the most number of `.`s.

``` {.r}
rgx_split <- "\\."
n_cols_max <-
  data_raw %>%
  pull(name) %>% 
  str_split(rgx_split) %>% 
  map_dbl(~length(.)) %>% 
  max()
n_cols_max
```

    ## [1] 7

With this number (7) identified, we can now choose the “correct” number
of columns to create with `separate()`. Note that we’ll still be left
with lots of `NA` values (corresponding to rows that don’t have the
maximum number of variables). This is expected.

``` {.r}
nms_sep <- paste0("name", 1:n_cols_max)
data_sep <-
  data_raw %>% 
  separate(name, into = nms_sep, sep = rgx_split, fill = "right")
data_sep
```

    ## # A tibble: 6,629 x 8
    ##    name1   name2      name3    name4 name5 name6 name7 value              
    ##    <chr>   <chr>      <chr>    <chr> <chr> <chr> <chr> <chr>              
    ##  1 leagues id         <NA>     <NA>  <NA>  <NA>  <NA>  28                 
    ##  2 leagues uid        <NA>     <NA>  <NA>  <NA>  <NA>  s:20~l:28          
    ##  3 leagues name       <NA>     <NA>  <NA>  <NA>  <NA>  National Football ~
    ##  4 leagues abbreviat~ <NA>     <NA>  <NA>  <NA>  <NA>  NFL                
    ##  5 leagues slug       <NA>     <NA>  <NA>  <NA>  <NA>  nfl                
    ##  6 leagues season     year     <NA>  <NA>  <NA>  <NA>  2018               
    ##  7 leagues season     startDa~ <NA>  <NA>  <NA>  <NA>  2018-08-02T07:00Z  
    ##  8 leagues season     endDate  <NA>  <NA>  <NA>  <NA>  2019-02-06T07:59Z  
    ##  9 leagues season     type     id    <NA>  <NA>  <NA>  2                  
    ## 10 leagues season     type     type  <NA>  <NA>  <NA>  2                  
    ## # ... with 6,619 more rows

By my interpretation, this `data_sep` variable is in tidy format. Of
course, it has



“Post-processing” the data
--------------------------

Getting the raw data in the format that `data_sep` is what I primarily
wanted to show. Nonetheless, there’s more to the story! (Reminder: We’re
seeking to get the scores from the 16 games in week 1 of the NFL’s 2018
regular season.) How can we work with the `NA`s to get a final format
that is actually presentable?

We continue by filter the `tibble` for only the rows that we will need.

``` {.r}
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

    ## # A tibble: 80 x 8
    ##    name1  name2        name3      name4 name5 name6 name7 value           
    ##    <chr>  <chr>        <chr>      <chr> <chr> <chr> <chr> <chr>           
    ##  1 events shortName    <NA>       <NA>  <NA>  <NA>  <NA>  ATL @ PHI       
    ##  2 events competitions date       <NA>  <NA>  <NA>  <NA>  2018-09-07T00:5~
    ##  3 events competitions competito~ score <NA>  <NA>  <NA>  18              
    ##  4 events competitions competito~ score <NA>  <NA>  <NA>  12              
    ##  5 events competitions status     type  name  <NA>  <NA>  STATUS_FINAL    
    ##  6 events shortName    <NA>       <NA>  <NA>  <NA>  <NA>  PIT @ CLE       
    ##  7 events competitions date       <NA>  <NA>  <NA>  <NA>  2018-09-09T17:0~
    ##  8 events competitions competito~ score <NA>  <NA>  <NA>  21              
    ##  9 events competitions competito~ score <NA>  <NA>  <NA>  21              
    ## 10 events competitions status     type  name  <NA>  <NA>  STATUS_FINAL    
    ## # ... with 70 more rows

Next, we’ll create appropriately named columns for the values that we
filtered for in the step above. [^4]

``` {.r}
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

    ## # A tibble: 80 x 8
    ##    name3    name4 name5 value       status    isscore datetime     gm     
    ##    <chr>    <chr> <chr> <chr>       <chr>     <lgl>   <chr>        <chr>  
    ##  1 <NA>     <NA>  <NA>  ATL @ PHI   <NA>      NA      <NA>         ATL @ ~
    ##  2 date     <NA>  <NA>  2018-09-07~ <NA>      NA      2018-09-07 ~ <NA>   
    ##  3 competi~ score <NA>  18          <NA>      TRUE    <NA>         <NA>   
    ##  4 competi~ score <NA>  12          <NA>      TRUE    <NA>         <NA>   
    ##  5 status   type  name  STATUS_FIN~ STATUS_F~ FALSE   <NA>         <NA>   
    ##  6 <NA>     <NA>  <NA>  PIT @ CLE   <NA>      NA      <NA>         PIT @ ~
    ##  7 date     <NA>  <NA>  2018-09-09~ <NA>      NA      2018-09-09 ~ <NA>   
    ##  8 competi~ score <NA>  21          <NA>      TRUE    <NA>         <NA>   
    ##  9 competi~ score <NA>  21          <NA>      TRUE    <NA>         <NA>   
    ## 10 status   type  name  STATUS_FIN~ STATUS_F~ FALSE   <NA>         <NA>   
    ## # ... with 70 more rows

With these columns created, we can use `tidyr::fill()` and
`dplyr::filter()` in a strategic manner to get rid of all the `NA`s
cluttering our `tibble`. Additionally, we can drop the dummy `name`
columns that we created with the `tidyr::separate()` call before.

``` {.r}
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

    ## # A tibble: 32 x 5
    ##    value status       isscore datetime         gm       
    ##    <chr> <chr>        <lgl>   <chr>            <chr>    
    ##  1 18    STATUS_FINAL TRUE    2018-09-07 00:55 ATL @ PHI
    ##  2 12    STATUS_FINAL TRUE    2018-09-07 00:55 ATL @ PHI
    ##  3 21    STATUS_FINAL TRUE    2018-09-09 17:00 PIT @ CLE
    ##  4 21    STATUS_FINAL TRUE    2018-09-09 17:00 PIT @ CLE
    ##  5 23    STATUS_FINAL TRUE    2018-09-09 17:00 CIN @ IND
    ##  6 34    STATUS_FINAL TRUE    2018-09-09 17:00 CIN @ IND
    ##  7 27    STATUS_FINAL TRUE    2018-09-09 17:00 TEN @ MIA
    ##  8 20    STATUS_FINAL TRUE    2018-09-09 17:00 TEN @ MIA
    ##  9 24    STATUS_FINAL TRUE    2018-09-09 17:00 SF @ MIN 
    ## 10 16    STATUS_FINAL TRUE    2018-09-09 17:00 SF @ MIN 
    ## # ... with 22 more rows

Finally, we can use a chain of
[`{dplyr}`](https://cran.r-project.org/web/packages/dplyr/index.html)
actions to get a pretty output. I should note that it is likely that
everything up to this point would have an analogous action no matter
what the data set is that you are working with. However, these final
actions are unique to this specific data.

``` {.r}
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

    ## # A tibble: 16 x 6
    ##    date       time                tm_home tm_away pts_home pts_away
    ##    <date>     <dttm>              <chr>   <chr>      <int>    <int>
    ##  1 2018-09-07 2018-09-07 00:55:00 PHI     ATL           18       12
    ##  2 2018-09-09 2018-09-09 17:00:00 BAL     BUF           47        3
    ##  3 2018-09-09 2018-09-09 17:00:00 IND     CIN           23       34
    ##  4 2018-09-09 2018-09-09 17:00:00 NE      HOU           27       20
    ##  5 2018-09-09 2018-09-09 17:00:00 NYG     JAX           15       20
    ##  6 2018-09-09 2018-09-09 17:00:00 CLE     PIT           21       21
    ##  7 2018-09-09 2018-09-09 17:00:00 MIN     SF            24       16
    ##  8 2018-09-09 2018-09-09 17:00:00 NO      TB            40       48
    ##  9 2018-09-09 2018-09-09 17:00:00 MIA     TEN           27       20
    ## 10 2018-09-09 2018-09-09 20:05:00 LAC     KC            28       38
    ## 11 2018-09-09 2018-09-09 20:25:00 CAR     DAL           16        8
    ## 12 2018-09-09 2018-09-09 20:25:00 DEN     SEA           27       24
    ## 13 2018-09-09 2018-09-09 20:25:00 ARI     WSH            6       24
    ## 14 2018-09-10 2018-09-10 00:20:00 GB      CHI           24       23
    ## 15 2018-09-10 2018-09-10 23:10:00 DET     NYJ           17       48
    ## 16 2018-09-11 2018-09-11 02:20:00 OAK     LAR           13       33

And there we have it! A nice, tidy `tibble` with the scores of the first
week of regular season games in the 2018 NFL regular season.



Sign-off
--------

Hopefully someone out there will find the technique(s) shown in this
post to be useful for an endeavor of their own.

Personally, I find web scraping to be fascinating, so I doubt this will
be the last time I write about something of this nature.



------------------------------------------------------------------------

[^1]: I use `data.frame` and `tibble` interchangeably. 
See [this chapter](http://r4ds.had.co.nz/tibbles.html) of the 
[***R for Data Science***](http://r4ds.had.co.nz/) 
for more details about the differences/similarities between the two.

[^2]: (See the webpage here: <http://www.espn.com/nfl/scoreboard/_/year/2018/seasontype/2/week/1>. 
Note that we won’t be scraping the html, but, instead, the underlying JSON 
from which the html is generated.)

[^3]: I say that it’s a secret because it’s API documentation is out of date.

[^4]: As a note to the reader, I don’t recommend suffixing variable names with numbers as I do in the next couple of step (i.e. variables suffixed with `1`, `2`, …) (It’s ugly!) In practice, you might do this during your exploratory phase of data scraping/analysis, but you should come up with more informative names and combine actions in a logical manner for your final script/package (in my opinion).
