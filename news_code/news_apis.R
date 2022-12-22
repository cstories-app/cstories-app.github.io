# Pull data from newsapi.org
# Jonathan Zadra
# 12/2/22


# Setup -------------------------------------------------------------------


library(tidyverse)
library(integral)
library(httr2)
library(rrapply)
library(janitor)
library(fs)
library(lubridate)

# Functions ---------------------------------------------------------------



# Searches ----------------------------------------------------------------


terms <- readLines("news_code/newsapi_searches.txt")

news_api_key <- Sys.getenv("NEWSAPI_KEY")

req <- request("https://newsapi.org/v2/everything?")

sortBy <- "publishedAt" #The order to sort the articles in. Possible options: relevancy, popularity, publishedAt.
  #relevancy = articles more closely related to q come first.
  #popularity = articles from popular sources and publishers come first.
  #publishedAt = newest articles come first (DEFAULT)

raw_news <- terms %>%
  map(function(search_terms) {

  print(search_terms)

    resp <- req %>%
      req_url_query(q = search_terms) %>%
      req_url_query(apiKey = news_api_key) %>%
      req_url_query(sortBy = sortBy) %>%
      req_perform() %>%
      resp_body_json()

    if(resp$totalResults == 0) return(NULL)

    resp %>%
      rrapply(how = "melt") %>%
      as_tibble() %>%
      slice(-(1:2)) %>%
      unnest(value) %>%
      mutate(name = coalesce(L4, L3)) %>%
      deselect(L3, L4) %>%
      pivot_wider() %>%
      deselect(L1) %>%
      clean_names() %>%
      add_column(search_date = date(today())) %>%
      add_column(sort_by = sortBy) %>%
      rename(sort_value = l2) %>%
      rename(source = name) %>%
      add_column(terms = search_terms)
  }) %>%
  bind_rows()

news <- raw_news %>%
  mutate(title = str_squish(title),
         description = str_squish(description)) %>%
  mutate(published_at = as_date(published_at) %>% as.character(),
         search_date = as.character(search_date)) %>%
  mutate(author = replace_na(author, "(unknown author)"),
         description = replace_na(description, "(no description)")) %>%
  deselect(id) %>%
  mutate(news_id = paste(abbreviate(str_remove_all(title, "[^\\w]")), abbreviate(source), published_at, sep = "_")) %>%
  rename(image = url_to_image) %>%
  group_by(news_id) %>%
  summarize(across(-terms), terms = paste(terms, collapse = " | ")) %>% #If we have the same result from different terms, combine the terms for use in filters
  filter(sort_value == min(sort_value)) %>% #Keep the result with the highest ranking
  ungroup() %>%
  distinct() %>%
  mutate(terms = str_replace_all(terms, "\"", "\'"))

existing_news <- read_rds("news_code/data/news_table.rds")


news <- existing_news %>%
  rows_upsert(news, by = "news_id")


news %>%
  write_rds("news_code/data/news_table.rds")


# Create QMDs -------------------------------------------------------------



news %>%
  anti_join(existing_news, by = "news_id") %>%
  deselect(sort_value, sort_by) %>%
  mutate(terms = str_remove_all(terms, " AND \\('offshore wind' \\)") %>%
           str_remove_all("'")) %>%
  pivot_longer(-news_id) %>%
  mutate(value = paste0("\"", value, "\"")) %>%
  unite(col = yaml, name, value, sep = ": ") %>%
  #mutate(yaml = str_wrap(yaml, exdent = 3)) %>%
  group_by(news_id) %>%
  summarize(yaml = paste(yaml, collapse = "\n")) %>%
  mutate(yaml = paste0("---\n", yaml, "\n---\n")) %>%
  mutate(full_qmd = paste0(yaml, "\n
Published: {{< meta published_at >}}\
\n
Source: {{< meta source >}}\
\n
[Read full article]({{< meta url >}})\
\n

![](`r rmarkdown::metadata$image[1]`)")) %>%
  rowwise() %>%
  pwalk(function(...) {
    x <- tibble(...)
    #yaml <- x %>% pull(yaml)
    #fileid <- x %>% pull(news_id)
    write_lines(x$full_qmd, file = paste0("news/", x$news_id, ".qmd"))
  })
