1. Create page bundle folder.
If Rmarkdown-converted rmd-to-md file exists, copy it 
to page bundle folder and rename it to "index.md". (These are "easier".)
Otherwise, use the pandoc-converted html-to-md file. (These are "harder".)
2. Clean up the post.
    - Clean up footnotes ands "div" tags, and possibly also "img" tags.
    (If using an html-to-md converted file, there will be more of these changes.)
    
    - Replace yaml font-matter with existing rmd yaml font-matter and update
    it to most recent academic theme format. See below for an example.
    
    - May need to fix tables "manually" by copying table from html file.
    
    ```
    title: An Analysis of Texas High School Academic Competition Results, Part 1 - Introduction
    # slug: analysis-texas-high-school-academics-intro
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
    ```
    
    - Add existing images to page bundle folder and
    clean up md references to images. (Possibly remove "-1" suffix? <- No).
        - Identify images that are not being used.
        Distinguish these by moving them in a trivial subdirectory (e.g. "unused").
    
3. Make a copy of the image to feature and rename it "featured.jpg".
 
...

After all updates, review each post individually and check for bugs.
(It's probably more tedious to do this after updating each individual post.)

--------------------------------------------------------------------------------

# Regular Expression Helpers

(Tip: work from the bottom of the page going up when replacing simple regular expressions.)

For images...
what: <img src="(.*)\" s.*
replace with: ![]\(\1\)

what: \{width.*
replace with: 

For in-text footnotes...
what: \^\]\(\#.*footnoteRef\}
replace with: ]

For bottom footnotes...
what: ^([0-9])+\.\s+
replace with: [^\1]: 

what: \[↩].*
replace with: 

what: \r\n    (4 spaces)
replace with:  (1 space)

# Find-Replace Helpers

For html tables... (Tip: Use "Replace All", starting from the top of the page, AFTER all
tables are fixed (so that there is no need to replace more than once.)

what:  class="table" style="width: auto !important; margin-left: auto; margin-right: auto;"
replace with: 

what: style="text-align:left;"
replace with: 

what: style="text-align:right;"
replace with: 

Or, with regular expressions, use.
what: \sstyle=\"text-align:.*
replace with: >

Then, to make things cleaner...

what: <t([dh])>\r?\n?(.*?)\r?\n?<\/t([dh])>
replace with: <t\1>\2</t\3>