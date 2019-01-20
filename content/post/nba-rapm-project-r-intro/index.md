+++
title = "Calculating NBA Regularized Adjusted Plus Minus (RAPM) with `R`, Series Introduction"
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
  caption = "Source: https://twitter.com/dr_ilardi/status/734592886331875328"

  # Focal point (optional)
  # Options: Smart, Center, TopLeft, Top, TopRight, Left, Right, BottomLeft, Bottom, BottomRight
  focal_point = ""
  preview_only = false
+++

# This Series

+ [An introduction to the project (this post)](/post/nba-rapm-project-r-intro)
+ [The "quantitative" side of the project](/post/nba-rapm-project-r-quantitative)
+ [The "qualitative" side of the project](/post/nba-rapm-project-r-qualitative)
+ More (to be linked)

In this "mini"-series, I'm going to describe a personal project from which I hope others
can extract value in one way or another. Specifically, I'll dedicate
one post to what I call the "quantitative" side of the project, which may
only be relevant to those who like the NBA and statistics, and another post
to the "qualitative" side of the project, which I hope is interesting to anyone
who has worked on their own data analysis project (using R or maybe some other programming language).
And, of course, there's this post, which is just a setup to the others.

# So, What's This All About?

This primary goal of this project was to calculate 
[Regularized Adjusted Plus-Minus](https://www.nbastuffer.com/analytics101/regularized-adjusted-plus-minus-rapm/) 
(RAPM)---an "advanced statistic"---for NBA players. [^1] [^2]

Additionally,
the project provided supplementary benefits to me as a developer and, more specifically,
as an R user. Among other things, I was challenged to tackle questions about

    + how best to work with (relatively) large data sets,
    + how to create an efficient data cleaning/processing pipeline,
    + what functionality to "expose" to the user, and
    + how and when to notify the user of warnings and errors.
    
The first two posts in this series describe these two 
aspects---(1) the "quantitative" efforts resulting in the RAPM values, 
and the (2) the "qualitative" process self-improvement as a programmer.
I'm sure I'll end up writing more about this project more, and I'll be sure
to add links to this post when that time comes.

----------------------------------------------------------------------

[^1]: The calculated values can be found in the set of `rapm_estimates`  CSVs in the project's repository.

[^2]: I've always told myself (and others) that I'm a "sports analytics" guy, but I had never done something "rigorous" like this myself. Up to this point, I have mostly been a consumer of the work and writing done by other people who write "smart" things about sports.
