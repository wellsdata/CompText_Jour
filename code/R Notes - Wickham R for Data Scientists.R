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


#left - right

# Left
ggplot(data = mpg) + 
  geom_point(mapping = aes(x = displ, y = hwy, alpha = class))

# Right
ggplot(data = mpg) + 
  geom_point(mapping = aes(x = displ, y = hwy, shape = class))

#Facets

ggplot(data = mpg) + 
  geom_point(mapping = aes(x = displ, y = hwy)) + 
  facet_wrap(~ manufacturer, nrow = 2)

#exercises
ggplot(data = mpg) + 
  geom_point(mapping = aes(x = drv, y = cyl))

#geoms
ggplot(data = mpg) + 
  geom_smooth(mapping = aes(x = displ, y = hwy))

#map
install.packages("maps")
nz <- map_data("nz")

map('county', 'arkansas', fill = TRUE, col = palette())

map.cities(us.cities, state="AR", fill = TRUE, col = palette())

# names of the San Juan islands in Washington state
map('county', 'washington,san', names = TRUE, plot = FALSE)


map("state", "Arkansas")
data(us.cities)
map.cities(us.cities, state="AR", fill = TRUE, col = palette())

ar <- (us.cities, state='AR')


ggplot(nz, aes(long, lat, group = group)) +
  geom_polygon(fill = "white", colour = "black")

ggplot(nz, aes(long, lat, group = group)) +
  geom_polygon(fill = "white", colour = "black") +
  coord_quickmap()


