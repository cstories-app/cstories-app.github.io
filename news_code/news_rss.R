library(tidyverse)
library(integral)
library(tidyRSS)


sb_rss <- read_lines("news/rss_feeds_santa_barbara.txt")

sb_rss %>%
  map(~tidyfeed(.x)) %>%
  bind_rows()

keyt <- tidyfeed("keyt.com/feed")

keyt %>% filter(str_detect(item_description, "wind"))
