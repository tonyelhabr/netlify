---
title: Dealing with Interval Data and the nycflights13 package using R, Part 2
# slug: interval-data-nycflights13-part-2
date: "2018-02-19"
categories:
  - r
tags:
  - r
  - dplyr
  - nycflights13
  - functional programming
image:
  caption: ""
  focal_point: ""
  preview_only: false
header:
  caption: ""
  image: "featured.jpg"
---


In this post, I’ll continue my discussion of working with regularly
sampled interval data using R. (See my previous post for some insight
regarding minute data.) The discussion here is focused more so on
function design.


Daily Data
----------

When I’ve worked with daily data, I’ve found that the .csv files tend to
be much larger than those for data sampled on a minute basis (as a
consequence of each file holding data for sub-daily intervals). In these
cases, I find that I need to perform the “processing” actions for each
file’s data immediately after extracting the daily data because
collecting data for all desired days (and performing computations
afterwards) would overload my R session.

Developing functions for importing and manipulating “singular” data that
is later grouped with other “singular” data can be interesting.
Nonetheless, even despite the pecularities of the situation, I do my
best to follow software design “best practices” in creating function–I
work with a small data set and verify that the expected result is
achieved before applying the function to a larger set of data (In this
context, this means that I’ll work with one file while developing my
core functions.) Sometimes I’ll build in different “capabilities” in
these functions –in order to handle unique cases or to experiment with a
different processed format– and have the function return a named list of
results. This can be useful if I am working on a separate function, for
which I may need the input data to be in different formats given a
certain condition, or need multiple elements of the output list.

After verifying that I the functions work properly on the hand-picked
data, I’ll write one or two “wrapper” functions to iterate over larger
temporal periods (i.e. months or years). Although I’ve tried to
transition to using `{purrr}` functions for all of my iteration needs, I
still find myself using loops as a “crutch” since I’ve been using them
since I first started programming. [^1]

To make things a bit more complicated, I’ve had at least one case where
I’ve needed to extract data from different kinds of files in the same
folders. In this case, I’ve re-factored functions (such as for
constructing file paths) to handle the different cases without needing
to write a lot more code. The re-factored functions are converted to
“core” functions, which are then called by “wrapper” or “API” functions
specific for each data type. [^2]


### An Example

To make all of this discussion relatable, let me provide an example of
some of these concepts together. As with my previous write-up, I’ll use
the `{nycflight13}` package; however, in order to demonstrate the
usefulness of core and wrapper functions, I’ll work with both the
`flights` and `weather` data sets in this package.


![](relational-nycflights.png)


To begin, I create daily files for each “type” of data (`flights` and
`weather`). Each daily file is stored in a day-specific folder, which is
nested in a month-specific folder, which, in turn, is nested in a
year-specific folder.

    2013
    |_2013-01/
      |_2013-01-01/
        |_flight.csv
        |_weather.csv
      |_2013-01-02/
        |_flight.csv
        |_weather.csv  
      .
      .
      .
    |_2013-02/
    .
    .
    .
    |_2013-12/

To reduce the amount of data for this example, I’ll work only with data
from the first two months of 2013. See the following (somewhat
non-robust) code for my implementation of this setup. (My focus is on
the subsequent code for extracting and processing the data from these
files.)

``` {.r}
# A helper funciton for filtering.
filter_nycflights_data <- function(data, origin_filter) {
  data %>%
    filter(month %in% mm_filter)
}

# Creating the data to export.
mm_filter <- c(1:2)
flights_export <-
  nycflights13::flights %>%
  filter_nycflights_data(origin_filter = origin_filter, mm_filter = mm_filter)
weather_export <-
  nycflights13::weather %>% 
  filter_nycflights_data(origin_filter = origin_filter, mm_filter = mm_filter)

# Two helper functions for exporting.
create_dir <- function(dir) {
  if(!dir.exists(dir))
    dir.create(dir)
}

# NOTE: This function is not robust! It assumes that there are `year`, `month`, and `day` columns.
add_ymd <- function(data) {
  data %>% 
    mutate(ymd = lubridate::ymd(sprintf("%04.0f-%02.0f-%02.0f", year, month, day)))
}

# The main export function.
library("readr")
export_files <-
  function(data,
           filename_base,
           dir_base = "data",
           ext = "csv") {
    data <- data %>% add_ymd()
    ymds <-
      data %>% 
      distinct(ymd) %>%
      arrange(ymd) %>%
      pull(ymd)
    
    i <- 1
    while (i <= length(ymds)) {
      ymd_i <- ymds[i]
      data_i <- data %>% filter(ymd == ymd_i)
      
      yyyymm <- strftime(ymd_i, "%Y-%m")
      dir_yyyymm <- file.path(dir_base, yyyymm)
      dir_ymd_i <- file.path(dir_yyyymm, ymd_i)
      filepath_i <-
        file.path(dir_ymd_i, paste0(filename_base, ".", ext))
      
      create_dir(dir_base)
      create_dir(dir_yyyymm)
      create_dir(dir_ymd_i)
      
      readr::write_csv(data_i, path = filepath_i)
      i <- i + 1
    }
  }

# Finally, using the main export function.
export_files(flights_export, filename_base = "flights")
export_files(weather_export, filename_base = "weather")
```

