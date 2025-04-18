**Agenda**
  --R Markdown 

--R Markdown, Desktop Publishing
--Andrew Ba Tran - Week 5 Publishing
http://learn.r-journalism.com/en/publishing/
  --R Markdown
http://learn.r-journalism.com/en/publishing/rmarkdown/rmarkdown/
  --More R Markdown
http://learn.r-journalism.com/en/publishing/more_rmarkdown/more-rmarkdown/
  
  --Rendering html as an output in GitHub  
https://rmarkdown.rstudio.com/lesson-9.html
https://github.com/rstudio/cheatsheets/raw/master/rmarkdown-2.0.pdf

--R Markdown Formatting  
Sizing images:  <.img src="drawing.jpg" alt="drawing" width="200"/>  
  (Note: Remove the period before "img")
https://rpubs.com/RatherBit/90926

--Terminology

Render  
Html  
Markdown  

**Notes**
  R Markdown

This is an R Markdown document. Markdown is a simple formatting syntax for authoring HTML, PDF, and MS Word documents. For more details on using R Markdown see <http://rmarkdown.rstudio.com>.

When you click the **Knit** button a document will be generated that includes both content as well as the output of any embedded R code chunks within the document. You can embed an R code chunk like this:
  
  ```{r cars}
summary(cars)
```

Including Plots

You can also embed plots, for example:
  
  ```{r pressure, echo=FALSE}
plot(pressure)
```

Note that the `echo = FALSE` parameter was added to the code chunk to prevent printing of the R code that generated the plot.


Line breaks: Use HTML tags. Adding <br> will give a single line break --     option for when two-space indentation is ignored. 

