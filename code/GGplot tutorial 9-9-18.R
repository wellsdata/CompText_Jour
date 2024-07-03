#GGplot 2 Tutorial 9-9-18
#Files loaded to desktop: learn-chapter-4-master

---
  title: "Charts with ggplot2"
author: "Andrew Ba Tran"
output:
  html_document:
  toc: yes
toc_float: yes
description: http://learn.r-journalism.com/en/visualizing/
  ---
  
  
  
  This is from the [fourth chapter](http://learn.r-journalism.com/en/visualizing/charts_with_ggplot/ggplot2/) of [learn.r-journalism.com](https://learn.r-journalism.com/).

---
  title: "Charts with ggplot2"
description: "Applying the grammar of graphics to data visualizations"
author: "Andrew Ba Tran"
date: 2018-05-27T21:13:14-05:00
categories: ["R"]
tags: ["R", "ggplot2"]
weight: 1
slug: ggplot2
---
  
  Let's load some data, create a chart, and break down the layers.

We'll some data from [Vulture.com](http://www.vulture.com/2013/04/leading-men-age-but-their-love-interests-dont.html) comparing ages of leading men in movies compared to their love interests.

library(readr)
ages <- read_csv("data/ages.csv")
#Updated 10-7 - moved ages into the Collins working directory to imoport#
ages <- read_csv("ages.csv")
head(ages)
library(ggplot2)
View(ages)

This is the data we're working with.

The variables/columns are Movie, Genre, actor, actor_age, actress, actress_age, budget.

Here's the chart. Run this in your console.

```{r chart_example, warning=F, message=F}
# If you haven't installed the ggplot2 package yet, uncomment and run the line below
install.packages("ggplot2")


# Video 2 https://journalismcourses.org/mod/page/view.php?id=2530  #

library(ggplot2)

ggplot(data=ages) +
  geom_point(mapping=aes(x=actor_age, y=actress_age)) + 
  expand_limits(x = 0, y = 0) +
  geom_abline(intercept=0, col="light gray") 


#Other options for graphics: So geom_point() 
# geom_bar()
# geom_boxplot() # 
```

#Bar chart with actors in films. One variable
ggplot(data=ages,
       aes(x=actor)) +
    geom_bar()

####
ggplot(data=ages,
       aes(x=actor, fill=Genre)) +
    geom_bar()

ggplot(data=ages,
       aes(x=actor, color=Genre)) +
  geom_bar()

ggplot(data=ages,
       aes(x=actor), fill=Genre) +
  geom_bar()

ggplot(data=ages,
       aes(x=actor, fill=Genre)) +
    geom_bar(position="dodge")

ggplot(data=ages,
       aes(x=actor, fill=Genre)) +
  geom_bar(position="fill")

#Video 3: https://journalismcourses.org/mod/page/view.php?id=2536  #

ggplot(ages, aes(x=actress_age, y=actor, color=Genre)) +
  geom_jitter()

ggplot(ages, aes(x=actor, y=actress_age)) +
  geom_boxplot()

ggplot(ages, aes(x=actor, y=actress_age)) +
  geom_boxplot(notch=T)

ggplot(ages, aes(x=actor, y=actress_age)) +
  geom_violin()

# scaling

ggplot(ages, aes(x=actor_age)) +
  geom_histogram()

ggplot(ages, aes(x=actor_age)) +
  geom_histogram() + scale_x_log10()

# kernel density plot

ggplot(ages, 
       aes(x=actress_age)) +
    geom_density(fill="red")



ggplot(ages, 
       aes(x=actress_age, fill=actor)) +
  geom_density(alpha=.3)

# dot plot

ggplot(ages, 
       aes(x=actress_age, y=Movie)) +
  geom_point()

# line plot

library(dplyr)

avg_age <- ages %>% 
  group_by(actor) %>% 
  mutate(age_diff=actor_age-actress_age) %>% 
  summarize(average_age_diff=mean(age_diff))

ggplot(avg_age,
       aes(x=actor, y=average_age_diff, group=1)) +
    geom_line()

ggplot(avg_age,
       aes(x=actor, y=average_age_diff, group=1)) +
  geom_bar(stat="identity")

ggplot(avg_age,
       aes(x=actor, y=average_age_diff, group=1)) +
  geom_line() +
  geom_point(size=5)

## scatter fit

ggplot(ages,
       aes(x=actor_age,
           y=actress_age)) +
    geom_point() +
    geom_smooth()

## grouping

ggplot(ages,
        aes(x=actor_age,
            y=actress_age,
            color=actor)) +
    geom_point()

ggplot(ages,
       aes(x=actor_age,
           y=actress_age,
           color=actor,
           shape=Genre)) +
  geom_point()

ggplot(ages,
       aes(x=actor_age,
           y=actress_age,
           color=actor,
           shape=actor)) +
  geom_point()

ggplot(ages,
       aes(x=actor_age,
           y=actress_age,
           color=actor,
           size=budget)) +
  geom_point()

##coords

ggplot(avg_age,
        aes(x=actor, y=average_age_diff))+
      geom_bar(stat ="identity") +
      coord_flip()

# Video 4 Facets and small multiples
# https://journalismcourses.org/mod/page/view.php?id=2538




