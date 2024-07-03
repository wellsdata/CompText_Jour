#Title: Machlis - Basic Data Visualization
#UpdatedJan 30 2019


#load software - Select NO when asked to restart
install.packages("ggplot2")
install.packages("dplyr")
install.packages("usethis")
install.packages("forcats")

#call software into memory
library(ggplot2)
library(dplyr)
library(usethis)
library(forcats)

#Basic demo
#You will run the commands from the Console below
demo(topic="graphics")

library(dplyr)

#Tutorial
#Import Data, Create Dataframe, Rename Columns
snowdata <- rio::import("data/BostonChicagoNYCSnowfalls.csv")
bostonsnow <- select(snowdata, Winter, Boston)
names(bostonsnow)[2] <- "TotalSnow"

#Doing the same thing but with pipe function
bostonsnow2 <- select(snowdata, Winter, Boston) %>%
  rename(TotalSnow = Boston)

#Doing the same thing but more efficiently
bostonsnow3 <- select(snowdata, Winter, TotalSnow = Boston) 

#Basic graphs
plot(bostonsnow$TotalSnow)

hist(bostonsnow$TotalSnow)
boxplot(bostonsnow$TotalSnow)
barplot(bostonsnow$TotalSnow)
barplot(sort(bostonsnow$TotalSnow, decreasing = TRUE))

#qplot
qplot(data=bostonsnow, y = TotalSnow)
qplot(y = bostonsnow$TotalSnow)

#basic ggplot2 - boxplot
ggplot(data=snowdata) + 
  geom_boxplot(aes(x = "Boston", y = Boston))

#dual box plots
ggplot(data=snowdata) + 
  geom_boxplot(aes(x = "Boston", y = Boston)) +
  geom_boxplot(aes(x = "Chicago", y = Chicago))

#bring in snowdata tidy
snowdata_tidy <- rio::import("data/snowdata_tidy.csv")

#view a tidy table
View(snowdata_tidy)

#Boxplot with ggplot
ggplot(snowdata_tidy, aes(x = City, y = TotalSnow)) +
  geom_boxplot()

#Line graphs
ggplot(snowdata_tidy, aes(x = Winter, y = TotalSnow, group = City)) +
  geom_line()

#ggplot with colors and points

ggplot(snowdata_tidy, aes(x = Winter, y = TotalSnow, group = City, color = City)) +
  geom_line()


#ggplot with colors and points
ggplot(snowdata_tidy, aes(x = Winter, y = TotalSnow, group = City, color = City)) +
  geom_line() +
  geom_point() 

#Filtered for two years, 1999 and 2000
snowdata_tidy21 <- filter(snowdata_tidy, Winter >= "1999-2000")
ggplot(snowdata_tidy21, aes(x = Winter, y = TotalSnow, group = City, color = City)) +
  geom_line() +
  geom_point()

#Barplots
ggplot(data = snowdata_tidy21, aes(x = Winter, y = TotalSnow, group = City, color = City)) +
  geom_col() 

#Not so ugly bars
ggplot(data = snowdata_tidy21, aes(x = Winter, y = TotalSnow, group = City, fill = City)) +
  geom_col(position = "dodge") 

#-------------------------------------------------------------------#
#Build a chart - Snow
#-------------------------------------------------------------------#

library(ggplot2)
SnowChartBoston <- ggplot(bostonsnow, aes(x = reorder(Winter, TotalSnow), y = TotalSnow))  +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = "Snow", 
       subtitle = "lots of it",
       caption = "Graphic by Rob Wells",
       x="Years",
       y="snow in inches")
plot(SnowChartBoston)


#Notes from R for Data Scientists - Wickham
#https://r4ds.had.co.nz/

#Feb. 2 2019
install.packages('tidyverse')
install.packages(c("nycflights13", "gapminder", "Lahman"))

#If we want to make it clear what package an object comes from, we’ll use the package name followed by two colons, like dplyr::mutate(), or
#nycflights13::flights. This is also valid R code.

library(tidyverse)


#Do cars with big engines use more fuel than cars with small engines? 
#displ, a car’s engine size, in litres.
#hwy, a car’s fuel efficiency on the highway, in miles per gallon (mpg). 
#A car with a low fuel efficiency consumes more fuel than a car with a high fuel efficiency when they travel the same distance.
#To learn more about mpg, open its help page by running ?mpg.

mpg

#Create a ggplot
ggplot(data = mpg) + 
  geom_point(mapping = aes(x = displ, y = hwy))

#3.2.3 A graphing template
#Let’s turn this code into a reusable template for making graphs with ggplot2. 
#To make a graph, replace the bracketed sections in the code below with a dataset, a geom function, or a collection of mappings.
#ggplot(data = <DATA>) + 
#  <GEOM_FUNCTION>(mapping = aes(<MAPPINGS>))

ggplot(data = mpg)

#using color to distinguish class
ggplot(data = mpg) + 
  geom_point(mapping = aes(x = displ, y = hwy, color = class))

#MPG categorical = manufacturer model cyl trans drv fl class
#continuous = disply cty hwy
#Map a continuous variable to color, size, and shape. 
#How do these aesthetics behave differently for categorical vs. continuous variables?
#Answer - they do not come up in discrete blocks by on a spectrum range

#Color by manufacturer
ggplot(data = mpg) + 
  geom_point(mapping = aes(x = displ, y = hwy, color =manufacturer))

#Color and Size
ggplot(data = mpg) + 
  geom_point(mapping = aes(x = displ, y = hwy, color =manufacturer, size=manufacturer))


#adding size
ggplot(data = mpg) + 
  geom_point(mapping = aes(x = displ, y = hwy, size = class, color = class))

#What does the stroke aesthetic do? What shapes does it work with? (Hint: use ?geom_point)
ggplot(data = mpg) + 
  geom_point(mapping = aes(x = displ, y = hwy, color = class, stroke=20))

#What happens if you map an aesthetic to something other than a variable name, 
#like aes(colour = displ < 5)? Note, you’ll also need to specify x and y.

ggplot(data = mpg) + 
  geom_point(mapping = aes(x = displ, y = hwy, color = displ < 5))

#It gives you a true false by color

#Exercise:
#Exercise with ArkCo_Income_2017
#1. Create a plot chart with the top 10 counties with the greatest percentage of low-income population
#Your answer should look like this
https://bit.ly/2BgPmyo

#2. Create a plot chart with the top 10 counties with the greatest percentage of upper-income population






