librarian::shelf(
  cli, crayon, integral, fs, janitor, lubridate, textclean, tidyRSS, tidyverse)

# Functions ---------------------------------------------------------------

scrape_rss <- function(feed) {
  feed %>%
    map(function(feed) {

      if(str_detect(feed, "^!")) {
        cli::cli_alert_danger("Skipping {feed}
                              \r")
        return(NULL)
      }

      cli::cli_alert_info("Reading {feed}")

      res <- tidyfeed(feed)

      #if(class(res$item_category) == "character") res <- res %>% nest(item_category = item_category)
      if(class(res$item_category) == "list") res <- res %>% mutate(item_category = map_chr(item_category, ~paste(.x, collapse = " | ")))


      return(res)

    }) %>%
    bind_rows()

}

update_feeds <- function(feed_files,
                         existing_rss_table = "news_code/data/rss_table.rds") {
  raw_feeds <- map(feed_files, function(feed_file) {

    cli::cli_alert_info("Starting feed scraping from {fs::path_file(feed_file)}...")
    feed <- read_lines(feed_file)

    scrape_rss(feed) %>%
      add_column(feed_file = as.character(feed_file))
  }) %>%
    bind_rows()

  rss <- raw_feeds %>%
    deselect(feed_last_build_date, feed_generator, feed_language) %>%
    mutate(across(c(item_title, item_description, feed_title, feed_description), ~str_squish(.x))) %>%
    mutate(across(where(is.character), ~if_else(.x == "", NA_character_, .x))) %>%
    distinct(across(-c(item_link, item_guid, item_comments, item_pub_date, feed_pub_date)), .keep_all = T) %>%
    mutate(item_pub_date = as_date(item_pub_date)) %>%
    mutate(rss_id = paste(abbreviate(replace_non_ascii(str_remove_all(item_title, "[^\\w]"))), abbreviate(replace_non_ascii(feed_title)), sep = "_")) %>%
    add_column(search_timestamp = as.character(now()))

  if(any(is.na(rss$item_title))) {
    cli_alert_danger(red("RSS items with no title are being removed:"))
    rss %>%
      filter(is.na(item_title)) %>%
      select(feed_title, item_link) %>%
      print()

    rss <- rss %>% filter(!is.na(item_title))
  }


  if(nrow(bad <- rss %>% get_dupes(rss_id)) > 0) {
    cli_alert_danger("Duplicate rss_id's in data.")
    print(bad)
    stop("Operation cannot continue")
  }

  existing_rss <- read_rds(existing_rss_table)

  new_rss <- rss %>%
    anti_join(existing_rss, by = "rss_id")


  rss <- existing_rss %>%
    rows_insert(rss, by = "rss_id", conflict = "ignore")


  rss %>%
    write_rds(existing_rss_table)

  return(new_rss)

}

create_rss_qmds <- function(rss_items, output_dir = "news") {

  if(nrow(rss_items) == 0) return(cli::cli_alert_info("No new rss items to create."))

  rss_items %>%
    mutate(item_pub_date = as.character(item_pub_date)) %>%
    add_column(image = "rss_img.png") %>%
    mutate(item_pub_date = coalesce(item_pub_date, as.character(as_date(search_timestamp)))) %>% #FIXME need to denote that this isn't the pub date or find the pub date
    select(title = item_title,
           source = feed_title,
           published_at = item_pub_date,
           url = item_link,
           description = item_description,
           image,
           rss_id) %>%
    pivot_longer(-rss_id) %>%
    #mutate(value = str_replace_all(value, '"', '\\"')) %>%
    #mutate(value = paste0("\"", value, "\"")) %>%
    mutate(yaml = case_when(name == "description" | name == "title" ~ paste0(name, ": >\n  ", value),
                            name == "source" | name == "url" ~paste0(name, ": \"", value, "\""),
                            TRUE ~ paste0(name, ": ", value))) %>%
    #unite(col = yaml, name, value, sep = ": >") %>%
    group_by(rss_id) %>%
    summarize(yaml = paste(yaml, collapse = "\n")) %>%
    mutate(yaml = paste0("---\n", yaml, "\n---\n")) %>%
    mutate(full_qmd = paste0(yaml, "\n
  Published: {{< meta published_at >}}\
  \n
  Source: {{< meta source >}}\
  \n
  [Read full article]({{< meta url >}})\
  \n")) %>%
    rowwise() %>%
    pwalk(function(...) {
      x <- tibble(...)

      #yaml <- x %>% pull(yaml)
      #fileid <- x %>% pull(news_id)
      write_lines(x$full_qmd, file = path_ext_set(path(output_dir, x$rss_id), "qmd"))

      cli::cli_alert_success("Successfully created {x$rss_id}.qmd")
    })
}

# x <- rvest::read_html("https://lostcoastoutpost.com/weather-alerts/1088/")
#
# x %>% html_attr("title")
#
# read_html("https://lostcoastoutpost.com/weather-alerts/1071/") %>%
#   html_nodes("title") %>%
#   html_text()
# rss %>%
#   mutate(item_title = if_else(is.na(item_title),
#                               read_html(item_link) %>%
#                                 html_nodes("title") %>%
#                                 html_text(), item_title))


# Get feeds ---------------------------------------------------------------

feed_files <- fs::dir_ls("news_code/rss_feeds/", glob = "*.txt")

rss_items <- update_feeds(feed_files)

# Filter feed for terms --------------------------------------------------

env_terms <- c("offshore wind", "wind energy", "seascape", "viewshed", "effects on wildlife")
loc_terms <- c("humboldt", "morro bay", "california")

rss_items <- rss_items %>%
  mutate(env_n = str_count(str_to_lower(item_description), paste0(env_terms, collapse = "|"))) %>%
  #mutate(loc_n = str_count(str_to_lower(item_description), paste0(loc_terms, collapse = "|"))) %>%
  filter(env_n > 0)


# Create qmds -------------------------------------------------------------


create_rss_qmds(rss_items)


#TODO: Check missing published_at / item_pub_date


