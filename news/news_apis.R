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

# Functions ---------------------------------------------------------------



# Searches ----------------------------------------------------------------


terms <- readLines("news/newsapi_searches.txt")

news_api_key <- Sys.getenv("NEWSAPI_KEY")

req <- request("https://newsapi.org/v2/everything?")

news <- terms %>%
  map(function(search_terms) {

    #TODO Take a look at https://httr2.r-lib.org/reference/multi_req_perform.html

    req %>%
      req_url_query(q = search_terms) %>%
      req_url_query(apiKey = news_api_key) %>%
      req_perform() %>%
      resp_body_json() %>%
      rrapply(how = "melt") %>%
      as_tibble() %>%
      slice(-(1:2)) %>%
      unnest(value) %>%
      mutate(name = coalesce(L4, L3)) %>%
      deselect(L3, L4) %>%
      pivot_wider() %>%
      deselect(L1) %>%
      clean_names() %>%
      rename(source = name) %>%
      add_column(terms = search_terms) %>%
      mutate()
  }) %>%
  bind_rows()
#
# if(fs::file_exists("news/data/news_table.rds")) {
#   news_table <- read_rds("news/data/news_table.rds")
#   news_table %>% rows_insert(news)
# } else
#   news_table <- news
#
# news_table %>%
#   rows_upsert(news, by = c("url", "published_at"))
news %>%
  write_rds("news/data/news_table.rds")




