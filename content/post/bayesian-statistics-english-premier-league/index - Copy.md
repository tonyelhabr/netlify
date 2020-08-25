---
title: A Bayesian Approach to Ranking English Premier League Teams (using R)
date: '2019-12-29'
draft: true
categories:
  - r
tags:
  - r
  - bayes
  - statistics
  - poisson
  - soccer
  - epl
image:
  caption: ''
  focal_point: ''
  preview_only: true
header:
  caption: ''
  image: 'featured.png'
output:
  html_document:
    keep_md: yes
always_allow_html: true
---





As [I mentioned back in July](/post/cheat-sheet-rmarkdown), I haven't had as much time (since summer of 2018) to write due to taking classes in pursuit of a degree from  [Georgia Tech's Online Master of Science in Analytics (OMSA)](https://pe.gatech.edu/degrees/analytics) program. On the other hand, the classes have given me some ideas for future content. And, in the case of the [Bayesian Statistics](https://en.wikipedia.org/wiki/Bayesian_statistics) class that I took this past fall, there's content that translates well to a blog post directly. What follows is a lightly edited version of the report that I submitted at the end of the semester for this class.







# Introduction

I model and predict [English Premier League](https://en.wikipedia.org/wiki/Premier_League) (EPL) game outcomes using Bayesian methods. Specifically, I estimated goals scored by each team in a given game as independent Poisson processes, taking the difference of the estimated points scored on each side to determine game winners. More broadly, one may call this a hierarchical Bayesian Poisson model.


Why model goals scored using a Poisson distribution? [By definition](https://en.wikipedia.org/wiki/Poisson_distribution), it "is a discrete probability distribution that expresses the probability of a given number of events occurring in a fixed interval of time with a known constant rate." In the context of soccer, the fixed interval of time is the 90 minutes of a game (disregarding injury time and over time), and the known constant rate is the expected number of goals scored per minute. Importantly, I must make the assumption that the rate of scored goals is the same across all minutes of a game. [^1] Additionally, when computing the difference between Poisson distributions, I must assume that the two distributions are independent of one another. [^2]

[^1]: This is arguably a "bad" assumption. [Research](http://article.sapub.org/10.5923.s.sports.201401.08.html) has shown that goal rate per minute increases in the last 15 minutes of a game.

[^2]: This may also be perceived to be a questionable assumption. One may argue that a matchup of "styles"---e.g. an aggressive team against another aggressive team---may distort the results from what would otherwise be expected.

Using Poisson distributions to model soccer scores is certainly not a novel concept. [^3] [^4] In particular, I would like to acknowledge [the work of Rasmus Bååth's](http://www.sumsar.net/blog/2013/07/modeling-match-results-in-la-liga-part-one/), whose series of blog posts exemplifying the use of R and [JAGS](http://mcmc-jags.sourceforge.net/) to model scores in [*La Liga*](https://en.wikipedia.org/wiki/La_Liga) games between the 2008-09 to 2012-13 season served as a guide for the analysis that I conduct here. [^5] [^6]

[^3]: This approach is arguably too "simplistic", but it is certainly a valid approach.

[^4]: See this [Pinnacle blog post](https://www.pinnacle.com/en/betting-articles/Soccer/how-to-calculate-poisson-distribution/MD62MLXUMKMXZ6A8) for a discussion of the topic. (Undoubtedly there are many more articles and papers that explore a similar notion.)

[^5]: There are several notable differences with my work compared to that of Bååth: (1) I use the [OpenBUGS](http://www.openbugs.net/w/FrontPage) software (and the [`{R2OpenBUGS}` package](https://cran.r-project.org/web/packages/R2OpenBUGS/index.html)) instead of JAGS; (2) I evaluate EPL teams instead of La Liga teams, and over a different time period; (3) I use a "tidy" approach (in terms of packages, plotting, coding style, etc.) instead of a more traditional "base R" approach; (4) I implement a modified version of the second of Bååth's three proposed models (notably, using different priors).

[^6]: Bååth's work is licensed under the [Creative Commons license](https://creativecommons.org/licenses/by/3.0/), which allows for others to adapt the work of another.

## Data Collection

For this project I retrieved game scores and outcomes for the previous three seasons of EPL games (i.e. from the 2016-17 season through the 2018-2019 season).






```r
# Reference: https://github.com/jalapic/engsoccerdata/blob/master/R/england_current.R
scrape_epl_data <- function(season = lubridate::year(Sys.Date()) - 1L) {
  s1 <- season %>% str_sub(3, 4) %>% as.integer()
  s2 <- s1 + 1L
  path <- sprintf('http://www.football-data.co.uk/mmz4281/%2d%2d/E0.csv', s1, s2)
  data_raw <- path %>% read_csv()
  data <-
    data_raw %>% 
    janitor::clean_names() %>% 
    mutate_at(vars(date), ~as.Date(., '%d/%m/%y')) %>% 
    select(
      date, 
      tm_h = home_team, 
      tm_a = away_team,
      g_h = fthg,
      g_a = ftag
    ) %>% 
    mutate(
      g_total = g_h + g_a,
      g_diff = g_h - g_a,
      result = 
        case_when(
          g_h > g_a ~ 'h', 
          g_h < g_a ~ 'a', 
          TRUE ~ 't'
        ),
      tm_winner = 
        case_when(
          g_h > g_a ~ tm_h, 
          g_h < g_a ~ tm_a, 
          TRUE ~ NA_character_
        )
    ) %>% 
    mutate_at(vars(matches('season|^g_')), as.integer)
}

data <-
  tibble(season = seasons) %>% 
  mutate(data = map(season, scrape_epl_data)) %>% 
  unnest(data)
data
```






```
#> # A tibble: 1,140 x 10
#>    season date                tm_h  tm_a    g_h   g_a g_total g_diff result
#>     <dbl> <dttm>              <chr> <chr> <dbl> <dbl>   <dbl>  <dbl> <chr> 
#>  1   2016 2016-08-13 00:00:00 Burn~ Swan~     0     1       1     -1 a     
#>  2   2016 2016-08-13 00:00:00 Crys~ West~     0     1       1     -1 a     
#>  3   2016 2016-08-13 00:00:00 Ever~ Tott~     1     1       2      0 t     
#>  4   2016 2016-08-13 00:00:00 Hull  Leic~     2     1       3      1 h     
#>  5   2016 2016-08-13 00:00:00 Man ~ Sund~     2     1       3      1 h     
#>  6   2016 2016-08-13 00:00:00 Midd~ Stoke     1     1       2      0 t     
#>  7   2016 2016-08-13 00:00:00 Sout~ Watf~     1     1       2      0 t     
#>  8   2016 2016-08-14 00:00:00 Arse~ Live~     3     4       7     -1 a     
#>  9   2016 2016-08-14 00:00:00 Bour~ Man ~     1     3       4     -2 a     
#> 10   2016 2016-08-15 00:00:00 Chel~ West~     2     1       3      1 h     
#> # ... with 1,130 more rows, and 1 more variable: tm_winner <chr>
```



<!-- Before implementing some models, I need to "wrangle" the raw data a bit in order to put it in a more workable format for OpenBUGs. (Specifically, I need to put it into a list.) -->



# Modeling

My model is formally defined as follows.

$$
\begin{array}{c}
g_h \sim \mathcal{Pois}(\lambda_{h,i,j}) \\
g_a \sim \mathcal{Pois}(\lambda_{a,i,j}) \\
\log(\lambda_{h,i,j}) = \text{baseline}_h + (z_i - z_j) \\
\log(\lambda_{a,i,j}) = \text{baseline}_a + (z_j - z_i). \\
\end{array}
$$

This model estimates the goals scored by the home team, $g_h$, and the goals scored by the away team, $g_a$, in a given game between home team, $\text{tm}_h$, and away team, $\text{tm}_a$, as random variables coming from independent Poisson processes, $\mathcal{Pois}(\lambda_{h,i,j})$ and $\mathcal{Pois}(\lambda_{a,i,j})$. The log of the rate of goals scored by the home team, $\lambda_{h,i,j}$, in a game between $\text{tm}_i$ and $\text{tm}_j$ is modeled as the sum of a "baseline" average of goals scored by any given team playing at home, $\text{baseline}_h$, and the difference between the team "strength" $z$ of teams $i$ and $j$ in a given game. I define the log of the goal rate by the away team, $\lambda_{a,i,j}$, in a similar fashion. [^8] It is important to distinguish the baseline levels for home and away so as to account for ["home field advantage"](https://en.wikipedia.org/wiki/Home_advantage). (One should expect to find that $\text{baseline}_h > \text{baseline}_a$ in the posterior estimates.)

[^8]: Note that I substitute the baseline home average goal rate with a baseline for away teams, $\text{baseline}_a$, and I swap the order of the $z_j$ and $z_i$ teams since the relationship is not bi-directional. Also, note that I am careful to distinguish between subscript pair $_h$ and $_a$ for home and away and pair $_i$ and $_j$ for team $i$ and team $j$. The latter pair is independent of the notion of home or away.

Since I am employing a Bayesian approach, I need to model priors as well. I define them as follows.

$$
\begin{array}{c}
\text{baseline}_h \sim \mathcal{N}(0, 2^2) \\
\text{baseline}_a \sim \mathcal{N}(0, 2^2) \\
z_{i} \sim \mathcal{N}(z_{\text{all}} , \sigma^2_{\text{all}}) \quad \text{tm}_i > 1 \\
z_{\text{all}} \sim \mathcal{N}(0, 2^2) \\
\sigma_{\text{all}} \sim \mathcal{U}(0, 2).
\end{array}
$$

There are a couple of things to note about these priors. First, I must "zero"-anchor the strength estimate $z$ of one team. (This is manifested by $\text{tm}_i > 1$.) Here, I choose the first team alphabetically---Arsenal. Second, the priors are intentionally defined to be relatively vague (although not too vauge) so as to allow the posterior estimates to be heavily defined by the data rather than the priors. Note that the standard deviation of the overall team strength parameter $z_{\text{all}}$, defined as $2$ on a log scale, corresponds to an interval of $\left[e^{-2}, e^2\right] = \left[0.13, 7.40\right]$ on an unstransformed scale, i.e. goals scored per game.


I leverage the [`{R2OpenBUGs}` package](https://cran.r-project.org/web/packages/R2OpenBUGS/index.html) to create this model with R on the "frontend" and generate the results using the OpenBUGS engine on the "backend". Regarding the implementation itself, note that I run 100,000 simulations (`n.iter`), minus 1,000 "burn-in" runs (`n.burn`).













The raw results are as follows. (As a quick "validation" of these results, note that $\text{baseline}_h > \text{baseline}_a$, as hypothesized.)









# Interpretation & Discussion

Next, I correspond the strength estimates $z$ to teams. Notably, I must "re-add" the zero-anchored team---Arsenal (whose $z$ is assigned a dummy value of 1). To do this, I impute its credible set quantiles using the values of the overall strength term $z_{\text{all}}$.











<img src="/post/index_files/figure-html/viz_summ_1_z-show-1.png" title="plot of chunk viz_summ_1_z-show" alt="plot of chunk viz_summ_1_z-show" style="display: block; margin: auto;" />

It's not surprising to see that the strength ($z$) corresponding to all but three teams---Liverpool, Man City, and Tottenham---is negative. These three teams, followed closely by Arsenal have been regarded as the best teams for the past two or three EPL seasons. So, relative to Arsenal, all other teams (aside from the top three) are viewed as "worse" by the model.

Note that the $z$ estimates above should not be interpreted as goals scored by the teams because they are relative to the strength of Arsenal. To facilitate such an interpretation, I need to translate $z$ to goals scored per game. To do this, for each $z$, I (1) subtract the average value of all $z$'s, (2) add the posterior mean of $\text{baseline}_{h}$, and (3) exponentiate.

The plot below shows the results of this transformation.









<img src="/post/index_files/figure-html/viz_summ_1_z_adj-show-1.png" title="plot of chunk viz_summ_1_z_adj-show" alt="plot of chunk viz_summ_1_z_adj-show" style="display: block; margin: auto;" />


## Predictions

I can make predictions of game results for the historical data, given the model. <hide>(Since the model estimates were calculated using this data, I'm really predicting on the "training" set here.)</hide> Specifically, I simulate the score for both teams in each matchup (1,140 in all) 1,000 times, choosing the result inferred by the mode of each side's simulated score. (For example, if the mode of the 1,000 simulated scores for the away team  is 1 and that of the home team is 2, then the predicted outcome is a win for the home team.) A breakdown of the predicted and actual outcomes is shown below.

















<img src="/post/index_files/figure-html/viz_conf_mat-show-1.png" title="plot of chunk viz_conf_mat-show" alt="plot of chunk viz_conf_mat-show" style="display: block; margin: auto;" />

I make a couple of observations:

+ The most common outcome  is an actual win by the home team and a predicted win by the home team.
+ The model never predicts a tie. (This may seem "unreasonable", but Bååth also found this to be true for his final model.) 
+ The model predicts the outcome correctly in 447 + 216 = 663 of 1,140 games (i.e., 58%).


The next couple of visuals provide more details regarding the simulated outcomes.







<img src="/post/index_files/figure-html/viz_g_mode-show-1.png" title="plot of chunk viz_g_mode-show" alt="plot of chunk viz_g_mode-show" style="display: block; margin: auto;" />

From the above graph of the mode of goals scored by both sides, it's apparent that a 2-1 scores in favor of the home side is the most common outcome.







<img src="/post/index_files/figure-html/viz_g_mean-show-1.png" title="plot of chunk viz_g_mean-show" alt="plot of chunk viz_g_mean-show" style="display: block; margin: auto;" />

The above histogram illustrating the mean (instead of the mode) of the simulated goals provides a bit more nuance to our understanding of modes shown before.







<img src="/post/index_files/figure-html/viz_result_mode-show-1.png" title="plot of chunk viz_result_mode-show" alt="plot of chunk viz_result_mode-show" style="display: block; margin: auto;" />

Finally, the above visual shows the predicted outcomes (inferred from the prior graph of predicted modes).

To better understand how the model works on a team-level basis, let's look at how well it predicts for each team.





<table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> Team </th>
   <th style="text-align:right;"> # of Wins </th>
   <th style="text-align:left;"> Win % </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Arsenal </td>
   <td style="text-align:right;"> 46 </td>
   <td style="text-align:left;"> 80.70% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Man City </td>
   <td style="text-align:right;"> 45 </td>
   <td style="text-align:left;"> 78.95% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Tottenham </td>
   <td style="text-align:right;"> 43 </td>
   <td style="text-align:left;"> 75.44% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Liverpool </td>
   <td style="text-align:right;"> 41 </td>
   <td style="text-align:left;"> 71.93% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Chelsea </td>
   <td style="text-align:right;"> 39 </td>
   <td style="text-align:left;"> 68.42% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Cardiff </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:left;"> 63.16% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Everton </td>
   <td style="text-align:right;"> 36 </td>
   <td style="text-align:left;"> 63.16% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Fulham </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:left;"> 63.16% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Man United </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:left;"> 61.40% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Huddersfield </td>
   <td style="text-align:right;"> 23 </td>
   <td style="text-align:left;"> 60.53% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Burnley </td>
   <td style="text-align:right;"> 34 </td>
   <td style="text-align:left;"> 59.65% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Stoke </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:left;"> 57.89% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Bournemouth </td>
   <td style="text-align:right;"> 30 </td>
   <td style="text-align:left;"> 52.63% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Crystal Palace </td>
   <td style="text-align:right;"> 30 </td>
   <td style="text-align:left;"> 52.63% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sunderland </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> 52.63% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Swansea </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:left;"> 52.63% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> West Ham </td>
   <td style="text-align:right;"> 30 </td>
   <td style="text-align:left;"> 52.63% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Watford </td>
   <td style="text-align:right;"> 29 </td>
   <td style="text-align:left;"> 50.88% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Newcastle </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:left;"> 50.00% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Leicester </td>
   <td style="text-align:right;"> 28 </td>
   <td style="text-align:left;"> 49.12% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Middlesbrough </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:left;"> 47.37% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> West Brom </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> 47.37% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Wolves </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:left;"> 47.37% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Brighton </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:left;"> 39.47% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Southampton </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:left;"> 38.60% </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Hull </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 31.58% </td>
  </tr>
</tbody>
</table>



In most cases, the model predicts the outcome correctly (see `is_correct`) with greater than 50% accuracy, although there are also teams for which its accuracy is less than 50%.

# Conclusion

In summary, I have created a hierarchical Poisson model to predict scores---and, consequently, game outcomes---for EPL games for the three seasons starting in 2016 and ending in 2018. The model has an training set prediction accuracy of 663. [Bååth](http://www.sumsar.net/blog/2013/07/modeling-match-results-in-la-liga-part-one/), whose work inspired mine, achieved an accuracy of 56% with his final model.

## Future Work

My model can certainly be improved. One major flaw of the model is that it does not account for temporal effects, i.e. differences in team strength across seasons. [^9] The consequences of this flaw are compounded by the fact that the pool of teams in each EPL season changes. At the end of each season, the three "worst" EPL teams (by win-loss-tie record) are "relegated" to a secondary league, and, in turn, three secondary league teams are "promoted" to the EPL in their place. [^10] Consequently, one might say that the estimates of the teams that do not appear in all seasons are exaggerated.

[^9]: There are certainly also changes in team strength within seasons, which are even more difficult to model.

[^10]: This explains why there are more than 20 teams in thee data set even though there are only 20 teams in the EPL in a given season.

# Appendix

## Code

See all relevant R code below.


```r
library(tidyverse)
# Data Collection
seasons <- 2016L:2018L
# Reference: https://github.com/jalapic/engsoccerdata/blob/master/R/england_current.R
scrape_epl_data <- function(season = lubridate::year(Sys.Date()) - 1L) {
  s1 <- season %>% str_sub(3, 4) %>% as.integer()
  s2 <- s1 + 1L
  path <- sprintf('http://www.football-data.co.uk/mmz4281/%2d%2d/E0.csv', s1, s2)
  data_raw <- path %>% read_csv()
  data <-
    data_raw %>% 
    janitor::clean_names() %>% 
    mutate_at(vars(date), ~as.Date(., '%d/%m/%y')) %>% 
    select(
      date, 
      tm_h = home_team, 
      tm_a = away_team,
      g_h = fthg,
      g_a = ftag
    ) %>% 
    mutate(
      g_total = g_h + g_a,
      g_diff = g_h - g_a,
      result = 
        case_when(
          g_h > g_a ~ 'h', 
          g_h < g_a ~ 'a', 
          TRUE ~ 't'
        ),
      tm_winner = 
        case_when(
          g_h > g_a ~ tm_h, 
          g_h < g_a ~ tm_a, 
          TRUE ~ NA_character_
        )
    ) %>% 
    mutate_at(vars(matches('season|^g_')), as.integer)
}

data <-
  tibble(season = seasons) %>% 
  mutate(data = map(season, scrape_epl_data)) %>% 
  unnest(data)
data
pull2 <- function(data, ...) {
  data %>%
    pull(...) %>% 
    as.factor() %>% 
    as.integer()
}

tms <- data %>% distinct(tm_h) %>% arrange(tm_h) %>% pull(tm_h)
n_tm <- tms %>% length()
n_gm <- data %>% nrow()
n_season <- seasons %>% length()

data_list <-
  list(
    g_h = data %>% pull(g_h),
    g_a = data %>% pull(g_a),
    tm_h = data %>% pull2(tm_h),
    tm_a = data %>% pull2(tm_a),
    season = data %>% pull2(season),
    n_tm = n_tm,
    n_gm = n_gm,
    n_season = n_season
  )
str(data_list)
model_1 <- glue::glue_collapse('model {
  for(g in 1:n_gm) {
    g_h[g] ~ dpois(lambda_h[tm_h[g], tm_a[g]])
    g_a[g] ~ dpois(lambda_a[tm_h[g], tm_a[g]])
  }

  for(h in 1:n_tm) {
    for(a in 1:n_tm) {
      lambda_h[h, a] <- exp(baseline_h + (z[h] - z[a]))
      lambda_a[h, a] <- exp(baseline_a + (z[a] - z[h]))
    }
  }
    
  z[1] <- 0 
  for(t in 2:n_tm) {
    z[t] ~ dnorm(z_all, tau_all)
  }
    
  z_all ~ dnorm(0, 0.25)
  tau_all <- 1 / pow(sigma_all, 2)
  sigma_all ~ dunif(0, 2)
  baseline_h ~ dnorm(0, 0.25)
  baseline_a ~ dnorm(0, 0.25)
}')

path_model_1 <- 'model_1.txt'
write_lines(model_1, path_model_1)
if(eval_model_1) {
  # inits_1 <- list(n_tm = data_list$n_tm)
  inits_1 <- NULL
  params_1 <-
    c(
      paste0('baseline', c('_a', '_h')),
      paste0('sigma_all'),
      paste0('z', c('', '_all'))
    )
  
  res_sim_1 <-
    R2OpenBUGS::bugs(
      # debug = TRUE,
      data = data_list,
      inits = inits_1,
      model.file = path_model_1,
      parameters.to.save = params_1,
      DIC = FALSE,
      n.chains = 1,
      n.iter = 10000,
      n.burnin = 1000
    )
}
# Model 1 Interpretation
z_var_lvls <- sprintf('z[%d]', 2:n_tm)
var_lvls <- c(paste0('baseline', c('_a', '_h')), 'sigma_all', z_var_lvls, 'z_all')
res_sim_summ_1 <-
  res_sim_1$summary %>% 
  as_tibble(rownames = 'var') %>% 
  # Re-order these.
  mutate_at(vars(var), ~factor(., levels = var_lvls)) %>% 
  arrange(var) %>% 
  # Then re-coerce var back to its original data type.
  mutate_at(vars(var), as.character)
res_sim_summ_1

tms_info <-
  tibble(tm = tms) %>% 
  mutate(tm_idx = row_number())
tms_info

res_sim_summ_1_z <-
  bind_rows(
    res_sim_summ_1 %>% 
      filter(var == 'z_all') %>% 
      mutate(var = 'z[1]') %>% 
      mutate(tm_idx = 1L) %>% 
      mutate_at(vars(matches('%$')), ~{. - mean}) %>% 
      mutate(mean = 0),
    res_sim_summ_1 %>% 
      filter(var %>% str_detect('^z\\[')) %>% 
      mutate(
        tm_idx = 
          var %>% 
          str_replace_all('(^z\\[)([0-9]+)(\\]$)', '\\2') %>% 
          as.integer()
      )
  ) %>% 
  left_join(tms_info, by = 'tm_idx') %>% 
  select(-tm_idx) %>% 
  select(tm, everything()) %>% 
  arrange(tm)
res_sim_summ_1_z
theme_custom <- function(...) {
  theme_light(base_size = 12) +
    theme(
      legend.position = 'bottom',
      legend.title = element_blank(),
      axis.title.x = element_text(hjust = 1),
      axis.title.y = element_text(hjust = 1),
      ...
    )
}

.lab_subtitle <- 'Seasons 2016-17 - 2018-19'
.visualize_res_sim_summ <- function(data, ...) {
  data %>% 
    arrange(-mean) %>% 
    mutate_at(vars(tm), ~forcats::fct_reorder(., mean)) %>% 
    ggplot() +
    aes(x = tm) +
    geom_pointrange(aes(y = mean, ymin = `2.5%`, ymax = `97.5%`)) +
    theme_custom() +
    coord_flip() +
    labs(
      subtitle = .lab_subtitle ,
      caption = glue::glue(
        'Posterior mean and 95% equitailed credible set depicted.
        {tms[1]} used as "zero"-anchor team.'
      ),
      y = NULL
    )
}

visualize_res_sim_summ_z <- function(data, ...) {
  data %>%
    .visualize_res_sim_summ() +
    geom_hline(aes(yintercept = 0)) +
    labs(
      title = glue::glue('Model\'s estimated strength (z)'),
      x = 'Posterior mean of z'
    )
}

visualize_res_sim_summ_z_adj <- function(data, ...) {
  data %>%
    .visualize_res_sim_summ() +
    labs(
      title = glue::glue('Model\'s estimated goals scored per game'),
      x = 'Posterior mean of z transformed to goals'
    )
}

export_png <-
  function(x,
           path,
           ...,
           units = 'in',
           width = 7,
           height = 5) {
    ggsave(
      plot = x,
      filename = path,
      units = units,
      width = width,
      height = height,
      ...
    )
  }
n_sim <- 1000
path_preds <- file_path_out('preds_1.rds')
eval_preds <- !fs::file_exists(path_preds)
if(eval_preds) {
  .baseline_h <- res_sim_summ_1 %>% filter(var == 'baseline_h') %>% pull(mean)
  .baseline_a <- res_sim_summ_1 %>% filter(var == 'baseline_a') %>% pull(mean)
  .extract_tab_max <- function(tab) {
    tab[ which.max(tab)] %>% names() %>% as.integer()
  }
  do_predict <- function(i) {
    data_filt <- data %>% slice(i)
    .tm_h <- data_filt %>% pull(tm_h)
    .tm_a <- data_filt %>% pull(tm_a)
    z_h <- res_sim_summ_1_z %>% filter(tm == .tm_h) %>% pull(mean)
    z_a <- res_sim_summ_1_z %>% filter(tm == .tm_a) %>% pull(mean)
    g_h <- rpois(n_sim, exp(.baseline_h + (z_h - z_a)))
    g_a <- rpois(n_sim, exp(.baseline_a + (z_a - z_h)))
    tab_h <- table(g_h)
    tab_a <- table(g_a)
    result_sign <- sign(g_h - g_a)
    tab_result <- table(result_sign)
    result_mode <- .extract_tab_max(tab_result)
    tibble(
      g_h_mode = .extract_tab_max(tab_h),
      g_a_mode = .extract_tab_max(tab_a),
      result_mode = result_mode,
      g_h_mean = mean(g_h),
      g_a_mean = mean(g_a)
    )
  }
  
  set.seed(42)
  preds <- 
    tibble(idx = 1:n_gm) %>% 
    mutate(res = map(idx, do_predict)) %>% 
    unnest(res)
  preds
}
preds_tidy <- 
  preds %>% 
  gather(key = 'key', value = 'value', -idx) %>% 
  select(idx, key, value)
preds_tidy

.key_lab_g_stem <- 'Team Goals'
.key_lab_g_h_prefix <- sprintf('Home %s, %%s', .key_lab_g_stem)
.key_lab_g_a_prefix <- sprintf('Away %s, %%s', .key_lab_g_stem)
keys_info <-
  tribble(
    ~key, ~key_lab,
    'g_h_mode', sprintf(.key_lab_g_h_prefix, 'Mode'),
    'g_a_mode', sprintf(.key_lab_g_a_prefix, 'Mode'),
    'g_h_mean', sprintf(.key_lab_g_h_prefix, 'Mean'),
    'g_a_mean', sprintf(.key_lab_g_a_prefix, 'Mean'),
    'result_mode', 'Result, Mode'
  ) %>% 
  mutate(idx = row_number()) %>% 
  mutate_at(vars(key_lab), ~forcats::fct_reorder(., idx)) %>% 
  select(-idx)
keys_info

preds_tidy_aug <-
  preds_tidy %>% 
  inner_join(keys_info)
preds_tidy_aug

preds_aug <-
  preds %>% 
  inner_join(data %>% mutate(idx = row_number())) %>% 
  mutate_at(
    vars(result_mode),
    ~case_when(
      . == 1 ~ 'h', 
      . == -1 ~ 'a', 
      . == 0 ~ 't'
    )
  )
conf_mat_tidy <-
  preds_aug %>% 
  count(result_mode, result)

conf_mat_correct <-
  conf_mat_tidy %>% 
  group_by(is_correct = result_mode == result) 

conf_mat_correct_summ <-
  conf_mat_correct %>% 
  summarise_at(vars(n), ~sum(.)) %>% 
  ungroup() %>% 
  mutate(frac = n / sum(n))
conf_mat_correct

conf_mat_correct_h <- conf_mat_correct %>% filter(is_correct, result == 'h')
# conf_mat_correct_t <- conf_mat_correct %>% filter(is_correct, result == 't')
conf_mat_correct_a <- conf_mat_correct %>% filter(is_correct, result == 'a')
conf_mat_correct_summ_yes <- conf_mat_correct_summ %>% filter(is_correct)

viz_conf_mat <-
  conf_mat_tidy %>%
  mutate(frac = n / sum(n)) %>% 
  mutate(n_lab = sprintf('%s (%s)', scales::comma(n), scales::percent(frac))) %>% 
  mutate_at(
    vars(matches('result')), 
    ~forcats::fct_relevel(., c('h', 'a')) # c('h', 't', 'a'))
  ) %>% 
  mutate_at(
    vars(matches('result')), 
    ~forcats::fct_recode(., Home = 'h', Away = 'a') # , Tie = 't')
  ) %>% 
  ggplot() +
  aes(x = result_mode, y = result) +
  geom_tile(aes(fill = n)) +
  geom_text(aes(label = n_lab), size = 5, fontface = 'bold', color = 'black') +
  # scale_fill_manual(limits = c(0, 0.5)) +
  scale_fill_viridis_c(alpha = 0.5, begin = 0, end = 1, option = 'E') +
  theme_custom() +
  theme(
    legend.position = 'none',
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  ) +
  labs(
    title = 'Comparison of Predicted and Actual Game Outcomes',
    subtitle = .lab_subtitle,
    x = 'Predicted Result',
    y = 'Actual Result'
  )
viz_conf_mat
viz_g_mode <-
  preds_tidy_aug %>% 
  filter(key %>% str_detect('^g.*mode$')) %>% 
  ggplot() +
  aes(x = value, fill = key_lab) +
  scale_fill_brewer(palette = 'Set1') +
  geom_bar(position = 'dodge', alpha = 0.8) +
  theme_custom() +
  theme(
    panel.grid.major.x = element_blank()
  ) +
  labs(
    title = 'Simulated Mode of Goals Scored By Home and Away Teams',
    subtitle = .lab_subtitle,
    caption = .lab_caption_n_gm,
    x = 'Goals Scored',
    y = 'Count of Games'
  )
viz_g_mode
viz_g_mean <-
  preds_tidy_aug %>% 
  # This is done so that the `aes()` can be defined before data is actually passed into the whole ggplot pipeline.
  filter(row_number() == 0) %>% 
  ggplot() +
  aes(x = value, fill = key_lab) +
  scale_fill_brewer(palette = 'Set1') +
  geom_histogram(data = filter(preds_tidy_aug, key == 'g_h_mean'), alpha = 1, binwidth = 0.2) +
  geom_histogram(data = filter(preds_tidy_aug, key == 'g_a_mean'), alpha = 0.5, binwidth = 0.2) +
  theme(
    panel.grid.major.x = element_blank()
  ) +
  theme_custom() +
  labs(
    title = 'Simulated Mean of Goals Scored By Home and Away Teams',
    subtitle = .lab_subtitle ,
    caption = .lab_caption_n_gm,
    x = 'Goals Scored',
    y = 'Count of Games'
  )
viz_g_mean
preds_tidy_res <-
  preds_tidy %>% 
  filter(key == 'res_mode') %>% 
  mutate_at(
    vars(value),
    list(value_lab = ~case_when(
      . == 1 ~ 'Home Team Wins',
      . == 0 ~ 'Draw',
      . == -1 ~ 'Away Team Wins'
    ))
  ) %>% 
  mutate_at(vars(value_lab), ~forcats::fct_reorder(., value))
preds_tidy_res %>% count(value_lab)

viz_result_mode <-
  preds_tidy %>% 
  filter(key == 'result_mode') %>% 
  mutate_at(
    vars(value),
    list(value_lab = ~case_when(
      . == 1 ~ 'Home Team Wins',
      . == 0 ~ 'Draw',
      . == -1 ~ 'Away Team Wins'
    ))
  ) %>% 
  mutate_at(vars(value_lab), ~forcats::fct_reorder(., value)) %>% 
  ggplot() +
  aes(x = value_lab) +
  geom_bar(position = 'dodge') +
  theme_custom() +
  theme(
    panel.grid.major.x = element_blank()
  ) +
  labs(
    title = 'Simulated Result of Games',
    subtitle = .lab_subtitle ,
    caption = .lab_caption_n_gm,
    x = NULL,
    y = 'Count of Games'
  )
viz_result_mode
preds_by_tm <-
  preds_aug %>% 
  group_by(tm_h) %>% 
  count(is_correct = result_mode == result) %>%
  mutate(frac = n / sum(n)) %>% 
  ungroup() %>% 
  filter(is_correct) %>% 
  arrange(-frac) %>% 
  mutate(pct = scales::percent(frac)) %>% 
  select(-frac)
```

