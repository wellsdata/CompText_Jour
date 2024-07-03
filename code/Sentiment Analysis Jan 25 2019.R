#--------Sentiment analysis ---- Jan 25 2019
# Updates the Collins Sentiment Analysis Notes from 10-13-18
#Based on these tutorials: http://varianceexplained.org/r/trump-tweets/ 
#https://rtweet.info/
#https://rtweet.info/articles/auth.html
#Text Mining with R A Tidy Approach Julia Silge and David Robinson  2018-12-21
#https://www.tidytextmining.com/ 

#Ch 2 
#The sentiments dataset

library(tidytext)
sentiments

get_sentiments("afinn")
get_sentiments("bing")
get_sentiments("nrc")


#------------------------------------------------------------------------------#
#                    Turning Articles into TidyText - YES!!!                         #
#------------------------------------------------------------------------------#


#Sentiment analysis via inner join
#
#USING PREP_DATA.R AS TEMPLATE
#library(readr)
#library(devtools)
#sensesensibility <- read_lines("http://www.gutenberg.org/cache/epub/161/pg161.txt", skip = 33)
#sensesensibility <- sensesensibility[1:(length(sensesensibility) - 370)]
#sensesensibility <- sensesensibility[!is.na(sensesensibility)]

#WITH NYT DATA
library(dplyr)
library(stringr)
library(readr)
install.packages("devtools")
library(devtools)
NYT <- read_lines("NYT1_26.txt")
NYT <-as.data.frame(NYT)

#skipped these two lines in tutorial. one removes trailing data
#the other does something with na
#NYT <- NYT[1:(length(NYT) - 370)]
#NYT<- NYT[!is.na(NYT)]


# another method Rename a specific column


colnames(NYT)[1] <- "Text"

#Replace this text string with "STARTOFARTICLE"
____________________________________________________________
#group$group.no.e <- 
#gsub("thingtoreplace", "replacementstring", group$group)
#
NYT$Start <- 
      gsub("____________________________________________________________", 
       "STARTOFARTICLE", NYT$Text)

#TidyTable - And this works!!!
#
#Built from this example
#tidy_books <- austen_books() %>%
#  group_by(book) %>%
#  mutate(linenumber = row_number(),
#         chapter = cumsum(str_detect(text, regex("^chapter [\\divxlc]", 
#                                                 ignore_case = TRUE)))) %>%
#  ungroup() %>%
#  unnest_tokens(word, text)
#
#
#Creates an index, numbering each line per article.
NYT2 <- NYT %>%
  mutate(linenumber = row_number(),
  newarticle = cumsum(str_detect(Start, regex("STARTOFARTICLE", 
                                                 ignore_case = TRUE, na.rm=TRUE)))) %>%
  ungroup()

#Delete blank cells
#df[!(is.na(df$start_pc) | df$start_pc==""), ]
NYT2 <- NYT2[!(is.na(NYT2$Start) | NYT2$Start==""), ]

#Delete ProQuest metadata
#"New York Times" and publication and the Proquest metadata is deleted
## Example - Sample Data
#https://stackoverflow.com/questions/22127342/how-to-remove-rows-in-a-dataframe-that-contain-certain-words-in-r
#NO <- c(34, 42, 21, 3)
#ARTICLE <- c('New York Times reports blah blah fake news',
             'Financial Times blah blah',
             'Fox News has been very nice to me',
             'Newswire reports blah blah')
#df <- data.frame(NO, ARTICLE)

# Create List of Exclusion Phrases
#fakenews <- c('New York Times', 'Newswire')

# Exclude
#very.nice.to.me <- df[ !grepl(paste(fakenews, collapse="|"), df$ARTICLE),]
NYT3 <- NYT2
# Create List of Exclusion Phrases
cutmeta <- c('Author:', 'Publication Info', 'http://',
             'Company:', 'Country of publication:', 'Dateline:', 'Document feature:', 
             'Document type:', 'Location:', 'Number of pages:', 'Place of publication:', 
             'Publication title:', 'Publication year:', 'Publisher:', 'Section:', 
             'Source type:', 'Subject:', 'Company / organization: ', 'Credit:') 


# Exclude
NYT4 <- NYT3[ !grepl(paste(cutmeta, collapse="|"), NYT3$Start),]

