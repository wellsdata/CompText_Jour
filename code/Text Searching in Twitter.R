#Text Searching in Twitter
#Rob Wells
#Feb 17 2019
#Credit where it is due:
#Thanks to https://awakeningdatascientist.wordpress.com/2015/07/20/r-of-the-day-grep-and-grepl/
#Thanks to https://haozhu233.github.io/kableExtra/awesome_table_in_html.html


#Load the AOC tweets
AOC <- rio::import("./Data/AOC.csv")
AOC <- janitor::clean_names(AOC)
colnames(AOC)
str(AOC)

#--------------------------------------------------------------------#
#                TEXT SEARCHING                                      #
#--------------------------------------------------------------------#

#Let's focus on the text and time
library(dplyr)
AOC1 <- AOC %>% select(created_at, text)
View(AOC1)
#What is wrong with this picture?

#Put it in a readable format
#https://haozhu233.github.io/kableExtra/awesome_table_in_html.html
#install.packages("kableExtra")
library(knitr)
library(kableExtra)
kable(AOC1)

#Better formatting into html. Bonus - you see emojis.
AOC1 %>%
  kable() %>%
  kable_styling()

#You can now see the tweets displayed nicely on the viewer
#Export: Viewer | Export | Save as Web Page
#Open File In Web Browser and read the Tweets

#Find instances of Trump in the Tweets#
#Primitive Method of Filtering
Test <- filter(AOC, grepl ("Trump", text))
Test <- Test%>%select(created_at, text)

#Filtered Table with 62 instances of Trump in Tweets
AOC_Trump <- filter(AOC, grepl ("Trump", text)) %>% 
  select(created_at, text)

#Use | as OR statement in text searches - 73 instances
AOC_Trump2 <- filter(AOC, grepl ("Trump|green", text)) %>% 
  select(created_at, text)

#Let's Look at GREP
??grepl
#Pattern Matching and Replacement
#grep, grepl, regexpr, gregexpr and regexec search for matches to argument pattern within each element of a character vector: they differ in the format of and amount of detail in the results.
#grepl(pattern, x, ignore.case = FALSE, perl = FALSE,
#           fixed = FALSE, useBytes = FALSE)
#Another resource: https://www.rdocumentation.org/packages/base/versions/3.5.2/topics/grep

#The Power of Grep!
#Or
#filter_for_value<-CO2[grep("non", CO2$Treatment), ]
#head(filter_for_value)
Test1 <-AOC[grep("Trump", AOC$text), ]
head(Test1)

#Filter Boolean  operators: & is “and”, | is “or”, and ! is “not”. 



#filter data set based on values that do not match the specified pattern
#filter_for_not_a_value<-CO2[-(grep("non", CO2$Treatment)),]
NotTrump <-AOC[-(grep("Trump", AOC$text)), ]

#Source: https://awakeningdatascientist.wordpress.com/2015/07/20/r-of-the-day-grep-and-grepl/


#Write your results into a table
write.csv(AOC_Trump, "AOC_Trump.csv")

#Look at your results in html. Bonus - you see emojis.
AOC_Trump %>%
  kable() %>%
  kable_styling()


#------------------------------------------------------------------------------#
#------------This Section Involves Processing the Twitter Data ----------------#
#------------------------------------------------------------------------------#

#Create a subset
AOC2 <- select(AOC, user_id, created_at, text, is_retweet, hashtags, urls_expanded_url)
View(AOC2)

#Filters to Just Retweets
AOC_retweets<- AOC2%>%select(user_id, is_retweet, hashtags)%>%filter(is_retweet=="TRUE")

#Create a table with frequency of word usage
Hashtags <-- table(AOC_retweets$hashtags)
View(Hashtags)

#Write to a CSV
#output this file to a CSV
write.csv(Hashtags, "Hashtags.csv")


#Who is engaging with AOC?
df3 <- group_by(AOC2, urls_expanded_url) %>% 
  summarize(total=n()) %>%    
  arrange(desc(total)) %>% 
  head()


