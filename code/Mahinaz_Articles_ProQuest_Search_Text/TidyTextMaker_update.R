#--------Text Cleaning - Tidy Tables - Sentiment analysis ----#
#       March 25, 2019        #
#       Austin Wilkins        #

# This script will take a .txt file from /China-FDI/ExtractedTexts and produce 4 TidyText .csv files.
# These files will be stored based on the name of the original .txt file used and saved to /TidyTexts.
# The whole thing in wrapped up in a function called make_TidyTexts().
# make_TidyTexts takes 1 argument, the name of the .txt file

# Example:
# make_TidyTexts("BroadFilter-IUCT.txt")


# Or just run the whole script to produce TidyTexts for the whole ExtractedTexts folder. 


#Script must be run from the China_FDI project folder, set working directory to your project folder
setwd("~/Documents/Projects/China_FDI")


#Credits to:
#Text Mining with R A Tidy Approach Julia Silge and David Robinson  2018-12-21
#https://www.tidytextmining.com/ 
#http://varianceexplained.org/r/trump-tweets/ 
#https://rtweet.info/
#https://rtweet.info/articles/auth.html


#libraries
library(dplyr)
library(stringr)
library(readr)
#install.packages("devtools")
library(devtools)
library(tidytext)
library(purrr)

#------------------------------------------------------------------------------#
#                    Turning Articles into TidyText                            #
#------------------------------------------------------------------------------#

