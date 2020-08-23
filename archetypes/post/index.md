---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
lastmod: {{ .Date }}
draft: true
categories:
  - r
tags:
  - r
image:
  caption: ''
  focal_point: ''
  preview_only: true
header:
  caption: ''
  image: 'featured.jpg'
output:
  html_document:
    keep_md: yes
always_allow_html: true
---
