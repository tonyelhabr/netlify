---
title: Making a Cheat sheet with Rmarkdown
date: "2019-07-07"
draft = true
categories:
  - r
tags:
  - r
  - rmarkdown
  - latex
image:
  caption: ""
  focal_point: ""
  preview_only: true
header:
  caption: ""
  image: "featured.jpg"
---


Unfortunately, I haven't had as much time to make blog posts
in the past year or so. 
I started taking classes as part of 
[Georgia Tech's Online Master of Science in Analytics (OMSA)](https://pe.gatech.edu/degrees/analytics)
program last summer (2018) while continuing to work full-time, so extra time
to code and write hasn't been abundant for me.

Anyways, I figured I would share one neat thing I learned to do
as a consequence of taking classes---writing compact 
["cheat sheets("]https://en.wikipedia.org/wiki/Cheat_sheet) with [Rmarkdown](https://rmarkdown.rstudio.com/).

Writing with Rmarkdown is fairly straightforward---mostly
thanks to an abundance of freely available learning resources, like the 
[***R Markdown: The Definitive Guide***](https://bookdown.org/yihui/rmarkdown)---and using
CSS and/or Javascript to customize your Rmarkdown output to your liking
is not too difficult either [^1].
Anyways, I really wanted to make an **extremely** compact PDF
that minimizes all white space
(in order to maximize the amount of space used for content, of course).
I had a hard time getting an output that I liked purely from CSS,
so I looked online to see if I could find some good LaTex templates.
(After all, I would be knitting the Rmarkdown document to PDF,
and [LaTex](https://www.latex-project.org/) would be incorporated via the equations on the cheatsheet.)
Some templates I found worked fine online, but weren't completely to my liking.

[^1] and is definitely worth your time

Eager to find an answer to my search for an "ideal" template, I read the
"fine print" in the very last portion of the 
[PDF chapter of the ***R Markdown*** book](https://bookdown.org/yihui/rmarkdown/pdf-document.html)
which states "You can also replace the underlying Pandoc template using the template option".
This finding would lead me to develop my own template.

At first, I was a bit intimidated by this idea. ("I have to write my own entire
template in a language (LaTeX) that I've hardly even touched before now! Argh ...")

Using the template from [this Stack Overflow post] as a basis, I ended
up with a relatively minimal template that looks as follows.
(Feel free to copy-paste it and use it as you like.)

[^1]: I found a couple of very good ones online, like [this one](https://github.com/tim-st/latex-cheatsheet), which was my favorite. However, it's a bit more complex than what I wanted. (This one implements a "structure" in which one "main" tex file refereces several others with the `\input` Latex command.)


```
% Packages and preamble
[...]

\begin{document}

[...]

\begin{multicols*}{5}

[...]


$body$

\end{multicols*}

\end{document}
```