#Table of Articles, Titles and Numbers
#Thanks to https://blog.exploratory.io/filter-with-text-data-952df792c2ba
#Finally, this mofo works. Example:
#flight %>%
#select(FL_DATE, CARRIER, ORIGIN, ORIGIN_CITY_NAME, ORIGIN_STATE_ABR, DEP_DELAY, DEP_TIME, ARR_DELAY, ARR_TIME) %>%   
#  filter(str_detect(ORIGIN_CITY_NAME, "New York"))


NYT_Tidy_Headlines <- NYT4 %>%
  select(Start, newarticle) %>%   
  filter(str_detect(Start, "Title: "))

#Rename Columns
#setnames(d, old = c('a','d'), new = c('anew','dnew'))
library(data.table)
setnames(NYT4, old = c('Text', 'Start', 'linenumber', 'newarticle'), new = c('x', 'text', 'line', 'article_nmbr'))
NYT4 <- select(NYT4, c(text, line, article_nmbr))

#Reindex the DF
NYT4 <- NYT4 %>%
  mutate(linenumber = row_number())

#random cleanup - may not need to run these lines
#NYT4 <- select(NYT4, c(headline, linenumber, article_nmbr))
#colnames(NYT4)[2] <- "line"


#Rename Columns
#setnames(d, old = c('a','d'), new = c('anew','dnew'))
library(data.table)
setnames(NYT_Tidy_Headlines, old = c('Start','newarticle'), new = c('headline','article_nmbr'))

#Join NYT_tidy_Headlines to other Data
#sandyCancelled <- left_join(sandyCancellationsPcts, carriers, by = c("CARRIER" = "Code"))

NYT_tidy <- inner_join(NYT_Tidy_Headlines, NYT4, by =c("article_nmbr" = "article_nmbr"))
NYT_tidy <- select(NYT_tidy, c(headline, article_nmbr, text, linenumber))

write.csv(NYT_tidy,"NYT_tidy.csv")

#Tokenize the NYT table
library(tidytext)
reg <- "([^A-Za-z\\d#@']|'(?![A-Za-z\\d#@]))"
NYT_token <- NYT_tidy %>%
  filter(!str_detect(text, '^"')) %>%
  mutate(text = str_replace_all(text, "https://t.co/[A-Za-z\\d]+|&amp;", "")) %>%
  unnest_tokens(word, text, token = "regex", pattern = reg) %>%
  filter(!word %in% stop_words$word,
         str_detect(word, "[a-z]"))

#Clean out ' character in word columm of NYT_token
#example: 'growing
NYT_token$word2 <- 
  gsub("'","", NYT_token$word)

NYT_token <- select (NYT_token, c(headline, article_nmbr, linenumber, word2))
colnames(NYT_token)[4] <- "word"

#Table of Common Words
CommonNYTWords <- NYT_token %>%
  count(word) %>%
  filter(sum(n) >= 5) %>%
  ungroup()

write.csv(CommonNYTWords,"CommonNYTWords.csv")

#Create a sentiment analysis table called nrc
nrc <- sentiments %>%
  filter(lexicon == "nrc") %>%
  dplyr::select(word, sentiment)

# Create a Table of Words and Sentiments
totalwords <- NYT_token %>%
  group_by(article_nmbr) %>%
  mutate(total_words = n()) %>%
  ungroup() %>%
  distinct(article_nmbr, total_words)

library(tidyselect)
NYT_sentiment <- CommonNYTWords %>%
  inner_join(nrc, by = "word") %>% 
  select(word, sentiment, n) %>% 
  arrange(desc(n))


#Export output this file to a CSV or Excel  write.csv or write.excel
write.csv(NYT_sentiment,"NYT_sentiment.csv")


#------------------------------------------------------------------------------#
#                 Summarizing Sentiments 
#------------------------------------------------------------------------------#

library(tidyselect)
library(dplyr)

total_NYTsentiment <- CommonNYTWords %>%
  inner_join(nrc, by = "word") %>%
  count(sentiment) %>%
  ungroup() %>%
  group_by(sentiment, nn) %>%
  summarize(words = sum(nn)) %>%
  arrange(desc(words)) %>% 
  ungroup()


total_NYTsentiment <- select (total_NYTsentiment, c(-nn))

