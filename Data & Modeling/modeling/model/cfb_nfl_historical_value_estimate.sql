drop table cfb_nfl_historical_value_estimate;
create table cfb_nfl_historical_value_estimate as
with union_game_logs as (
    select distinct
        player_name
      , gsis_id
      , coalesce(player_display_name, player_name || ': ' || player_name_id) as player_display_name
      , position_group
      , game_id::varchar(255)                                                as game_id
      , 'cfb'                                                                as league
      , team
      , opponent
      , team_elo
      , opponent_elo
      , is_home_game
      , year::float                                                          as year
      , week
      , approximate_date                                                     as approximate_date
      , season::float                                                        as season
      , true_date
      , experience_yrs
      , experience_dec
      , approximate_age
      , coalesce(true_age +
        case
            when player_name = 'Tetairoa McMillan'
                then 0.3
            when player_name = 'Travis Hunter'
                then 0.2
            when player_name = 'Jayden Higgins'
                then 0.8
            when player_name = 'Jaylin Noel'
                then -0.2
            when player_name = 'Colston Loveland'
                then -0.9
            when player_name = 'Emeka Egbuka'
                then -0.4
            when player_name = 'Xavier Restrepo'
                then -0.7
            when player_name = 'Harold Fannin Jr.'
                then -1
            when player_name = 'Tez Johnson'
                then -0.8
            when player_name = 'Gunnar Helm'
                then -1
            when player_name = 'Matthew Golden'
                then -0.1
            when player_name = 'Jack Bech'
                then 0
            when player_name = 'Tre Harris'
                then 0
            when player_name = 'Luther Burden III'
                then 0
            when player_name = 'Dont''e Thornton'
                then -0.2
                else 0
            end)
                                                                             as true_age
      , player_game_number
      , player_games_remaining
      , player_season_game_number
      , player_season_games_remaining
      , player_dropbacks
      , team_dropbacks
      , team_snaps
      , null::float                                                          as snap_percent
      , null::float                                                          as snap_count
      , pass_attempts
      , completions
      , completion_percentage
      , passing_yards
      , passing_yards_per_completion
      , passing_yards_per_attempt
      , passing_air_yards
      , passing_air_yards_per_attempt
      , passing_touchdowns
      , passing_touchdowns_per_attempt
      , sacks_taken
      , sacks_per_dropback
      , targets
      , receptions
      , receiving_yards
      , air_yards::float                                                     as air_yards
      , yards_after_catch::float                                             as yards_after_catch
      , receiving_touchdowns
      , rush_attempts
      , rushing_yards
      , rushing_touchdowns
      , twopt_conversions::float                                             as twopt_conversions
      , fumbles
      , fumbles_lost
      , passing_interception
      , receiver_interception
      , return_yards
      , return_touchdowns
      , epa
      , fantasy_points_std
      , fantasy_points_half_ppr
      , fantasy_points_ppr
      , fantasy_points_t
    from cfb_game_logs
    union all
    select
        player_name
      , gsis_id
      , player_display_name
      , position_group
      , game_id::varchar(255)
      , 'nfl' as league
      , team
      , opponent
      , null
      , null
      , null
      , year
      , week
      , game_date::date
      , year
      , true_date
      , experience_yrs
      , experience_dec
      , age
      , true_age
      , player_game_number
      , player_games_remaining
      , player_season_game_number
      , player_season_games_remaining
      , player_dropbacks
      , team_dropbacks
      , team_snaps
      , snap_percent
      , snap_count
      , pass_attempts
      , completions
      , completion_percentage
      , passing_yards
      , passing_yards_per_completion
      , passing_yards_per_attempt
      , passing_air_yards
      , passing_air_yards_per_attempt
      , passing_touchdowns
      , passing_touchdowns_per_attempt
      , sacks_taken
      , sacks_per_dropback
      , targets
      , receptions
      , receiving_yards
      , air_yards
      , yards_after_catch
      , receiving_touchdowns
      , rush_attempts
      , rushing_yards
      , rushing_touchdowns
      , twopt_conversions
      , fumbles
      , fumbles_lost
      , passing_interception
      , receiver_interception
      , return_yards
      , return_touchdowns
      , epa
      , fantasy_points_std
      , fantasy_points_half_ppr
      , fantasy_points_ppr
      , fantasy_points_t
    from nfl_game_logs
    where
        gsis_id <> '00-0021306'
    )
   , base_stats as (
    select
          n.*
      ,   (sum(snap_count * pow(0.15, -(true_date - 1999))) over (partition by player_display_name order by true_date)
            + nfl.alpha_snaps * pow(0.15, -(true_date - 1999)))
                  / (
                    sum(snap_count / nullif(snap_percent, 0) * pow(0.15, -(true_date - 1999)))
                    over (partition by player_display_name order by true_date)
                    + (nfl.alpha_snaps + nfl.beta_non_snaps) * pow(0.15, -(true_date - 1999)))                                                                     as est_snap_share
          -- PASSING STATS:
      ,   (sum(
           pass_attempts
                   * coalesce(opp_adj.pass_share_adj_ratio, 1)
                   * coalesce(team_adj.pass_share_adj_ratio, 1)
                   * pow(0.25, -(true_date - 1999)))
           over (partition by player_display_name order by true_date)
            + coalesce(cfb.alpha_passes, nfl.alpha_passes) * pow(0.25, -(true_date - 1999)))
                  / (
                    sum(coalesce(snap_count, team_snaps) * pow(0.25, -(true_date - 1999)))
                    over (partition by player_display_name order by true_date)
                    + (coalesce(cfb.alpha_passes, nfl.alpha_passes) + coalesce(cfb.beta_passes_snaps, nfl.beta_passes_snaps)) * pow(0.25, -(true_date - 1999)))    as est_passes_per_snap
          -- snap count estimates not as good for pre 2012
      ,   (sum(
           completions
                   * coalesce(opp_adj.comp_pct_adj_ratio, 1)
                   * coalesce(team_adj.comp_pct_adj_ratio, 1)
                   * pow(0.5, -(true_date - 1999)))
           over (partition by player_display_name order by true_date)
            + coalesce(cfb.alpha_comps, nfl.alpha_comps) * pow(0.5, -(true_date - 1999)))
                  / (sum(pass_attempts * pow(0.5, -(true_date - 1999))) over (partition by player_display_name order by true_date)
                + (coalesce(cfb.alpha_comps, nfl.alpha_comps) + coalesce(cfb.beta_comps_passes, nfl.beta_comps_passes)) * pow(0.5, -(true_date - 1999)))           as est_completion_pct
      ,   (sum(
           passing_touchdowns
                   * coalesce(opp_adj.pass_tds_adj_ratio, 1)
                   * coalesce(team_adj.pass_tds_adj_ratio, 1)
                   * pow(0.5, -(true_date - 1999)))
           over (partition by player_display_name order by true_date)
            + coalesce(cfb.alpha_pass_tds, nfl.alpha_pass_tds) * pow(0.5, -(true_date - 1999)))
                  / (sum(completions * pow(0.5, -(true_date - 1999))) over (partition by player_display_name order by true_date)
                + (coalesce(cfb.alpha_pass_tds, nfl.alpha_pass_tds) + coalesce(cfb.beta_pass_tds_comps, nfl.beta_pass_tds_comps)) * pow(0.5, -(true_date - 1999))) as est_tds_per_completion
      ,   (sum(
           passing_yards
                   * coalesce(opp_adj.pass_yds_adj_ratio, 1)
                   * coalesce(team_adj.pass_yds_adj_ratio, 1)
                   * pow(0.25, -(true_date - 1999)))
           over (partition by player_display_name order by true_date)
            + coalesce(cfb.alpha_pass_yds, nfl.alpha_pass_yds) * pow(0.25, -(true_date - 1999)))
                  / (sum(completions * pow(0.25, -(true_date - 1999))) over (partition by player_display_name order by true_date)
                + coalesce(cfb.beta_pass_yds_comps, nfl.beta_pass_yds_comps) * pow(0.25, -(true_date - 1999)))                                                     as est_yards_per_completion
          -- RECEIVING STATS:
      ,   (sum(
           targets
                   * pow(0.25, -(true_date - 1999)))
           over (partition by player_display_name order by true_date)
            + nfl.alpha_tgts * pow(0.25, -(true_date - 1999)))
                  / (
                    sum(coalesce(snap_count, team_snaps) * pow(0.25, -(true_date - 1999)))
                    over (partition by player_display_name order by true_date)
                    + (nfl.alpha_tgts + nfl.beta_tgts_snaps) * pow(0.25, -(true_date - 1999)))                                                                     as est_tgt_share
      ,   (sum(
           receptions
                   * pow(0.25, -(true_date - 1999)))
           over (partition by player_display_name order by true_date)
            + nfl.alpha_recs * pow(0.25, -(true_date - 1999)))
                  / (sum(targets * pow(0.25, -(true_date - 1999))) over (partition by player_display_name order by true_date)
                + (nfl.alpha_recs + nfl.beta_recs_tgts) * pow(0.25, -(true_date - 1999)))                                                                          as est_catch_pct -- too high from 2003-2008
      ,   (sum(
           receptions
                   * coalesce(opp_adj.rec_share_adj_ratio, 1)
                   * coalesce(team_adj.rec_share_adj_ratio, 1)
                   * pow(0.25, -(true_date - 1999)))
           over (partition by player_display_name order by true_date)
            + coalesce(cfb.alpha_recs, nfl.alpha_rec_snaps) * pow(0.25, -(true_date - 1999)))
                  / (sum(team_snaps * pow(0.25, -(true_date - 1999))) over (partition by player_display_name order by true_date)
                + coalesce(cfb.beta_recs_snaps, nfl.beta_rec_snaps) * pow(0.25, -(true_date - 1999)))                                                              as est_rec_share
      ,   (sum(
           receiving_touchdowns
                   * coalesce(opp_adj.rec_tds_adj_ratio, 1)
                   * coalesce(team_adj.rec_tds_adj_ratio, 1)
                   * pow(0.7, -(true_date - 1999)))
           over (partition by player_display_name order by true_date)
            + coalesce(cfb.alpha_rec_tds, nfl.alpha_rec_tds) * pow(0.7, -(true_date - 1999)))
                  / (sum(receptions * pow(0.7, -(true_date - 1999))) over (partition by player_display_name order by true_date)
                + (coalesce(cfb.alpha_rec_tds, nfl.alpha_rec_tds) + coalesce(cfb.beta_rec_tds_recs, nfl.beta_rec_tds_recs))
                    * pow(0.7, -(true_date - 1999)))                                                                                                               as est_touchdowns_per_reception
      ,   (sum(
           receiving_yards
                   * coalesce(opp_adj.rec_yds_adj_ratio, 1)
                   * coalesce(team_adj.rec_yds_adj_ratio, 1)
                   * pow(0.5, -(true_date - 1999)))
           over (partition by player_display_name order by true_date)
            + coalesce(cfb.alpha_rec_yds, nfl.alpha_rec_yds) * pow(0.5, -(true_date - 1999)))
                  / (sum(receptions * pow(0.5, -(true_date - 1999))) over (partition by player_display_name order by true_date)
                + coalesce(cfb.beta_rec_yds_recs, nfl.beta_rec_yds_recs) * pow(0.5, -(true_date - 1999)))                                                          as est_yds_per_rec
          -- RUSHING STATS:
      ,   (sum(
           rush_attempts
                   * coalesce(opp_adj.rush_share_adj_ratio, 1)
                   * coalesce(team_adj.rush_share_adj_ratio, 1)
                   * pow(0.25, -(true_date - 1999)))
           over (partition by player_display_name order by true_date)
            + coalesce(cfb.alpha_rushes, nfl.alpha_rushes) * pow(0.25, -(true_date - 1999)))
                  / (
                    sum(coalesce(snap_count, team_snaps) * pow(0.25, -(true_date - 1999)))
                    over (partition by player_display_name order by true_date)
                    + (coalesce(cfb.alpha_rushes, nfl.alpha_rushes) + coalesce(cfb.beta_rushes_snaps, nfl.beta_rushes_snaps)) * pow(0.25, -(true_date - 1999)))    as est_rushes_per_snap
      ,   (sum(
           rushing_touchdowns
                   * coalesce(opp_adj.rush_tds_adj_ratio, 1)
                   * coalesce(team_adj.rush_tds_adj_ratio, 1)
                   * pow(0.7, -(true_date - 1999)))
           over (partition by player_display_name order by true_date)
            + coalesce(cfb.alpha_rush_tds, nfl.alpha_rush_tds) * pow(0.7, -(true_date - 1999)))
                  / (sum(rush_attempts * pow(0.7, -(true_date - 1999))) over (partition by player_display_name order by true_date)
                + (coalesce(cfb.alpha_rush_tds, nfl.alpha_rush_tds) + coalesce(cfb.beta_rush_tds_rushes, nfl.beta_rush_tds_rushes))
                    * pow(0.7, -(true_date - 1999)))                                                                                                               as est_touchdowns_per_rush
      ,   (sum(
           rushing_yards
                   * coalesce(opp_adj.rush_yds_adj_ratio, 1)
                   * coalesce(team_adj.rush_yds_adj_ratio, 1)
                   * pow(0.5, -(true_date - 1999)))
           over (partition by player_display_name order by true_date)
            + coalesce(cfb.alpha_rush_yds, nfl.alpha_rush_yds) * pow(0.5, -(true_date - 1999)))
                  / (sum(rush_attempts * pow(0.5, -(true_date - 1999))) over (partition by player_display_name order by true_date)
                + coalesce(cfb.beta_rush_yds_rushes, nfl.beta_rush_yds_rushes) * pow(0.5, -(true_date - 1999)))                                                    as est_yds_per_rush
    from union_game_logs                                    as n
         left join nfl_beta_priors                          as nfl on nfl.position_group = n.position_group and nfl.since_2012 = (n.year >= 2012) and n.league = 'nfl'
         left join cfb_beta_priors                          as cfb on cfb.position_group = n.position_group and n.league = 'cfb'
         left join nfl_beta_priors                          as prior on prior.position_group = n.position_group and prior.since_2012 = true
         left join cfb_opponent_strength_adjustment_metrics as opp_adj
                   on opp_adj.adj_from_is_home_game = n.is_home_game and opp_adj.position_group = n.position_group and opp_adj.opponent_elo = coalesce(n.opponent_elo, 1000)
                           and n.league = 'cfb'
         left join cfb_team_strength_adjustment_metrics     as team_adj on team_adj.position_group = n.position_group and team_adj.team_elo = coalesce(n.team_elo, 1000) and n.league = 'cfb'
    )
