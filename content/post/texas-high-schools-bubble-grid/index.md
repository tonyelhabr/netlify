---
title: Visualizing Texas High School SAT Math Scores with Bubble Grids
# slug: bubble-grid-texas-high-school
date: "2018-07-22"
categories:
  - r
tags:
  - r
  - ggplot2
  - sf
  - bubble grid
  - texas
  - academics
image:
  caption: ""
header:
  caption: ""
  image: "featured.jpg"
---

Two awesome things inspired this post:

-   [`{ggplot2}`’s version 3.0
    release](https://www.tidyverse.org/articles/2018/07/ggplot2-3-0-0/)
    on [CRAN](https://cran.r-project.org/), including full support for
    the `{sf}` package and new functions `geom_sf()` and `coord_sf()`,
    which make plotting data from shapefiles very straightforward.

-   [Jonas Scholey’s blog
    post](http://jschoeley.github.io/2018/06/30/bubble-grid-map.html)
    discussing the use of “bubble grid” maps as an alternative to
    [choropleth](https://en.wikipedia.org/wiki/Choropleth_map) maps,
    which seem to be used more prevalent.

As Jonas implies, using color as a visual encoding is not always the
best option, a notion with which I strongly agree.
[Cartograms](https://en.wikipedia.org/wiki/Cartogram) try to address the
ambiguity of color encoding with distortion of land area/distance, but I
think the result can be difficult to interpret. Bubble grid maps seem to
me to be an interesting alternative that can potentially display
information in a more direct manner.

With that being said, I decided to adapt Jonas’ code to visualize the
Texas high school SAT/ACT data that I’ve looked at in other posts. To
simplify the visual encoding of information, I’ll filter the data down
to a single statistic—the math test scores for the SAT for the year
2015. (For other applications, the statistic might be population
density, average median household income, etc.) For the geo-spatial
data, I downloaded the shapefiles for
[schools](https://schoolsdata2-tea-texas.opendata.arcgis.com/datasets/059432fd0dcb4a208974c235e837c94f_0)
and
[counties](https://schoolsdata2-tea-texas.opendata.arcgis.com/datasets/c71146b6426248a5a484d8b3c192b9fe_0)
provided by the [Texas Education Agency](https://tea.texas.gov/) (TEA).
Additionally, I downloaded shapefiles for [Texas
cities](https://opendata.arcgis.com/datasets/993d420b9f0742b9afa06622d27a37e0_0.geojson)
and for [Texas
highways](http://hub.arcgis.com/datasets/e661b4004aee4c939569a563b6bb881a_0),
provided by the [Texas Department of
Transportation](https://www.txdot.gov/) (TxDOT). By plotting the major
cities and roadways in the state, the locations of “sparsely” populated
areas should be evident, which can explain why there doesn’t appear to
any data in some regions. Finally, I’ll also use the Texas state and
county border data provided in the `ggplot2::map_data()` (which is
essentially just serves as a wrapper for extracting data provided in the
`{maps}` package).

``` {.r}
library("tidyverse")
library("teplot")
library("sf")
```

I’ll skip over the data collection and munging steps and just show the
cleaned data that I’m using. (See the GitHub repository for the full
code.)

``` {.r}
schools_tea_filt %>% glimpse()
```

    ## Observations: 1,567
    ## Variables: 7
    ## $ test     <chr> "SAT", "SAT", "SAT", "SAT", "SAT", "SAT", "SAT", "SAT...
    ## $ year     <int> 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015,...
    ## $ school   <chr> "A C JONES", "A M CONS", "A MACEO SMITH NEW TECH", "A...
    ## $ district <chr> "BEEVILLE ISD", "COLLEGE STATION ISD", "DALLAS ISD", ...
    ## $ county   <chr> "BEE", "BRAZOS", "DALLAS", "DALLAS", "HILL", "HALE", ...
    ## $ city     <chr> "CORPUS CHRISTI", "HUNTSVILLE", "RICHARDSON", "RICHAR...
    ## $ value    <dbl> 458, 567, 411, 428, 539, 533, 482, 538, 507, 428, 428...

``` {.r}
schools_sf %>% glimpse()
```

    ## Observations: 8,701
    ## Variables: 11
    ## $ schl_nm  <int> 20901109, 58905001, 15909001, 15915119, 101907149, 10...
    ## $ school   <fct> HOOD-CASE EL, KLONDIKE ISD, SOMERSET, HOWSMAN EL, WAR...
    ## $ distrct  <fct> ALVIN ISD, KLONDIKE ISD, SOMERSET ISD, NORTHSIDE ISD,...
    ## $ city     <fct> ALVIN, LAMESA, SOMERSET, SAN ANTONIO, CYPRESS, HOUSTO...
    ## $ county   <fct> BRAZORIA, DAWSON, BEXAR, BEXAR, HARRIS, HARRIS, HUTCH...
    ## $ regn_nm  <int> 4, 17, 20, 20, 4, 4, 16, 11, 11, 4, 11, 1, 10, 11, 19...
    ## $ grd_grp  <fct> EE PK KG 01 02 03 04 05, EE PK KG 01 02 03 04 05 06 0...
    ## $ grd_gr_  <int> 1, 5, 4, 1, 1, 2, 4, 4, 4, 1, 1, 1, 4, 4, 1, 2, 1, 2,...
    ## $ instr_t  <fct> REGULAR INSTRUCTIONAL, REGULAR INSTRUCTIONAL, REGULAR...
    ## $ magnet   <fct> No, No, No, No, No, No, No, No, No, No, No, No, No, N...
    ## $ geometry <POINT [Â°]> POINT (-95 29), POINT (-102 33), POINT (-99 29...

``` {.r}
counties_sf %>% glimpse()
```

    ## Observations: 254
    ## Variables: 2
    ## $ county   <fct> DALLAM, BORDEN, FISHER, SHERMAN, STEPHENS, HANSFORD, ...
    ## $ geometry <POLYGON [Â°]> POLYGON ((-102 37, -102 37,..., POLYGON ((-1...

``` {.r}
cities_sf %>% glimpse()
```

    ## Observations: 9
    ## Variables: 15
    ## $ objectid  <int> 3028, 3212, 2291, 2984, 258, 623, 863, 1402, 1658
    ## $ gid       <int> 2703, 3058, 2835, 2659, 40, 1165, 1405, 1074, 1988
    ## $ city_nm   <fct> San Antonio, Laredo, Corpus Christi, Houston, Lubboc...
    ## $ city_nbr  <int> 37450, 24000, 9800, 19750, 25650, 2100, 13400, 10850...
    ## $ inc_flag  <fct> Yes, Yes, Yes, Yes, Yes, Yes, Yes, Yes, Yes
    ## $ cnty_seat <fct> Yes, Yes, Yes, Yes, Yes, Yes, Yes, Yes, Yes
    ## $ city_fips <fct> 4865000, 4841464, 4817000, 4835000, 4845000, 4805000...
    ## $ pop1990   <int> 935933, 122899, 257453, 1630553, 186206, 465622, 515...
    ## $ pop2000   <int> 1144646, 176576, 277454, 1953631, 199564, 656562, 56...
    ## $ pop2010   <int> 1327407, 236091, 305215, 2099451, 229573, 790390, 64...
    ## $ cnty_nbr  <fct> 15, 240, 178, 102, 152, 227, 72, 57, 69
    ## $ dist_nbr  <fct> 15, 22, 16, 12, 5, 14, 24, 18, 6
    ## $ x         <dbl> -98, -100, -97, -95, -102, -98, -106, -97, -102
    ## $ y         <dbl> 29, 28, 28, 30, 34, 30, 32, 33, 32
    ## $ geometry  <POINT [Â°]> POINT (-98 29), POINT (-100 28), POINT (-97 2...

``` {.r}
hwys_sf %>% glimpse()
```

    ## Observations: 225
    ## Variables: 15
    ## $ fid        <dbl> 1, 8, 9, 14, 15, 19, 20, 22, 25, 26, 30, 38, 53, 69...
    ## $ rte_nm     <fct> SH0155-KG, US0190-KG, SH0155-KG, IH0014-KG, SH0155-...
    ## $ rte_prfx   <fct> SH, US, SH, IH, SH, US, SH, FM, IH, US, BS, SH, SH,...
    ## $ rte_nbr    <dbl> 155, 190, 155, 14, 155, 190, 155, 510, 14, 77, 71, ...
    ## $ rdbd_type  <fct> KG, KG, KG, KG, KG, KG, KG, KG, KG, KG, KG, KG, KG,...
    ## $ begin_dfo  <dbl> 78.750, 308.163, 41.640, 283.029, 55.883, 255.923, ...
    ## $ end_dfo    <dbl> 123.1, 340.2, 55.0, 302.3, 68.4, 277.5, 40.1, 22.2,...
    ## $ asset_nm   <fct> Memorial Highway, Memorial Highway, Memorial Highwa...
    ## $ memorial_h <fct> Blue Star Memorial Highways, Port to Plains Highway...
    ## $ asset_cmnt <fct> Assigned by Minute Order, H. C. R.# 157, 5/7/85, As...
    ## $ des_type   <fct> Other, Other, Other, Other, Other, Other, Other, Lo...
    ## $ system     <fct> On, On, On, On, On, On, On, On, On, On, On, On, On,...
    ## $ shape_len  <dbl> 0.6718, 0.5125, 0.2142, 0.3193, 0.1902, 0.3563, 0.6...
    ## $ n          <int> 20, 2, 20, 2, 20, 2, 20, 1, 2, 1, 2, 20, 1, 6, 4, 4...
    ## $ geometry   <LINESTRING [Â°]> LINESTRING (-95 32, -95 32,..., LINESTR...

``` {.r}
tx_border %>% glimpse()
```

    ## Observations: 1,088
    ## Variables: 6
    ## $ long      <dbl> -94, -94, -94, -94, -94, -94, -94, -94, -94, -94, -9...
    ## $ lat       <dbl> 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, ...
    ## $ group     <dbl> 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, ...
    ## $ order     <int> 12203, 12204, 12205, 12206, 12207, 12208, 12209, 122...
    ## $ region    <chr> "texas", "texas", "texas", "texas", "texas", "texas"...
    ## $ subregion <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, ...

Here I create the grid of data that I’ll use for the visual. (Thanks to
Jonas for [his
example](http://jschoeley.github.io/2018/06/30/bubble-grid-map.html).)

``` {.r}
counties_grid_sf <-
  counties_sf %>%
  st_make_grid(n = c(40, 40))

schools_grid_sf <-
  counties_sf %>%
  left_join(schools_tea_filt) %>%
  select(value) %>%
  # NOTE: Set `extensive = FALSE` to get the mean. Otherwise, set `extensive = TRUE` for the sum.
  st_interpolate_aw(to = counties_grid_sf, extensive = FALSE) %>%
  st_centroid() %>%
  cbind(st_coordinates(.))
```

``` {.r}
schools_grid_sf %>% glimpse()
```

    ## Observations: 855
    ## Variables: 5
    ## $ Group_1  <dbl> 26, 27, 28, 29, 30, 64, 65, 66, 67, 68, 69, 70, 103, ...
    ## $ value    <dbl> NA, NA, 465, 465, 465, NA, NA, NA, NA, 463, 465, 465,...
    ## $ X        <dbl> -98, -98, -98, -97, -97, -99, -99, -98, -98, -98, -97...
    ## $ Y        <dbl> 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 27, 2...
    ## $ geometry <POINT [Â°]> POINT (-98 26), POINT (-98 26), POINT (-98 26)...

``` {.r}
viz_schools_grid <-
  schools_grid_sf %>%
  ggplot() +
  geom_polygon(
    data = tx_border,
    aes(x = long, y = lat, group = group),
    size = 1.5,
    color = "black",
    fill = NA
  ) +
  geom_sf(
    data = hwys_sf,
    linetype = "solid",
    size = 0.1
  ) +
  geom_point(
    aes(x = X, y = Y, size = value, color = value),
    # show.legend = FALSE,
    shape = 16
  ) +
  geom_sf(
    data = cities_sf,
    shape = 16,
    size = 2,
    fill = "black"
  ) +
  ggrepel::geom_label_repel(
    data = cities_sf,
    aes(x = x, y = y, label = city_nm)
  ) +
  coord_sf(datum = NA) +
  scale_color_viridis_c(option = "B", na.value = "#FFFFFF") +
  teplot::theme_map(legend.position = "bottom") +
  labs(
    title = str_wrap("Texas High School Math SAT Scores, 2015", 80),
    caption = "By Tony ElHabr."
  )
viz_schools_grid
```

![](viz_schools_grid-1.png)

Cool! I like this visualization because it seems to offer a finer amount
of detail compared to a choropleth. (In other words, it seems to
emphasize specific areas in counties and not the entire county itself.)
Nonetheless, there are some disadvantages of this technique.

-   There is subjectivity involved in the choice of precision for
    interpolation. The grid in my example seems a bit “too” granular
    around the San Antonio and Austin area, where it seems like there
    are no values at all! (Perhaps this is just an “operator error” on
    my behalf.)

-   `sf::st_interpolate_aw()` seems to only be capable of aggregating by
    sum (with `extensive = TRUE`) or mean (with `extensive = FALSE`).
    There are certainly some cases where other aggregation functions
    would be desirable. For my example, I actually would have preferred
    a maximum. An average is sensitive to area with a relatively small
    number of schools (that, consequently, may be “over”-emphasized by
    the value encoding); and a sum may too strongly emphasize areas with
    a large number of schools without providing any insight into their
    scores.

For comparison’s purposes, let’s look at what a choropleth map would
look like. I’ll need an additional data.frame for this
exercise—`schools_tea_filt_join`—which is just the `schools_tea_filt`
data joined with counties data that can be retrieved from a call to
`ggplot2::map_data()`.

``` {.r}
viz_schools_chlr <-
  ggplot() +
  geom_polygon(
    data = tx_border,
    aes(x = long, y = lat, group = group),
    size = 1.5,
    color = "black",
    fill = NA
  ) +
  geom_polygon(
    data = schools_tea_filt_join,
    aes(x = long, y = lat, group = group, fill = value),
  ) +
  geom_sf(
    data = hwys_sf,
    linetype = "solid",
    size = 0.1
  ) +
  geom_sf(
    data = cities_sf,
    shape = 16,
    size = 2,
    fill = "black"
  ) +
  ggrepel::geom_label_repel(
    data = cities_sf,
    aes(x = x, y = y, label = city_nm)
  ) +
  coord_sf(datum = NA) +
  scale_fill_viridis_c(option = "B", na.value = "#FFFFFF") +
  teplot::theme_map(legend.position = "bottom") +
  labs(
    title = str_wrap("Texas High School Math SAT Scores, 2015", 80),
    caption = "By Tony ElHabr."
  )
viz_schools_chlr
```

![](viz_schools_chlr-1.png)

This choropleth actually isn’t so bad, but I think I still prefer the
bubble grid.
