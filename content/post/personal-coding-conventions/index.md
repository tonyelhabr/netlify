---
title: Personal Coding Conventions
# slug: personal-coding-conventions
date: "2018-02-10"
categories:
  - r
image:
  caption: ""
  focal_point: ""
  preview_only: false
header:
  caption: ""
  image: "featured.jpg"
---

As a person who’s worked with various programming languages over time, I
have become interested in the nuances and overlaps among languages. In
particular, concepts related to code syntax and organization–everything
from technical concepts such as lexical scoping, to more broad concepts
such as importing and naming data–really fascinate me. Organization
“enthusiasts” like me truly appreciate software/applications that follow
consistent norms.

In the R community, the `tidyverse` ecosystem has become extremely
popular because it implements a consistent, intuitive framework that is,
consequently, easy to learn. Even aside from the `tidyverse`, `R`’s
system for package development, documentation, etc. has strong
community-wide standards. [^1] In all,
there’s something magical about R’s framework that has made it my
favorite language to use.

While I tend to follow most of the R community’s “best practices”, there
are certain “traditional” or well-agreed upon aspects of `R` programming
where I knowingly deviate from the norm. I think
spelling out exactly why I follow the norm on some fronts and not on
others is a good exercise in self-understanding, if not just a fun
exercise in seeing how many people disagree with me.


Setup
-----

-   Use quotes (i.e standard evaluation) when importing a package.

``` {.r}
library("dplyr")
# instead of
library(dplyr)
```

I believe most people use the non-standard evaluation (NSE) approach,
but I like not having to use NSE when it is not really intended to be
used as the primary means of invoking a function. (Note that with some
packages, such as `dplyr`, NSE **is** intended to be the primary means
of working with variables and functions. In that case, I would not go
out of my way to invoke standard evaluation methods.)

-   Import tidyverse packages explicitly instead of importing the
    `tidyverse` package itself.

``` {.r}
library("dplyr")
library("stringr")
# instead of 
library("tidyverse")
```

Again, I think I’m probably in the minority on this one (although most
people may not even have an opinion on which method is “best”). One can
argue that the whole point of bundling the six or so packages that get
loaded with `library("tidyverse")` is to “abstract away” having to think
about what packages will be necessary for a specific analysis.

-   Do not import a package if it is only being used once or twice.
    Instead, use the `package::function` notation.

``` {.r}
iris_cleaned <- janitor::clean_names(iris)
# instead of
library("janitor")
iris_cleaned <- clean_names(iris)
# ... Then go on to not use janitor again.
```

Additionally, I may sometimes use the `package::function` notation even
after importing a package if the function name might be confused with a
variable name. For example, I might specify `lubridate::year()` even
after calling `library("lubridate")` because `year` might seem like a
verb. (There’s more on that in another section.)

I’m not really sure if there is a general consensus or not on this
matter.

-   Favor `sprintf()` over `paste()` (or another similar function) if
    inserting numerics or strings in some kinds of “boiler-plate”
    string.

I think `sprintf()` offers slightly better “find-and-replace” syntax,
which can be useful when re-using code or even when debugging. Also, I
think that it makes the underlying string more readable in the case that
there are a lot of variables to substitute in to the string.
Nonetheless, my justification in this matter is not unwavering–one can
argue that `paste()` has the advantage of more clarity depending on the
length of the boiler-plate string and the number of variables to be
inserted. (In fact, I often find myself switching among `sprintf()`,
`paste()`, `paste0()`, and `stringr::str_c()` with no real discretion,
so I can by hypocritical on this matter.)

``` {.r}
person <- "Tony"
sprintf("%s is a wonderful person.", person)
# is not really any easier or more explicit than
paste(person, "is a wonderful person.")

# but for a case like this
team_1 <- "Yankees"
team_2 <- "Red Sox"
score_1 <- 3
score_2 <- 4

sprintf("The %s defeated the %s by a score of %0.f to %0.f.", team_1, team_2, score_1, score_2)
# is probably better than 
paste("The", team_1, "defeated the", team_2, "a score of ", score_1, "to", score_2, ".")
```

-   Favor `stringr` functions over their base R equivalents (i.e.
    `gsub`, `grep`, etc.).

