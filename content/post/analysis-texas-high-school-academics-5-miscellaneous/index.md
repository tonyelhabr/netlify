---
title: An Analysis of Texas High School Academic Competition Results, Part 5 - Miscellaneous
# slug: analysis-texas-high-school-academics-5-miscellaneous
date: "2018-05-20"
categories:
  - r
tags:
  - r
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

There's a lot to analyze with the Texas high school academic UIL data
set. Maybe I find it more interesting than others due to my personal
experiences with these competitions.

Now, after examining some of the biggest topics associated with this
data--including competitions, individuals, and schools--in a broad
manner, there are some other things that don't necessarily fall into
these categories that I think are worth investigating.

Siblings
--------

Let's look at the performance of siblings. Maybe this topic only came to
mind for me because I have brothers, on of who is my twin, but I think
anyone can find something interesting on this matter.

### Sibling Participation

So, let's start with something easy--which siblings competed together
the most?

<table class="table" style="margin-left: auto; margin-right: auto; color: #ffffff;">
<thead>
<tr>
<th>Rank</th>
<th>Last Name</th>
<th>First Names</th>
<th>Count</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>1</td>
<td>Zhang</td>
<td>Jim &amp; Mark</td>
<td>24</td>
</tr>
<tr class="even">
<td>2</td>
<td>Ballard</td>
<td>Chance &amp; Rance</td>
<td>22</td>
</tr>
<tr class="odd">
<td>3</td>
<td>Garcia</td>
<td>Javier &amp; Juan</td>
<td>20</td>
</tr>
<tr class="even">
<td>4</td>
<td>Walter</td>
<td>Collin &amp; Lowell</td>
<td>20</td>
</tr>
<tr class="odd">
<td>5</td>
<td>Bass</td>
<td>Brian &amp; Michael</td>
<td>19</td>
</tr>
<tr class="even">
<td>6</td>
<td>Fabre</td>
<td>Guadalupe &amp; Maria</td>
<td>19</td>
</tr>
<tr class="odd">
<td>7</td>
<td>Priest</td>
<td>Alex &amp; Chandler</td>
<td>18</td>
</tr>
<tr class="even">
<td>8</td>
<td>Vicuna</td>
<td>Bianca &amp; Daniel</td>
<td>17</td>
</tr>
<tr class="odd">
<td>9</td>
<td>Gee</td>
<td>Grace &amp; John</td>
<td>16</td>
</tr>
<tr class="even">
<td>10</td>
<td>Morris</td>
<td>Jason &amp; Ty</td>
<td>16</td>
</tr>
<tr class="odd">
<td>18</td>
<td>Elhabr</td>
<td>Andrew &amp; Anthony</td>
<td>13</td>
</tr>
</tbody>
</table>

**Note:** <sup>1</sup> \# of total rows: 2,289

Admittedly, I am a bit
disappointed to find that my twin brother and I are not at the very top
of this list. Nonetheless, we are fairly near the top, so I can take
some satisfaction in that. [^1]

I should note that the scraped data does not distinguish siblings, so I
had to define criteria to do so. To be specific, the table above
enforces the criteria that two people have the same last name, school,
and city, and that they compete in the exact same competition--that is,
a competition occurring in a given year and being of a same competition
type and same competition level (as well as the same conference and
competition area, if applicable). The numbers are inflated when not
enforcing the criteria that the two people must have competed in the
same competition type and level (nor conference and competition area),
and even more so when throwing out the criteria for same year.

### Sibling Performance

Participation in competitions is one thing, but what about sibling
performance? Let's use the same metric used elsewhere for ranking
performance--percent rank of scores summed across all records
(`prnk_sum`)--and see which sibling pairs show up among the top.

<table class="table" style="margin-left: auto; margin-right: auto; color: #ffffff;">
<thead>
<tr>
<th>Rank</th>
<th>Last Name</th>
<th>First Names</th>
<th>Count, Competition</th>
<th>Defeated</th>
<th>Count, State</th>
<th>Total Percent Rank</th>
<th>Best Rank</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>1</td>
<td>Priest</td>
<td>Alex &amp; Chandler</td>
<td>1,222</td>
<td>1,022</td>
<td>11</td>
<td>31.73</td>
<td>72</td>
</tr>
<tr class="even">
<td>2</td>
<td>Fabre</td>
<td>Guadalupe &amp; Maria</td>
<td>1,348</td>
<td>1,078</td>
<td>14</td>
<td>30.31</td>
<td>76</td>
</tr>
<tr class="odd">
<td>3</td>
<td>Walter</td>
<td>Collin &amp; Lowell</td>
<td>1,074</td>
<td>768</td>
<td>16</td>
<td>29.99</td>
<td>80</td>
</tr>
<tr class="even">
<td>4</td>
<td>Bass</td>
<td>Brian &amp; Michael</td>
<td>1,138</td>
<td>889</td>
<td>12</td>
<td>29.62</td>
<td>76</td>
</tr>
<tr class="odd">
<td>5</td>
<td>Gee</td>
<td>Grace &amp; John</td>
<td>896</td>
<td>711</td>
<td>10</td>
<td>26.28</td>
<td>64</td>
</tr>
<tr class="even">
<td>6</td>
<td>Morris</td>
<td>Jason &amp; Ty</td>
<td>852</td>
<td>625</td>
<td>11</td>
<td>24.13</td>
<td>64</td>
</tr>
<tr class="odd">
<td>7</td>
<td>Patterson</td>
<td>Ben &amp; Jeremy</td>
<td>994</td>
<td>708</td>
<td>9</td>
<td>22.30</td>
<td>62</td>
</tr>
<tr class="even">
<td>8</td>
<td>Alsup</td>
<td>Jon &amp; Mason</td>
<td>886</td>
<td>667</td>
<td>9</td>
<td>22.18</td>
<td>56</td>
</tr>
<tr class="odd">
<td>9</td>
<td>Vicuna</td>
<td>Bianca &amp; Daniel</td>
<td>1,056</td>
<td>653</td>
<td>3</td>
<td>21.39</td>
<td>68</td>
</tr>
<tr class="even">
<td>10</td>
<td>Beavers</td>
<td>Clay &amp; Cody</td>
<td>902</td>
<td>696</td>
<td>8</td>
<td>20.71</td>
<td>52</td>
</tr>
<tr class="odd">
<td>17</td>
<td>Elhabr</td>
<td>Andrew &amp; Anthony</td>
<td>788</td>
<td>481</td>
<td>5</td>
<td>16.89</td>
<td>52</td>
</tr>
</tbody>
</table>

