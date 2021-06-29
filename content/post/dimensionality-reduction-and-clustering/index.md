---
title: Quantifying Relative Soccer League Strength
date: '2021-06-26'
categories:
  - r
tags:
  - r
  - soccer
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
---



## Introduction

Combining principal component analysis (PCA) and kmeans clustering seems to be a pretty popular 1-2 punch in data science. I'm not here to illustrate when using both a dimensionality reduction technique and clustering technique is really the best thing to do[^1], I'm here to illustrate the potential advantages of upgrading your PCA + kmeans workflow to Uniform Manifold Approximation and Projection (UMAP) + Gaussian Mixture Model (GMM)

[^1]: In some contexts you can may just want to do feature selection and/or a manual grouping of dataSome might say that you may not need to

<blockquote class="twitter-tweet">

<p lang="tl" dir="ltr">

tired: PCA + kmeans<br>wired: UMAP + GMM

</p>

--- Tony (@TonyElHabr) <a href="https://twitter.com/TonyElHabr/status/1400149998629703681?ref_src=twsrc%5Etfw">June 2, 2021</a>

</blockquote>

```{=html}
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
```
For this demonstration, I'll be using the [data set](https://docs.google.com/spreadsheets/d/1lQgIDcxsHT1m_IayMldmiHVOt4ICbX-ys8Mh9rggPHM/edit?usp=sharing) pointed out [here](https://twitter.com/ronanmann/status/1408504415690969089?s=21), including over 100 stats for players from soccer's "Big 5" European leagues.

## True Unsupervised Evaluation

ay of getting a quick understanding of data (possibly for exploratory data analysis) or to try to gain some actionable insight for an unsupervised task.