# This is the function, run to import and use
make_TidyTexts <- function(textfile){

#load the article into function environment
article <- paste0("ExtractedTexts/",textfile)

#rename textfile (removes .txt to make saving easier)
textfile <- gsub('.{4}$','',textfile)

TEXT <- read_lines(article)
TEXT <-as.data.frame(TEXT)


# another method Rename a specific column
colnames(TEXT)[1] <- "Text"


#Replace this text string with "STARTOFARTICLE"
TEXT$Start <- 
  gsub("____________________________________________________________", 
       "STARTOFARTICLE", TEXT$Text)


#Create an index, numbering each line per article.
TEXT <- TEXT %>%
  mutate(linenumber = row_number(),
         newarticle = cumsum(str_detect(Start, regex("STARTOFARTICLE", 
                                                     ignore_case = TRUE, na.rm=TRUE)))) %>%
  ungroup()


#Delete blank cells
TEXT <- TEXT[!(is.na(TEXT$Start) | TEXT$Start==""), ]

#Table of Articles, Titles and Numbers
TEXT_Tidy_Headlines <- TEXT %>%
  select(Start, newarticle) %>%   
  filter(str_detect(Start, "Title: "))

colnames(TEXT_Tidy_Headlines)[1] <- "headline"
colnames(TEXT_Tidy_Headlines)[2] <- "article_nmbr"

#Extract headlines and years
#
TEXT_Years <- TEXT %>%
  select(Start, newarticle) %>%   
  filter(str_detect(Start, "Publication year: "))
#
TEXT_Years$Start <- str_remove(TEXT_Years$Start, "Publication year: ")
colnames(TEXT_Years)[1] <- "Year"
colnames(TEXT_Years)[2] <- "article_nmbr"

Text_Headlines_Year <- TEXT_Tidy_Headlines %>% 
  inner_join(TEXT_Years) %>% 
  select(Year, headline, article_nmbr)

write.csv(Text_Headlines_Year,paste0("TidyTexts/",textfile,"_tidy.csv"))

# # # Delete ProQuest metadata # # #
# Create List of Exclusion Phrases
cutmeta <- c('Author:', 'Publication Info', 'http://',
             'Company:', 'Country of publication:', 'Dateline:', 'Document feature:', 
             'Document type:', 'Location:', 'Number of pages:', 'Place of publication:', 
             'Publication title:', 'Publication year:', 'Publisher:', 'Section:', 
             'Source type:', 'Subject:', 'Company / organization: ', 'Credit:', 'https',
             'Abstract','Volume','Issue','Publication date','Publication subject','Language',
             'ProQuest','Document URL','Copyright:','Last updated','Database: ','Publication info: ',
             'STARTOFARTICLE','Title','ISSN','People') 


# Exclude
TEXT <- TEXT[ !grepl(paste(cutmeta, collapse="|"), TEXT$Start),]

TEXT$Start <- gsub("Full text: ",'',TEXT$Start) 

#Rename Columns of TEXT
library(data.table)
setnames(TEXT, old = c('Text', 'Start', 'linenumber', 'newarticle'), new = c('x', 'text', 'line', 'article_nmbr'))
TEXT <- select(TEXT, c(text, line, article_nmbr))

#Reindex the DF
TEXT <- TEXT %>%
  mutate(linenumber = row_number())

#Rename Columns of TEXT_TIDY_HEADLINES
setnames(TEXT_Tidy_Headlines, old = c('Start','newarticle'), new = c('headline','article_nmbr'))

#Join TEXT_tidy_Headlines to other Data)
TEXT_tidy <- inner_join(TEXT_Tidy_Headlines, TEXT, by =c("article_nmbr" = "article_nmbr"))
TEXT_tidy <- select(TEXT_tidy, c(headline, article_nmbr, text, linenumber))


#SAVE
write.csv(TEXT_tidy,paste0("TidyTexts/",textfile,"_tidy.csv"))




#Tokenize the TEXT table)
reg <- "([^A-Za-z\\d#@']|'(?![A-Za-z\\d#@]))"
TEXT_token <- TEXT_tidy %>%
  filter(!str_detect(text, '^"')) %>%
  mutate(text = str_replace_all(text, "https://t.co/[A-Za-z\\d]+|&amp;", "")) %>%
  unnest_tokens(word, text, token = "regex", pattern = reg) %>%
  filter(!word %in% stop_words$word,
         str_detect(word, "[a-z]"))

#Clean out ' character in word columm of TEXT_token
#example: 'growing
TEXT_token$word2 <- 
  gsub("'","", TEXT_token$word)

TEXT_token <- select (TEXT_token, c(headline, article_nmbr, linenumber, word2))
colnames(TEXT_token)[4] <- "word"

#Table of Common Words
CommonTEXTWords <- TEXT_token %>%
  count(word) %>%
  filter(sum(n) >= 5) %>%
  ungroup()

#save
write.csv(CommonTEXTWords,paste0("TidyTexts/CommonWords_",textfile,".csv"))


#Create a sentiment analysis table called nrc
nrc <- sentiments %>%
  filter(lexicon == "nrc") %>%
  dplyr::select(word, sentiment)

# Create a Table of Words and Sentiments
totalwords <- TEXT_token %>%
  group_by(article_nmbr) %>%
  mutate(total_words = n()) %>%
  ungroup() %>%
  distinct(article_nmbr, total_words)

library(tidyselect)
TEXT_sentiment <- CommonTEXTWords %>%
  inner_join(nrc, by = "word") %>% 
  select(word, sentiment, n) %>% 
  arrange(desc(n))


#Export output this file to a CSV
write.csv(TEXT_sentiment,paste0("TidyTexts/Sentiment_",textfile,".csv"))


#------------------------------------------------------------------------------#
#                 Summarizing Sentiments 
#------------------------------------------------------------------------------#

#create totalled sentiment
total_TEXTsentiment <- CommonTEXTWords %>%
  inner_join(nrc, by = "word") %>%
  count(sentiment) %>%
  ungroup() %>%
  group_by(sentiment, n) %>%
  summarize(words = sum(n)) %>%
  arrange(desc(words)) %>% 
  ungroup()


total_TEXTsentiment <- select (total_TEXTsentiment, c(-n))

#Export output this file to a CSV or Excel  write.csv or write.excel
write.csv(total_TEXTsentiment,paste0("TidyTexts/total_sentiment_",textfile,".csv"))

}


# # # This section will run all files in /ExtractedTexts at the same time, takes a minute
#first, make a list of all files in /ExtractedTexts
extractedTexts <- list.files('ExtractedTexts')

map(extractedTexts,make_TidyTexts)

#make_TidyTexts("/home/austin/Documents/Projects/China_FDI/ExtractedTexts/BroadFilter-NYT.txt")

