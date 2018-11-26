---
title: Fuzzy Matching with Texas High School Academic Competition Results and SAT/ACT Scores
slug: fuzzymathc-texas-high-school-academics
date: "2018-08-04"
categories:
  - r
tags:
  - r
  - fuzzymatch
  - fuzzyjoin
  - texas
  - academics
image:
  caption: ""
  focal_point: ""
  preview_only: false
header:
  caption: ""
  image: "featured.jpg"
---

Introduction
------------

As a follow-up to [a previous
post](/post/correlations-texas-high-school-academics/) about
correlations between Texas high school academic UIL competition scores
and SAT/ACT scores, I wanted explore some of the “alternatives” to
joining the two data sets—which come from different sources. In that
post, I simply perform a an `inner_join()` using the `school` and `city`
names as keys. While this decision ensures that the data integrity is
“high”, there are potentially many un-matched schools that could have
been included in the analysis with some sound [“fuzzy
matching”](https://en.wikipedia.org/wiki/Fuzzy_matching_(computer-assisted_translation)).
For my exploration here, I’ll leverage [David
Robinson](http://varianceexplained.org/)’s excellent [{fuzzyjoin}
package](https://github.com/dgrtwo/fuzzyjoin).

My dissatisfaction with the results that I came up with various fuzzy
matching attempts ultimately led me to “settle” upon



Fuzzy Matching
--------------

In its raw form,the UIL data—scraped from <https://www.hpscience.net/>
(which was the only site that I found to have the academic competition
scores)—is much “more unclean” than the data from the SAT and ACT data
from the [TEA website](https://tea.texas.gov/). In particular, many of
the city, schoo, and individual participant names are inconsistent
across different webpages. [^1] Even after
eliminating much of the “self-inconsistency” of the UIL data and
creating a suitable “clean” data set to use as the basis for my series
of posts exploring the UIL data exclusively, there are more than a few
differences in the names of schools between the UIL and TEA data.

To aid in my experimentation with “fuzzy joining”, I use a function from
my `{tetidy}` package—`join_fuzzily()`, which is essentially a wrapper
for the `stringdist_*_join()` functions provided by the `{fuzzyjoin}`
package. With this function, I was able to evaluate different values for
`max_dist` and different join columns to help me make a judgement
regarding the quality of joins. I primarily considered counts of joined
and unjoined rows computed with the `summarise_join_stats()`
function—also from my `{tetidy}` package—to make a decision on how I
should join the UIL and SAT/ACT school data. [^2]

What follows is the results of some of my experimentation. Of course,
let’s first have a look at the data sets that we’re working with. (See
my other posts to see how I created these data sets.)

``` {.r}
schools_tea
```

<table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;">
test
</th>
<th style="text-align:right;">
year
</th>
<th style="text-align:left;">
school
</th>
<th style="text-align:left;">
district
</th>
<th style="text-align:left;">
county
</th>
<th style="text-align:left;">
city
</th>
<th style="text-align:right;">
math
</th>
<th style="text-align:right;">
reading
</th>
<th style="text-align:left;">
writing
</th>
<th style="text-align:right;">
english
</th>
<th style="text-align:right;">
science
</th>
<th style="text-align:right;">
total
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
A C JONES
</td>
<td style="text-align:left;">
BEEVILLE ISD
</td>
<td style="text-align:left;">
BEE
</td>
<td style="text-align:left;">
CORPUS CHRISTI
</td>
<td style="text-align:right;">
19
</td>
<td style="text-align:right;">
18
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
17
</td>
<td style="text-align:right;">
19
</td>
<td style="text-align:right;">
18
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
A J MOORE ACAD
</td>
<td style="text-align:left;">
WACO ISD
</td>
<td style="text-align:left;">
MCLENNAN
</td>
<td style="text-align:left;">
WACO
</td>
<td style="text-align:right;">
19
</td>
<td style="text-align:right;">
18
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
16
</td>
<td style="text-align:right;">
18
</td>
<td style="text-align:right;">
18
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
A M CONS
</td>
<td style="text-align:left;">
COLLEGE STATION ISD
</td>
<td style="text-align:left;">
BRAZOS
</td>
<td style="text-align:left;">
HUNTSVILLE
</td>
<td style="text-align:right;">
26
</td>
<td style="text-align:right;">
24
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
23
</td>
<td style="text-align:right;">
24
</td>
<td style="text-align:right;">
24
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
A MACEO SMITH HIGH SCHOOL
</td>
<td style="text-align:left;">
DALLAS ISD
</td>
<td style="text-align:left;">
DALLAS
</td>
<td style="text-align:left;">
RICHARDSON
</td>
<td style="text-align:right;">
16
</td>
<td style="text-align:right;">
14
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
13
</td>
<td style="text-align:right;">
15
</td>
<td style="text-align:right;">
14
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
ABBOTT SCHOOL
</td>
<td style="text-align:left;">
ABBOTT ISD
</td>
<td style="text-align:left;">
HILL
</td>
<td style="text-align:left;">
WACO
</td>
<td style="text-align:right;">
20
</td>
<td style="text-align:right;">
20
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
19
</td>
<td style="text-align:right;">
21
</td>
<td style="text-align:right;">
20
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
ABERNATHY
</td>
<td style="text-align:left;">
ABERNATHY ISD
</td>
<td style="text-align:left;">
HALE
</td>
<td style="text-align:left;">
LUBBOCK
</td>
<td style="text-align:right;">
22
</td>
<td style="text-align:right;">
20
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
19
</td>
<td style="text-align:right;">
21
</td>
<td style="text-align:right;">
21
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
ABILENE
</td>
<td style="text-align:left;">
ABILENE ISD
</td>
<td style="text-align:left;">
TAYLOR
</td>
<td style="text-align:left;">
ABILENE
</td>
<td style="text-align:right;">
21
</td>
<td style="text-align:right;">
21
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
20
</td>
<td style="text-align:right;">
21
</td>
<td style="text-align:right;">
21
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
ACADEMY
</td>
<td style="text-align:left;">
ACADEMY ISD
</td>
<td style="text-align:left;">
BELL
</td>
<td style="text-align:left;">
WACO
</td>
<td style="text-align:right;">
24
</td>
<td style="text-align:right;">
23
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
21
</td>
<td style="text-align:right;">
24
</td>
<td style="text-align:right;">
23
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
ACADEMY HIGH SCHOOL
</td>
<td style="text-align:left;">
HAYS CISD
</td>
<td style="text-align:left;">
HAYS
</td>
<td style="text-align:left;">
AUSTIN
</td>
<td style="text-align:right;">
NA
</td>
<td style="text-align:right;">
NA
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
NA
</td>
<td style="text-align:right;">
NA
</td>
<td style="text-align:right;">
NA
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
ACADEMY OF CAREERS AND TECHNOLOGIE
</td>
<td style="text-align:left;">
ACADEMY OF CAREERS AND TECHNOLOGIE
</td>
<td style="text-align:left;">
BEXAR
</td>
<td style="text-align:left;">
SAN ANTONIO
</td>
<td style="text-align:right;">
15
</td>
<td style="text-align:right;">
14
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
12
</td>
<td style="text-align:right;">
14
</td>
<td style="text-align:right;">
14
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
ACADEMY OF CREATIVE ED
</td>
<td style="text-align:left;">
NORTH EAST ISD
</td>
<td style="text-align:left;">
BEXAR
</td>
<td style="text-align:left;">
SAN ANTONIO
</td>
<td style="text-align:right;">
NA
</td>
<td style="text-align:right;">
NA
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
NA
</td>
<td style="text-align:right;">
NA
</td>
<td style="text-align:right;">
NA
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
ADRIAN SCHOOL
</td>
<td style="text-align:left;">
ADRIAN ISD
</td>
<td style="text-align:left;">
OLDHAM
</td>
<td style="text-align:left;">
AMARILLO
</td>
<td style="text-align:right;">
19
</td>
<td style="text-align:right;">
18
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
20
</td>
<td style="text-align:right;">
19
</td>
<td style="text-align:right;">
19
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
ADVANTAGE ACADEMY
</td>
<td style="text-align:left;">
ADVANTAGE ACADEMY
</td>
<td style="text-align:left;">
DALLAS
</td>
<td style="text-align:left;">
RICHARDSON
</td>
<td style="text-align:right;">
18
</td>
<td style="text-align:right;">
20
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
19
</td>
<td style="text-align:right;">
16
</td>
<td style="text-align:right;">
18
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
AGUA DULCE
</td>
<td style="text-align:left;">
AGUA DULCE ISD
</td>
<td style="text-align:left;">
NUECES
</td>
<td style="text-align:left;">
CORPUS CHRISTI
</td>
<td style="text-align:right;">
21
</td>
<td style="text-align:right;">
19
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
18
</td>
<td style="text-align:right;">
20
</td>
<td style="text-align:right;">
19
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
AIM CENTER
</td>
<td style="text-align:left;">
VIDOR ISD
</td>
<td style="text-align:left;">
ORANGE
</td>
<td style="text-align:left;">
BEAUMONT
</td>
<td style="text-align:right;">
NA
</td>
<td style="text-align:right;">
NA
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
NA
</td>
<td style="text-align:right;">
NA
</td>
<td style="text-align:right;">
NA
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
AKINS
</td>
<td style="text-align:left;">
AUSTIN ISD
</td>
<td style="text-align:left;">
TRAVIS
</td>
<td style="text-align:left;">
AUSTIN
</td>
<td style="text-align:right;">
19
</td>
<td style="text-align:right;">
17
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
16
</td>
<td style="text-align:right;">
17
</td>
<td style="text-align:right;">
17
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
ALAMO HEIGHTS
</td>
<td style="text-align:left;">
ALAMO HEIGHTS ISD
</td>
<td style="text-align:left;">
BEXAR
</td>
<td style="text-align:left;">
SAN ANTONIO
</td>
<td style="text-align:right;">
25
</td>
<td style="text-align:right;">
24
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
24
</td>
<td style="text-align:right;">
24
</td>
<td style="text-align:right;">
24
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
ALBA-GOLDEN
</td>
<td style="text-align:left;">
ALBA-GOLDEN ISD
</td>
<td style="text-align:left;">
WOOD
</td>
<td style="text-align:left;">
KILGORE
</td>
<td style="text-align:right;">
20
</td>
<td style="text-align:right;">
19
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
18
</td>
<td style="text-align:right;">
20
</td>
<td style="text-align:right;">
19
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
ALBANY JR-SR
</td>
<td style="text-align:left;">
ALBANY ISD
</td>
<td style="text-align:left;">
SHACKELFORD
</td>
<td style="text-align:left;">
ABILENE
</td>
<td style="text-align:right;">
24
</td>
<td style="text-align:right;">
22
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
21
</td>
<td style="text-align:right;">
22
</td>
<td style="text-align:right;">
22
</td>
</tr>
<tr>
<td style="text-align:left;">
ACT
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:left;">
ALDINE
</td>
<td style="text-align:left;">
ALDINE ISD
</td>
<td style="text-align:left;">
HARRIS
</td>
<td style="text-align:left;">
HOUSTON
</td>
<td style="text-align:right;">
19
</td>
<td style="text-align:right;">
17
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
16
</td>
<td style="text-align:right;">
18
</td>
<td style="text-align:right;">
18
</td>
</tr>
</tbody>
<tfoot>
<tr>
<td style="padding: 0; border:0;" colspan="100%">
<sup>1</sup> # of total rows: 15,073
</td>
</tr>
</tfoot>

``` {.r}
schools_uil
```
<table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;">
school
</th>
<th style="text-align:left;">
city
</th>
<th style="text-align:right;">
complvl_num
</th>
<th style="text-align:right;">
score
</th>
<th style="text-align:right;">
year
</th>
<th style="text-align:right;">
conf
</th>
<th style="text-align:left;">
complvl
</th>
<th style="text-align:left;">
comp
</th>
<th style="text-align:right;">
advanced
</th>
<th style="text-align:right;">
n_state
</th>
<th style="text-align:right;">
n_bycomp
</th>
<th style="text-align:right;">
prnk
</th>
<th style="text-align:right;">
n_defeat
</th>
<th style="text-align:left;">
w
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
HASKELL
</td>
<td style="text-align:left;">
HASKELL
</td>
<td style="text-align:right;">
13
</td>
<td style="text-align:right;">
616
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
8
</td>
<td style="text-align:right;">
1.00
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:left;">
POOLVILLE
</td>
<td style="text-align:left;">
POOLVILLE
</td>
<td style="text-align:right;">
13
</td>
<td style="text-align:right;">
609
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
8
</td>
<td style="text-align:right;">
0.86
</td>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
FALSE
</td>
</tr>
<tr>
<td style="text-align:left;">
LINDSAY
</td>
<td style="text-align:left;">
LINDSAY
</td>
<td style="text-align:right;">
17
</td>
<td style="text-align:right;">
553
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
1.00
</td>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:left;">
PLAINS
</td>
<td style="text-align:left;">
PLAINS
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
537
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
10
</td>
<td style="text-align:right;">
1.00
</td>
<td style="text-align:right;">
9
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:left;">
SAN ISIDRO
</td>
<td style="text-align:left;">
SAN ISIDRO
</td>
<td style="text-align:right;">
32
</td>
<td style="text-align:right;">
534
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:right;">
1.00
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:left;">
CANADIAN
</td>
<td style="text-align:left;">
CANADIAN
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
527
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
1.00
</td>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:left;">
GARDEN CITY
</td>
<td style="text-align:left;">
GARDEN CITY
</td>
<td style="text-align:right;">
10
</td>
<td style="text-align:right;">
518
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
8
</td>
<td style="text-align:right;">
1.00
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:left;">
WATER VALLEY
</td>
<td style="text-align:left;">
WATER VALLEY
</td>
<td style="text-align:right;">
10
</td>
<td style="text-align:right;">
478
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
8
</td>
<td style="text-align:right;">
0.86
</td>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
FALSE
</td>
</tr>
<tr>
<td style="text-align:left;">
GRUVER
</td>
<td style="text-align:left;">
GRUVER
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
464
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
0.83
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:left;">
FALSE
</td>
</tr>
<tr>
<td style="text-align:left;">
YANTIS
</td>
<td style="text-align:left;">
YANTIS
</td>
<td style="text-align:right;">
19
</td>
<td style="text-align:right;">
451
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
10
</td>
<td style="text-align:right;">
1.00
</td>
<td style="text-align:right;">
9
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:left;">
SHINER
</td>
<td style="text-align:left;">
SHINER
</td>
<td style="text-align:right;">
27
</td>
<td style="text-align:right;">
450
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
9
</td>
<td style="text-align:right;">
1.00
</td>
<td style="text-align:right;">
8
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:left;">
WEST TEXAS
</td>
<td style="text-align:left;">
STINNETT
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
443
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
0.67
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
FALSE
</td>
</tr>
<tr>
<td style="text-align:left;">
HONEY GROVE
</td>
<td style="text-align:left;">
HONEY GROVE
</td>
<td style="text-align:right;">
17
</td>
<td style="text-align:right;">
440
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
0.83
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:left;">
FALSE
</td>
</tr>
<tr>
<td style="text-align:left;">
LATEXO
</td>
<td style="text-align:left;">
LATEXO
</td>
<td style="text-align:right;">
23
</td>
<td style="text-align:right;">
439
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
10
</td>
<td style="text-align:right;">
1.00
</td>
<td style="text-align:right;">
9
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:left;">
MUENSTER
</td>
<td style="text-align:left;">
MUENSTER
</td>
<td style="text-align:right;">
17
</td>
<td style="text-align:right;">
436
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
0.67
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
FALSE
</td>
</tr>
<tr>
<td style="text-align:left;">
VAN HORN
</td>
<td style="text-align:left;">
VAN HORN
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
436
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
1.00
</td>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:left;">
SLOCUM
</td>
<td style="text-align:left;">
ELKHART
</td>
<td style="text-align:right;">
23
</td>
<td style="text-align:right;">
415
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
10
</td>
<td style="text-align:right;">
0.89
</td>
<td style="text-align:right;">
8
</td>
<td style="text-align:left;">
FALSE
</td>
</tr>
<tr>
<td style="text-align:left;">
ERA
</td>
<td style="text-align:left;">
ERA
</td>
<td style="text-align:right;">
17
</td>
<td style="text-align:right;">
415
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
0.50
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
FALSE
</td>
</tr>
<tr>
<td style="text-align:left;">
GOLDTHWAITE
</td>
<td style="text-align:left;">
GOLDTHWAITE
</td>
<td style="text-align:right;">
15
</td>
<td style="text-align:right;">
413
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
1.00
</td>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:left;">
NEWCASTLE
</td>
<td style="text-align:left;">
NEWCASTLE
</td>
<td style="text-align:right;">
12
</td>
<td style="text-align:right;">
408
</td>
<td style="text-align:right;">
2011
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
District
</td>
<td style="text-align:left;">
Calculator Applications
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
10
</td>
<td style="text-align:right;">
1.00
</td>
<td style="text-align:right;">
9
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
</tbody>
<tfoot>
<tr>
<td style="padding: 0; border:0;" colspan="100%">
<sup>1</sup> # of total rows: 27,359
</td>
</tr>
</tfoot>
</table>

For my first attempt at fuzzy matching, I tried joining using only
`school` as a key column and setting `max_dist = 1`. (Note that I do a
“full” join because my `tetidy::summarise_join_stats()` function works
best with this kind of input.)

``` {.r}
library("tidyverse")
schools_uil_distinct <-
  schools_uil %>%
  distinct(school, city)
```

``` {.r}
summ_schools_joinfuzzy_1 <-
  schools_tea %>%
  tetidy::join_fuzzily(
    schools_uil_distinct,
    mode = "full",
    max_dist = 1,
    cols_join = c("school"),
    suffix_x = "_tea",
    suffix_y = "_uil"
  ) %>%
  tetidy::summarise_join_stats(school_uil, school_tea) %>% 
  select(-x, -y) %>% 
  gather(metric, value)
summ_schools_joinfuzzy_1
```

<table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;">
metric
</th>
<th style="text-align:left;">
value
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
n_x
</td>
<td style="text-align:left;">
12,367
</td>
</tr>
<tr>
<td style="text-align:left;">
n_y
</td>
<td style="text-align:left;">
17,542
</td>
</tr>
<tr>
<td style="text-align:left;">
n_joined
</td>
<td style="text-align:left;">
12,119
</td>
</tr>
<tr>
<td style="text-align:left;">
n_x_unjoined
</td>
<td style="text-align:left;">
5,423
</td>
</tr>
<tr>
<td style="text-align:left;">
n_y_unjoined
</td>
<td style="text-align:left;">
248
</td>
</tr>
<tr>
<td style="text-align:left;">
x_in_y_pct
</td>
<td style="text-align:left;">
98
</td>
</tr>
<tr>
<td style="text-align:left;">
y_in_x_pct
</td>
<td style="text-align:left;">
69
</td>
</tr>
</tbody>
</table>

This kind of join represents a very “optimistic” or “over-zealous”
implementation that likely results in matches that are not “true”.
Nonetheless, it’s hard to really conclude anything about the quality of
the join without comparing it to the results of another attempt.

Next, I tried the same join, only setting `max_dist = 0` this time. Note
that this is really like “exact” string matching, meaning that there is
not really any fuzzy matching going on. (Nonetheless, it was worthwhile
to evaluate the counts of matches and mis-matches with a full join.)

``` {.r}
summ_schools_joinfuzzy_2 <-
  schools_tea %>%
  tetidy::join_fuzzily(
    schools_uil_distinct,
    mode = "full",
    max_dist = 0,
    cols_join = c("school"),
    suffix_x = "_tea",
    suffix_y = "_uil"
  ) %>%
  tetidy::summarise_join_stats(school_uil, school_tea) %>% 
  select(-x, -y) %>% 
  gather(metric, value)
summ_schools_joinfuzzy_2
```

<table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;">
metric
</th>
<th style="text-align:left;">
value
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
n_x
</td>
<td style="text-align:left;">
11,666
</td>
</tr>
<tr>
<td style="text-align:left;">
n_y
</td>
<td style="text-align:left;">
16,898
</td>
</tr>
<tr>
<td style="text-align:left;">
n_joined
</td>
<td style="text-align:left;">
11,399
</td>
</tr>
<tr>
<td style="text-align:left;">
n_x_unjoined
</td>
<td style="text-align:left;">
5,499
</td>
</tr>
<tr>
<td style="text-align:left;">
n_y_unjoined
</td>
<td style="text-align:left;">
267
</td>
</tr>
<tr>
<td style="text-align:left;">
x_in_y_pct
</td>
<td style="text-align:left;">
98
</td>
</tr>
<tr>
<td style="text-align:left;">
y_in_x_pct
</td>
<td style="text-align:left;">
67
</td>
</tr>
</tbody>
</table>

As we should expect, this results in a lower number of joins, but my
feeling is that the join is still too naive as a result of using only
one key column for joining—`school`.

What about changing the key columns to `school` and `city` and setting
`max_dist = 1`? (Note that I `unite()` the two columns only for my
`tetidy::summarise_join_stats()` function, which can only work with a
single “key” column. If only joining the data, the two join columns
could be kept separate.)

``` {.r}
summ_schools_joinfuzzy_3 <-
  schools_tea %>%
  unite(school_city, school, city, remove = FALSE) %>%
  tetidy::join_fuzzily(
    schools_uil_distinct %>%
      unite(school_city, school, city, remove = FALSE),
    mode = "full",
    max_dist = 1,
    cols_join = c("school_city"),
    suffix_x = "_tea",
    suffix_y = "_uil"
  ) %>%
  tetidy::summarise_join_stats(school_city_uil, school_city_tea) %>% 
  select(-x, -y) %>% 
  gather(metric, value)
summ_schools_joinfuzzy_3
```

<table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;">
metric
</th>
<th style="text-align:left;">
value
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
n_x
</td>
<td style="text-align:left;">
2,842
</td>
</tr>
<tr>
<td style="text-align:left;">
n_y
</td>
<td style="text-align:left;">
15,076
</td>
</tr>
<tr>
<td style="text-align:left;">
n_joined
</td>
<td style="text-align:left;">
1,697
</td>
</tr>
<tr>
<td style="text-align:left;">
n_x_unjoined
</td>
<td style="text-align:left;">
13,379
</td>
</tr>
<tr>
<td style="text-align:left;">
n_y_unjoined
</td>
<td style="text-align:left;">
1,145
</td>
</tr>
<tr>
<td style="text-align:left;">
x_in_y_pct
</td>
<td style="text-align:left;">
60
</td>
</tr>
<tr>
<td style="text-align:left;">
y_in_x_pct
</td>
<td style="text-align:left;">
11
</td>
</tr>
</tbody>
</table>

This is probably the best option of the many alternatives that I
tested—including many not shown here that try different columns for
joining and increasing the value of `max_dist`. In fact, the number of
rows that would be returned with an inner join and the same settings
(i.e. `max_dist = 1` and the key columns)—as indicated by the value
`n_joined`—is only slightly greater than that which you get when you
combine the two data sets with an `inner_join()` on `school` and `city`,
as I ended up doing. [^3]



Conclusion
----------

In some ways, I think this is not too unlike the classic [“bias
vs. variance”
trade-off](https://en.wikipedia.org/wiki/Bias%E2%80%93variance_tradeoff)
with machine learning. To what extent do you try to minimize error with
your training data—and potentially overfit your model? Or do you try to
make a simpler model that generalizes better to a data set outside the
training data—potentially creating a model that is “underfit” because it
is *too* simplified? In this case, the question is about to what extent
do you try to maximize the number of observations joined—perhaps
creating some false matches that compromise the data and the results?
And, from the other persepective, if you don’t include all of the data
that is only not included due to poor matching, how can you guarante
that your data “representative” are that your results are legitimate?
It’s a tricky trade-off, as with many things in the realm of data
analysis. And, as with most things, the best solution depends heavily on
the context. In this case, I think erring on the side of caution with a
“conservative” joining policy is a logical choice because there are lots
of rows that *are* matched, and one can only assume that there is no
underlying “trend” or “bias” in those schools that are mismatched.
(i.e. The un-matched schools are just as ikely to be superior/inferior
academically relative to all other schools as those that are matched.)

Something that I did not consider here but is certainly worthy of
exploration is [neural network text
classificaton](https://machinelearnings.co/text-classification-using-neural-networks-f5cd7b8765c6).
With this approach, I could quantify the probability that one string is
“equivalent” to another, and choose matches with the highest
probabilities for any given string. I have a feeling that this kind of
approach would be more successful, although it does not seem as easy to
implement. (I may come back and visit this idea in a future post.)



------------------------------------------------------------------------

[^1]: In fact, the rigor involved in cleaning the UIL data obliged be to
completely hide it from the reader in my write-ups on the
topic.

[^2]: Check out [my post on the “DRY” principle and its application to `R` 
packages](/post/dry-principle-make-a-package/). Creating packages
for actions that you perform across projects is a real
time-saver!

[^3]: Actually, I also joined on `year` in the previous post (in order to
make sure that school scores across years were “aligned”
properly.

