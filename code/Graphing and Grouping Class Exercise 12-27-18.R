Title: Graphic and Grouping Exercise

#Data: ny and sandyFlights data from Ch 7 and Ch 8 of Machlis book

#load this software
pacman::p_load(dplyr, janitor, ggplot2, geofacet, RColorBrewer)

#Graphing and Grouping: 
#What was the percent of cancelled flights each day 
#among flights that were supposed to leave during the Hurricane Sandy time period? 

#Create a data frame called departing_cancellations from the ny data. 
#Hint: You first want to filter for flights leaving JFK, LGA, and EWR; 
#group by day; summarize the number of cancellations and total flights; 
#and then calculate percents. (Answer is at the end of this chapter.)

#answer key below

departing_cancellations <- ny %>%
  filter(ORIGIN %in% c("JFK", "LGA", "EWR")) %>%
  filter(FL_DATE >= "2012-10-27", FL_DATE <= "2012-11-03",
  ) %>%
  group_by (FL_DATE, ORIGIN) %>%
  summarize(
    TotalCancelled = sum(CANCELLED),
    TotalFlights = n(),
    PctCancelled = (TotalCancelled / TotalFlights) * 100
  )

#Then plot your data

ggplot(departing_cancellations, aes(x=FL_DATE, y=PctCancelled, fill=ORIGIN)) + 
  geom_col(position="dodge") +
  theme(axis.text.x = element_text(angle = 45, vjust = 1.2, hjust = 1.1))