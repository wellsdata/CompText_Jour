# Austin Wilkins - April 29, 2019
# This script contains functions used in other scripts in the China_FDI project folder
library(tidytext)
library(tidyverse)


# This is used in TidyTextMaker.R
# Takes input of a .txt file and outputs multiple "tidy" files into TidyTexts folder
# The project folder must me set as the working directory
make_tidytexts <- function(textfile){
  
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
  
  
  
  # # # Delete ProQuest metadata # # #
  # Create List of Exclusion Phrases
  cutmeta <- c('Author:', 'Publication Info', 'http://',
               'Company:', 'Country of publication:', 'Dateline:', 'Document feature:', 
               'Document type:', 'Location:', 'Number of pages:', 'Place of publication:', 
               'Publication title:', 'Publication year:', 'Publisher:', 'Section:', 
               'Source type:', 'Subject:', 'Company / organization: ', 'Credit:', 'https',
               'Abstract','Volume','Issue','Publication date','Publication subject','Language',
               'ProQuest','Document URL','Copyright:','Last updated','Database: ','Publication info: ',
               'STARTOFARTICLE','Title','ISSN','People','Classification:') 
  
  
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


# Used in TopicModeling
# Takes input of .txt and returns a tidy version
clean_text <- function(textfile){
  NYT <- read_lines(textfile)
  NYT <-as.data.frame(NYT)
  colnames(NYT)[1] <- "Text"
  
  #Replace this text string with "STARTOFARTICLE"
  NYT$Start <- 
    gsub("____________________________________________________________", 
         "STARTOFARTICLE", NYT$Text)
  #
  #Creates an index, numbering each line per article.
  NYT <- NYT %>%
    mutate(linenumber = row_number(),
           newarticle = cumsum(str_detect(Start, regex("STARTOFARTICLE", 
                                                       ignore_case = TRUE, na.rm=TRUE)))) %>%
    ungroup()
  
  #Delete blank cells
  #df[!(is.na(df$start_pc) | df$start_pc==""), ]
  NYT <- NYT[!(is.na(NYT$Start) | NYT$Start==""), ]
  # Exclude Meta data
  #
  NYT2 <- NYT
  cutmeta <- c('Author:', 'Publication info', 'http://',
               'Company:', 'Country of publication:', 'Dateline:', 'Document feature:', 
               'Document type:', 'Location:', 'Number of pages:', 'Place of publication:', 
               'Publication title:', 'Publication year:', 'Publisher:', 'Section:', 
               'Source type:', 'Subject:', 'Company / organization: ', 'Credit:')
  # Cuts the metadata using an exclude function 
  NYT2 <- NYT2[ !grepl(paste(cutmeta, collapse="|"), NYT2$Start),]
  #
  #Slimmed down cleaned NYT table
  NYT <- select(NYT2, Text, linenumber, newarticle)
  #
  # Clean and tokenize the data and create a word colonm 
  reg <- "([^A-Za-z\\d#@']|'(?![A-Za-z\\d#@]))"
  # 
  tidy_NYT  <- NYT %>%
    filter(!str_detect(Text, '^"')) %>%
    mutate(Text = str_replace_all(Text, "https://t.co/[A-Za-z\\d]+|&amp;", "")) %>%
    unnest_tokens(word, Text, token = "regex", pattern = reg) %>%
    filter(!word %in% stop_words$word, str_detect(word, "[a-z]"))
  #
  #More data cleaning: result <- gsub("'", '', yourString)
  tidy_NYT$word  <- gsub("'", '', tidy_NYT$word)
  tidy_NYT$word  <- gsub("york", '', tidy_NYT$word)
  #
  #Filter out some garbage
  junk <- c("http", "mt", "rt","1","2","3","4","5","6","7","8","9")
  
  tidy_NYT2 <- tidy_NYT %>%
    filter(!word %in% junk)
  #Delete blank cells
  #df[!(is.na(df$start_pc) | df$start_pc==""), ]
  tidy_NYT <- tidy_NYT2[!(is.na(tidy_NYT$word) | tidy_NYT$word==" "), ]
  tidy_text <- tidy_NYT
  return(tidy_text)
}


#-----------------------------------------------------------------------#
# Token_Headlines: Makes a tidy table with headlines
#-----------------------------------------------------------------------#
token_headlines <- function(textfile){
  #WITH NYT DATA
  #
  NYT <- rio::import(textfile)
  #
  #Tokenize the NYT table
  reg <- "([^A-Za-z\\d#@']|'(?![A-Za-z\\d#@]))"
  #
  Token_table <- NYT %>%
    filter(!str_detect(text, '^"')) %>%
    mutate(text = str_replace_all(text, "https://t.co/[A-Za-z\\d]+|&amp;", "")) %>%
    unnest_tokens(word, text, token = "regex", pattern = reg) %>%
    filter(!word %in% stop_words$word,
           str_detect(word, "[a-z]"))
  
  #Clean out ' character in word columm of NYT_token
  #example: 'growing
  Token_table$word2 <- 
    gsub("'","", Token_table$word)
  
  Token_table <- select (Token_table, c(article_nmbr, headline, linenumber, word))
  return(Token_table)}


#-----------------------------------------------------------------------#
# sentence_table: Makes a text file into sentence level table
#-----------------------------------------------------------------------#
sentence_table <- function(textfile){
  NYT <- read_lines(textfile)
  NYT <-as.data.frame(NYT)
  colnames(NYT)[1] <- "Text"
  
  #Replace this text string with "STARTOFARTICLE"
  NYT$Start <- 
    gsub("____________________________________________________________", 
         "STARTOFARTICLE", NYT$Text)
  #
  
  #Creates an index, numbering each line per article.
  NYT <- NYT %>%
    mutate(linenumber = row_number(),
           newarticle = cumsum(str_detect(Start, regex("STARTOFARTICLE", 
                                                       ignore_case = TRUE, na.rm=TRUE)))) %>%
    ungroup()
  
  #Delete blank cells
  #df[!(is.na(df$start_pc) | df$start_pc==""), ]
  NYT <- NYT[!(is.na(NYT$Start) | NYT$Start==""), ]
  #
  # Exclude Meta data
  #
  cutmeta <- c('Author:', 'Publication info', 'http://',
               'Company:', 'Country of publication:', 'Dateline:', 'Document feature:', 
               'Document type:', 'Location:', 'Number of pages:', 'Place of publication:', 
               'Publication title:', 'Publication year:', 'Publisher:', 'Section:', 
               'Source type:', 'Subject:', 'Company / organization: ', 'Credit:')
  # Cuts the metadata using an exclude function 
  NYT <- NYT[ !grepl(paste(cutmeta, collapse="|"), NYT$Start),]
  
  
  
  #Reindex the DF
  NYT <- NYT %>%
    mutate(linenumber = row_number())
  
  #Table of with headlines
  NYThead <- NYT %>%
    select(Start, newarticle) %>%   
    filter(str_detect(Start, "Title: "))
  
  NYT3 <- NYT %>% 
    inner_join(NYThead, by = "newarticle") %>% 
    select(Start.y, newarticle, linenumber, Text) 
  
  
  colnames(NYT3)[1-4] <- c("headline", "article_nmbr", "linenumber", "Text")
  colnames(NYT3)[4] <- "Text"    
  
  NYT <- select (NYT3, c(headline, article_nmbr, linenumber, Text))
  
  return(NYT)
  
  
}


#-----------------------------------------------------------------------#
# headline_date: Makes a tidy table with headlines and dates
# Gives warning and omits entries with no date
#-----------------------------------------------------------------------#
textfile <- "ExtractedTexts/cos_newsearch7_18.txt"
headline_date <- function(textfile){
  NYT <- read_lines(textfile)
  NYT <- NYT[! str_detect(NYT,"Abstract: ")]
  NYT <-as.data.frame(NYT)
  colnames(NYT)[1] <- "text"
  
  #Replace this text string with "STARTOFARTICLE"
  NYT$Start <- 
    gsub("____________________________________________________________", 
         "STARTOFARTICLE", NYT$text)
  #
  
  #Creates an index, numbering each line per article.
  NYT <- NYT %>%
    mutate(linenumber = row_number(),
           newarticle = cumsum(str_detect(Start, regex("STARTOFARTICLE", 
                                                       ignore_case = TRUE, na.rm=TRUE)))) %>%
    ungroup()
  
  #Delete blank cells
  #df[!(is.na(df$start_pc) | df$start_pc==""), ]
  NYT <- NYT[!(is.na(NYT$Start) | NYT$Start==""), ]
  #
  # Exclude Meta data
  #
  cutmeta <- c('Author:', 'Publication info', 'http://',
               'Company:', 'Country of publication:', 'Dateline:', 'Document feature:',
               'Company:', 'Country of publication:', 'Dateline:', 'Document feature:',
               'Location:', 'Number of pages:', 'Place of publication:', 'column: ',
               'Publication year:', 'Publisher:', 'Section:', 
               'Source type:', 'Subject:', 'Company / organization: ', 'Credit:','Pages:','ISSN:','Publication subject:',
               'CODEN:','Language of publication:','Copyright:','Last updated:','Database:','brary.uark.',
               'https://','Abstract','People:','ProQuest document ID','Document URL:','Classification')
  # Cuts the metadata using an exclude function 
  NYT <- NYT[ !grepl(paste(cutmeta, collapse="|"), NYT$Start),]
  
  
  
  #Reindex the DF
  NYT <- NYT %>%
    mutate(linenumber = row_number())
  
  #Table of with headlines
  NYThead <- NYT %>%
    select(Start, newarticle) %>%   
    filter(str_detect(Start, "Title: "))
  
  NYTdate <- NYT %>%
    select(Start, newarticle) %>%   
    filter(str_detect(Start, "Publication date: "))
  
  NYT3 <- NYT %>% 
    inner_join(NYThead, by = "newarticle") %>% 
    select(Start.y, newarticle, linenumber, text) 
  NYT3 <- NYT3 %>% 
    inner_join(NYTdate, by = "newarticle") %>% 
    select(Start.y, newarticle, linenumber, text, Start)
  
  #new publication table  
  NYTpub <- NYT %>%
    select(Start, newarticle) %>%   
    filter(str_detect(Start, "Publication title: "))
  
  #New join for publication
  NYT3 <- NYT3 %>% 
    inner_join(NYTpub, by = "newarticle") %>% 
    select(Start.y, newarticle, linenumber, text, Start.x, Start.y.y)
  
  
  colnames(NYT3)[1] <- "headline"
  colnames(NYT3)[2] <- "article_nmbr"
  colnames(NYT3)[3] <- "linenumber"
  colnames(NYT3)[4] <- "text"    
  colnames(NYT3)[5] <- "date"
  colnames(NYT3)[6] <- "pub"
  
  NYT <- select (NYT3, c(headline, article_nmbr, linenumber, text, date, pub))
  NYT$date <- NYT$date %>% str_replace_all("Publication date: ","")
  NYT$text <- NYT$text %>% str_remove_all("Publication date: .+")
  NYT$pub <- NYT$pub %>% str_replace_all("Publication title: ","")
  
  NYT$pub[grep("Wall Street Journal", NYT$pub)] <- "WSJ"
  NYT$pub[grep("Los Angeles Times", NYT$pub)] <- "LAT"  
  NYT$pub[grep("Los Angeles T imes", NYT$pub)] <- "LAT"  
  NYT$pub[grep("Washington Post", NYT$pub)] <- "WP"  
  NYT$pub[grep("New York Times", NYT$pub)] <- "NYT"  
  NYT$pub[grep("Inside US Trade", NYT$pub)] <- "IUT"  
  
  library(lubridate)
  #NYT <- na.omit(NYT)
  NYT$date <- NYT$date %>% mdy
  #NYT <- na.omit(NYT)
  NYT <- NYT %>% separate(date, c("year","month","day"),"-", convert=TRUE) %>% 
    filter(year != 2019) %>% 
    unite("date", c("year","month","day"),sep = "-", remove=TRUE)
 
  #cleans the headlines of random junk
  NYT$headline <- NYT$headline %>% str_sub(8L,9999L)
  NYT$headline <- NYT$headline %>% str_remove_all(":\\s+\\[FINAL Edition \\]")
  NYT$headline <- NYT$headline %>% str_remove_all("\\(Posted.+")
  
  #adds in a source to better combine dataframes later
  NYT$search <- str_extract(textfile, "[^/]+(?=\\.txt$)")
  
  #-----------------------------------------------------------------------#
  # This whole section is to create the News/Opinion columns
  #-----------------------------------------------------------------------#
  
  x_type <-NYT %>%
    select(text, article_nmbr) %>%   
    filter(str_detect(text, "Document type: "))
  #
   colnames(x_type)[1] <- "type"
  #
  NYT <- inner_join(NYT, x_type) 
  
  #type columns
  NYT$type <- NYT$type %>% str_remove_all("^.+:[:space:]+")
  # NYT$type <- str_replace_all(NYT$type, pattern=fixed(' '), replacement=fixed('') )
  # NYT$type <- str_replace_all(NYT$type, pattern=fixed(','), replacement=fixed('') )
  NYT$type_detail <- NYT$type
  
  #manual type changing
  NYT$type <- str_replace_all(NYT$type, pattern=fixed('Feature'), replacement=fixed('News'))
  NYT$type <- str_replace_all(NYT$type, pattern=fixed('Corrections/Retraction'), replacement=fixed('News'))
  NYT$type <- str_replace_all(NYT$type, pattern=fixed('NEWSPAPER'), replacement=fixed('News'))
  NYT$type <- str_replace_all(NYT$type, pattern=fixed('Interview'), replacement=fixed('News'))
  NYT$type <- str_replace_all(NYT$type, pattern=fixed('Speech'), replacement=fixed('News'))
  NYT$type <- str_replace_all(NYT$type, pattern=fixed('BookReview'), replacement=fixed('News'))
  NYT$type <- str_replace_all(NYT$type, pattern=fixed('Brief'), replacement=fixed('News'))
  NYT$type <- str_replace_all(NYT$type, pattern=fixed('Series'), replacement=fixed('News'))
  
  NYT$type <- str_detect(NYT$type, "News", negate = FALSE)
  NYT$type <- as.character(NYT$type)
  
  NYT$type[NYT$type==TRUE] <- "News"
  NYT$type[NYT$type==FALSE] <- "Opinion"
  # 
  #cuts publication type from text column
  NYT <- NYT[ !grepl("^Document.+:.+$",NYT$text),]
  #cuts duplicate title column
  NYT <- NYT[ !grepl("^Title:.+",NYT$text),]
  NYT <- NYT[ !grepl("^Publication title:.+",NYT$text),]
  NYT <- NYT[ !grepl("^Source.+",NYT$text),]
  NYT <- NYT[ !grepl("^Publication date:.+",NYT$text),]

  NYT <- NYT %>%
    mutate(linenumber = row_number())
  
  
  return(NYT)
}


#-----------------------------------------------------------------------#
# Tokenize a Tidy csv
#-----------------------------------------------------------------------#
make_token <- function(textfile){
  if (is.character(textfile) & length(textfile) == 1){
    textfile <- headline_date(textfile)
  }

  reg <- "([^A-Za-z\\d#@']|'(?![A-Za-z\\d#@]))"
  token <- textfile %>%
    filter(!str_detect(text, '^"')) %>%
    mutate(text = str_replace_all(text, "https://t.co/[A-Za-z\\d]+|&amp;", "")) %>%
    unnest_tokens(word, text, token = "regex", pattern = reg) %>%
    filter(!word %in% stop_words$word,
           str_detect(word, "[a-z]"))
  return(token)

}


#-----------------------------------------------------------------------#
# Graph Bigrams - takes textfile and cutoff amount
#-----------------------------------------------------------------------#
graph_bigrams <- function(textfile,cutoff = 30){
  library(igraph)
  
  if (is.character(textfile) & length(textfile) == 1){
    textfile <- headline_date(textfile)
    textfile <- table_bigrams(textfile,merge = FALSE, n = cutoff)
  }
  else if(is.data.frame(textfile) & length(textfile) == 2){
    textfile <- textfile %>%
      separate(bigram, c("word1", "word2"), sep = " ")
  }
  else if(is.data.frame(textfile) & length(textfile) == 5){
    textfile <- table_bigrams(textfile,merge = FALSE,n = cutoff)
  }

  #-------------------------------------------------#
  # Analyze Network of Bigrams
  #-------------------------------------------------#
  
  # filter for only relatively common combinations
  bigram_graph <- textfile %>%
    filter(n > cutoff) %>%
    graph_from_data_frame()
  
  library(ggraph)
  set.seed(2016)
  
  a <- grid::arrow(type = "closed", length = unit(.10, "inches"))
  
  graphic <- ggraph(bigram_graph, layout = "fr") +
    geom_edge_link(aes(edge_alpha = n), show.legend = FALSE,
                   arrow = a, end_cap = circle(.07, 'inches')) +
    geom_node_point(color = "lightblue", size = 3) +
    geom_node_text(aes(label = name), vjust = 1, hjust = 1) +
    theme_void() +
    ggtitle("")
  graphic
  return(graphic)
}


#-----------------------------------------------------------------------#
# Make Bigrams - takes textfile and cutoff amount
# merge = FALSE will split the bigrams into two columns
#-----------------------------------------------------------------------#
table_bigrams <- function(textfile, n = 1000000, merge = TRUE, by_year = FALSE){
  if (is.character(textfile) & length(textfile) == 1){
    textfile <- headline_date(textfile) %>% 
      separate(date, c("year","month","day"), "-", convert=TRUE)
  }
  
  #Text Cleaning Section - remove 's and resolve koreas
  textfile$text <- textfile$text %>%
    str_replace_all("'s", "")
  
  textfile$text <- tolower(textfile$text)
  
  textfile$text <- gsub("korean","korea",textfile$text)
  
  
  
  cutoff <- n
  if (by_year == TRUE){
     bigrams <- textfile %>%
       group_by(year) %>% 
       unnest_tokens(bigram, text, token = "ngrams", n = 2) %>%
       add_count(bigram) %>% 
       separate(bigram, c("word1", "word2"), sep = " ") %>% 
       filter(!word1 %in% stop_words$word) %>%
       filter(!word2 %in% stop_words$word) %>% 
       na.omit() %>% 
       select(word1,word2,n, year) %>% 
       distinct()
     
     bigrams <- bigrams %>% 
       group_by(year) %>% 
       arrange(desc(n)) %>% 
       slice(1:cutoff)
       
   }
  else{
    bigrams <- textfile %>%
      unnest_tokens(bigram, text, token = "ngrams", n = 2) %>%
      add_count(bigram) %>% 
      separate(bigram, c("word1", "word2"), sep = " ") %>% 
      filter(!word1 %in% stop_words$word) %>%
      filter(!word2 %in% stop_words$word) %>% 
      na.omit() %>% 
      select(word1,word2,n) %>% 
      distinct() %>% 
      arrange(desc(n)) %>% 
      head(n)
  }
  

  if (merge == TRUE){
    bigrams <- bigrams %>%
    unite(bigram, word1, word2, sep = " ")
  }
  
 return(bigrams)
  
}


#-----------------------------------------------------------------------#
# Get Bing score - takes textfile
#-----------------------------------------------------------------------#
sentiment_score <- function(textfile){
  library(sentimentr)
 
  if (is.character(textfile) & length(textfile) == 1){
    textfile <- headline_date(textfile)
  }
  
  bingscore <- textfile %>% 
    make_token() %>% 
    inner_join(get_sentiments("bing")) %>% 
    group_by(article_nmbr) %>% 
    count(sentiment) %>% 
    arrange(desc(n)) %>% 
    spread(sentiment, n, fill=0) %>% 
    mutate(article_score = positive - negative)
  
  bingscore <- bingscore[c(1,4)]
  
  scores <- textfile %>% 
    inner_join(bingscore) %>% 
    group_by(article_nmbr) %>% 
    distinct()
  
  # scores <- scores %>% 
  #   separate(date, c("year","month","day"), "-", convert = TRUE)
  
  return(scores)
  
}


#-----------------------------------------------------------------------#
# Finds all articles in given regex - takes textfile
#-----------------------------------------------------------------------#
find_articles <- function(textfile, regex){
  
  negTable <- headline_date(textfile) %>% 
    filter(grepl (regex, text, ignore.case = TRUE)) %>% 
    separate(date, c("year","month","day"), "-", convert=TRUE) %>%
    add_count(article_nmbr) %>% 
    select(article_nmbr, n, year) %>%
    distinct()
  
  return(negTable)
}


#--------------------------------------------------#
#Simple_bigrams - unfiltered bigram tables. May 27 2019
#--------------------------------------------------#
simple_bigrams <- function(textfile){
  if (is.character(textfile) & length(textfile) == 1){
    textfile <- headline_date(textfile) %>% 
      separate(date, c("year","month","day"), "-", convert=TRUE)
  }
  
  
  #Text Cleaning Section - remove 's and resolve koreas
  textfile$text <- textfile$text %>%
    str_replace_all("'s", "")
  
  textfile$text <- tolower(textfile$text)
  
  textfile$text <- gsub("korean","korea",textfile$text)
  
  
  bigrams <- textfile %>%
    group_by(year) %>% 
    unnest_tokens(bigram, text, token = "ngrams", n = 2) %>%
    add_count(bigram) %>% 
    separate(bigram, c("word1", "word2"), sep = " ") %>% 
    filter(!word1 %in% stop_words$word) %>%
    filter(!word2 %in% stop_words$word) %>% 
    na.omit() %>% 
    select(word1,word2,n, year) %>% 
    distinct()
  
  
  return(bigrams)
  
}


#-----------------------------------------------------------------------#
# Word String Search - takes textfile
#-----------------------------------------------------------------------#
string_search <- function(textfile,regex,type = "table"){
  library(kableExtra)
  library(quanteda)
  
  WSJ<- read_lines(textfile)
  WSJ <-as.data.frame(WSJ)
  colnames(WSJ)[1] <- "Text"
  #
  WSJ$Start <-
    gsub("____________________________________________________________",
         "STARTOFARTICLE", WSJ$Text)
  #
  WSJ <- WSJ %>%
    mutate(linenumber = row_number(),
           newarticle = cumsum(str_detect(Start, regex("STARTOFARTICLE",
                                                       ignore_case = TRUE, na.rm=TRUE)))) %>%
    ungroup()
  #Delete blank cells
  #df[!(is.na(df$start_pc) | df$start_pc==""), ]
  WSJ <- WSJ[!(is.na(WSJ$Start) | WSJ$Start==""), ]
  #
  
  
  #Quanteda for phrase searching
  #install.packages("quanteda")
  #library(quanteda)
  #
  #Convert text to tokenized characters
  WSJ_char <- WSJ$Text    
  WSJ_char <- as.character(WSJ_char)    
  toks <- tokens(WSJ_char)
  results <- (kwic(toks, pattern = phrase(regex))) 
  results1 <- as.data.frame(results) 
  #
  #Create an index from results1 columne docname
  results1$index <- results1$docname
  #
  #delete "text" from results1$index
  results1$index <- str_remove(results1$index, "text")
  results1$index <- as.numeric(results1$index)
  #
  #Join the phrases with the headlines and dates
  #BroadFilter-WSJ.txt is a dummy variable processed through headline_date
  #Text_With_Headlines <- headline_date("RAW TEXT FILE HERE.txt")
  
  #source("Functions.R")
  WSJ_Econ_headlines <- headline_date(textfile)
  #
  #Join quanteda table with reqular table
  #!!!!changed to link to WSJ_Econ_headlines
  #!!!!!!!not have V1 in WSJ_Broadfilter!!!!!
  #
  WSJ_Econ_NegPhrase <- results1 %>% 
    inner_join(WSJ_Econ_headlines, by=c("index"="linenumber"))
  
  #dates
  #create date objects with lubridate
  #library(lubridate)
  #Format for year
  WSJ_Econ_NegPhrase$date <- ymd(WSJ_Econ_NegPhrase$date)
  #Create year field
  WSJ_Econ_NegPhrase$year <- year(WSJ_Econ_NegPhrase$date)
  
  #Table with each individual hit of a negative phrase by year
  table <- WSJ_Econ_NegPhrase %>% 
    select(article_nmbr, year, headline, pattern, pre, post)
  
  if (type == "kable"){
    table <- table %>% 
      kable() %>%
      kable_styling("striped")
  }
  else {
    
  }
  
  return(table)
  
}
#WSJ<- string_search("./ExtractedTexts/BroadFilter-WSJ.txt",verynegterms,type = "kable"


#-----------------------------------------------------------------------#
# Pull article - takes textfile and article number
#-----------------------------------------------------------------------#
pull_article <- function(textfile,article_number){
  article <- headline_date(textfile) %>% filter(article_nmbr == article_number) %>% select(text)
  
  text <- paste0(article[2:nrow(article),1])
  text2 <- text %>% str_c(text, collapse = "")
  
  return(text2)
}
#text <- pull_article("ExtractedTexts/BroadFilter-WSJ.txt", 115)

#-----------------------------------------------------------------------#
# phrase_search - takes textfile and search phrase
#built for single textfiles
#-----------------------------------------------------------------------#
phrase_search <- function(textfile,phrase){
  library(tidyverse)
  library(quanteda)
  library(lubridate)

  #-----------------------------------------------------------------------------#
  #Load and process data into a table with one line per sentence
  #-----------------------------------------------------------------------------#
  WP <- headline_date(textfile)
  
  ## ---------creates index
  WP$index <- seq.int(nrow(WP))
  ## --------- AW
  
  
  #Convert text to tokenized characters
  #Including date field - text to tokenized characters
  WP2 <- select(WP, text, date,article_nmbr,index)
  

  WP3 <- corpus(WP2)
  results <- (kwic(WP3, pattern = phrase(phrase))) 
  results <- as.data.frame(results) 
  
  
  #Create an index from results1 columne docname
  results$index <- results$docname
  results$index <- str_remove(results$index, "[:alpha:]+")
  results$index <- as.numeric(results$index)
  
  
  WP2 <- as.data.frame(WP2)
  
  #Create an index from results1 column docname
  WP2$doc_id <- WP2$index
  WP2$index <- as.numeric(WP2$index)
  
  WP_Econ_NegPhrase <- results %>% 
    inner_join(WP2, by="index")
  
  #Format for year
  WP_Econ_NegPhrase$date <- ymd(WP_Econ_NegPhrase$date)
  #Create year field
  WP_Econ_NegPhrase$year <- year(WP_Econ_NegPhrase$date)
  
  #Table with each individual hit of a negative phrase by year
  Xi_WP_Econ <- WP_Econ_NegPhrase %>% 
    select(docname, date, year, pattern, pre, post, text,doc_id,article_nmbr)
  
  Xi_WP_Econ$source <- str_extract(textfile, "[^/]+(?=\\.txt$)")
  
  return(Xi_WP_Econ)
}
#text <- phrase_search("ExtractedTexts/BroadFilter-WSJ.txt", c("Xi Jinping"))

#-----------------------------------------------------------------------#
# corpus_search - takes corpus and search phrase
#searches everything within a specific ExtractedTexts folder
#-----------------------------------------------------------------------#
corpus_search <- function(corpus,phrase){
  
  if (corpus == "EconomicFilter"){
    econ_texts <- list.files("ExtractedTexts/EconomicFilter",full.names = TRUE)
    econ <- lapply(econ_texts,phrase_search,phrase)

    econ2 <- list()
    for (i in econ){
      econ2 <- bind_rows(econ2,i)
    }
    return(econ2)
  }
  else if (pub == "BroadFilter"){
    broad_texts <- list.files("ExtractedTexts/BroadFilter",full.names = TRUE)
    broad <- lapply(broad_texts,phrase_search,phrase)
    broad2 <- list()
    for (i in broad){
      broad2 <- bind_rows(broad2,i)
    }
    return(broad2)
  }
  else if (pub == "ChinaFDI"){
    FDI_texts <- list.files("ExtractedTexts/ChinaFDI",full.names = TRUE)
    FDI <- lapply(FDI_texts,phrase_search,phrase)
    FDI2 <- list()
    for (i in FDI){
      FDI2 <- bind_rows(FDI2,i)
    }
    return(FDI2)
  }
  else {print("Not a valid corpus. Please use either 'EconomicFilter', 'BroadFilter', or 'ChinaFDI'.")}

  
}
#econ_table <- corpus_search("EconomicFilter","trade war")

#-----------------------------------------------------------------------#
# normalize_search - takes a output from corpus_search or phrase_search
#-----------------------------------------------------------------------#
normalize_search <- function(table) {
 
   sum_totals <- list()
  for (i in unique(table$source)){
    sum_table <- table %>% 
      filter(source == i) %>% 
      select(year, article_nmbr) %>% 
      group_by(year) %>% 
      count(article_nmbr) %>% 
      summarise(total = sum(n))
    sum_table$source <- i
    
    sum_totals <- rbind(sum_table,sum_totals)
  }
   
   file_list <- list.files(paste0("ExtractedTexts/",unique(str_extract(table$source,"^[:alpha:]+"))),full.names = TRUE)
   
   econ_totals <- list()
   for (i in file_list){
     full_table <- headline_date(i)
     full_table$source <- str_extract(i, "[^/]+(?=\\.txt$)")
     econ_totals <- rbind(full_table,econ_totals)
   }
   
   econ_totals$year <- year(econ_totals$date)
   
   econ_sum <- list()
   for (i in unique(econ_totals$source)){
     econ_sum_hold <- econ_totals %>% 
       filter(source == i) %>% 
       select(year, article_nmbr) %>% 
       group_by(year) %>% 
       count(article_nmbr) %>% 
       summarise(total = sum(n))
     econ_sum_hold$source <- i
     
     econ_sum <- rbind(econ_sum_hold,econ_sum)
   }
   
   
   econ_table_sum2 <- econ_sum %>% inner_join(sum_totals,by=c("year","source"))
   econ_table_sum2$pct <- econ_table_sum2$total.y/econ_table_sum2$total.x

   colnames(econ_table_sum2)[4] <- "search_hits"   
   colnames(econ_table_sum2)[2] <- "total_articles"
   
   return(econ_table_sum2)
}
#normalize_search(econ_table)


