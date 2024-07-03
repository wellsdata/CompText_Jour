# Sentiment Analysis Over Time
#  April 10, 2019
#Based on these tutorials: http://varianceexplained.org/r/trump-tweets/ 
#https://rtweet.info/
#https://rtweet.info/articles/auth.html
#
#Set Working Directory#
setwd("Your directory")
#load packages needed for this; needs to be done every time
#these are all part of tidyverse

#Install packages if you haven't already
#install.packages("twitteR")
#install.packages("rtweet")
#install.packages("stringr")
#install.packages("tidytext") 
## install httpuv if not already
if (!requireNamespace("httpuv", quietly = TRUE)) {
  install.packages("httpuv")
}

#Call libraries
library(twitteR)
library(rtweet)
library(stringr)
library(tidytext)
library(tidyverse)
library(lubridate)
library(ggthemes) 
library(purrr)
library(rio)
library(tidyr)

#------------------------------------------------------------------------------#
#                       Load and Process Tables of Twitter Data                #
#------------------------------------------------------------------------------#

#
#Import Twitter data
AOC <- rio::import("./data/AOC.csv")
#
#Smaller table for this exercise
#
AOC2 <- select(AOC, V1, user_id, created_at, screen_name, 
               text, source, is_retweet, favorite_count, 
               retweet_count, hashtags)
#
#Process with lubridate
#
AOC3 <- AOC2 %>% 
  separate(created_at, c("date", "seconds"), " ")
#
some_date <- "2019-01-01"
ymd(some_date)
#
#New separate date field
AOC3$date2 <- ymd(AOC3$date)
str(AOC3)
#
#Disaggregate by day, month, weekday
#
AOC3$year <- year(AOC3$date2)
AOC3$month <- month(AOC3$date2, label=TRUE)
AOC3$day <- day(AOC3$date2)
AOC3$weekday <- wday(AOC3$date2, label=TRUE, abbr=FALSE)

#------------------------------------------------------------------------------#
#                       ANALYZE WORDS                       #
#------------------------------------------------------------------------------#
#from book: https://www.tidytextmining.com/tidytext.html #
#from tutorial: http://varianceexplained.org/r/trump-tweets/

#Define characters
reg <- "([^A-Za-z\\d#@']|'(?![A-Za-z\\d#@]))"
#
#
AOC4 <- AOC3 %>%
  filter(!str_detect(text, '^"')) %>%
  mutate(text = str_replace_all(text, "https://t.co/[A-Za-z\\d]+|&amp;", "")) %>%
  unnest_tokens(word, text, token = "regex", pattern = reg) %>%
  filter(!word %in% stop_words$word,
         str_detect(word, "[a-z]"))

#By Month
AOCmonth <- AOC4 %>%
  count(word, month) %>%
  filter(sum(n) >= 5) %>%
  spread(month, n, fill = 0) %>%
  ungroup()

#Don't count as separate months#
AOCwords <- AOC4 %>%
  count(word) %>%
  filter(sum(n) >= 5) %>%
  ungroup() %>% 
  arrange(desc(n))


#------------------------------------------------------------------------------#
#                               Sentiment Analysis
#------------------------------------------------------------------------------#
#Based on these tutorials: http://varianceexplained.org/r/trump-tweets/ 
# http://saifmohammad.com/WebPages/NRC-Emotion-Lexicon.htm
#install.packages("sentimentr")
library(sentimentr)

#The sentiments dataset
library(tidytext)
sentiments

get_sentiments("afinn")
get_sentiments("bing")
get_sentiments("nrc")

#Sentiments
#AFINN rates words positive - negative: https://rdrr.io/cran/corpus/man/sentiment_afinn.html
AFINN <- get_sentiments("afinn")
#
#Tidy table, date for AOC - Twitter data
tidy_AOC <- AOC4 %>%
  group_by(date2) %>%
  mutate(linenumber = row_number(),
         tweet_number = V1)

#Joins the Twitter data to sentiment scoring
AOC_afinn <- AOC4 %>% 
  inner_join(get_sentiments("afinn")) %>% 
  group_by(V1) %>% 
  summarise(sentiment = sum(score)) 
#
#Basic plot according to Tweet in sequence
#
ggplot(AOC_afinn, aes(V1, sentiment, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  labs(title = "Sentiment of AOC Tweets", 
       subtitle = "Postive, Negative Sentiment in AOC Tweets, 2018-2019",
       caption = "Measured by Tweet. Source: Twitter 
       Graphic by Rob Wells",
       x="Specific Tweet",
       y="Sentiment, Positive or Negative") +
  theme(legend.position="none")
#
#Using date as grouping variable
#
AOC_Date <- AOC4 %>% 
  inner_join(get_sentiments("afinn")) %>% 
  group_by(V1, date2) %>% 
  summarise(sentiment = sum(score)) %>% 
  arrange(desc(sentiment))
#
#Adding sentiment score to the full corpus of Tweets
#This is a big deal
#
AOC3a <- AOC_Date %>%
  inner_join(AOC3) %>% 
  group_by(V1, date2)
#
#That gives us 2020 observations. But we had 3193 Tweets.
#
#Try this: Gives us 3193 observations
#
AOC3b <- AOC_Date %>%
  full_join(AOC3) %>% 
  group_by(V1, date2)
#
#Question: What are the issues between AOC3a and AOC3b?
#
#Question: Find the most negative tweet.
#Hint: kable might be useful for reading the text
#
#Question: Create a table with tweets with a rating more negative than -10.
#Question: Create a table with tweets with a rating more positive than 10.
#Hint: Dplyr is your buddy
#
#------------------------------------------------------------------#
#  Sentiment Over Time
#------------------------------------------------------------------#
#
#Here it is, plotting sentiment over time
ggplot(AOC_Date, aes(date2, sentiment, color = sentiment, fill=sentiment)) +
  geom_col(show.legend = FALSE) +
  labs(title = "AOC Tweets: Sentiment", 
       subtitle = "Postive, Negative Sentiment in AOC Tweets, 2018-2019",
       caption = "Source: Twitter 
       Graphic by Rob Wells",
       x="Month",
       y="Sentiment, Positive or Negative") +
  theme(legend.position="none")
#
#Question: Which time periods had the most negative sentiment?
#Filter those time periods
#
#Revel in your nerd powers
#
#Question: Now, figure out the same thing with Ann Coulter's tweets




