+++
title = "The Qualitative Side of My NBA Regularized Adjusted Plus Minus (RAPM) `R` Project"
date = "2018-12-31"
draft = true

# Authors. Comma separated list, e.g. `["Bob Smith", "David Jones"]`.
authors = []

# Tags and categories
# For example, use `tags = []` for no tags, or the form `tags = ["A Tag", "Another Tag"]` for one or more tags.
tags = ["r", "nba", "lasso", "regression"]
categories = ["r", "nba"]

# Projects (optional).
#   Associate this post with one or more of your projects.
#   Simply enter your project's folder or file name without extension.
#   E.g. `projects = ["deep-learning"]` references 
#   `content/project/deep-learning/index.md`.
#   Otherwise, set `projects = []`.
projects = ["nba-rapm"]

# Featured image
# To use, add an image named `featured.jpg/png` to your page's folder. 
[image]
  # Caption (optional)
  caption = ""

  # Focal point (optional)
  # Options: Smart, Center, TopLeft, Top, TopRight, Left, Right, BottomLeft, Bottom, BottomRight
  focal_point = ""
  preview_only = false
+++

~~
[implementing custom conditions](https://adv-r.hadley.nz/conditions.html).
~~

### Cleaning the Data

I touched upon some of the "imperfections" in the raw data in my previous post.
I wanted to describe in more detail exactly how I addressed these issues.
to download player-specific and team-level
data from [basketball-reference](https://www.basketball-reference.com/)
and compare my "calculated" values with the "actual" values for various 
things---such as team wins and points,
individual player minutes and games played, and even five-man lineup plus-minus 
totals.


### Features

+ The project provides a [command-line interface](https://en.wikipedia.org/wiki/Command-line_interface) 
(CLI) that blends seamlessly with interactive use (i.e. not via the 
command line). This is achieved by
adept use of the `{config}` and `{argparser}` packages for providing
APIs to work with `yaml` and the command line respectively. [^1]

    To provide more detail, two `yaml` files are used: (1) a "static" one to specify
parameters that are not configurable via the command line, but which the developer
would like to specify in order to keep file names consistent across different
raw data sets.
    


### Developer and API Conventions

+ A dot prefix is used for un-"exposed" functions that are not intended to be used directly by the user.
(i.e. like how "helper" functions in a package are not exported). Part
of the reason for doing this is to maintain a "minimal" Environment pane
in the RStudio editor. (One might argue that this is a good reason to 
hide the Environment pane entirely.

+ The `auto_` prefix is used for "exposed" functions with arguments set equal to command line `args`.
This prefix indicates (to the user) that these are to be used for batch-style automated runs.

+ `path`-like function parameters 
are converted to variables borrowing their namesake.
For example, `path_raw_play_by_play` is converted to `raw_play_by_play`,
`path_raw_game_summary` is converted to `raw_game_summary`, etc. 
The season from which the data comes from is "attached" as a suffix to the corresponding file.
These `path`-like parameters are converted to/from their variable equivalents via the 
internal `.[import|export]_data_from_path()` functions.

+ The names of `path`-like parameters in exposed functions are intentionally
named in a verbose manner (somewhat compromising the "abstractness" of the functions).
This is done to implicitly indicate to the user 
(and the unacquainted developer, such as myself looking back at this in
the future)  what the intended
value of the parameter is to be (e.g. `path_play_by_play` is used, as opposed to
something simpler/more generic like `path` in order to indicate that the path format
is intended to be filled with a value representing the path format of
`play_by_play` data.
This convention is applied even in the case that only a single "significant" 
path-like format is required as an input
(or exported as an output) for a given function.
While such verboseness may seem cumbersome and/or unnecessary, this style is
useful in the cases where more than one "significant" input
is required for a given function. For example, the `clean_raw_play_by_play()`
function depends on both `raw_play_by_play` and `raw_game_summary` 
(imported from their corresponding path-like parameters).

This convention for path-like paramters also applies to first-ini arguments that
would otherwise just be named something like `data` (in accordance with `{tidyverse}`
conventions). As with the path-like arguments, this is done primarily for
"self-documenting" purposes.

+ Use all-caps variable names to indicate any one of the following:
    + a global default to pass to any argument that uses it (e.g. `VERBOSE`, `EXPORT`, etc.)
    + a "hard-coded" variable in a function (e.g. `.SUFFIX_COLS_STATS_ORDER1`)
  
+ Save result from `.export_data_from_path_format()` as `path_export` always
(no matter what the `data` or `path_format` is).

+ Note the following idiom:
1. Beforehand, create a ".get" function to retrieve/recreate 
some relatively trivial data  (e.g. `players`, `teams`, `game_summary`)
2. In function that is capable of recreating it and is dependent on it,
check if the data exists in the following manner:
  + Create a `.import_*_partially()` function (passing on the calling functions
  shared parameters).
  + Create a `.import_*_possibly()` function, using the aforementioned `_partially()`
  function as the `.f` parameter. (Note that this step and the previous one
  could be combined so that no explicity `partially()` function is created.)
  Set `.otherwise` to some sentinetl (e.g. `NULL`)
  + Call the `possibly()` function.
  + Check if the result is the sentinel (e.g. is.null(...))
  + If the result is the sentinel, then call the `.get_*` function. Pass the shared
  parameters from the calling function.

+ `.validate_*()` functions are not called in functions where there target of validation
is not a "requirement". (To provide an example, `.validate_season()` is called in the
`.import_data_from_path_format()` function--where `path` depends on the value of `season`---and
not from `clean_play_by_play()`, which itself calls `.import_data_from_path_format()`
and is not directly dependent on the value of `season`.

+ `season` always follows the `path_format`-like parameters in functions.
This is done simply to maintain some kind of consistency. (An equally valid choice
would have been to place `season` before the `path_format`-like parameters.)
`...` is left as the last paramter in all functions so that "side-effect"-like
paramters (i.e. `verbose`, `export`, `backup`, etc.) are passed "efficiently".

+ If a function exports some data, then return the data it exports silently with `invisible()`.

+ If more than one import data set is created by an exposed function, then
the results are returned in a named list.

+ Must include `skip` as an explicit paramter in exposed, non-"auto" functions because
the function may be exited early depending on its value. This "power" of the `skip`
parameter indicates that it cannot really be interpreted to have the same
level of significance as the "side"-effect set of paremeters.


----------------------------------------------------------------------

[^1]: although any packages that provide good `yaml` and CLI functionality certainly could have been used
