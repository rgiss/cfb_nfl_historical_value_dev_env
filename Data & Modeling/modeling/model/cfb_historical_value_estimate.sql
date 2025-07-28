drop table cfb_historical_value_estimate;
create table cfb_historical_value_estimate as
with game_log_dim as (
    select
        n.*
      , opp_adj.rec_share_adj_ratio                                                     as opp_rec_share_adj_ratio
      , team_adj.rec_share_adj_ratio                                                    as team_rec_share_adj_ratio
      , opp_adj.rec_yds_adj_ratio                                                       as opp_rec_yds_adj_ratio
      , team_adj.rec_yds_adj_ratio                                                      as team_rec_yds_adj_ratio
      , opp_adj.rec_tds_adj_ratio                                                       as opp_rec_tds_adj_ratio
      , team_adj.rec_tds_adj_ratio                                                      as team_rec_tds_adj_ratio
        -- PASSING STATS:
      , (sum(pass_attempts * opp_adj.pass_share_adj_ratio * team_adj.pass_share_adj_ratio * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
            + alpha_passes * pow(0.25, -experience_dec))
                / (sum(team_snaps * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
                + (alpha_passes + beta_passes_snaps) * pow(0.25, -experience_dec))      as est_passes_per_snap
      , (sum(completions * opp_adj.comp_pct_adj_ratio * team_adj.comp_pct_adj_ratio * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
            + alpha_comps * pow(0.25, -experience_dec))
                / (sum(pass_attempts * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
                + (alpha_comps + beta_comps_passes) * pow(0.25, -experience_dec))       as est_completion_pct
      , (sum(passing_touchdowns * opp_adj.pass_tds_adj_ratio * team_adj.pass_tds_adj_ratio * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
            + alpha_pass_tds * pow(0.25, -experience_dec))
                / (sum(completions * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
                + (alpha_pass_tds + beta_pass_tds_comps) * pow(0.25, -experience_dec))  as est_tds_per_completion
      , (sum(passing_yards * opp_adj.pass_yds_adj_ratio * team_adj.pass_yds_adj_ratio * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
            + alpha_pass_yds * pow(0.25, -experience_dec))
                / (sum(completions * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
                + (beta_pass_yds_comps) * pow(0.25, -experience_dec))                   as est_yards_per_completion
        -- RECEIVING STATS:
      , (sum(receptions * opp_adj.rec_share_adj_ratio * team_adj.rec_share_adj_ratio * pow(0.25, -experience_dec))
         over (partition by player_name, player_name_id order by true_date)
            + alpha_recs * pow(0.25, -experience_dec))
                / (sum(team_snaps * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
                + (beta_recs_snaps) * pow(0.25, -experience_dec))                       as est_rec_share
      , (sum(receiving_touchdowns * opp_adj.rec_tds_adj_ratio * team_adj.rec_tds_adj_ratio * pow(0.25, -experience_dec))
         over (partition by player_name, player_name_id order by true_date) + alpha_rec_tds * pow(0.25, -experience_dec))
                / (sum(targets * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
                + (alpha_rec_tds + beta_rec_tds_recs) * pow(0.25, -experience_dec))     as est_touchdowns_per_reception
      , (sum(receiving_yards * opp_adj.rec_yds_adj_ratio * team_adj.rec_yds_adj_ratio * pow(0.25, -experience_dec))
         over (partition by player_name, player_name_id order by true_date)
            + alpha_rec_yds * pow(0.25, -experience_dec))
                / (sum(receptions * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
                + (beta_rec_yds_recs) * pow(0.25, -experience_dec))                     as est_yds_per_rec
        -- RUSHING STATS:
      , (sum(rush_attempts * opp_adj.rush_share_adj_ratio * team_adj.rush_share_adj_ratio * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
            + alpha_rushes * pow(0.25, -experience_dec))
                / (sum(team_snaps * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
                + (alpha_rushes + beta_rushes_snaps) * pow(0.25, -experience_dec))      as est_rushes_per_snap
      , (sum(rushing_touchdowns * opp_adj.rush_tds_adj_ratio * team_adj.rush_tds_adj_ratio * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
            + alpha_rush_tds * pow(0.25, -experience_dec))
                / (sum(rush_attempts * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
                + (alpha_rush_tds + beta_rush_tds_rushes) * pow(0.25, -experience_dec)) as est_touchdowns_per_rush
      , (sum(rushing_yards * opp_adj.rush_yds_adj_ratio * team_adj.rush_yds_adj_ratio * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
            + alpha_rush_yds * pow(0.25, -experience_dec))
                / (sum(rush_attempts * pow(0.25, -experience_dec)) over (partition by player_name, player_name_id order by true_date)
                + (beta_rush_yds_rushes) * pow(0.25, -experience_dec))                  as est_yds_per_rush
    from cfb_game_logs                                      as n
         inner join cfb_beta_priors                         as b on b.position_group = n.position_group and team_snaps > 0
         left join cfb_opponent_strength_adjustment_metrics as opp_adj
                   on opp_adj.position_group = n.position_group and opp_adj.opponent_elo = coalesce(n.opponent_elo, 1000) and opp_adj.adj_from_is_home_game = n.is_home_game
         left join cfb_team_strength_adjustment_metrics     as team_adj
                   on team_adj.position_group = n.position_group and team_adj.team_elo = coalesce(n.team_elo, 1000)
    where
          player_name not in ('', 'Team', 'TEAM', 'team', '-', '#')
      and player_name not like '%Catch made%'
      and targets + pass_attempts + rush_attempts > 0
    )
select
    g.*
  , est_passes_per_snap * est_completion_pct                                        as est_completions
  , est_passes_per_snap * est_completion_pct * est_yards_per_completion             as est_pass_yards
  , est_passes_per_snap * est_completion_pct * est_tds_per_completion               as est_pass_td
  , est_rec_share                                                                   as est_receptions
  , est_rec_share * est_yds_per_rec                                                 as est_rec_yards
  , est_rec_share * est_touchdowns_per_reception                                    as est_rec_tds
  , est_rushes_per_snap * est_yds_per_rush                                          as est_rush_yards
  , est_rushes_per_snap * est_touchdowns_per_rush                                   as est_rush_tds
  , est_passes_per_snap * est_completion_pct * est_yards_per_completion * 0.04
            + est_passes_per_snap * est_completion_pct * est_tds_per_completion * 6 as est_passing_fantasy_points_per_snap
  , est_rec_share
            + est_rec_share * est_yds_per_rec * 0.1
            + est_rec_share * est_touchdowns_per_reception * 6                      as est_receiving_fantasy_points_per_snap
  , est_rushes_per_snap * est_yds_per_rush * 0.1
            + est_rushes_per_snap * est_touchdowns_per_rush * 6                     as est_rushing_fantasy_points_per_snap
  , est_passes_per_snap * est_completion_pct * est_yards_per_completion * 0.04
            + est_passes_per_snap * est_completion_pct * est_tds_per_completion * 6
            + est_rec_share
            + est_rec_share * est_yds_per_rec * 0.1
            + est_rec_share * est_touchdowns_per_reception * 6
            + est_rushes_per_snap * est_yds_per_rush * 0.1
            + est_rushes_per_snap * est_touchdowns_per_rush * 6                     as est_fantasy_points_per_snap
  , (est_passes_per_snap * est_completion_pct * est_yards_per_completion * 0.04
        + est_passes_per_snap * est_completion_pct * est_tds_per_completion * 6
        + est_rec_share
        + est_rec_share * est_yds_per_rec * 0.1
        + est_rec_share * est_touchdowns_per_reception * 6
        + est_rushes_per_snap * est_yds_per_rush * 0.1
        + est_rushes_per_snap * est_touchdowns_per_rush * 6)
            * case
                  when position_group = 'QB'
                      then 65
                  when position_group = 'TE'
                      then 50
                  when position_group = 'WR'
                      then 55
                  when position_group = 'RB'
                      then 45
                  end                                                               as est_fantasy_points_value
from game_log_dim as g