**Note:** <sup>1</sup> \# of total rows: 1,787

It looks like the pairs at the top of these rankings based on score are
fairly similar to the list of pairs competing most frequently. (This is
not too surprising given that my choice of metric of ranking is based on
a summed value that "rewards" volume of participation rather than
per-competition performance.) Again, my twin brother and I appear near
the top.

My High School
--------------

Even though I highlighted my high school ("CLEMENS") in my examination
of schools and looked at individual scores elsewhere, I did not look at
other individuals that have gone to my school. Perhaps it is a bit
egotistical, but I am interested in knowing how I compare with others
that have attended my school (either before, with, or after me).

<table class="table" style="margin-left: auto; margin-right: auto; color: #ffffff;">
<thead>
<tr>
<th>Rank</th>
<th>Name</th>
<th>Count</th>
<th>Sum of Percent Rank</th>
<th>Avg. of Percent Rank</th>
<th>Sum of Defeated</th>
<th>Avg. of Defeated</th>
<th>Sum of Advanced</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>1</td>
<td>Land, Noah</td>
<td>17</td>
<td>13.67</td>
<td>0.80</td>
<td>447</td>
<td>26.29</td>
<td>14</td>
</tr>
<tr class="even">
<td>2</td>
<td>Fulton, Chris</td>
<td>18</td>
<td>12.66</td>
<td>0.70</td>
<td>351</td>
<td>19.50</td>
<td>16</td>
</tr>
<tr class="odd">
<td>3</td>
<td>Gonzales, Gavyn</td>
<td>17</td>
<td>12.26</td>
<td>0.72</td>
<td>371</td>
<td>21.82</td>
<td>15</td>
</tr>
<tr class="even">
<td>4</td>
<td>Elhabr, Andrew</td>
<td>15</td>
<td>9.87</td>
<td>0.66</td>
<td>296</td>
<td>19.73</td>
<td>11</td>
</tr>
<tr class="odd">
<td>5</td>
<td>Perry, Robert</td>
<td>15</td>
<td>8.75</td>
<td>0.58</td>
<td>249</td>
<td>16.60</td>
<td>10</td>
</tr>
<tr class="even">
<td>6</td>
<td>Garcia, Jon</td>
<td>9</td>
<td>7.94</td>
<td>0.88</td>
<td>259</td>
<td>28.78</td>
<td>6</td>
</tr>
<tr class="odd">
<td>7</td>
<td>Nesser, Austin</td>
<td>17</td>
<td>7.93</td>
<td>0.47</td>
<td>231</td>
<td>13.59</td>
<td>15</td>
</tr>
<tr class="even">
<td>8</td>
<td>Elhabr, Anthony</td>
<td>13</td>
<td>7.76</td>
<td>0.60</td>
<td>216</td>
<td>16.62</td>
<td>10</td>
</tr>
<tr class="odd">
<td>9</td>
<td>Guyott, David</td>
<td>9</td>
<td>5.37</td>
<td>0.60</td>
<td>157</td>
<td>17.44</td>
<td>7</td>
</tr>
<tr class="even">
<td>10</td>
<td>Baker, Ian</td>
<td>10</td>
<td>5.32</td>
<td>0.53</td>
<td>185</td>
<td>18.50</td>
<td>8</td>
</tr>
</tbody>
</table>

**Note:** <sup>1</sup> \# of total rows: 95

Alas, although my twin brother and I did not rank among the very top of
the siblings by participation and performance, we do appear among the
top when evaluating only people from my high school. In my opinion, the
sample size isn't so small that this achievement is trivial.

Wrap-Up
-------

I think all I've done here is more investigation of my personal
performance, so I'll spare the reader any more of my egotistical
exporation. And, with that said, I think this is a good point to bring
an end to my investigation of Texas high school academic UIL
competitions.

[^1]: I don't explicitly try to filter for twins only, but it's reasonable to believe that many, if not most, are twins.