#Export output this file to a CSV or Excel  write.csv or write.excel
write.csv(total_NYTsentiment,"total_NYTsentiment.csv")

#------------------------------------------------------------------------------#
#                     Collins Sentiment Analysis Script - Awesome!!!!          #
#------------------------------------------------------------------------------#


#Set Working Directory#
setwd("~/Dropbox/Current Projects Sept 2018/Collins Twitter")
#load packages needed for this; needs to be done every time
#these are all part of tidyverse
library(tidyverse)
#for importing csv file
library(readr) 
#for analysis
library(dplyr) 
#for creating charts
library(ggplot2)  
#for working with dates
library(lubridate)
#themes for data viz
library(ggthemes) 
#Install procedure
install.packages("twitteR")
library(purrr)
library(twitteR)
## install rtweet from CRAN
install.packages("rtweet")
## load rtweet
library(rtweet)
#load stringr to analyze text strings
install.packages("stringr")
#text analysis package
install.packages("tidytext") 
library(tidytext)



## install httpuv if not already
if (!requireNamespace("httpuv", quietly = TRUE)) {
  install.packages("httpuv")
}
#------------------------------------------------------------------------------#
#                       LOAD PREVIOUSLY CREATED TABLES                         #
#------------------------------------------------------------------------------#


##Import Collins2
library(readr)
Collins2 <- read_csv("collins2.csv")
Collins2 <- read_csv(file.choose())


##Import the other tables created
Collins_URLS <- read_csv("Collins_URLS.csv")
Trump_Collins <- read.csv("Trump_Collins.csv")
Collins_URL_Detail <- read_csv("Collins_URL_Detail.csv")

#------------------------------------------------------------------------------#
#----------  ANALYZE WORDS ---------------#
#------------------------------------------------------------------------------#
#from book: https://www.tidytextmining.com/tidytext.html #
#from tutorial: http://varianceexplained.org/r/trump-tweets/

reg <- "([^A-Za-z\\d#@']|'(?![A-Za-z\\d#@]))"
tweet_words <- Collins2 %>%
  filter(!str_detect(text, '^"')) %>%
  mutate(text = str_replace_all(text, "https://t.co/[A-Za-z\\d]+|&amp;", "")) %>%
  unnest_tokens(word, text, token = "regex", pattern = reg) %>%
  filter(!word %in% stop_words$word,
         str_detect(word, "[a-z]"))

tweet_words

CommonCollinsWords <- tweet_words %>%
  count(word, source) %>%
  filter(sum(n) >= 5) %>%
  spread(source, n, fill = 0) %>%
  ungroup()

#Don't count as separate devices#
CommonCollinsWords <- tweet_words %>%
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
#Export output this file to a CSV or Excel  write.csv or write.excel
write.csv(sentiment_words,"sentiment_words.csv")

#------------------------------------------------------------------------------#
#                 Summarizing Sentiments Based on Collins Screen Name
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
write.csv(total_sentiment,"total_sentiment.csv")

#------------------------------------------------------------------------------#
# Analytics
#------------------------------------------------------------------------------#

library(broom)

sentiment_differences <- total_sentiment %>%
  group_by(sentiment) %>%
  do(tidy(poisson.test(.$words, .$total_words)))

sentiment_differences

#Export output this file to a CSV or Excel  write.csv or write.excel
write.csv(sentiment_differences,"sentiment_differences.csv")


#------------------------------------------------------------------------------#
#      Create a Chart With Top Sentiments
#------------------------------------------------------------------------------#

library(forcats)
#this works
ggplot(total_sentiment,
       aes(x=words, y=fct_reorder(sentiment, words, desc=TRUE))) +
  geom_point() +
  labs(x="Count of Words in Twitter Feed", y="Words", 
       title = "Sentiment In Collins Twitter April-August 2018",
       subtitle = "Draft Data, Oct 13, 2018",
       caption = "Data analysis by Rob Wells") +
  theme_wsj() +
  geom_text(aes(label=words), hjust=-.4) 


ggsave("Collins Sentiment 10-26-18.png", width=30, height=20, units="cm")


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

library(broom)

sentiment_differences <- by_source_sentiment %>%
  group_by(sentiment) %>%
  do(tidy(poisson.test(.$words, .$total_words)))

sentiment_differences
