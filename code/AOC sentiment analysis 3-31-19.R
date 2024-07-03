# AOC Sentiment Analysis 
# March 31, 2019
#Based on these tutorials: http://varianceexplained.org/r/trump-tweets/ 
#https://rtweet.info/
#https://rtweet.info/articles/auth.html


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

#------------------------------------------------------------------------------#
#                       LOAD PREVIOUSLY CREATED TABLES                         #
#------------------------------------------------------------------------------#


##Import AOC
AOC <- ArkCensus <- rio::import("./data/AOC.csv")

#Process date field
library(lubridate)
#Load dplyr
library(dplyr)
library(tidyr)
AOC2 <- AOC %>% 
  separate(created_at, c("date", "seconds"), " ")
#
some_date <- "2019-01-01"
ymd(some_date)
#
#New separate date field
AOC2$date2 <- ymd(AOC2$date)
str(AOC2)

AOC2$year <- year(AOC2$date2)
AOC2$month <- month(AOC2$date2, label=TRUE)
AOC2$day <- day(AOC2$date2)
AOC2$weekday <- wday(AOC2$date2, label=TRUE, abbr=FALSE)

#------------------------------------------------------------------------------#
#                       ANALYZE WORDS                       #
#------------------------------------------------------------------------------#
#from book: https://www.tidytextmining.com/tidytext.html #
#from tutorial: http://varianceexplained.org/r/trump-tweets/

#Define characters
reg <- "([^A-Za-z\\d#@']|'(?![A-Za-z\\d#@]))"
#
#
AOC2 <- AOC2 %>%
  filter(!str_detect(text, '^"')) %>%
  mutate(text = str_replace_all(text, "https://t.co/[A-Za-z\\d]+|&amp;", "")) %>%
  unnest_tokens(word, text, token = "regex", pattern = reg) %>%
  filter(!word %in% stop_words$word,
         str_detect(word, "[a-z]"))

#By Month
AOCmonth <- AOC2 %>%
  count(word, month) %>%
  filter(sum(n) >= 5) %>%
  spread(month, n, fill = 0) %>%
  ungroup()

#Don't count as separate devices#
AOCwords <- tweet_words %>%
  count(word) %>%
  filter(sum(n) >= 5) %>%
  ungroup()


#------------------------------------------------------------------------------#
#                               Sentiment Analysis
#------------------------------------------------------------------------------#
#Based on these tutorials: http://varianceexplained.org/r/trump-tweets/ 
# http://saifmohammad.com/WebPages/NRC-Emotion-Lexicon.htm
#NRC Word-Emotion Association lexicon, available from the tidytext package
#Associates words with 10 sentiments: positive, negative, anger, anticipation, disgust, fear, joy, sadness, surprise, and trust.

#Create a sentiment analysis table called nrc
nrc <- sentiments %>%
  filter(lexicon == "nrc") %>%
  dplyr::select(word, sentiment)

nrc

#------------------------------------------------------------------------------#  
#Count the number of words by screen_name:
#------------------------------------------------------------------------------#  
screen_name <- tweet_words %>%
    group_by(screen_name) %>%
    mutate(total_words = n()) %>%
    ungroup() %>%
    distinct(user_id, screen_name, total_words)

#------------------------------------------------------------------------------#
# Create a Table of Words and Sentiments
#------------------------------------------------------------------------------#

sentiment_words <- tweet_words %>%
  count(word) %>%
  inner_join(nrc, by = "word") %>% 
  select(word, sentiment, n) %>% 
  arrange(desc(n))
#
#By month
sentiment_month <- AOC2 %>% 
  count(word, month) %>%
  inner_join(nrc, by = "word") %>% 
  select(word, month, sentiment, n) %>% 
  group_by(month) %>% 
  arrange(desc(n))

#Sentiment by month
sentiment_month <- AOC2 %>% 
  count(word, month) %>%
  inner_join(nrc, by = "word") %>% 
  select(month, sentiment, n) %>% 
  arrange(desc(n))



#Export output this file to a CSV or Excel  write.csv or write.excel
write.csv(sentiment_words,"AOC_sentiment_words.csv")

#------------------------------------------------------------------------------#
#                 Summarizing Sentiments Based on AOC Screen Name
#------------------------------------------------------------------------------#

total_sentiment <- tweet_words %>%
  inner_join(nrc, by = "word") %>%
  count(sentiment, user_id) %>%
  ungroup() %>%
  complete(sentiment, user_id, fill = list(n = 0)) %>%
  inner_join(screen_name) %>%
  group_by(screen_name, sentiment, total_words) %>%
  summarize(words = sum(n)) %>%
  arrange(desc(words)) %>% 
  ungroup()

head(total_sentiment)

#Export output this file to a CSV or Excel  write.csv or write.excel
write.csv(total_sentiment,"AOC_total_sentiment.csv")

#------------------------------------------------------------------------------#
#      Create a Chart With Top Sentiments
#------------------------------------------------------------------------------#

library(forcats)
library(ggthemes)
#this works
ggplot(total_sentiment,
       aes(x=words, y=fct_reorder(sentiment, words, desc=TRUE))) +
  geom_point() +
  labs(x="Count of Words in Twitter Feed", y="Words", 
       title = "Sentiment In AOC Twitter 2018-2019",
       subtitle = "Chart: 3-31-19",
       caption = "Data analysis by Rob Wells") +
  theme_wsj() +
  geom_text(aes(label=words), hjust=-.4) 



#------------------------------------------------------------------------------#
# Anoter Version Count the number of words in each category of phone:
#------------------------------------------------------------------------------#

sources <- tweet_words %>%
  group_by(source) %>%
  mutate(total_words = n()) %>%
  ungroup() %>%
  distinct(user_id, source, total_words)

by_source_sentiment <- tweet_words %>%
  inner_join(nrc, by = "word") %>%
  count(sentiment, user_id) %>%
  ungroup() %>%
  complete(sentiment, user_id, fill = list(n = 0)) %>%
  inner_join(sources) %>%
  group_by(source, sentiment, total_words) %>%
  summarize(words = sum(n)) %>%
  ungroup()

head(by_source_sentiment)


#------------------------------------------------------------------------------#
# Analytics
#------------------------------------------------------------------------------#

library(broom)

sentiment_differences <- total_sentiment %>%
  group_by(sentiment) %>%
  do(tidy(poisson.test(.$words, .$total_words)))

sentiment_differences

#Export output this file to a CSV or Excel  write.csv or write.excel
write.csv(sentiment_differences,"AOC_sentiment_differences.csv")

ggsave("Collins Sentiment 10-26-18.png", width=30, height=20, units="cm")