#----------  ANALYZE WORDS ---------------#
#from book: https://www.tidytextmining.com/tidytext.html #
#from tutorial: http://varianceexplained.org/r/trump-tweets/
# using tidytext: https://cran.r-project.org/web/packages/tidytext/
#https://cran.r-project.org/web/packages/tidytext/vignettes/tidytext.html
#https://cran.r-project.org/web/packages/tidytext/tidytext.pdf
#Comparison of words
#Now that we’re sure there’s a difference between these two accounts, what can we say about the difference in the content? 
#We’ll use the tidytext package that Julia Silge and I developed.

#We start by dividing into individual words using the unnest_tokens function (see this vignette for more),
#and removing some common “stopwords”2:
#Sept. 28 Session #

#install.packages("tidytext")
install.packages("tidyr")
library(tidytext)
library(tidyr)
library(dplyr)
library(stringr)

#reg <- "([^A-Za-z\\d#@']|'(?![A-Za-z\\d#@]))"
#tweet_words <- tweets %>%
#  filter(!str_detect(text, '^"')) %>%
#  mutate(text = str_replace_all(text, "https://t.co/[A-Za-z\\d]+|&amp;", "")) %>%
#  unnest_tokens(word, text, token = "regex", pattern = reg) %>%
#  filter(!word %in% stop_words$word,
#         str_detect(word, "[a-z]"))

#tweet_words

#android_iphone_ratios <- tweet_words %>%
#count(word, source) %>%
# filter(sum(n) >= 5) %>%
#  spread(source, n, fill = 0) %>%
#  ungroup() %>%
#  mutate_each(funs((. + 1) / sum(. + 1)), -word) %>%
#  mutate(logratio = log2(Android / iPhone)) %>%
#  arrange(desc(logratio))

reg <- "([^A-Za-z\\d#@']|'(?![A-Za-z\\d#@]))"
tweet_words <- AOC %>%
  filter(!str_detect(text, '^"')) %>%
  mutate(text = str_replace_all(text, "https://t.co/[A-Za-z\\d]+|&amp;", "")) %>%
  unnest_tokens(word, text, token = "regex", pattern = reg) %>%
  filter(!word %in% stop_words$word,
         str_detect(word, "[a-z]"))

tweet_words

CommonAOCWords <- tweet_words %>%
  count(word, source) %>%
  filter(sum(n) >= 5) %>%
  spread(source, n, fill = 0) %>%
  ungroup()

#Don't count as separate devices#
#Removes source from table
CommonAOCWords <- tweet_words %>%
  count(word) %>%
  filter(sum(n) >= 5) %>%
  ungroup()

#Write to CSV
write.csv(CommonAOCWord, "CommonAOCWord.csv")

#Filter to Words With More than 100 Occurences #
CommonWord <- filter(CommonAOCWords, n >= 100) %>% 
  group_by(word, n) %>% 
  arrange(desc(n)) 

#Same table but not in a grouped df - do this for ggplot below
CommonWord1 <- filter(CommonAOCWords, n >= 100)

library(dplyr)
library(ggplot2)

#Convert to data frame
CommonWords <- as.data.frame(CommonAOCWords)
head(CommonCollinsWords)


#Visualize it!

#Do the Katie Serrano special and add some killer colors
CommonAOCChart <- ggplot(CommonWord, aes(x = reorder(word, -n), y = n, color = word, fill=word))  +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = "Top Words In AOC Twitter Feed", 
       subtitle = "AOC Twitter Feed",
       caption = "Graphic by Rob Wells",
       x="Word",
       y="Count of the word usage") +
      theme(legend.position="none") 

plot(CommonAOCChart)


#For Later, Indexing

#Filters to Just Trump, Dumps into New Column
library(stringr)
AOC$Trump <- str_match(AOC$text, "Trump")
AOC$Trump <- as.character(AOC$Trump)

