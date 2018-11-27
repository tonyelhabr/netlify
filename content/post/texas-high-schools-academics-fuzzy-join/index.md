---
title: Fuzzy Matching with Texas High School Academic Competition Results and SAT/ACT Scores
# slug: fuzzymath-texas-high-school-academics
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
post](/post/texas-high-schools-academics-cors/) about
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

In its raw form,the UIL data—scraped from https<nolink>://www.hpscience.net/
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

<table>
<thead>
<tr>
<th>test</th>
<th>year</th>
<th>school</th>
<th>district</th>
<th>county</th>
<th>city</th>
<th>math</th>
<th>reading</th>
<th>writing</th>
<th>english</th>
<th>science</th>
<th>total</th>
</tr>
</thead>
<tbody>
<tr>
<td>ACT</td>
<td>2011</td>
<td>A C JONES</td>
<td>BEEVILLE ISD</td>
<td>BEE</td>
<td>CORPUS CHRISTI</td>
<td>19</td>
<td>18</td>
<td>NA</td>
<td>17</td>
<td>19</td>
<td>18</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>A J MOORE ACAD</td>
<td>WACO ISD</td>
<td>MCLENNAN</td>
<td>WACO</td>
<td>19</td>
<td>18</td>
<td>NA</td>
<td>16</td>
<td>18</td>
<td>18</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>A M CONS</td>
<td>COLLEGE STATION ISD</td>
<td>BRAZOS</td>
<td>HUNTSVILLE</td>
<td>26</td>
<td>24</td>
<td>NA</td>
<td>23</td>
<td>24</td>
<td>24</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>A MACEO SMITH HIGH SCHOOL</td>
<td>DALLAS ISD</td>
<td>DALLAS</td>
<td>RICHARDSON</td>
<td>16</td>
<td>14</td>
<td>NA</td>
<td>13</td>
<td>15</td>
<td>14</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>ABBOTT SCHOOL</td>
<td>ABBOTT ISD</td>
<td>HILL</td>
<td>WACO</td>
<td>20</td>
<td>20</td>
<td>NA</td>
<td>19</td>
<td>21</td>
<td>20</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>ABERNATHY</td>
<td>ABERNATHY ISD</td>
<td>HALE</td>
<td>LUBBOCK</td>
<td>22</td>
<td>20</td>
<td>NA</td>
<td>19</td>
<td>21</td>
<td>21</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>ABILENE</td>
<td>ABILENE ISD</td>
<td>TAYLOR</td>
<td>ABILENE</td>
<td>21</td>
<td>21</td>
<td>NA</td>
<td>20</td>
<td>21</td>
<td>21</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>ACADEMY</td>
<td>ACADEMY ISD</td>
<td>BELL</td>
<td>WACO</td>
<td>24</td>
<td>23</td>
<td>NA</td>
<td>21</td>
<td>24</td>
<td>23</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>ACADEMY HIGH SCHOOL</td>
<td>HAYS CISD</td>
<td>HAYS</td>
<td>AUSTIN</td>
<td>NA</td>
<td>NA</td>
<td>NA</td>
<td>NA</td>
<td>NA</td>
<td>NA</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>ACADEMY OF CAREERS AND TECHNOLOGIE</td>
<td>ACADEMY OF CAREERS AND TECHNOLOGIE</td>
<td>BEXAR</td>
<td>SAN ANTONIO</td>
<td>15</td>
<td>14</td>
<td>NA</td>
<td>12</td>
<td>14</td>
<td>14</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>ACADEMY OF CREATIVE ED</td>
<td>NORTH EAST ISD</td>
<td>BEXAR</td>
<td>SAN ANTONIO</td>
<td>NA</td>
<td>NA</td>
<td>NA</td>
<td>NA</td>
<td>NA</td>
<td>NA</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>ADRIAN SCHOOL</td>
<td>ADRIAN ISD</td>
<td>OLDHAM</td>
<td>AMARILLO</td>
<td>19</td>
<td>18</td>
<td>NA</td>
<td>20</td>
<td>19</td>
<td>19</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>ADVANTAGE ACADEMY</td>
<td>ADVANTAGE ACADEMY</td>
<td>DALLAS</td>
<td>RICHARDSON</td>
<td>18</td>
<td>20</td>
<td>NA</td>
<td>19</td>
<td>16</td>
<td>18</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>AGUA DULCE</td>
<td>AGUA DULCE ISD</td>
<td>NUECES</td>
<td>CORPUS CHRISTI</td>
<td>21</td>
<td>19</td>
<td>NA</td>
<td>18</td>
<td>20</td>
<td>19</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>AIM CENTER</td>
<td>VIDOR ISD</td>
<td>ORANGE</td>
<td>BEAUMONT</td>
<td>NA</td>
<td>NA</td>
<td>NA</td>
<td>NA</td>
<td>NA</td>
<td>NA</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>AKINS</td>
<td>AUSTIN ISD</td>
<td>TRAVIS</td>
<td>AUSTIN</td>
<td>19</td>
<td>17</td>
<td>NA</td>
<td>16</td>
<td>17</td>
<td>17</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>ALAMO HEIGHTS</td>
<td>ALAMO HEIGHTS ISD</td>
<td>BEXAR</td>
<td>SAN ANTONIO</td>
<td>25</td>
<td>24</td>
<td>NA</td>
<td>24</td>
<td>24</td>
<td>24</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>ALBA-GOLDEN</td>
<td>ALBA-GOLDEN ISD</td>
<td>WOOD</td>
<td>KILGORE</td>
<td>20</td>
<td>19</td>
<td>NA</td>
<td>18</td>
<td>20</td>
<td>19</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>ALBANY JR-SR</td>
<td>ALBANY ISD</td>
<td>SHACKELFORD</td>
<td>ABILENE</td>
<td>24</td>
<td>22</td>
<td>NA</td>
<td>21</td>
<td>22</td>
<td>22</td>
</tr>
<tr>
<td>ACT</td>
<td>2011</td>
<td>ALDINE</td>
<td>ALDINE ISD</td>
<td>HARRIS</td>
<td>HOUSTON</td>
<td>19</td>
<td>17</td>
<td>NA</td>
<td>16</td>
<td>18</td>
<td>18</td>
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
<table>
<thead>
<tr>
<th>school</th>
<th>city</th>
<th>complvl_num</th>
<th>score</th>
<th>year</th>
<th>conf</th>
<th>complvl</th>
<th>comp</th>
<th>advanced</th>
<th>n_state</th>
<th>n_bycomp</th>
<th>prnk</th>
<th>n_defeat</th>
<th>w</th>
</tr>
</thead>
<tbody>
<tr>
<td>HASKELL</td>
<td>HASKELL</td>
<td>13</td>
<td>616</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>8</td>
<td>1.00</td>
<td>7</td>
<td>TRUE</td>
</tr>
<tr>
<td>POOLVILLE</td>
<td>POOLVILLE</td>
<td>13</td>
<td>609</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>8</td>
<td>0.86</td>
<td>6</td>
<td>FALSE</td>
</tr>
<tr>
<td>LINDSAY</td>
<td>LINDSAY</td>
<td>17</td>
<td>553</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>7</td>
<td>1.00</td>
<td>6</td>
<td>TRUE</td>
</tr>
<tr>
<td>PLAINS</td>
<td>PLAINS</td>
<td>3</td>
<td>537</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>10</td>
<td>1.00</td>
<td>9</td>
<td>TRUE</td>
</tr>
<tr>
<td>SAN ISIDRO</td>
<td>SAN ISIDRO</td>
<td>32</td>
<td>534</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>4</td>
<td>1.00</td>
<td>3</td>
<td>TRUE</td>
</tr>
<tr>
<td>CANADIAN</td>
<td>CANADIAN</td>
<td>7</td>
<td>527</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>7</td>
<td>1.00</td>
<td>6</td>
<td>TRUE</td>
</tr>
<tr>
<td>GARDEN CITY</td>
<td>GARDEN CITY</td>
<td>10</td>
<td>518</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>8</td>
<td>1.00</td>
<td>7</td>
<td>TRUE</td>
</tr>
<tr>
<td>WATER VALLEY</td>
<td>WATER VALLEY</td>
<td>10</td>
<td>478</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>0</td>
<td>0</td>
<td>8</td>
<td>0.86</td>
<td>6</td>
<td>FALSE</td>
</tr>
<tr>
<td>GRUVER</td>
<td>GRUVER</td>
<td>7</td>
<td>464</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>0</td>
<td>0</td>
<td>7</td>
<td>0.83</td>
<td>5</td>
<td>FALSE</td>
</tr>
<tr>
<td>YANTIS</td>
<td>YANTIS</td>
<td>19</td>
<td>451</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>10</td>
<td>1.00</td>
<td>9</td>
<td>TRUE</td>
</tr>
<tr>
<td>SHINER</td>
<td>SHINER</td>
<td>27</td>
<td>450</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>9</td>
<td>1.00</td>
<td>8</td>
<td>TRUE</td>
</tr>
<tr>
<td>WEST TEXAS</td>
<td>STINNETT</td>
<td>7</td>
<td>443</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>0</td>
<td>0</td>
<td>7</td>
<td>0.67</td>
<td>4</td>
<td>FALSE</td>
</tr>
<tr>
<td>HONEY GROVE</td>
<td>HONEY GROVE</td>
<td>17</td>
<td>440</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>7</td>
<td>0.83</td>
<td>5</td>
<td>FALSE</td>
</tr>
<tr>
<td>LATEXO</td>
<td>LATEXO</td>
<td>23</td>
<td>439</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>10</td>
<td>1.00</td>
<td>9</td>
<td>TRUE</td>
</tr>
<tr>
<td>MUENSTER</td>
<td>MUENSTER</td>
<td>17</td>
<td>436</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>0</td>
<td>0</td>
<td>7</td>
<td>0.67</td>
<td>4</td>
<td>FALSE</td>
</tr>
<tr>
<td>VAN HORN</td>
<td>VAN HORN</td>
<td>1</td>
<td>436</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>7</td>
<td>1.00</td>
<td>6</td>
<td>TRUE</td>
</tr>
<tr>
<td>SLOCUM</td>
<td>ELKHART</td>
<td>23</td>
<td>415</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>0</td>
<td>0</td>
<td>10</td>
<td>0.89</td>
<td>8</td>
<td>FALSE</td>
</tr>
<tr>
<td>ERA</td>
<td>ERA</td>
<td>17</td>
<td>415</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>0</td>
<td>0</td>
<td>7</td>
<td>0.50</td>
<td>3</td>
<td>FALSE</td>
</tr>
<tr>
<td>GOLDTHWAITE</td>
<td>GOLDTHWAITE</td>
<td>15</td>
<td>413</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>7</td>
<td>1.00</td>
<td>6</td>
<td>TRUE</td>
</tr>
<tr>
<td>NEWCASTLE</td>
<td>NEWCASTLE</td>
<td>12</td>
<td>408</td>
<td>2011</td>
<td>1</td>
<td>District</td>
<td>Calculator Applications</td>
<td>1</td>
<td>0</td>
<td>10</td>
<td>1.00</td>
<td>9</td>
<td>TRUE</td>
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

