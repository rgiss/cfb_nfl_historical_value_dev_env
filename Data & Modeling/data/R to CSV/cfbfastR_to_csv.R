# You can install using the pacman package using the following code:
if (!requireNamespace('pacman', quietly = TRUE)){
  install.packages('pacman')
}
pacman::p_load(dplyr,tidyr, gt)
pacman::p_load_current_gh("sportsdataverse/cfbfastR")
usethis::edit_r_environ()

library(cfbfastR)

pbp <- data.frame()
seasons <- 2014:cfbfastR:::most_recent_cfb_season()
progressr::with_progress({
  pbp <- cfbfastR::load_cfb_pbp(seasons)
})
tictoc::toc()
max(pbp[4])



progressr::with_progress({
  write.csv(pbp,na="","~/CFB_NFL_DEV_ENV/NFL_fantasy_app_SQL/data/raw_data/cfb_pbp_2014_2024.csv")
})

sapply(pbp,class)



elo_df <- data.frame()
seasons <- 2002:cfbfastR:::most_recent_cfb_season()
progressr::with_progress({
  
  elo_df <- cfbd_ratings_elo(year = seasons)
})

progressr::with_progress({
  write.csv(pbp,na="","/Users/riley.gisseman/Downloads/cfb_elo_2002_2024.csv")
})