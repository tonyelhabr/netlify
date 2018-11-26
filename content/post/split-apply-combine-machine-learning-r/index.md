---
title: The Split-Apply-Combine Technique for Machine Learning with R
# slug: split-apply-combine-machine-learning-r
date: "2018-08-05"
categories:
  - r
tags:
  - r
  - tidyverse
  - caret
  - machine learning
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

Much discussion in the R community has revolved around the proper way to
implement the
[“split-apply-combine”](https://www.google.com/search?q=split+apply+combine&rlz=1C1GGRV_enUS751US752&oq=split+apply+combine&aqs=chrome..69i57j69i60l2.2919j0j4&sourceid=chrome&ie=UTF-8).
In particular, I love the exploration of this topic [in this blog
post](https://coolbutuseless.bitbucket.io/2018/03/03/split-apply-combine-my-search-for-a-replacement-for-group_by---do/).
It seems that the “preferred” approach is `dplyr::group_by()` +
`tidyr::nest()` for splitting, `dplyr::mutate()` + `purrr::map()` for
applying, and `tidyr::unnest()` for combining.

Additionally, many in the community have shown implementations of the
[“many models”](http://r4ds.had.co.nz/many-models.html) approach in
`{tidyverse}`-style pipelines, often also using the `{broom}` package.
For example, see any one of Dr. Simon J’s many blog posts on machine
learning, such as [this one on k-fold cross
validation](https://drsimonj.svbtle.com/k-fold-cross-validation-with-modelr-and-broom).

However, I haven’t seen as much exploration of how to apply the
split-apply-combine technique to machine learning with the `{caret}`
package, which is perhaps the most popular “generic” `R` machine
learning package (along with `{mlr}`). One interesting write-up that I
found on this subject is [this one by Rahul
S.](https://rsangole.netlify.com/post/pur-r-ify-your-carets/). Thus, I
was inspired to experiment with my own `{tidyverse}`-like pipelines
using `{caret}`. (I actually used these techniques in my homework
solutions to the [edX](https://www.edx.org/) Georgia Tech [*Introduction
to Analytics Modeling*
class](https://pe.gatech.edu/courses/introduction-analytics-modeling)
that I have been taking this summer.)



Setup
-----

For this walk-through, I’ll be exploring the `PrimaIndiansDiabetes` data
set provided by the `{mlbench}` package. This data set was originally
collected by the [National Institute of Diabetes and Digestive and
Kidney Diseases](https://www.niddk.nih.gov/) and [published as one of
the many datasets available in the UCI
Repository](http://archive.ics.uci.edu/ml/datasets/Pima+Indians+Diabetes).
It consists of 768 rows and 9 variables. It is useful for practicing
binary classification, where the `diabetes` class variable (consisting
of `pos` and `neg` values) is the response which I aim to predict.

``` {.r}
data("PimaIndiansDiabetes", package = "mlbench")
```

``` {.r}
PimaIndiansDiabetes
```

    ##     pregnant glucose pressure triceps insulin mass pedigree age diabetes
    ## 1          6     148       72      35       0   34    0.627  50      pos
    ## 2          1      85       66      29       0   27    0.351  31      neg
    ## 3          8     183       64       0       0   23    0.672  32      pos
    ## 4          1      89       66      23      94   28    0.167  21      neg
    ## 5          0     137       40      35     168   43    2.288  33      pos
    ## 6          5     116       74       0       0   26    0.201  30      neg
    ## 7          3      78       50      32      88   31    0.248  26      pos
    ## 8         10     115        0       0       0   35    0.134  29      neg
    ## 9          2     197       70      45     543   30    0.158  53      pos
    ## 10         8     125       96       0       0    0    0.232  54      pos
    ## 11         4     110       92       0       0   38    0.191  30      neg
    ##  [ reached getOption("max.print") -- omitted 757 rows ]

``` {.r}
fmla_diabetes <- formula(diabetes ~ .)
```

Additionally, I’ll be using the `{tidyverse}` suite of packages—most
notably `{dplyr}`, `{purrr}`, and `{tidyr}`—as well as the `{caret}`
package for its machine learning API.

``` {.r}
library("tidyverse")
library("caret")
```



Traditional `{caret}` Usage
---------------------------

First, I think it’s instructive to show how one might typically use
`{caret}` to create individual models so that I can create a baseline
with which to compare a “many models” approach.

So, let’s say that I want to fit a cross-validated CART ([classification
and regression
tree](https://machinelearningmastery.com/classification-and-regression-trees-for-machine-learning/))
model with scaling and a grid of reasonable complexity parameter (`cp`)
values. (I don’t show the output here because the code is shown purely
for exemplary purposes.)

``` {.r}
fit_rpart <-
  train(
    form = fmla_diabetes,
    data = PimaIndiansDiabetes,
    method = "rpart",
    preProcess = "scale",
    trControl = trainControl(method = "cv", number = 5),
    metric = "Accuracy",
    minsplit = 5,
    tuneGrid = data.frame(cp = 10 ^ seq(-2, 1, by = 1))
  )
fit_rpart
```

    ## CART 
    ## 
    ## 768 samples
    ##   8 predictor
    ##   2 classes: 'neg', 'pos' 
    ## 
    ## Pre-processing: scaled (8) 
    ## Resampling: Cross-Validated (5 fold) 
    ## Summary of sample sizes: 615, 614, 614, 614, 615 
    ## Resampling results across tuning parameters:
    ## 
    ##   cp     Accuracy  Kappa
    ##    0.01  0.74      0.43 
    ##    0.10  0.73      0.36 
    ##    1.00  0.65      0.00 
    ##   10.00  0.65      0.00 
    ## 
    ## Accuracy was used to select the optimal model using the largest value.
    ## The final value used for the model was cp = 0.01.

It’s reasonable to use `{caret}` directly in the manner shown above when
simply fitting one model. But, let’s say that now you want to compare
the previous results with a model fit with un-scaled predictors (perhaps
for pedagogical purposes. Now you copy-paste the previous statement,
only modifying `preProcess` from `"scale"` to `NULL`.

``` {.r}
fit_rpart_unscaled <-
  train(
    form = fmla_diabetes,
    data = PimaIndiansDiabetes,
    method = "rpart",
    preProcess = NULL,
    trControl = trainControl(method = "cv", number = 5),
    metric = "Accuracy",
    minsplit = 5,
    tuneGrid = data.frame(cp = 10 ^ seq(-2, 1, by = 1))
  )
fit_rpart_unscaled
```

    ## CART 
    ## 
    ## 768 samples
    ##   8 predictor
    ##   2 classes: 'neg', 'pos' 
    ## 
    ## No pre-processing
    ## Resampling: Cross-Validated (5 fold) 
    ## Summary of sample sizes: 614, 615, 614, 614, 615 
    ## Resampling results across tuning parameters:
    ## 
    ##   cp     Accuracy  Kappa
    ##    0.01  0.73      0.40 
    ##    0.10  0.72      0.36 
    ##    1.00  0.65      0.00 
    ##   10.00  0.65      0.00 
    ## 
    ## Accuracy was used to select the optimal model using the largest value.
    ## The final value used for the model was cp = 0.01.

Although I might feel bad about copying-and-pasting so much code, I end
up with what I wanted.

But now I want to try a different method–a random forest. Now I will
need to change the value of the `method` argument (to `"rf"`) **and**
the value of `tuneGrid`—because there are different parameters to tune
for a random forest—**and** remove the `minsplit` argument—because it is
not applicable for the `caret::train()` method for `"rf"`, and,
consequently, will cause an error.

``` {.r}
fit_rf <-
  train(
    form = fmla_diabetes,
    data = PimaIndiansDiabetes,
    method = "rf",
    preProcess = "scale",
    trControl = trainControl(method = "cv", number = 5),
    metric = "Accuracy",
    tuneGrid = data.frame(mtry = c(3, 5, 7))
  )
fit_rf
```

    ## Random Forest 
    ## 
    ## 768 samples
    ##   8 predictor
    ##   2 classes: 'neg', 'pos' 
    ## 
    ## Pre-processing: scaled (8) 
    ## Resampling: Cross-Validated (5 fold) 
    ## Summary of sample sizes: 614, 614, 614, 615, 615 
    ## Resampling results across tuning parameters:
    ## 
    ##   mtry  Accuracy  Kappa
    ##   3     0.76      0.46 
    ##   5     0.75      0.44 
    ##   7     0.75      0.44 
    ## 
    ## Accuracy was used to select the optimal model using the largest value.
    ## The final value used for the model was mtry = 3.

Then, what if I want to try yet another different method (with the same
formula (`form`) and `data`)? I would have to continue copy-pasting like
this, which, of course, can start to become tiresome. The [DRY
principle](/post/dry-principle-make-a-package/) is certainly relevant
here—an approach using functions to automate the re-implementation the
“constants” among methods is superior.

Anyways, I think it is evident that a better approach than copy-pasting
code endlessly can be achieved. With that said, next I’ll demonstrate
two approaches. While I believe the second of these is superior because
it is less verbose, I think it’s worth showing the first approach as
well for instructive purposes.



split-apply-combine + `{caret}`, Approach \#1
---------------------------------------------

For this first approach,

1.  First, I define a “base” function that creates a list of arguments
    passed to `caret::train()` that are common among each of the methods
    to evaluate.
2.  Next, I define several “method-specific” functions for `rpart"`,
    `"rf"`, and `"ranger"` (a faster implementation of the random forest
    than that of the more well known `{randomForest}` package, which is
    used by the `"rf"` method for `caret::train()`). These functions
    return lists of parameters for `caret::train()` that are unique for
    each function—most notably `tuneGrid`. (The `{caret}` [package’s
    documentation](https://topepo.github.io/caret) should be consulted
    to identify exactly which arguments must be defined.) Additionally,
    note that there may be parameters that are passed directly to the
    underlying function called by `caret::train()` (via the `...`
    argument). such as `minsplit` for the `"rpart"`. (
3.  Finally, I define a `sprintf`-style function—with `method` as an
    argument—to call the method-specific functions (using
    `purrr::invoke()`).

Thus, the call stack for this approach looks like this. [^1]

![](diagram.PNG)


``` {.r}
setup_caret_base_tree <-
  function() {
    list(
      form = fmla_diabetes,
      data = PimaIndiansDiabetes,
      trControl = trainControl(method = "cv", number = 5),
      metric = "Accuracy"
    )
  }

setup_caret_rpart <-
  function() {
    list(method = "rpart",
         minsplit = 5,
         tuneGrid = data.frame(cp = 10 ^ seq(-2, 1, by = 1)))
  }

setup_caret_rf <-
  function() {
   list(method = "rf", tuneGrid = data.frame(mtry = c(3, 5, 7)))
  }

setup_caret_ranger <-
  function() {
    list(method = "ranger",
         tuneGrid = 
           expand.grid(
             mtry = c(3, 5, 7),
             splitrule = c("gini"),
             min.node.size = 5,
             stringsAsFactors = FALSE
            )
    )
  }

fit_caret_tree_sprintf <-
  function(method, preproc = NULL) {
    invoke(
      train,
      c(
        invoke(setup_caret_base_tree),
        invoke(sprintf("setup_caret_%s", method)),
        preProcess = preproc
      )
    )
  }
```

(I apologize if the `_tree` suffix with the functions defined here seems
verbose, but I think this syntax servers as an informational “hint” that
other functions with non-tree-based methods could be written in a
similar fashion.)

Next, I define the “grids” of method and pre-processing specifications
to pass to the functions. I define a relatively “minimal” set of
different combinations in order to emphasize the functionality that is
implemented (rather than the choices for methods and pre-processing).

Note the following:

-   The `_desc` column(s) are purely for informative purposes—they
    aren’t used in the functions.
-   The `idx_method` column is defined for use as the key column in the
    join that it does to combine these “grid” specifications and the
    functions when the functions are called. (See `fits_diabetes_tree`.)
-   I want to try methods without any pre-processing, meaning that
    `preProcess` should be set to `NULL` in `caret::train()`. However,
    it is not possible (to my knowledge) to explicitly define a `NULL`
    in a data.frame, so I use the surrogate `"none"`, which gets ignored
    (i.e. treated as `NULL`) when passed as the value of `preProcess` to
    `caret::train()`.
-   The `method` and `preproc` columns are not actually used directly
    for this approach, but for the next one.

``` {.r}
grid_preproc <-
  tribble(
    ~preprocess_desc, ~preproc,
    "Scaled", "scale",
    "Unscaled", "none"
  )
```

``` {.r}
grid_methods_tree <-
  tribble(
    ~method_desc, ~method,
    "{rpart} CART", "rpart",
    "{randomForest} Random Forest", "rf",
    "{ranger} Random Forest", "ranger"
  ) %>% 
  crossing(
    grid_preproc
  ) %>% 
  unite(method_desc, method_desc, preprocess_desc, sep = ", ") %>% 
  mutate(idx_method = row_number()) %>% 
  select(idx_method, everything())
grid_methods_tree
```

    ## # A tibble: 6 x 4
    ##   idx_method method_desc                            method preproc
    ##        <int> <chr>                                  <chr>  <chr>  
    ## 1          1 {rpart} CART, Scaled                   rpart  scale  
    ## 2          2 {rpart} CART, Unscaled                 rpart  none   
    ## 3          3 {randomForest} Random Forest, Scaled   rf     scale  
    ## 4          4 {randomForest} Random Forest, Unscaled rf     none   
    ## 5          5 {ranger} Random Forest, Scaled         ranger scale  
    ## 6          6 {ranger} Random Forest, Unscaled       ranger none

Finally, for the actual implementation, I call
`fit_caret_tree_sprintf()` for each combination of method and
pre-processing transformation(s). Importantly, the calls should be made
in the same order as that implied by `grid_methods_tree` so that the
join on `idx_method` is “valid” (in the sense that the model fit aligns
with the description).

``` {.r}
set.seed(42)
fits_diabetes_tree_1 <-
  tribble(
    ~fit,
    fit_caret_tree_sprintf(method = "rpart", preproc = NULL),
    fit_caret_tree_sprintf(method = "rpart", preproc = "scale"),
    fit_caret_tree_sprintf(method = "rf", preproc = NULL),
    fit_caret_tree_sprintf(method = "rf", preproc = "scale"),
    fit_caret_tree_sprintf(method = "ranger", preproc = NULL),
    fit_caret_tree_sprintf(method = "ranger", preproc = "scale")
  ) %>% 
  mutate(idx_method = row_number()) %>% 
  left_join(grid_methods_tree) %>% 
  # Rearranging so that `fit` is the last column.
  select(-fit, everything(), fit)
fits_diabetes_tree_1
```

    ## # A tibble: 6 x 5
    ##   idx_method method_desc                         method preproc fit       
    ##        <int> <chr>                               <chr>  <chr>   <list>    
    ## 1          1 {rpart} CART, Scaled                rpart  scale   <S3: trai~
    ## 2          2 {rpart} CART, Unscaled              rpart  none    <S3: trai~
    ## 3          3 {randomForest} Random Forest, Scal~ rf     scale   <S3: trai~
    ## 4          4 {randomForest} Random Forest, Unsc~ rf     none    <S3: trai~
    ## 5          5 {ranger} Random Forest, Scaled      ranger scale   <S3: trai~
    ## 6          6 {ranger} Random Forest, Unscaled    ranger none    <S3: trai~

I get the results that I wanted, albeit with a bit more verbosity than I
might have liked. (Note the repeated calls to the sprintf function.)

There are a couple of other things that I did not mention before about
the code that I think are worth saying.

-   If one does not wish to specify `tuneGrid`, then the implementation
    becomes simpler.
-   Other `purrr` functions such as `partial()` or `compose()` could
    possibly be used in some manner to reduce some of the redundant code
    to an even greater extent.
-   If one only wants to implement pre-processing for certain methods,
    then the method-specific functions and the sprintf function could be
    re-defined such that `preproc` is passed as an argument to the
    method-specific functions and not used in the sprintf function.



split-apply-combine + `{caret}`, Approach \#2
---------------------------------------------

For this next approach (my preferred one), the fundamental difference is
with the use of the `grid_methods_tree` data.frame created before.
Because the split-apply-combine recipe for this approach directly uses
the `method` and `preproc` columns—recall that these are not used with
the previous approach—it is necessary to use `grid_methods_tree` at the
beginning of the modeling pipeline.

Because I use the `grid_methods_tree` columns directly, I remove much of
the verbosity seen in the prior approach. Now I define a function that
essentially serves the same purpose as the sprintf function defined
before—it binds the lists returned by a base `{caret}` function and a
method-specific `{caret}` function, as well as a value for the
`preProcess` argument.

There is a bit of “hacky” part of the implementation here—I use a
`switch()` statement in order to substitute `NULL` for `"none"`. As
mentioned before, it does not seem possible to create a `NULL` value in
a data.frame, so `"none"` serves as a “stand-in”. Notably, an `ifelse()`
call does not work because it cannot return a `NULL`.

``` {.r}
fit_caret_tree <-
  function(method, preproc = "scale") {
    invoke(
      train,
      c(
        invoke(setup_caret_base_tree),
        invoke(sprintf("setup_caret_%s", method)),
        preProcess = switch(preproc == "none", NULL, preproc)
      )
    )
  }
```

``` {.r}
set.seed(42)
fits_diabetes_tree_2 <-
  grid_methods_tree %>%
  group_by(idx_method, method_desc) %>% 
  nest() %>% 
  mutate(
    fit = 
      purrr::map(data, 
                 ~fit_caret_tree(method = .x$method, preproc = .x$preproc))
  ) %>% 
  ungroup()
fits_diabetes_tree_2
```

    ## # A tibble: 6 x 4
    ##   idx_method method_desc                         data           fit       
    ##        <int> <chr>                               <list>         <list>    
    ## 1          1 {rpart} CART, Scaled                <tibble [1 x ~ <S3: trai~
    ## 2          2 {rpart} CART, Unscaled              <tibble [1 x ~ <S3: trai~
    ## 3          3 {randomForest} Random Forest, Scal~ <tibble [1 x ~ <S3: trai~
    ## 4          4 {randomForest} Random Forest, Unsc~ <tibble [1 x ~ <S3: trai~
    ## 5          5 {ranger} Random Forest, Scaled      <tibble [1 x ~ <S3: trai~
    ## 6          6 {ranger} Random Forest, Unscaled    <tibble [1 x ~ <S3: trai~

Cool! This approach complies with the modern split-apply-combine
approach—`dplyr::group_by()` + `tidyr::nest()`, `dplyr::mutate()` +
`purrr::map()` and `tidyr::unnest()`—and achieves the results which I
sought.



Quantifying Model Quality
-------------------------

So I’ve got the fitted models for “many models” in a single `tibble`.
How do I extract the results from this? `{purrr}`’s `pluck()` function
is helpful here, along with the `dplyr::mutate()`, `purrr::map()`, and
`tidyr::unnest()` functions used before.

``` {.r}
unnest_caret_results <-
  function(fit, na.rm = TRUE) {
    fit %>%
      dplyr::mutate(results = map(fit, ~pluck(.x, "results"))) %>% 
      unnest(results, .drop = TRUE)
  }
```

We get the same exact results with both approaches demonstrated above,
so I’ll only show the results for one here.

``` {.r}
summ_diabetes_tree <-
  fits_diabetes_tree_2 %>%
  unnest_caret_results() %>%
  select(-matches("SD")) %>%
  arrange(desc(Accuracy))
summ_diabetes_tree
```

    ## # A tibble: 20 x 8
    ##    idx_method method_desc    cp Accuracy  Kappa  mtry splitrule
    ##         <int> <chr>       <dbl>    <dbl>  <dbl> <dbl> <chr>    
    ##  1          4 {randomFor~ NA      0.7734 0.4881     5 <NA>     
    ##  2          5 {ranger} R~ NA      0.7669 0.4713     5 gini     
    ##  3          5 {ranger} R~ NA      0.7669 0.4687     3 gini     
    ##  4          6 {ranger} R~ NA      0.7643 0.4686     3 gini     
    ##  5          6 {ranger} R~ NA      0.7631 0.4694     7 gini     
    ##  6          6 {ranger} R~ NA      0.7630 0.4666     5 gini     
    ##  7          3 {randomFor~ NA      0.7630 0.4632     3 <NA>     
    ##  8          4 {randomFor~ NA      0.7630 0.4661     7 <NA>     
    ##  9          5 {ranger} R~ NA      0.7629 0.4639     7 gini     
    ## 10          3 {randomFor~ NA      0.7617 0.4615     7 <NA>     
    ## 11          3 {randomFor~ NA      0.7591 0.4569     5 <NA>     
    ## 12          4 {randomFor~ NA      0.7578 0.4520     3 <NA>     
    ## 13          2 {rpart} CA~  0.01   0.7501 0.4311    NA <NA>     
    ## 14          1 {rpart} CA~  0.01   0.7396 0.4144    NA <NA>     
    ## 15          1 {rpart} CA~  0.1    0.7382 0.3794    NA <NA>     
    ## 16          2 {rpart} CA~  0.1    0.7240 0.3696    NA <NA>     
    ## 17          1 {rpart} CA~  1      0.6510 0         NA <NA>     
    ## 18          1 {rpart} CA~ 10      0.6510 0         NA <NA>     
    ## 19          2 {rpart} CA~  1      0.6510 0         NA <NA>     
    ## 20          2 {rpart} CA~ 10      0.6510 0         NA <NA>     
    ## # ... with 1 more variable: min.node.size <dbl>

And, with the results fashioned like this, we can easily perform other
typical `{dplyr}` actions to gain insight from the results quickly.

``` {.r}
summ_diabetes_bymethod <-
  summ_diabetes_tree %>% 
  group_by(idx_method, method_desc) %>% 
  summarise_at(vars(Accuracy), funs(min, max, mean, n = n())) %>% 
  ungroup() %>% 
  arrange(desc(max))
summ_diabetes_bymethod
```

    ## # A tibble: 6 x 6
    ##   idx_method method_desc                           min    max   mean     n
    ##        <int> <chr>                               <dbl>  <dbl>  <dbl> <int>
    ## 1          4 {randomForest} Random Forest, Uns~ 0.7578 0.7734 0.7647     3
    ## 2          5 {ranger} Random Forest, Scaled     0.7629 0.7669 0.7656     3
    ## 3          6 {ranger} Random Forest, Unscaled   0.7630 0.7643 0.7635     3
    ## 4          3 {randomForest} Random Forest, Sca~ 0.7591 0.7630 0.7613     3
    ## 5          2 {rpart} CART, Unscaled             0.6510 0.7501 0.6940     4
    ## 6          1 {rpart} CART, Scaled               0.6510 0.7396 0.6950     4

And let’s not forget about visualizing the results.

![](viz_summ_diabetes_bymethod_show-1.png)


Conclusion
----------

That’s it for this tutorial. I hope that this is useful for others. (If
nothing else, it’s useful for me to review.) While the `{caret}` package
does allow users [to create custom `train()`
functions](https://topepo.github.io/caret/using-your-own-model-in-train.html),
I believe that this functionality is typically beyond what a user needs
when experimenting with different approaches (and can be quite complex).
I believe that the approach (primarily the second one) that I’ve shown
in this post offers a great amount of flexibility that complements the
many other aspects of `{caret}`’s user-friendly, dynamic API.

In an actual analysis, the approach(es) that I’ve shown can be extremely
useful in experimenting with many different methods, parameters, and
data pre-processing in order to identify a set that is most appropriate
for the context.

------------------------------------------------------------------------

[^1]: This figure is created with the awesome `{DiagrammeR}` package.