<table>
<thead>
<tr>
<th>metric</th>
<th>value</th>
</tr>
</thead>
<tbody>
<tr>
<td>n_x</td>
<td>12,367</td>
</tr>
<tr>
<td>n_y</td>
<td>17,542</td>
</tr>
<tr>
<td>n_joined</td>
<td>12,119</td>
</tr>
<tr>
<td>n_x_unjoined</td>
<td>5,423</td>
</tr>
<tr>
<td>n_y_unjoined</td>
<td>248</td>
</tr>
<tr>
<td>x_in_y_pct</td>
<td>98</td>
</tr>
<tr>
<td>y_in_x_pct</td>
<td>69</td>
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

<table>
<thead>
<tr>
<th>metric</th>
<th>value</th>
</tr>
</thead>
<tbody>
<tr>
<td>n_x</td>
<td>11,666</td>
</tr>
<tr>
<td>n_y</td>
<td>16,898</td>
</tr>
<tr>
<td>n_joined</td>
<td>11,399</td>
</tr>
<tr>
<td>n_x_unjoined</td>
<td>5,499</td>
</tr>
<tr>
<td>n_y_unjoined</td>
<td>267</td>
</tr>
<tr>
<td>x_in_y_pct</td>
<td>98</td>
</tr>
<tr>
<td>y_in_x_pct</td>
<td>67</td>
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

<table>
<thead>
<tr>
<th>metric</th>
<th>value</th>
</tr>
</thead>
<tbody>
<tr>
<td>n_x</td>
<td>2,842</td>
</tr>
<tr>
<td>n_y</td>
<td>15,076</td>
</tr>
<tr>
<td>n_joined</td>
<td>1,697</td>
</tr>
<tr>
<td>n_x_unjoined</td>
<td>13,379</td>
</tr>
<tr>
<td>n_y_unjoined</td>
<td>1,145</td>
</tr>
<tr>
<td>x_in_y_pct</td>
<td>60</td>
</tr>
<tr>
<td>y_in_x_pct</td>
<td>11</td>
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

[^1]: In fact, the rigor involved in cleaning the UIL data obliged be to completely hide it from the reader in my write-ups on the topic.

[^2]: Check out [my post on the “DRY” principle and its application to `R`  packages](/post/dry-principle-make-a-package/). Creating packages for actions that you perform across projects is a real time-saver!

[^3]: Actually, I also joined on `year` in the previous post (in order to make sure that school scores across years were “aligned” properly.

