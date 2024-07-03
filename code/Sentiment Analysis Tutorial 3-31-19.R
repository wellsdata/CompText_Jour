#Sentiment Analysis Tutorial: Jane Austen
# March 31, 2019
#Exercises from Text Mining with R A Tidy Approach 
#By Julia Silge and David Robinson  2018-12-21
#
#https://www.tidytextmining.com/ 


library(tidytext)
sentiments

get_sentiments("afinn")
get_sentiments("bing")
get_sentiments("nrc")


#------------------------------------------------------------------------------#
#                    Turning a Book into TidyText                              #
#------------------------------------------------------------------------------#


#Sentiment analysis via inner join
#
#USING PREP_DATA.R AS TEMPLATE
library(readr)
library(devtools)
sensesensibility <- read_lines("http://www.gutenberg.org/cache/epub/161/pg161.txt", skip = 33)
sensesensibility <- sensesensibility[1:(length(sensesensibility) - 370)]
sensesensibility <- sensesensibility[!is.na(sensesensibility)]
#
#Look at what we loaded: a book
http://www.gutenberg.org/cache/epub/161/pg161.txt
#
library(janeaustenr)
library(dplyr)
library(stringr)

original_books <- austen_books() %>%
  group_by(book) %>%
  mutate(linenumber = row_number(),
         chapter = cumsum(str_detect(text, regex("^chapter [\\divxlc]",
                                                 ignore_case = TRUE)))) %>%
  ungroup()

original_books

#
#Built from this example
tidy_books <- austen_books() %>%
  group_by(book) %>%
  mutate(linenumber = row_number(),
         chapter = cumsum(str_detect(text, regex("^chapter [\\divxlc]", 
                                                 ignore_case = TRUE)))) %>%
  ungroup() %>%
  unnest_tokens(word, text)

#Sentiment dictionaries
nrc_joy <- get_sentiments("nrc") %>% 
  filter(sentiment == "joy")

tidy_books %>%
  filter(book == "Emma") %>%
  inner_join(nrc_joy) %>%
  count(word, sort = TRUE)

#Measure sentiment
library(tidyr)

jane_austen_sentiment <- tidy_books %>%
  inner_join(get_sentiments("bing")) %>%
  count(book, index = linenumber %/% 80, sentiment) %>%
  spread(sentiment, n, fill = 0) %>%
  mutate(sentiment = positive - negative)

#Plot
library(ggplot2)

ggplot(jane_austen_sentiment, aes(index, sentiment, fill = book)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~book, ncol = 2, scales = "free_x")

#

data(stop_words)

tidy_books <- tidy_books %>%
  anti_join(stop_words)
#
tidy_books %>%
  count(word, sort = TRUE) 
#
library(ggplot2)
#Quick Chart
#
tidy_books %>%
  count(word, sort = TRUE) %>%
  filter(n > 600) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n)) +
  geom_col() +
  xlab(NULL) +
  coord_flip()

