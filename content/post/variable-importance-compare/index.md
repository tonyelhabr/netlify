---
title: Comparing Variable Importance Functions (For Modeling)
date: '2020-07-13'
categories:
  - r
tags:
  - r
  - variable importance
  - machine learning
  - interpretable
  - tidymodels
image:
  caption: ''
  focal_point: ''
  preview_only: true
header:
  caption: ''
  image: 'featured.jpg'
---



I've been doing some machine learning recently, and one thing that keeps popping up is the need to explain the models and their components. There are a variety of ways to go about explaining model features, but probably the most common approach is to use **[variable (or feature) importance](https://stats.stackexchange.com/questions/332960/what-is-variable-importance)** scores. Unfortunately, computing variable importance scores isn't as straightforward as one might hope---there are a variety of methodologies! Upon implementation, I came to the question "How similar are the variable importance scores calculated using different methodologies?" [^1] I think it's important to know if the different methods will lead to drastically different results. If so, then the choice of method is a source of bias in model interpretation, which is not ideal.

[^1]: After all, I want to make sure my results aren't sensitive to some kind of bias (unintentional in this case).

This post isn't intended to be a deep-dive into [model interpretability](https://christophm.github.io/interpretable-ml-book/) or variable importance, but some concepts should be highlighted before attempting to answer this question. Generally, variable importance can be categorized as either being ["model-specific"](https://topepo.github.io/caret/variable-importance.html) or ["model-agnostic"](https://christophm.github.io/interpretable-ml-book/agnostic.html). Both depend upon some kind of loss function, e.g. [root mean squared error (RMSE)](https://en.wikipedia.org/wiki/Root-mean-square_deviation), [classification error](https://en.wikipedia.org/wiki/Confusion_matrix), etc. The loss function for a model-specific approach will generally be "fixed" by the software and package that are used [^2], while model-agnostic approaches tend to give the user flexibility in choosing a loss function. Finally, within model-agnostic approaches, there are different methods, e.g. [permutation](https://christophm.github.io/interpretable-ml-book/feature-importance.html) and [SHAP (Shapley Additive Explanations)](https://christophm.github.io/interpretable-ml-book/shap.html). 

[^2]: For example, for linear regression models using `lm` from the `{stats}` package, variable importance is based upon the absolute value of the t-statistics for each feature.

So, to summarize, variable importance "methodologies" can be broken down in several ways:

1. model-specific vs. model-agnostic approach
2. loss function
3. model agnostic method (given a model agnostic approach)

I'm going to attempt to address (1) and (3) above. I'm leaving (2) out because (a) I think the results won't differ too much when using different loss functions (although I haven't verified this assumption) and (b) for the sake of simplicity, I don't want to be too exhaustive in this analysis. [^3]

[^3]: This isn't an academic paper after all!

I also want to evaluate how variable importance scores differ across more than one of each of the following:

1. model type (e.g. linear regression, decision trees, etc.)
2. type of target variables (continuous or discrete)
3. data set

While evaluating the sensitivity of variable importance scores to  different methodologies is the focus of this analysis, I think it's important to test how the findings hold up when (1) varying model types, (2) varying target variables, and (3) varying the data itself. This should help us highlight any kind of bias in the results due to choice of model type and type of target variable. Put another way, it should help us quantify the robustness the conclusions that are drawn. If we find that the scores are similar under variation, then we can be more confident that the findings can be generalized.

Additionally, I'm going to use more than one package for computing variable importance scores. As with varying model types, outcome variables, and data, the purpose is to highlight and quantify possible bias due to choices in this analysis---in this case, the choice of package. Are the results of a permutation-based variable importance calculation the same when using different packages (holding all else equal)?

Specifically, I'll be using the [`{vip}`](https://cran.r-project.org/web/packages/vip/index.html) and [`{DALEX}`](https://cran.r-project.org/web/packages/DALEX/index.html) packages. The `{vip}` package is my favorite package to compute variable importance scores using R is  because it is capable of doing both types of calculations (model-specific and model-agnostic) for a variety of model types. But other packages are also great. `{DALEX}` package specializes in model-agnostic model interpretability and can do a lot more than just variable importance calculations.