With the setup ret of the way, we can start to look at my approach for
importing and manipulating data from these files.

First, I would write a core function for constructing the file paths
(`get_type_filepaths_bymonth`). In this case, I’ve decided that the year
(`yyyy`) and month (`mm`) are to be passed in as inputs (in addition to
the base directory (`dir_base`) in which to look for files, as well as a
regular expression (`rgx_filepath`) to use for identifying a file by
name. This function is set up to “calculate” the names all of the
individual day files within a given month’s file.

I could have reasonably decided to make this function more “granular” by
making it capable of only identifying a single day file; or, conversely,
I could have made it less granular by making it capable of extracting
all monthly and daily files for an entire year. Nonetheless, my design
choice here is based on a subjective judgement that months is a good
compromise–single days is probably inefficient if using this function in
a long loop iterating over all days across multiple years, and whole
years does not provide much flexibility in the case that there are
sporadic missing days or if only looping over several months in a single
year. [^3]

In addition to the core function, I’ve written two wrapper functions
(`get_flights_filepaths_bymonth`) and (`get_weather_filepaths_bymonth`)
to work specifically with each “type” of data that I’ll need to import
from daily files. As we’ll see later, this kind of function hierarchy
allows a singular, higher-level function for importing and processing
data to be used for either data type (`flight` or `weather`).

As an alternative to the wrapper functions, I might pass the type
directly as a parameter in this function. While this might be fine when
there are two options, I think it gets more difficult to manage when
there are lots of options. Also, I believe that this kind of design
strays away from the general “best practice” of designing functions to
“do one thing, and do it well”. [^4]

``` {.r}
# This is the "base" function for importing different types of data 
# from the same daily folders in monthly folders.
# "Core" filepath-constructing function.
get_type_filepaths_bymonth <-
  function(yyyy,
           mm,
           dir_base,
           rgx_filepath) {
    
    # Check that no parameters are missing.
    # Credit for this snippet:
    # https://stackoverflow.com/questions/38758156/r-check-if-any-missing-arguments.
    defined <- ls()
    passed <- names(as.list(match.call())[-1])
    if (any(!defined %in% passed)) {
      stop(paste("Missing values for", paste(setdiff(defined, passed), collapse = ", ")), call. = FALSE)
    }

    # Now start keyucting the filepaths.
    dir_ym <-
      file.path(dir_base, sprintf("%04.0f-%02.0f", yyyy, mm))

    filepaths <-
      list.files(
        path = dir_ym,
        pattern = rgx_filepath,
        full.names = TRUE,
        recursive = FALSE
      )
    
    # Error handling.
    if(length(filepath) == 0) {
      stop(sprintf("No filepaths found for month %.0f in year %.0f", mm, yyyy), call. = FALSE) 
    }

    # NOTE: There might be a case where a day does not have a file for some reason.
    date_ymd <- lubridate::ymd(sprintf("%04.0f_%02.0f_01", yyyy, mm))
    dd_inmonth <- as.numeric(lubridate::days_in_month(date_ymd))
    if (length(filepaths) != dd_inmonth) {
      stop(
        sprintf(
          "Number of filepaths %.0f is not equal to number of days in month %.0f in year %.0f.",
          length(filepaths),
          mm,
          yyyy
        ),
        call. = FALSE
      )
    }
    filepaths
  }

dir_base_valid <- "data"
# "Type-specific" filepath-constructing functions.
get_flights_filepaths_bymonth <-
  function(yyyy,
           mm,
           dir_base = dir_base_valid,
           rgx_filepath = "flights") {
    get_type_filepaths_bymonth(
      yyyy = yyyy,
      mm = mm,
      dir_base = dir_type,
      rgx_filepath = rgx_filepath
    )
  }


get_weather_filepaths_bymonth <-
  function(yyyy,
           mm,
           dir_base = dir_base_valid
           rgx_filepath = "weather") {
    get_type_filepaths_bymonth(
      yyyy = yyyy,
      mm = mm,
      dir_base = dir_type,
      rgx_filepath = rgx_filepath
    )
  }
```

Now, after the functions for constructing a proper file path, I would
use the same design idiom for functions to import data. My import
functions tend to be “short-and-sweet” because I like to reserve all
processing–even something as simple as renaming or dropping columns–for
separate functions. (Note that, because I identify the file extension
with the file path constructor, I can simply use `rio::import()` to read
in the data, irregardless of the file type.)

One can argue that it is not necessary to have separate functions for
file path construction and importing, but I think having clear,
axiomatic functions to perform singular actions justifies the
distinction.

``` {.r}
library("rio")
# "Core" importing function.
import_type_data <-
  function(filepath) {
    if (missing(filepath)) {
      stop("Missing filepath", call. = FALSE)
    }
    rio::import(filepath) %>% as_tibble()
  }

# "Type-specific" importing functions.
import_flights_data <- import_type_data
import_weather_data <- import_type_data
```

After importing the data, it is time to process it. Again, it can pay
off to write a generic function that is wrapped by other functions.
Notably, as opposed to the functions for file path construction and data
import, it is likely that a generic processing function will have less
code than the wrapper functions, where action is likely to be highly
dependent on the data. The core processing function might only add some
kind of identifier for the date in order to help with grouping after all
of the data is bound together.

In this example, let’s say that I want to add a time stamp indicating
when the data was extracted. (Clearly, this may not be necessary if
working with static data such as the data in this example; nonetheless,
in a real-world situation, adding a time stamp can be extremely
significant for reproducibility and/or auditing purposes.) This can
implemented in the core `process_type_data()` function. [^5] [^6]

Now, let’s say that I need to aggregate over any sub-hourly `flights`
data (i.e. data in the departure time (`dep_time`) and arrival
(`arr_time`) columns), knowing in advance that my computer will not have
enough memory to hold all of the data at the end of all extraction.
(Obviously, this is not the case with this example.) This could be
implemented in the processing function for the flights data, without
needing to write any extra logic in the `weather` processing function to
ignore this action. (Note that the `weather` data has hourly
measurements.)

Also, let’s say that I know in advance that I will only need data for a
specific subset of the flights data, such as for only certain
destinations (`dest`). (Note that there are 110 unique destinations.) In
addition to aggregating over hourly data, filtering for specific
destinations will allow me to avoid memory issues. To implement this
functionality, I use a generically-named `keys` argument (that does not
need to be specified). Although the `*weather()` function does not use
`keys` for anything, it is passed as a parameter to both wrapper
processing functions in order to make both work with an API function
that can call either without needing to specify different parameters.

``` {.r}
# "Core" processing function.
process_type_data <- function(data) {
  data %>% mutate(wd = lubridate::wday(ymd))
}

process_flights_data <- function(data, keys = NULL) {
  ret <- process_type_data(data)

  ret <- 
    ret %>% 
    mutate_at(vars(contains("dep_time$|arr_time$")), funs(hh = round(. / 100, 0) - 1)) %>% 
    group_by(dep_time_hh %>% 
    summarize_at(vars(contains("dep|arr")), funs(mean(., na.rm = TRUE))) 
  # This is "custom" processing for the flight-specific function.
  ret <- ret %>% select(-minute, -time_hour)
  if (!is.null(keys)) {
    ret <- ret %>% filter(dest %in% keys)
  }
  ret
}

process_weather_data <- function(data, keys = NULL) {
  process_type_data(data = data)
}
```

Now I can use one main “looping” function to call the wrapper functions
for file path construction, data import, and (basic) data processing to
extract all daily data for a given month. Note how the `type` parameter
provides the flexibility of extracting either `flights` or `weather`
data with a single function under my design. The names of the functions
are constructed using `type`, and the functions themselves are invoked
with `do.call()`. [^7]

``` {.r}
types_valid <- c("flights", "weather")
# The main function for a single month.
get_type_data_bymonth <- function(yyyy, mm, type = types_valid, keys = NULL) {
  
  # Create names for functions to be passed to `do.call()` in the main `while` loop.
  type <- match.arg(type)
  func_get_filepaths <- sprintf("get_%s_data_filepaths_bymonth", type)
  func_import <- sprintf("import_%s_data", type)
  func_process <- sprintf("process_%s_data", type)
  
  # Gat all filepath for month.
  filepaths <- do.call(func_get_filepaths, list(yyyy = yyyy, mm = mm))
  data_i_list <- vector("list", length(filepaths))
  
  i <- 1
  while (i <= length(filepaths)) {
    
    filepath_i <- filepaths[i]
    message(sprintf("filepath: %s.", filepath_i))
    ymd_i <- filepath_i %>% str_extract("[0-9]{4}-[0-9]{2}-[0-9]{2}")
    
    data_i <- do.call(func_import, list(filepath = filepath_i))
    data_i <- do.call(func_process, list(data = data_i, ymd = ymd_i, keys = keys))
    
    data_i_list[i] <- list(data_i)
    names(data_i_list[i]) <- ymd_i
    
    message(sprintf("Done processing %02.0f.", i))
    i <- i + 1
  }

  ret <- do.call("rbind", data_i_list)
  ret
}

# Using the main function.
flights_nyc_01 <-
  get_type_data_bymonth(yyyy = 2013, mm = 1L, type = "flights")
flights_nyc_0102_atllax <-
  get_type_data_bymonth(
    yyyy = 2013,
    mm = 1L,
    type = "flights",
    keys = c("ATL", "LAX")
  )
weather_nyc_0102 <-
  get_type_data_bymonth(yyyy = 2013, mm = 1L, type = "weather")
```

Then, if I need to extract data for multiple months and/or multiple
years, writing another function to wrap my monthly function
(`get_type_data_bymonth()`) is fairly straightforward. All I need are
loops for years (`yyyy`) and months (`mm`).

``` {.r}
# The main function for multiple years/months.
get_type_data_byyear <-
  function(yyyy,
           mm = seq(1L, 12L, 1L),
           type = types_valid ,
           keys) {
    match.arg(type)
    n_yyyy <- length(yyyy)
    n_mm <- length(mm)
    
    data_list <- vector("list", n_yyyy * n_mm)
    y_i <- 1
    while (y_i <= n_yyyy) {
      m_i <- 1
      while (m_i <= n_mm) {
        m_i <- mm[i]
        data_ym <-
          get_type_data_bymonth(
            yyyy = y_i,
            mm = m_i,
            type = type,
            keys = keys
          )
        
        ym_i <- y_i + m_i
        data_list[(ym_i)] <- list(data_ym)
        names(data_ym[ym_i]) <- sprintf("%04.0f_%02.0f", y_i, m_i)
        m_i <- m_i + 1
      }
      y_i <- y_i + 1
    }
    do.call("rbind", data_list)
  }

# Using the main function.
flights_nyc_0102 <-
  get_type_data_byyear(yyyy = 2013, mm = 1L:2L, type = "flights")
flights_nyc_0102_atllax <-
  get_type_data_byyear(
    yyyy = 2013,
    mm = 1L:2L,
    type = "flights",
    keys = c("ATL", "LAX")
  )
weather_nyc_0102 <-
  get_type_data_byyear(yyyy = 2013, mm = 1L:2L, type = "weather")
```

With all of the data collected, more detailed data processing (beyond
the the basic processing done for each file) can be performed.
[^8]




Final Thoughts
--------------

In my experience, writing generic functions that can be wrapped by
“type-specific” functions has been helpful in a number of situations,
such as with extracting data from daily files. This design pattern
reduces code length (in most cases), and, more importantly, enhances the
readability and re-usability of the code.



------------------------------------------------------------------------

[^1]: When I do use traditional loops, I nearly always opt for `while` loops instead of `for` loops, despite the potential trap of an infinite loop if I forget to write the increment for the index. I believe that `while` loops are more dynamic for situations where the vector/list being iterated upon is not continuous. Also, I find `while` loops easier to debug.

[^2]: In software design, this kind of idiom is similar to the [adapter pattern](https://en.wikipedia.org/wiki/Adapter_pattern) and [facade pattern](https://en.wikipedia.org/wiki/Facade_pattern) in object-oriented (OO) programming.

[^3]: Either way, one could easily adapt this function depending on the use case.

[^4]: See [this article](https://martinfowler.com/bliki/FlagArgument.html) for a discussion of Boolean arguments used to determine the action of functions.)

[^5]: One must be careful with adding processing action that can be done just as easily on the entire data set after it has been collected. For example, adding a column for the day of the week of a certain date should be done at the end of the entire data extraction process.

[^6]: Note that reducing any kind of processing of raw data until completely necessary may require some re-factoring after initial development of the processing function, where only a single file's data is being used to test a subsequent function.

[^7]: Note that I explicitly set `keys = NULL` by default in order to avoid a "missing" error when using `do.call()` with the processing function.

[^8]: If one had done some fairly custom processing prior to combining all of the data, then one might need re-extract all of the data again if the processing actions need to be changed at some later point in time.
 