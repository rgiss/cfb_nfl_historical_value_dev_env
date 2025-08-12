# Required packages
library(nflreadr)
library(dplyr)
library(tidyr)
library(Matrix)
library(glmnet)
library(readr)

# --- Step 1: Load player participation data ---
pp_data <- load_participation(
  seasons = TRUE,
  include_pbp = TRUE,
  file_type = getOption("nflreadr.prefer", default = "rds")
)

colnames(pp_data)

pp_filtered <- pp_data %>%
  filter(qb_kneel == 0, qb_spike == 0, qb_dropback = 1)

# --- Step 2: Select relevant columns ---
pp_subset <- pp_filtered %>%
  select(nflverse_game_id, play_id, penalty, offense_players, defense_players) %>%
  filter(!is.na(offense_players), !is.na(defense_players))  %>%
  mutate(penalty = ifelse(is.na(penalty), 0, penalty))

summary(pp_subset$penalty)


# --- Step 3: Parse player strings into lists ---
pp_long <- pp_subset %>%
  mutate(row_id = row_number()) %>%
  mutate(
    offense_list = strsplit(offense_players, ";"),
    defense_list = strsplit(defense_players, ";")
  )

# --- Step 4: Create sparse design matrix ---
all_rows <- lapply(1:nrow(pp_long), function(i) {
  row <- pp_long[i, ]
  offense <- unlist(row$offense_list)
  defense <- unlist(row$defense_list)

  # Skip rows where both lists are empty
  if (length(offense) == 0 && length(defense) == 0) return(NULL)

  data.frame(
    row = i,
    player = c(offense, defense),
    value = c(rep(1, length(offense)), rep(-1, length(defense))),
    stringsAsFactors = FALSE
  )
})

# Remove NULLs
design_df <- bind_rows(all_rows)

# Remove duplicate (row, player) combos if any (only one +1/-1 per play per player)
design_df <- distinct(design_df, row, player, .keep_all = TRUE)

# Create sparse matrix
X_sparse <- sparseMatrix(
  i = design_df$row,
  j = as.integer(factor(design_df$player)),
  x = design_df$value,
  dims = c(nrow(pp_long), length(unique(design_df$player))),
  dimnames = list(NULL, levels(factor(design_df$player)))
)

# --- Step 5: Ridge Regression WITH POSITION-BASED PRIORS ---

# Define priors by position
position_priors <- c(
  QB   = -0.085,
  TE   = -0.0185,
  SPEC = -0.009,
  RB   = -0.0176,
  WR   = -0.016,
  DL   = -0.0156,
  DB   = -0.0136,
  OL   = -0.0105,
  LB   = -0.006
)

# Merge position info to get priors per player
player_meta <- load_players()
player_positions <- data.frame(gsis_id = colnames(X_sparse)) %>%
  left_join(player_meta %>% select(gsis_id, position_group), by = "gsis_id") %>%
  mutate(position_group = ifelse(is.na(position_group), "UNK", position_group))

# Get prior values per player
beta_0_vec <- sapply(player_positions$position_group, function(pos) {
  prior <- if (pos %in% names(position_priors)) position_priors[[pos]] else 0
})

# Assume prior weight is equivalent to 1000 plays for each player
prior_weight <- 1000
num_players <- ncol(X_sparse)

# Build identity matrix for priors (diagonal matrix)
I_sparse <- Diagonal(n = num_players)

# Augment design matrix and response vector
X_aug <- rbind(X_sparse, sqrt(prior_weight) * I_sparse)
y_aug <- c(y, sqrt(prior_weight) * beta_0_vec)

# Fit Ridge model with prior
lambda_val <- 0.1  # You can tune this
ridge_model <- glmnet(X_sparse, y, alpha = 0, lambda = lambda_val, intercept = FALSE)

# Get coefficients (exclude intercept)
coefs <- as.numeric(coef(ridge_model, s = lambda_val))[-1]
players <- colnames(X_sparse)
ra_penalty <- data.frame(gsis_id = players, ra_penalty_per_play = coefs)

# --- Step 6: Play counts per player ---
player_counts <- design_df %>%
  group_by(player) %>%
  summarize(play_count = n(), .groups = 'drop') %>%
  rename(gsis_id = player)

# --- Step 7: Merge + Total Impact ---
ra_penalty_df <- ra_penalty %>%
  left_join(player_counts, by = "gsis_id") %>%
  mutate(
    ra_penalty_total_impact = ra_penalty_per_play * play_count
  )

colnames(load_players)

# --- Step 8: Add Player Names (requires nflreadr::load_rosters) ---
player_meta <- load_players()
ra_penalty_named <- ra_penalty_df %>%
  left_join(player_meta %>% select(gsis_id, display_name, position_group), by = "gsis_id") %>%
  arrange(desc(ra_penalty_total_impact))

# --- Step 9: Save to CSV ---
write_csv(ra_penalty_named, "nfl_RA-penalty.csv")

# --- Step 10: Preview top players ---
print(head(ra_penalty_named, 20))
