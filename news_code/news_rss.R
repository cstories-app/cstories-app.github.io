library(tidyverse)
library(integral)
library(tidyRSS)


# Functions ---------------------------------------------------------------

scrape_rss <- function(feed) {
  feed %>%
    map(function(feed) {

      if(str_detect(feed, "^!")) {
        cli::cli_alert_danger("Skipping {feed}
                              \r")
        return(NULL)
      }

      cli::cli_alert_info("Reading {feed}...")

      return(tidyfeed(feed))

    }) %>%
    bind_rows()

}


# Get feeds ---------------------------------------------------------------


sb_feeds <- read_lines("news_code/rss_feeds_santa_barbara.txt") %>%
  scrape_rss

hb_feeds <- read_lines("news_code/rss_feeds_humboldt.txt") %>%
  scrape_rss()


feed_sb <- scrape_rss(sb_rss)

  keyt <- tidyfeed("keyt.com/feed")

keyt %>% filter(str_detect(item_description, "wind"))

keyt %>% slice(1) %>% glimpse



