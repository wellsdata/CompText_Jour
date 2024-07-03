# DPLYR Bootcamp
# Rob Wells - *Updated* Feb 13 2019


library(dplyr)

#Remember from Dplyr Presentation 
#Five basic verbs in Dplyr
#• filter() • select() • arrange() • mutate() • summarize() group_by()

#-----------------------------------------------#
#Task #1: Build yourself a dplyr cheat sheet. 

#Search the tutorials and exercises so far. That would be Intro_to_R, Downloading Data, Basic Data Visualization, Answer to Monday Feb 4 Exercise.

#Find examples of all of these (except summarise, which I provided). Copy those examples on this grid below. 

#This is boot camp! Do it now!!


#filter()

#select()

#arrange()

#mutate()

#summarize()
#summarise()
summarize(murders, average_victim_age=mean(VicAge))

#group_by()

#Pipes: pipe %>% 

#Find the vignette on dplyr - copy the URL for the "Introduction to dplyr" file


#----------------------------------------------------------#

#Task #2
#With those examples, use the DPLYR vignette to include basic definitions of these operations. For example:
#  summarise() =  to condense multiple values to a single value.

#This is boot camp! Hurry!!

#Hand it in end of the class. Blackboard.

#----------------------------------------------------------#
#Task 3
#Use your cheat sheet to answer the following questions
#from this dataset: 
https://github.com/profrobwells/Data-Analysis-Class-Jour-405v-5003/blob/master/Data/ArkCampusCrime.xlsx

ArkCampusCrime <- rio::import('./Data/ArkCampusCrime.xlsx') 

#Clean labels with janitor
#check the column names
#check datatypes with str
#backup your data with write.csv


#1: Filter the entire table for just UA Fayetteville
#Put results in dataframe called Fayetteville


#2: Filter entire ArkCampusCrime table for Fayetteville and Little Rock
#Put results in dataframe called FAYLR
#Hint ??filter, look for dplyr. See multiple criteria

#3: Select a table with limited columns
#Table with university_college, campus, enrollment, violent and property crime
#Result in table called Main

#4: Arrange table to sort descending by property crime.
#Dump results into PropertyCrime

#5: Mutuate - Create New Column with Total Crimes
#Put results in table TotalCrime
#Hint: see vignette on how to use actual column names to add things

#mutate() mutate() and transmute() to add new variables that are functions of existing variables.

#6: Calculate a violate crime rate per 1,000 students. 
#Create a table selecting campuses, enrollment and crime rates 
#just for the top 5 crime rates

#--------------------------------------#
#     Now We Will Graph                #
#--------------------------------------#

library(ggplot2)

#Refer to Basic Data Visualization 2-4-19.R for the following

#1: Create a histogram of campus violentrate

#Basic plot of violentrate

#Histogram of property crime

#Box Plot

#Dual box plots

#2: Graph the top 5 by violent rate in a chart
#For guidance, see Answer Key to Assignment #1
#Do the Katie Serrano special and add some killer colors

#3: Super Nerd Bonus Question: Dual Chart Violent and Property Crime
#For Guidance, Dual Chart was in Basic Data Visualization 2-4-19.r
