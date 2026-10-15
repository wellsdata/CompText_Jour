# Extract the full text of each ProQuest article into its own .txt file
# ---------------------------------------------------------------------
# Each article starts with a line of underscores followed by
# "Document X of 500". For every article, the text from "Full text:" up to
# (but not including) "Subject:" is saved to extracted_articles/<headline>.txt
#
# Usage:
#   source("extract_articles.R")
#   index <- make_TidyTexts("my_proquest_export.txt")

library(tidyverse)

# Make a headline safe to use as a file name
safe_filename <- function(x, max_chars = 150) {
  x %>%
    str_replace_all('[\\\\/:*?"<>|\\r\\n\\t]', " ") %>%  # characters not allowed in file names
    str_squish() %>%
    str_sub(1, max_chars) %>%                           # keep paths under OS limits
    str_remove("[ .]+$")                                # no trailing spaces/dots (Windows)
}

# Pull headline, year, document number and full text out of one article
extract_one <- function(lines) {

  # Document number ("Document 1 of 500")
  doc_idx <- str_which(lines, "^\\s*Document \\d+ of \\d+")[1]
  if (is.na(doc_idx)) return(NULL)
  doc_num <- as.integer(str_match(lines[doc_idx], "Document (\\d+) of")[, 2])

  # Headline: use the "Title:" field if present, otherwise the first
  # non-blank line after "Document X of 500"
  title_idx <- str_which(lines, "^Title:\\s*")[1]
  if (!is.na(title_idx)) {
    headline <- str_remove(lines[title_idx], "^Title:\\s*")
  } else {
    after    <- tail(lines, -doc_idx)
    headline <- after[str_trim(after) != ""][1]
  }
  headline <- str_squish(headline)

  # Publication year (optional, for the index)
  year_idx <- str_which(lines, "^Publication year:\\s*")[1]
  year <- if (is.na(year_idx)) NA_character_ else
    str_squish(str_remove(lines[year_idx], "^Publication year:\\s*"))

  # Full text section: from "Full text:" to the line before "Subject:"
  ft_start <- str_which(lines, regex("^Full text:", ignore_case = TRUE))[1]
  if (is.na(ft_start)) {
    return(tibble(article_nmbr = doc_num, Year = year, headline = headline,
                  status = "no full text", body = list(NULL)))
  }

  subj    <- str_which(lines, regex("^Subject:", ignore_case = TRUE))
  ft_end  <- subj[subj > ft_start][1]
  status  <- "ok"
  if (is.na(ft_end)) {               # no Subject: line -> take rest of article
    ft_end <- length(lines) + 1
    status <- "ok (no Subject: line, took text to end of article)"
  }

  body    <- lines[ft_start:(ft_end - 1)]
  body[1] <- str_remove(body[1], regex("^Full text:\\s*", ignore_case = TRUE))

  # trim leading/trailing blank lines
  keep <- which(str_trim(body) != "")
  body <- if (length(keep)) body[min(keep):max(keep)] else character(0)

  tibble(article_nmbr = doc_num, Year = year, headline = headline,
         status = status, body = list(body))
}


# This is the function, run to import and use
make_TidyTexts <- function(textfile,
                           source_dir = "source",
                           out_dir    = "extracted_articles") {

  article_path <- file.path(source_dir, textfile)
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  # Read the export and number the articles at each underscore line
  TEXT <- tibble(Text = read_lines(article_path)) %>%
    mutate(Text       = str_remove(Text, "\\s+$"),
           is_sep     = str_detect(Text, "^_{20,}$"),
           newarticle = cumsum(is_sep)) %>%
    filter(newarticle > 0, !is_sep)   # drop anything before the first article

  # Extract every article
  articles <- TEXT %>%
    group_split(newarticle) %>%
    map(~ extract_one(.x$Text)) %>%
    compact() %>%
    bind_rows()

  # Build unique, safe file names from the headlines
  articles <- articles %>%
    mutate(file_base = safe_filename(headline),
           file_base = if_else(is.na(file_base) | file_base == "",
                               paste("Document", article_nmbr), file_base)) %>%
    group_by(file_base) %>%
    mutate(file_base = if (n() > 1) paste0(file_base, " (Doc ", article_nmbr, ")")
                       else file_base) %>%
    ungroup() %>%
    mutate(file = file.path(out_dir, paste0(file_base, ".txt")))

  # Write each article's full text
  to_write <- articles %>% filter(str_starts(status, "ok"))
  walk2(to_write$body, to_write$file,
        ~ write_lines(.x, .y))

  # Save an index of what was extracted
  index <- articles %>%
    mutate(file = if_else(str_starts(status, "ok"), file, NA_character_),
           n_lines = map_int(body, length)) %>%
    select(article_nmbr, Year, headline, file, status, n_lines)

  write_csv(index, file.path(out_dir, "_index.csv"))

  message(sum(str_starts(index$status, "ok")), " of ", nrow(index),
          " articles written to ", out_dir, "/")
  if (any(!str_starts(index$status, "ok"))) {
    message("Articles without a full text section: ",
            paste(index$article_nmbr[!str_starts(index$status, "ok")], collapse = ", "))
  }

  invisible(index)
}
