#Bigrams and Sentiment - Updated April 22 2019
#
#-------------------------------------------------------------------------#
#    Tokenize Table
#-------------------------------------------------------------------------#

#Create the Coulter3 table - see Sentiment and Time Analysis 4-9-19
#Import Twitter data
Coulter <- rio::import("./data/Coulter.csv")
#
#Smaller table for this exercise
#
Coulter2 <- select(Coulter, V1, user_id, created_at, screen_name, 
                   text, source, is_retweet, favorite_count, 
                   retweet_count, hashtags)
#
#Process with lubridate
#
Coulter3 <- Coulter2 %>% 
  separate(created_at, c("date", "seconds"), " ")
#
some_date <- "2019-01-01"
ymd(some_date)
#
#New separate date field
Coulter3$date2 <- ymd(Coulter3$date)
str(Coulter3)
#
#Disaggregate by day, month, weekday
#
Coulter3$year <- year(Coulter3$date2)
Coulter3$month <- month(Coulter3$date2, label=TRUE)
Coulter3$day <- day(Coulter3$date2)
Coulter3$weekday <- wday(Coulter3$date2, label=TRUE, abbr=FALSE)



#-------------------------------------------------#
# Analyze sentiment by bigrams
#-------------------------------------------------#
#from Ch 4, https://www.tidytextmining.com/ngrams.html
#
#austen_bigrams <- austen_books() %>%
#  unnest_tokens(bigram, text, token = "ngrams", n = 2)
#
#Eliminate https and t.co
Coulter3 <- Coulter3 %>%
  mutate(text = str_replace_all(text, "https://t.co/", "")) 
  
Coulter_bigrams <- Coulter3 %>%
  unnest_tokens(bigram, text, token = "ngrams", n = 2)
#
#Eliminate duplication in bigrams
Coulter_bigrams %>%
  count(bigram, sort = TRUE)
#
library(tidyr)

bigrams_separated <- Coulter_bigrams %>%
  separate(bigram, c("word1", "word2"), sep = " ")

bigrams_filtered <- bigrams_separated %>%
  filter(!word1 %in% stop_words$word) %>%
  filter(!word2 %in% stop_words$word)
#


# new bigram counts:
bigram_counts <- bigrams_filtered %>% 
  count(word1, word2, sort = TRUE)

bigram_counts
#
#Save in Table, Bigrams > 5
bigram_counts1 <- bigram_counts %>%
  filter(n >= 5) %>%
  ungroup() %>% 
  arrange(desc(n))

write.csv(bigram_counts1,"Coulter_bigram_counts1.csv") 
#
#United bigrams
bigrams_united <- bigrams_filtered %>%
  unite(bigram, word1, word2, sep = " ")

bigrams_united
#-------------------------------------------------------------------#
#Sentiments
#-------------------------------------------------------------------#
AFINN <- get_sentiments("afinn")
#
bigram_sentiment <- bigrams_separated %>%
  inner_join(AFINN, by = c(word2 = "word")) %>%
  count(word2, score, sort = TRUE)
#
library(ggplot2)
#
bigram_sentiment %>%
  mutate(contribution = n * score) %>%
  arrange(desc(abs(contribution))) %>%
  head(20) %>%
  mutate(word2 = reorder(word2, contribution)) %>%
  ggplot(aes(word2, n * score, fill = n * score > 0)) +
  geom_col(show.legend = FALSE) +
  xlab("Sentiment score * number of occurrences") +
  ylab("Sentiment in Coulter tweets by word pair") +
  coord_flip()
#-------------------------------------------------------------------#
#Filter by not words
#-------------------------------------------------------------------#
not_words <- bigrams_separated %>%
  filter(word1 == "not") %>%
  inner_join(AFINN, by = c(word2 = "word")) %>%
  count(word2, score, sort = TRUE)

not_words %>%
  mutate(contribution = n * score) %>%
  arrange(desc(abs(contribution))) %>%
  head(20) %>%
  mutate(word2 = reorder(word2, contribution)) %>%
  ggplot(aes(word2, n * score, fill = n * score > 0)) +
  geom_col(show.legend = FALSE) +
  xlab("Words preceded by Not, Sentiment score * number of occurrences") +
  ylab("Sentiment in Coulter tweets by word pair") +
  coord_flip()

#Filter by many negation terms
#Common negation terms: not, can't, wouldn't, didn't, aren't, isn't, wasn't, weren't
#couldn't, mustn't, shouldn't, won't, 
#doesn't, don't
#hasn't, haven't, hadn't
#
nonos <- c("not", "can't", "wouldn't", "didn't", 
           "aren't", "isn't", "wasn't", "weren't", 
           "couldn't", "mustn't", "shouldn't", 
           "won't", "doesn't", "don't", "hasn't", 
           "haven't", "hadn't")

not_words <- bigrams_separated %>%
  filter(word1 %in% nonos) %>%
  inner_join(AFINN, by = c(word2 = "word")) %>%
  count(word2, score, sort = TRUE)

not_words %>%
  mutate(contribution = n * score) %>%
  arrange(desc(abs(contribution))) %>%
  head(20) %>%
  mutate(word2 = reorder(word2, contribution)) %>%
  ggplot(aes(word2, n * score, fill = n * score > 0)) +
  geom_col(show.legend = FALSE) +
  xlab("Words preceded by Negation Terms, Sentiment score * number of occurrences") +
  ylab("Sentiment in Coulter tweets by word pair") +
  coord_flip()



#-------------------------------------------------------------------#
# Analyze Network of Bigrams
#-------------------------------------------------------------------#
#Using iGraph package
#https://igraph.org/r/
#  
install.packages("igraph")
library(igraph)

# filter for only relatively common combinations
bigram_graph <- bigram_counts %>%
  filter(n > 20) %>%
  graph_from_data_frame()

install.packages("ggraph")
library(ggraph)
set.seed(2017)

#Basic graph
ggraph(bigram_graph, layout = "fr") +
  geom_edge_link() +
  geom_node_point() +
  geom_node_text(aes(label = name), vjust = 1, hjust = 1)
#
#Improved graph
#
set.seed(2016)

a <- grid::arrow(type = "closed", length = unit(.15, "inches"))

ggraph(bigram_graph, layout = "fr") +
  geom_edge_link(aes(edge_alpha = n), show.legend = FALSE,
                 arrow = a, end_cap = circle(.07, 'inches')) +
  geom_node_point(color = "lightblue", size = 5) +
  geom_node_text(aes(label = name), vjust = 1, hjust = 1) +
  theme_void()
