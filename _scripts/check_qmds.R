# libraries ----
librarian::shelf(
  dplyr, fs, glue, here, purrr, quarto, readr,
  multidplyr, parallel, furrr) # run in parallel on multiple CPUs

# paths ----
dir_qmd <- here("news")
log_csv <- here("_scripts/check_qmds_log.csv")
qmd_csv <- here("_scripts/check_qmds_notok.csv")

# function to check qmd ----
#   that logs and returns logical (TRUE or FALSE)
qmd_isok <- function(qmd, log_csv){
  # debug:
  #   qmd <- dir_ls(dir_qmd, glob = "*.qmd")[1]
  #   browser()

  # log()
  log <- function(status){
    d <- tibble(
      qmd    = basename(!!qmd),
      status = !!status,
      dtime  = Sys.time())
    if (!file_exists(log_csv)){
      write_csv(d, log_csv)
    } else {
      write_csv(d, log_csv, append = T)
    }
  }

  # copy qmd to temp file isolated and outside typical rendering environment
  tmp <- tempfile(fileext = ".qmd")
  file_copy(qmd, tmp)

  # render qmd, return FALSE if error
  r <- try(quarto_render(tmp))

  # get status: isok = F if error
  isok <- !"try-error" %in% class(r)

  # cleanup files
  dir_ls(
    path_dir(tmp),
    glob = glue("{path_ext_remove(tmp)}*")) %>%
    file_delete()

  # log and return status
  log(isok)
  isok
}

# setup cluster to parallelize ----
cl <- new_cluster(detectCores() - 1) # eg my MacBook Air has 8 CPUs, so 7 cores used
cluster_library(
  cl, c(
    "dplyr", "fs", "glue", "here", "purrr", "quarto", "readr"))
cluster_assign(
  cl,
  log_csv  = log_csv,
  qmd_isok = qmd_isok)

# check all qmds with cluster ----
d <- tibble(
  qmd = dir_ls(dir_qmd, glob = "*.qmd")) %>%
  partition(cl) %>%
  mutate(
    isok = map_lgl(qmd, qmd_isok, log_csv = log_csv))



# write out bad qmds ----
d %>%
  filter(!isok) %>%
  collect() %>%
  write_csv(qmd_csv)

# rename bad qmds with _* prefix to prevent auto render ----
read_csv(qmd_csv, show_col_types = F) %>%
  mutate(
    qmd_new = glue("{path_dir(qmd)}/_{path_file(qmd)}")) %>%
  filter(
    file_exists(qmd),
    !file_exists(qmd_new)) %>%
  pwalk(
    function(qmd, qmd_new, ...)
      file_move(qmd, qmd_new) )



#Using furrr ----
plan(multisession)
d <- tibble(
  qmd = dir_ls(dir_qmd, glob = "*.qmd")) %>%
  mutate(
    isok = future_map_lgl(qmd, qmd_isok, log_csv = log_csv))
