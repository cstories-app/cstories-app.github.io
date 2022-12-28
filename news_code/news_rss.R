library(tidyverse)
library(integral)
library(tidyRSS)


sb_rss <- read_lines("news_code/rss_feeds_santa_barbara.txt")

feed_sb <- sb_rss %>%
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

keyt <- tidyfeed("keyt.com/feed")

keyt %>% filter(str_detect(item_description, "wind"))

keyt %>% slice(1) %>% glimpse