select
    coalesce(nfl_hex.primary_color, cfb_hex.primary_color)                                                                              as team_primary_color_hex
  , b.*
  , est_passes_per_snap * est_completion_pct * coalesce(est_snap_share, 1) * 65                                                         as est_completions_per_game
  , est_passes_per_snap * est_completion_pct * est_yards_per_completion * coalesce(est_snap_share, 1) * 65                              as est_pass_yards_per_game
  , est_passes_per_snap * est_completion_pct * est_tds_per_completion * coalesce(est_snap_share, 1) * 65                                as est_pass_td_per_game
  , coalesce(est_tgt_share * est_catch_pct, est_rec_share) * coalesce(est_snap_share, 1) * 65                                           as est_receptions_per_game
  , coalesce(est_tgt_share * est_catch_pct, est_rec_share) * est_yds_per_rec * coalesce(est_snap_share, 1) * 65                         as est_rec_yards_per_game
  , coalesce(est_tgt_share * est_catch_pct, est_rec_share) * est_touchdowns_per_reception * coalesce(est_snap_share, 1) * 65            as est_rec_tds_per_game
  , est_rushes_per_snap * est_yds_per_rush * coalesce(est_snap_share, 1) * 65                                                           as est_rush_yards_per_game
  , est_rushes_per_snap * est_touchdowns_per_rush * coalesce(est_snap_share, 1) * 65                                                    as est_rush_tds_per_game
  , (est_passes_per_snap * est_completion_pct * est_yards_per_completion * 0.04
        + est_passes_per_snap * est_completion_pct * est_tds_per_completion * 6) * coalesce(est_snap_share, 1) * 65                     as est_passing_fantasy_points_per_game
  , (coalesce(est_tgt_share * est_catch_pct, est_rec_share)
        + coalesce(est_tgt_share * est_catch_pct, est_rec_share) * est_yds_per_rec * 0.1
        + coalesce(est_tgt_share * est_catch_pct, est_rec_share) * est_touchdowns_per_reception * 6) * coalesce(est_snap_share, 1) * 65 as est_receiving_fantasy_points_per_game
  , (est_rushes_per_snap * est_yds_per_rush * 0.1
        + est_rushes_per_snap * est_touchdowns_per_rush * 6) * coalesce(est_snap_share, 1) * 65                                         as est_rushing_fantasy_points_per_game
  , (est_passes_per_snap * est_completion_pct * est_yards_per_completion * 0.04
        + est_passes_per_snap * est_completion_pct * est_tds_per_completion * 6
        + coalesce(est_tgt_share * est_catch_pct, est_rec_share)
        + coalesce(est_tgt_share * est_catch_pct, est_rec_share) * est_yds_per_rec * 0.1
        + coalesce(est_tgt_share * est_catch_pct, est_rec_share) * est_touchdowns_per_reception * 6
        + est_rushes_per_snap * est_yds_per_rush * 0.1
        + est_rushes_per_snap * est_touchdowns_per_rush * 6)                                                                            as est_fantasy_points_per_snap
  , (est_passes_per_snap * est_completion_pct * est_yards_per_completion * 0.04
        + est_passes_per_snap * est_completion_pct * est_tds_per_completion * 6
        + coalesce(est_tgt_share * est_catch_pct, est_rec_share)
        + coalesce(est_tgt_share * est_catch_pct, est_rec_share) * est_yds_per_rec * 0.1
        + coalesce(est_tgt_share * est_catch_pct, est_rec_share) * est_touchdowns_per_reception * 6
        + est_rushes_per_snap * est_yds_per_rush * 0.1
        + est_rushes_per_snap * est_touchdowns_per_rush * 6)
            * coalesce(est_snap_share, 1) * 65                                                                                          as est_fantasy_points_per_game
from base_stats as b
     left join nfl_hex on nfl_hex.team_code = b.team
     left join cfb_hex on cfb_hex.team_name = b.team