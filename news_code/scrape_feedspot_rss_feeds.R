# Scrape blog.feedspot.com RSS directory pages
# Jonathan Zadra
# 12/8/22

library(tidyverse)
library(integral)
library(rvest)
library(furrr)
plan(multisession)

options(future.rng.onMisuse = "ignore")


# Scrape the directory for all RSS categories -----------------------------


rss <- map(letters, function(page) {
  Sys.sleep(4) #throws 405 error if too many requests

  read_html(paste0("https://blog.feedspot.com/rss_directory/", page)) %>%
    html_nodes(".cat-col-1 a") %>%
    html_attr('href') %>%
    enframe(name = NULL, value = "url")
}) %>%
  bind_rows()

rss <- rss %>%
  mutate(url = str_remove(url, "\\?.*$"))

write_rds(rss, "news_code/data/feedspot_rss_directory_scrape.rds")


# Manually inspect (for now) to find relevant directory pages -------------


rss %>% filter(str_detect(url, "wind"))
rss %>% filter(str_detect(url, "energy"))
rss %>% filter(str_detect(url, "offshore"))
rss %>% filter(str_detect(url, "environment"))
rss %>% filter(str_detect(url, "ocean"))
rss %>% filter(str_detect(url, "santa"))



# Example using one of the results ----------------------------------------


wind_energy <- read_html("https://blog.feedspot.com/wind_energy_rss_feeds/") %>%
  html_nodes(".fa-rss+ .ext") %>%
  html_attr("href")

wind_energy <- wind_energy %>%
  enframe(name = NULL, value = "url") %>%
  filter(url != "")

results <- wind_energy$url %>%
  future_map(function(feed) {

    res <- try(tidyfeed(feed))

    if(!is_tibble(res)) return(NULL)

    res <- res %>%
      mutate(item_category = lst(item_category)) #Some of these don't return as list and bind_rows() fails

    return(res)

    }) %>%
  bind_rows()

