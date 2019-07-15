---
title: Generating a Gallery of Visualizations for a Static Website (using R)
date: "2019-07-27"
draft: true
categories:
  - r
tags:
  - r
  - blogdown
  - portfolio
image:
  caption: ""
  focal_point: ""
  preview_only: true
header:
  caption: ""
  image: "featured.jpg"
---

While I was browsing [Ryo Nakagawara's blog](https://ryo-n7.github.io/)---one 
of my favorite R bloggers, by the way---I 
was intrigued by his ["Visualizations" page](https://ryo-n7.github.io/visualizations/).
The concept of creating an online "portfolio" is not novel [^1], but
I hadn't thought to make one as a sort of collaporation of work
that I'd described elsewhere (e.g. blog posts).

With the idea in mind, I realized that it wouldn't be hard to generate
such a page by using `R` to navigate files in my local blog folder.
The code that follows shows how I generated the body of my visualization
portfolio page.

A couple of caveats/notes for anyone looking to emulate my approach:

  + I take advantage of the fact that I use the same prefix for (almost) all
  vizzes that I generate with R---`"viz_"`---[^2], as well as the same file
  format---.png.
  
  + At the time of writing, my website---a [`{blogdown}`](https://bookdown.org/yihui/blogdown/)-based 
  website---uses [Hugo's page bundles](https://gohugo.io/content-management/page-bundles/)
  content organization system,
  combined with the ever popular [Academic theme for Hugo](https://sourcethemes.com/academic/).
  Thus, there's no guarantee that the following code will work for you "as is". [^3]
  (If it doesn't, I think the changes that would be needed to get the code to work should be fairly simple.)
  
  + The markdown structure that is generated should not be too difficult to change.
  In my code,
  I create headers and links from the titles of the blog posts
  (via something like `sprintf('# (%s)[%s]', ...)` and I order everything according
  to descending date and ascending line in the post.


[^1]: in fact, many people dedicate website's exclusively to showing off work that they've done.

[^2]: I apologize if I've offended English speakers/readers who use/prefer "s" to "z" (for "viz"). I'm American, and nearly all Americans use "z"!

[^3]: Because Hugo websites follow a standard structure, I really don't think that the choice of theme shouldn't be the reason why this wouldn't work for someone else's website, but I figured I would mention the theme.
