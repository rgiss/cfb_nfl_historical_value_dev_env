# You can install using the pacman package using the following code:if (!requireNamespace('pacman', quietly = TRUE)){
if (!requireNamespace('pacman', quietly = TRUE)){
  install.packages('pacman')
}
pacman::p_load(tidyverse, nflfastR, zoo, ggimage, gt)
usethis::edit_r_environ()
install.packages("gsisdecoder")
install.packages("nflfastR")
library(nflfastR)
library(nflreadr)



pbp <- data.frame()
seasons <- 2000:2023
progressr::with_progress({
  pbp <- nflfastR::load_nfl_pbp(seasons)
})
write.csv(pbp,na="","/Users/riley.gisseman/Downloads/nfl_pbp_1999_2023.csv")

pbp <- data.frame()
seasons <- 2024
progressr::with_progress({
  pbp <- nflfastR::load_nfl_pbp(seasons)
})
write.csv(pbp,na="","/Users/riley.gisseman/Downloads/play_by_play_2024.csv")
# Made this chunk in 2024 to only re-write most recent season. I know there are better ways to do this but lazy & local.

# nfl_players.csv
players <- data.frame()
players <- nflreadr::load_players()
write.csv(players,na="","/Users/riley.gisseman/Downloads/nfl_players.csv")


# nfl_snap_counts.csv
install.packages("nflreadr")
library(nflreadr)
seasons <- 2012:2024
snap_counts <- data.frame()
progressr::with_progress({
  snap_counts <- nflreadr::load_snap_counts(seasons)
})
write.csv(snap_counts,na="","/Users/riley.gisseman/Downloads/nfl_snap_counts_2012_2024.csv")


# nfl_player_participation.csv
seasons <- 2016:2024

pp_data <- load_participation(
  seasons = TRUE,
  include_pbp = FALSE,
  file_type = getOption("nflreadr.prefer", default = "rds")
)
write_csv(pp_data, "nfl_player_participation_2016_present.csv")