# Setup

For data, I'm going to be using two data sets [^4]: 

1. `diamonds` from `{ggplot2}`. [^5]
2. `mpg` from `{ggplot2}`. [^6]

I made modifications to both, so see the footnotes and/or code if you're interested in the details.

[^4]: Apologies for using "bland" data sets here. At least they aren't `mtcars` (nor a flower data set that is not to be named)!

[^5]: I've made the following modification: (a) I've taken a sampled fraction of the data set to increase computation time. (b) I've excluded two of the categorical features---`clarity` and `color`, both of which are categorical with a handful of levels. I've done this in order to reduce the number of variables involved and, consequently, to speed up computation. (This is just an example after all!) (c) To test how variable importance scores differ for a continuous target variable, I'll be defining models that predict `price` as a function of all other variables. (d) For discrete predictions, the target is a binary variable `grp` that I've added. It is equal to `'1. Good'` when `cut %in% c('Idea', 'Premium')` and `2. Bad'` otherwise. It just so happens that `grp` is relatively evenly balanced between the two levels, so there should not be any bias in the results due to class imbalance.

[^6]: Modifications include the following: (a) I've excluded `manufacturer`, `model`, `trans`, and `class`. (b) For continuous predictions, I'll predict `displ` as a function of all other variables. (c) For discrete predictions, I've created a binary variable `grp` based on `class`.

For model types, I'm going to trial the following:

1. [generalized linear model (linear and logistic regression)](https://en.wikipedia.org/wiki/Generalized_linear_model) with `stats::lm()` and `stats::glm()` respectively
2. [generalized linear model with regularization](https://en.wikipedia.org/wiki/Regularized_least_squares) using the [`{glmnet}` package](https://cran.r-project.org/web/packages/glmnet/index.html)
3. bagged tree ([random forest](https://en.wikipedia.org/wiki/Random_forest)) using the [`{ranger}` package](https://cran.r-project.org/web/packages/ranger/index.html)
4. boosted tree (extreme [gradient boosting](https://en.wikipedia.org/wiki/Gradient_boosting)) using the [`{xgboost}` package](https://cran.r-project.org/web/packages/xgboost/index.html)

With `glmnet::glmnet()`, I'm actually not going to use a penalty, so (I think) it should return the same results as `lm()`/`glm()`. [^7] For `{ranger}` and `{xgboost}`, I'm going to be using defaults for all parameters. [^8]

[^7]: (I haven't actually checked the source for `{glmnet}` and compared it to that of `lm()`/`glm()`. Differences may arise due to underlying differences in the algorithm for least squares.)

[^8]: I should say that I'm using the `{tidymodels}` package to assist with all of this. It really shows off its flexibility here, allowing me to switch between models only having to change-out one line of code!Finally, for variable importance scores (which is really the focus), I'm going to use the following packages and functions.

1. `{vip}`'s model-specific scores with (`vip::vip(method = 'model')`)
2. `{vip}`'s permutation-based scores (with `vip::vip(method = 'permute')`)
3. `{vip}`'s SHAP-based values (with `vip::vip(method = 'shap')`)
4.  [`{DALEX}`'s permutation-based scores](https://pbiecek.github.io/ema/featureImportance.html) (with `DALEX::variable_importance()`)

Note that the model-specific vs. model-agnostic concern is addressed in comparing method (1) vs. methods (2)-(4). I'll be consistent with the loss function in variable importance computations for the model-agnostic methods--minimization of RMSE for a continuous target variable and [sum of squared errors (SSE)](https://en.wikipedia.org/wiki/Residual_sum_of_squares) for a discrete target variable. [^9]

[^9]: Yes, SSE is certainly not the best measure of loss for classification. Nonetheless, when dealing with a binary outcome variable, as is done here, it can arguably be acceptable. 


























