My behavior in this matter is probably not all that controversial, but I
just wanted to make a note of it because I sometimes catch myself using
functions like `gsub()` and `grep()` in “tidy” pipelines, only to
realize that a `str_replace()` or `str_detect()` would save me some
effort because I don’t have to use a `.` to anonymously specify the
`x`/`string` argument. Nonetheless, I have found that using the
`stringr` functions is not necessarily second nature for me because the
base R methods shown in many [Stack Overflow](www.stackoverflow.com)
have ingrained in me non-`tidyverse` style. (I should be clear–these
other techniques are not “bad” or “incorrect” in any way.)



Naming
------


### Files and Folders

For naming files and folders, [Jenny Bryan’s informative presentation
“Naming
Things”](http://www2.stat.duke.edu/~rcs46/lectures_2015/01-markdown-git/slides/naming-slides/naming-slides.pdf)
is a must-read. I do my best to follow the principles she outlines,
while also adding in some of my own “flair”.

-   Use “-” as a separator in file names to distinguish different
    components (e.g. `...scrape-[website]-...`. Otherwise, use an
    underscore “\_" as a separator for words that make up a single
    topic/entity/component (e.g. `...-new_zealand-...`)

I don’t think my choices in this matter are too controversial.

-   Add a numeric prefix for files that are to be executed in a
    pre-defined order.

<!-- -->

    01-scrape.R
    02-process.R
    03-analyze.R
    04-report.R

I don’t think my convention is unusual here–there is no conflict with
Jenny’s principles.

Notably, I like to add a “main” file, i.e. `00-main.R`, that sources
each of the files in a workflow. Something like GNU Make could also be
used, but I like to stick with R tools exclusively. In that case, an R
package like `remake` or `drake` could be used, but typically my project
workflow is not so complex that it necessitates the added functionality
that these packages present. Jenny discusses these things in her [*All
the Automation Things* Topics
page](http://stat545.com/automation00_index.html) Topics page for her
class.

Sometimes my project has a “configuration”, i.e. `config.R` or
“functions” `functions-analyze.R` file that might need to be “sourced”
at the beginning of a workflow. I tend to not added numeric prefixes to
these files, and I source them in at the beginning of my “main” script.

-   Add numbers for file suffixes, i.e. `-v01`, `-v02`, etc., for
    versioning.

This practice of mine is probably atypical. I realize that this is not
really necessary if using git or some other version control service, but
I have a difficult time completely deleting a file that I am not 100%
sure I will never need to look back at. (I generally oppose “hoarding”
of things in this manner, but some habits are hard to break).) In my
opinion, keeping the file is simply easier than restoring previous
snapshots in a git life cycle. Once I’m completely convinced that I no
longer have use for an “old” file, then I delete it.



### Functions

For functions, I do my best to implement the principles outlined in the
[Functions chapter of the R for Data Science
e-book](http://r4ds.had.co.nz/functions.html). The notion of using verbs
for function names (unless the function is so simple that a noun might
be more appropriate) makes a lot of sense to me.

Perhaps the reader might find it interesting that I like to use the verb
prefix `compute_` for functions that use `dplyr` functions in a piped
action simply because it is not extremely common and, consequently, not
likely to interfere with an existing function name from an imported
package. I think my logic on this matter is in tune with general
practices–many packages nowadays use package-specific prefixes for their
functions in order to distinguish them (e.g. the `str_` prefix for
`stringr` functions).

Additionally, sometimes I’ll use the simple verb prefix `get_` (a la the
`get` and `set` methods of an object class in an object-oriented
programming framework) if the function is fairly simple and there is no
other intuitive name to use.



### Variables

I think, in general, my conventions with variables are “acceptable”.
Personally, I implement “snake case” for my variable names, although I
have no qualms with those who use some other convention (e.g. “Camel
Case”) as long as they are consistent. Interestingly, I went through a
phase with R programming where I implemented a form of the Visual Basic
style of prefixing variable names with the class type of the variable
(i.e. `strVariable` for a string, `intVariable` for an integer, etc.).
[^2] I was prefixing my character variables
with `ch_`, data-like variables (i.e. `data.frame`/`matrix` with `d_`,
etc.). This practice is probably not all too abhorrent, but I think its
more verbose than is necessary, and goes against the original
inspiration for `R`, a language created by statisticians in order to
make scientific work more natural for those with little to no experience
with computer science.


#### Variables for Files and Folders

I tend to break up the names of files into the following components:

-   `dir`: Directory. i.e. what would be returned by
    `gsub(basename(.), "", .)`
-   `filename`: Name of the file, without the directory or extension.
    i.e. what would be returned by `basename(.)`.
-   `ext`: File extension, without the “.”. i.e. What would be returned
    by `tools::file_ext(.)`.

When combining these three components, I name the variable `filepath`
(using the OS-agnostic `file.path()` function). Perhaps the more
traditional name for such a thing is simply `path`, but I tend to think
that that term is a bit ambiguous.

``` {.r}
# Should be a relative path!
dir <- "/path/to/file/"
filename <- "mysupercoolfile"
ext <- "txt"
filepath <- file.path(dir, paste0(filename, ".", ext))
# Don't care if an extra forward-slash is added here. It will still work.
filepath
```

    ## [1] "/path/to/file//mysupercoolfile.txt"



#### Variables for Dates

Because I often work with dates, I have an opinion on naming
date-related variables.

-   I like to use `yyyymmdd` (as opposed to something maybe more
    intuitive like `date` or `ymd`) to refer to a date in the ISO 8601
    international standard format (i.e. “2017-03-14” for March 3, 2017).

I feel that this format is more explicit and stands out. Similarly, if
assigning a number for a year, month, or day, I like to use `yyyy`,
`mm`, and `dd` respectively (even if the month or day is a single
digit). Others may reason to use `year`, `month`, and `day`, but these
names conflict directly with functions in the `lubridate` package (which
I often use for converting numbers representing some kind of time/date).
The very short `y`, `m`, and `d` might be another option, but I think
each can be can be extremely ambiguous. Is `d` a day or date? Or data?
Is `m` a month or minute? Is `y` a year or the response variable in a
regression model?

Likewise, my logic advocating the use of `yyyymmdd` for dates explains
my preference for `hhmmss` for time variables (and `hh`, `mm`, `ss` for
individual components of time-related variables).



#### Other Objects

-   I prefer to use `colname` instead of `col_name` when referencing the
    **name** of a column in a `data.frame`/`matrix`. Since I don’t think
    `col` (for column) and `name` really represent separate entities, I
    don’t think it’s best to separate them with an underscore. (This
    convention also explains my preference for `filename` instead of
    `file_name`, as well as `filepath` instead of `file_path`.)

My stance on this matter might be “out of sync” with the `tidyverse`
mantra. Note that the `readr` package uses `col_names` as a parameter.

-   I prefer `col` instead of `var` when referencing the **values** in a
    `data.frame`/`matrix`. `var` can be ambiguous. (Is it a variable in
    a formula?)

I think I’ve seen someone high-up in the R community (Hadley?) mention
that they prefer `col` over `var` as well, so maybe my practice is
“advisable”, if not the norm.

-   I prefer `data` as the name of the data parameter in a function
    (assuming that the operation is being performed on a `data.frame`),
    as opposed to `df`,`dat`, or `d`. In the case of a function that
    operates on columns/rows in a `data.frame`/`matrix`, I prefer the
    name `x`.

I think there’s probably a wide range of styles that people have
regarding this specific matter, especially the `data` parameter.

-   I try to truncate longer names or actions to 3 or 4 letters. For
    example, For example, I often use `proc` instead of `processed` to
    indicate that a data object has been transformed in some manner. (In
    this example, `proc` would be appended on the name of the input
    variable (i.e. `data_proc` if the original variable is `data`.) Some
    of my other “go-to”’s include `tidy` and `summ` (instead of
    `summarized`). Notably, I like to pair `trn` and `tst` when working
    with `train`ing and `test`ing sets for machine learning.

-   I like to use `out` for the output variable of a function,
    irregardless of what the function does (assuming that there are more
    than a single action in the function, which would require assignment
    to a variable).

I think this is fairly common. In fact, I think I picked up this
convention when studying other people’s package code.

-   I like to end variables with the “s” suffix when I know that it is a
    vector. For example, I might use `yyyymmdds` for a vector of dates.

``` {.r}
yyyymmdds <- c(as.Date("2018-01-01"), as.Date("2018-02-01"))
```

This technique can sometimes result in awkward names, which makes me
think that most people would be against it. (Perhaps the more likely
case is that most people would see the difference as trivial and ask me
why I’m thinking so hard about this anyways.)





Projects and Workflow
---------------------

I draw heavy inspiration on my format of a project skeleton from the
ideas laid out in [Nice R’s blog post on
projects](https://nicercode.github.io/blog/2013-04-05-project/) and in
[Carl Boettiger’s description of his
workflow](http://www.carlboettiger.info/2012/05/06/research-workflow.html).

-   For project skeleton, emulate the structure of an R package as
    closely as possible.

To be explicit, my projects tend to look like this.

    [project_name]/
    |--data/
    |--data-raw/
    |--docs/
    |--figs/
    |--output/
    |--R/

A short explanation of each: + `data/`: Data created from scripts
(e.g. a web scraper) that are **not** intended to be shared as part of
the project’s output. Preferably stored in an R data format (e.g. .rds
file). + `data-raw/`: Manually-collected data. Probably saved as a .csv
or .xlsx file. Appropriate location for SQL files and output if a
database connection (i.e. with a company/enterprise database) cannot be
made directly through R. + `docs/`: Documentation of the project.
Preferably RMarkdown or Markdown file(s). + `figs/`: Ad-hoc
visualizations created interactively that are **not** designated for the
project’s output. + `output/`: Deliverables. Preferably RMarkdown files
or files `knitted` from RMarkdown. Possibly includes nested `data` or
`figs` folders. + `R/`: R code. .R files that function primarily as
scripts or host a set of functions that are “sourced” into a script file
are appropriate.

(See Hadley Wickham’s book on [*R Packages*](http://r-pkgs.had.co.nz/)
for more explanation.)

Probably the most significant difference between my structure and that
of an R package is the `output/` folder (which might be considered the
analogue of a `vignettes/` folder in an R package).

Regarding project documentation, I prefer the `docs/` name for the
documentation folder, as opposed to the R package standard of `man/`. In
my opinion, `docs/` is more appropriate because it seems to be the
standard name for a folder hosting extensive documentation of a package
(as opposed to `man/`, which is for package functions). (Additionally, I
should note that the `pkgdown` R package for creating a website for an R
package and its documentation generates a `docs/` folder.)

Finally, in compliance with standard R package development, one should
add folders for `src/` and `tests/` for C code and testing scripts. (I
personally have never written C code or tests for my projects.)

-   Create an `old/` folder in the same location that a no-longer-used
    file was previously used.

This practice of mine goes hand-in-hand with my “manual” versioning of
files. When I begin using a newer version of a script, I’ll typically
put the previous version(s) in an `old/` folder.



Conclusion
==========

In general, Hadley Wickham and Jenny Bryan are the “go-to” knowledge
resources in the `R` community on all things related to `R` programming
style, practices, etc.

-   Jenny’s Class pages
    [here](https://www.stat.ubc.ca/~jenny/STAT545A/#stat-545a-exploratory-data-analysis)
    and here [here](http://stat545.com/index.html). [This page on code
    formatting](https://www.stat.ubc.ca/~jenny/STAT545A/block19_codeFormattingOrganization.html)
    is a must-bookmark.

-   Hadley’s [original *Tidy data*
    paper](http://vita.had.co.nz/papers/tidy-data.html), [*R for Data
    Science* book](http://r4ds.had.co.nz/) (co-authored), [“Tidyverse
    Style Guide”](http://style.tidyverse.org/), and [“Tidy Tools
    Manifesto”](https://cran.r-project.org/web/packages/tidyverse/vignettes/manifesto.html).

Of course, these resources represent only a very small subset of amazing
resources out there. I know I could go on for days reading about style,
syntax, etc., but maybe that’s just me. [^3]



------------------------------------------------------------------------



[^1]: Of course, other programming languages/communities have their own sets of standards that deserve merit.

[^2]: Note that Camel Case is the preferred style amongst the Visual Basic community.

[^3]: If you enjoy this topic, then you probably enjoy classic software-related debates such as ["spaces vs. tabs"](https://stackoverflow.blog/2017/06/15/developers-use-spaces-make-money-use-tabs/) and ["R vs. python"](https://www.datacamp.com/community/tutorials/r-or-python-for-data-analysis).
