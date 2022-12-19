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


terms <- readLines("news/newsapi_searches.txt")

news_api_key <- Sys.getenv("NEWSAPI_KEY")

req <- request("https://newsapi.org/v2/everything?")

news <- terms %>%
  map(function(search_terms) {

    #TODO Take a look at https://httr2.r-lib.org/reference/multi_req_perform.html
  print(search_terms)

    resp <- req %>%
      req_url_query(q = search_terms) %>%
      req_url_query(apiKey = news_api_key) %>%
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
      rename(source = name) %>%
      add_column(terms = search_terms)
  }) %>%
  bind_rows()

news <- news %>%
  mutate(published_at = as_date(published_at) %>% as.character()) %>%
  mutate(author = replace_na(author, "(unknown author)"),
         description = replace_na(description, "(no description)")) %>%
  deselect(id) %>%
  rename(image = url_to_image)


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







news %>%
  deselect(l2, terms) %>%
  mutate(rn = row_number()) %>%
  pivot_longer(-rn) %>%
  mutate(value = paste0("\"", value, "\"")) %>%
  unite(col = yaml, name, value, sep = ": ") %>%
  #mutate(yaml = str_wrap(yaml, exdent = 3)) %>%
  group_by(rn) %>%
  summarize(yaml = paste(yaml, collapse = "\n")) %>%
  mutate(yaml = paste0("---\n", yaml, "\n---\n")) %>%
  rowwise() %>%
  pwalk(function(...) {
    x <- tibble(...)
    yaml <- x %>% pull(yaml)
    fileid <- x %>% pull(rn)
    write_lines(yaml, file = paste0("news-qmds/", fileid, ".qmd"))
  })
