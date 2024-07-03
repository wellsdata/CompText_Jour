#Text Mining with R A Tidy Approach Julia Silge and David Robinson  2018-12-21
#https://www.tidytextmining.com/
#Jan 20 2019

#ALL TEXT BELOW COPIED FROM Julia Silge and David Robinson'S BOOK
#ALL TEXT BELOW COPIED FROM Julia Silge and David Robinson'S BOOK
#ALL TEXT BELOW COPIED FROM Julia Silge and David Robinson'S BOOK


#The unnest_tokens function

text <- c("Because I could not stop for Death -",
         "He kindly stopped for me -",
         "The Carriage held but just Ourselves -",
         "and Immortality")

text

#TIBBLE
#put in dataframe. creates a tibble
# A tibble is a modern class of data frame within R, available in the dplyr 
#and tibble packages, that has a convenient print method, 
#will not convert strings to factors, and does not use row names. 
#Tibbles are great for use with tidy tools.

library(dplyr)
text_df <- data_frame(line = 1:4, text = text)

text_df

#We need to convert this so that it has one-token-per-document-per-row.
#break the text into individual tokens (a process called tokenization) 
#and transform it to a tidy data structure. 
#To do this, we use tidytext’s unnest_tokens() function.

library(tidytext)

text_df %>%
  unnest_tokens(word, text)

#Tidying the works of Jane Austen
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

#convert to a tidy dataset
library(tidytext)
tidy_books <- original_books %>%
  unnest_tokens(word, text)

tidy_books

#remove stop words: the of to etc
data(stop_words)
#------------------------------------------#
#beware of this stop words data - it has 1149 words. some may be needed for our analysis!'
#------------------------------------------#


tidy_books <- tidy_books %>%
  anti_join(stop_words)


tidy_books %>%
  count(word, sort = TRUE) 

#visualize
library(ggplot2)

tidy_books %>%
  count(word, sort = TRUE) %>%
  filter(n > 600) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n)) +
  geom_col() +
  xlab(NULL) +
  coord_flip()

#Word frequencies
install.packages("gutenbergr")
library(gutenbergr)

#HG Wells
hgwells <- gutenberg_download(c(35, 36, 5230, 159))

tidy_hgwells <- hgwells %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words)

tidy_hgwells %>%
  count(word, sort = TRUE)

#Bronte
bronte <- gutenberg_download(c(1260, 768, 969, 9182, 767))

tidy_bronte <- bronte %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words)

tidy_bronte %>%
  count(word, sort = TRUE)

#Mash the two together
library(tidyr)

frequency <- bind_rows(mutate(tidy_bronte, author = "Brontë Sisters"),
                       mutate(tidy_hgwells, author = "H.G. Wells"), 
                       mutate(tidy_books, author = "Jane Austen")) %>% 
  mutate(word = str_extract(word, "[a-z']+")) %>%
  count(author, word) %>%
  group_by(author) %>%
  mutate(proportion = n / sum(n)) %>% 
  select(-n) %>% 
  spread(author, proportion) %>% 
  gather(author, proportion, `Brontë Sisters`:`H.G. Wells`)

#Viz
library(scales)

# expect a warning about rows with missing values being removed
ggplot(frequency, aes(x = proportion, y = `Jane Austen`, color = abs(`Jane Austen` - proportion))) +
  geom_abline(color = "gray40", lty = 2) +
  geom_jitter(alpha = 0.1, size = 2.5, width = 0.3, height = 0.3) +
  geom_text(aes(label = word), check_overlap = TRUE, vjust = 1.5) +
  scale_x_log10(labels = percent_format()) +
  scale_y_log10(labels = percent_format()) +
  scale_color_gradient(limits = c(0, 0.001), low = "darkslategray4", high = "gray75") +
  facet_wrap(~author, ncol = 2) +
  theme(legend.position="none") +
  labs(y = "Jane Austen", x = NULL)

#Correlation test on word frequencies Austen - Bronte
cor.test(data = frequency[frequency$author == "Brontë Sisters",],
         ~ proportion + `Jane Austen`)

#Correlation test on word frequencies Austen - Wells
cor.test(data = frequency[frequency$author == "H.G. Wells",], 
         ~ proportion + `Jane Austen`)

#Do this for Wittgenstein
#Text mining Wittgenstein Tractatus Logico-Philosophicus: 5740

#doesn't work - no text version of book!
library(gutenbergr)
wittgenstein <- gutenberg_download(c(5740))

#created text version and imported into spreadsheet, single column csv
options(header=FALSE, stringsAsFactors = FALSE,fileEncoding="utf-8")
wittgenstein <- read.csv(file.choose(), stringsAsFactors = FALSE)

#Rename a specific column
colnames(wittgenstein)[1] <- "text"

tidy_wittgenstein <- wittgenstein %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words)

tidy_wittgenstein %>%
  count(word, sort = TRUE)

tidy_wittgenstein %>%
  count(word, sort = TRUE) %>%
  filter(n > 200) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n)) +
  geom_col() +
  xlab(NULL) +
  coord_flip()