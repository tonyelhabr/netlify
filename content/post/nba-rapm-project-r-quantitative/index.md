+++
title = "Calculating NBA Regularized Adjusted Plus Minus (RAPM) with `R`, The Details"
date = "2018-12-31"
draft = true

# Authors. Comma separated list, e.g. `["Bob Smith", "David Jones"]`.
authors = []

# Tags and categories
# For example, use `tags = []` for no tags, or the form `tags = ["A Tag", "Another Tag"]` for one or more tags.
tags = ["r", "nba", "lasso", "regression"]
categories = ["nba"]

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

# Introduction



# What is [Regularized Adjusted Plus-Minus](https://www.nbastuffer.com/analytics101/regularized-adjusted-plus-minus-rapm/) (RAPM)?

RAPM is an "all-in-one" metric used to quantify individual player impact
that accounts for the skill of the player's teammates and opponents and
and for biases in traditional modelling. [^#]
To develop a better understanding,
I highly encourage the reader to browse the link provided,
as well as the pages linked from it, such as the one on 
[Adjusted Plus-Minus](https://www.nbastuffer.com/analytics101/adjusted-plus-minus/),
upon which RAPM is based.

[^#]: Perhaps it can help to break it down into three components: (1) **plus minus** = *"impact"*; (2) **adjusted** = *"accounts for the skill of the player's teammates and opponents"*; (3) **regularized** = *"accounts... for biases in traditional modelling"*

Additionally, for an even more in-depth explanation (about as detailed of an explanation
that you'll find on the Internet) of RAPM and some pratical examples,
check out [Justin Jacobs](https://twitter.com/squared2020)' series of posts
on the topic on [his website](https://squared2020.com/):

    + [Part 1, an example with discussion focused on the mathematics behind the theory](https://squared2020.com/2017/09/18/deep-dive-on-regularized-adjusted-plus-minus-i-introductory-example/)
    + [Part 2, data preparation with `R` code](https://squared2020.com/2017/09/18/deep-dive-on-regularized-adjusted-plus-minus-ii-basic-application-to-2017-nba-data-with-r/)
    + [Part 3, discussion focused on "weaknesses" in approach)](https://squared2020.com/2018/12/24/regularized-adjusted-plus-minus-part-iii-what-had-really-happened-was/)

I would highly encourage anyone that wishes to calculate RAPM themselves
to read those articles [^#]. [^#] In fact, if you're going to follow along
with the next section, I'd say that these are "required readings".

[^#]: as well as anything else on his site if you're interested in analytics in general.

[#]: The [basektball-analytics](http://basketball-analytics.gitlab.io/rapm-data/) website [GitLab repo](https://gitlab.com/basketball-analytics/rapm-model)
and [Evan Zamir](https://twitter.com/thecity2)'s [GitHub repo](https://github.com/EvanZ/nba-rapm) also serve as 
great code resources.

# The Implementation

[Jacobs' second post on RAPM](https://squared2020.com/2017/09/18/deep-dive-on-regularized-adjusted-plus-minus-ii-basic-application-to-2017-nba-data-with-r/) really provides a great primer for exactly how
play by play data should be "massaged" to coax it into a format that can be used
for modelling, so I direct the reader to his post for details on the data
preparation part of the RAPM formulation. [^#]

[^#]: My implementation is more "tidy" (in terms of `R` code), but his more traditional use of `for` and `if` clauses is arguably more pedagogical.

To compare data preparation steps to Jacobs' [^#],

    + I use the same criteria for counting possessions---any possession ending 
    in "a converted last free throw, made field goal, 
    defensive rebound, turnover, or end of period". [^#] [^#]
    
    + I implement the "alternative" technique
    that Jacobs touches upon in the last section in this article
    (titled "Choose Your Own Adventure in Models"),
    where possessions are **not** aggreggated into stints 
    (i.e. consecutive sets of possessions without changes in lineups by either team) 
    and positive points are
    used instead point differential (which is more natural when aggreggating possessions
    into stints).
    I found this alternative approach to be a bit more intuitive for me,
    although I acknowledge that it results in a larger data set (i.e. a data set with more rows),
    which is less ideal for computational purposes. Nonetheless, Jacobs' notes that
    the techniques that do and don't aggregate possessions into stints lead to similar
    results.
    
    + I distinguish players in a given game by offense and defense instead
    of by home and away teams, which Jacobs demonstrates in
    [his first post](https://squared2020.com/2017/09/18/deep-dive-on-regularized-adjusted-plus-minus-i-introductory-example/).
    (On the other hand, he seems to use the offense/defense perspective in
    [his third post](https://squared2020.com/2018/12/24/regularized-adjusted-plus-minus-part-iii-what-had-really-happened-was/)
    As long as point tallying accounts
    for the orientation of teams properly, this difference should not have
    any effect on the calculations.

[^#]: See the `clean_play_by_play()` and `munge_play_by_play()` functions in [my project's repo](https://github.com/tonyelhabr/nba-rapm).
    
[^#]: Note that possessions that begin with an offensive rebound after a missed field goal/free throw are **not** counted as a distinct possession.

[^#]: Regarding my implementation with `R`, this step involves a lot of `{dplyr}` and `{tidyr}` usage, most notably `dplyr::mutate()`, `dplyr::filter()`, `dplyr::arrange()`, and `tidyr::fill()`.

In its final "cleaned" form, my data set---what Jacobs' refers
to as the "stint matrix" or "design matrix"---has one row for each possession and 
one column for each player, as well as
an additional column---the "response" to be modelled---tallying points scored on
the possession. The cells in this "matrix" (aside from those in response column) take
on values of `1`, `-1`, or `0` to represent that the player is on offense, on defense,
or not on the court (for one reason or another, such as not being a participant in the game).
The values in the response column are either `0` or a positive value
(most commonly `2` or `3`). [^#]

[^#]: The set of possible values for cells in the stint matrix (i.e. `1`, `-1`, or `0`) would **not** be different
for the technique that Justin describes in detail (i.e. the non-"alternative" approach). On the other hand, the set of values in the response column **would be** different for the stint
technique that Justin describes because points are aggreggated.

Finally, after getting the data into this format, the modeling---in particular,
[ridge regression](https://en.wikipedia.org/wiki/Tikhonov_regularization)---can be done.
For my implementation with `R`, this is reflected in a call to `glmnet::glmnet()`---setting
`alpha = 0` for the [L2 loss function](https://towardsdatascience.com/l1-and-l2-regularization-methods-ce25e7fc831c).
(This call is nested in my `fit_rapm_models()` function.)
Jacobs has a good discussion of the technique towards
[the end of his first post on RAPM](https://squared2020.com/2017/09/18/deep-dive-on-regularized-adjusted-plus-minus-i-introductory-example/),
so I'll defer to that for the reader interested in knowing more.

I should note that there are actually two models to fit---to calculate the
offensive and defensive components of RAPM separately. [^#]

[^#]: While some calculate RAPM **without** splitting into two components, most people do split RAPM nowadays, as
pointed out by Jacobs in [his third article](https://squared2020.com/2018/12/24/regularized-adjusted-plus-minus-part-iii-what-had-really-happened-was/). Ultimately, the results **shouldn't** be too different.

Now, regarding the choice of value for the penalty term `lambda`---which 
is not trivial---Jacobs specificies a value of `1000` after some
quick experimentation with a range of values.
From my readings elsewhere and from my own experimentation, 
this value seems too high to me. [^#]
I ended up choosing values of `100` and `250` for offensive and defensive RAPM
after finding that values around these were identified as "optimal"
via cross-validation across several seasons.


[^#]: Jacobs seems to indicate that he chose this value mostly for demonstration purposes.

## A Short Aside on Possessions

Speaking of possessions, throughout his post Jacobs elaborates upon the
the "subjectivity" involved in determining exactly what constitutes a possession.
(e.g. How do we consider possessions across substitutions between free throws?)
This subject is undoubtedly one of the primary reasons why everyone seems to come
up with different results when calculating RAPM for themselves. [^#]
(More on this in a later section.)

[^#]: In fact, he has [an entirely separate article](https://squared2020.com/2017/07/10/analyzing-nba-possession-models/) dedicated to the matter.

## A Longer Aside on the Raw Data

The raw data comes from the `play_by_play_with_lineup/` zip file from
[this public Google Drive folder](https://drive.google.com/drive/folders/1GMiP-3Aoh2AKFCoGZ8f0teMYNlkm87dm),
which is generously provided by [Ryan Davis](https://twitter.com/rd11490), who
is himself an active member of the online NBA analytics community.
Gathering the data needed to calculate RAPM would have been a large task itself,
so I was glad to find that someone else had already done that work and was willing
to share! [^#]

[^#]: Although the NBA provides an API for accessing its data, combining
5-man lineup data with play by play data is not straightforward whatsoever.
Check out [Ryan's explanation](https://github.com/rd11490/NBA-Play-By-Play-Example)
to get a feel for the difficulty of the task.

Not having to collect this data myself---which would have been a challenge
in and of itself---gave me a nice "head start" towards
my goal of calculating RAPM. Nonetheless, this raw data---as most raw data seems 
to be---required some non-trivial cleaning and other "munging" in order to 
create a data set in the format that I could use for modelling.
Initially, I naively assumed the data was "perfect" and wrote the code to do the modeling,
only to realize that I would have to do some major work to process the raw data
when I came up with extremely "unexpected" results.

While I won't bother to describe all of the details involved in the data cleaning
and re-formatting process, here is a quick list of some of the notable things
requiring attention, as well as the the repercussions and possible source of error for each.

    + The home and away team point totals were swapped! Of course, leaving these values
    "as is" would certainly cause the final calculations to be erroneous.
    I think that the swapped team point totals may have been a simple error on Ryan's part.
    (I don't mean to criticize Ryan whatsoever for the "cleanliness" of his provided data. [^#])
    
    + Certain possession types (e.g. timeouts and other kinds of time stoppages)
    needed to be removed. Irrelevant possessions need to be filtered out
    in order to prevent "over-counting" of possession totals, which, consequently,
    can "deflate" the final calculated values.
    Note that this isn't actually an error at all [^#]; 
    it's just not something that I needed/wanted in the data for modeling.
    
    + Some possessions (albeit, a very small proportion of them) are listed "out-of-order" (as implied
    by a running index of possessions for each game). If these kinds of plays
    had not been addressed, the running team point totals would have been thrown off,
    which, in turn, throws off the calculation of single-possession points derived
    from the running point totals. This incorrect "indexing" of plays---seems to me to
    be an "upstream" data recording error. I checked some of these problemmatic
    plays myself with [basketball-reference](https://www.basketball-reference.com/)'s [^#] [^#]
    play-by-play logs and saw that it had the plays listed in the same manner.
    

[^#]: In fact, I tried at least one other "raw" data source and found that it did
not provide as "nice" as a start point as Ryan's data.

[^#]: After all, it's just a part of raw play-by-play data.

[^#]: While I believe Ryan retrieved his data directly from the [NBA's stats API](https://stats.nba.com/),
[basketball-reference](https://www.basketball-reference.com/) retrieves its data
from this source as well, meaning that Ryan's data and [basketball-reference](https://www.basketball-reference.com/)
would have the same incorrect play indexing.

[^#]: (TODO: Provide an example here?)

Anyways, the need for some kind of "data validation"
compelled me to write some code (actually, lots of code) to verify
the integrity of the processed data. See my other post about this project
for some more specifics about how I went about doing this.


# Results Validation

To validate the reasonability of my calculations, I compared my final estimates
to those posted at the [basketball-analytics website](http://basketball-analytics.gitlab.io/rapm-data/). [#]
The results posted there are based on "traditional" RAPM.

[^#]: Shoutout to the NBA analytics online "home"---the [APBRMetrics forum](http://apbr.org/metrics/viewforum.php?f=2)--- and [this post]http://apbr.org/metrics/viewtopic.php?f=2&t=9491 specifically for pointing out this website.

Unfortunately, the results are not as "close" as I would have hoped.
Additionally, [Spearman's correlations](https://en.wikipedia.org/wiki/Spearman%27s_rank_correlation_coefficient) [#]between our results are not as high as I was hoping.

[^#]: I used the Spearman correlation instead of the [Pearson correlation](https://en.wikipedia.org/wiki/Pearson_product-moment_correlation_coefficient)
because the former should be "accurate" for comparing relative ranks (i.e. ranks relative to a given data set/source).

This could mean a number of things:

    1. My implementation and, consequently, my final values, are "wrong".
    2. Their implementation and values are "wrong".
    3. Our raw/cleaned data is different, which would inevitably lead to different results.

Assuming that the guys who put together the [basketball-analytics website] know what they
are doing and having some confidence in my own implementation,
I'm most inclined to believe last of these explanations.

I put "traditional" in
quotations earlier because there are actually several different "flavors" of RAPM---e.g.
["Multi-Year" RAPM](https://twitter.com/jerryengelmann/status/746377998102847492?lang=en),
["Four Factors" RAPM](https://thecity2.wordpress.com/2012/02/21/new-player-metric-2-5-year-adjusted-four-factor-a4pm/), ["Player Impact" RAPM](https://fansided.com/2018/01/11/nylon-calculus-introducing-player-impact-plus-minus/), etc.
One of these is 
[Real Plus-Minus](http://www.espn.com/nba/story/_/id/10740818/introducing-real-plus-minus) (RPM),
which is published by [ESPN](http://www.espn.com). [^#] More specifically, it is
created by former [Phoenix Suns](http://www.espn.com/nba/team/_/name/phx/phoenix-suns) affiliate 
[Jeremias Engelmann](https://twitter.com/JerryEngelmann).

[^#]:  Unfortunately, the linked article doesn't describe exactly how ESPN's version
differs from "traditional" RAPM.
(It simply states that "RPM is based on Engelmann's xRAPM (Regularized Adjusted Plus-Minus)".)
Nonetheless, my understanding is that it is not **too** different from traditional RAPM.

I point out ESPN's version of the metric because I also compared my values
with theirs (even though it's evident that the methodology is not identical). [^#]

[^#]: I chose to do this (1) because ESPN is reputable---although some might argue that ESPN isn't exaclty
the "World Wide Leader" when it comes to **advanced** analytics---and (2) because their values are public and are simple to scrape/retrieve. (Some other potential "sources" post their results
occassionally on Twitter or in some other medium, but don't provide a reliable/static
means of extracting their values.)

So, do my numbers match those of ESPN's RPM more closely? Ehhh, not really.

# About the Data



### Other References

+ http://www.espn.com/nba/story/_/id/10740818/introducing-real-plus-minus
+ http://www.espn.com/nba/statistics/rpm/_/year/2018
+ http://apbr.org/metrics/viewtopic.php?f=2&t=9491
    + http://web.archive.org/web/20150408042813/http://stats-for-the-nba.appspot.com:80/
    + https://sites.google.com/site/rapmstats/
    + http://basketball-analytics.gitlab.io/rapm-data/season/2016-17/regular-season/


----------------------------------------------------------------------

[^1]:
