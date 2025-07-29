drop table cfb_beta_priors;
create table cfb_beta_priors as
with players_grouping as (
    select
        player_name
      , year
      , gl.position_group
      , sum(team_snaps)                                                   as snaps
      , (.37 + sum(receptions * opp_adj.rec_share_adj_ratio * team_adj.rec_share_adj_ratio * nfl_adj.rec_share_adj_ratio))
                / (6.9 + (sum(team_snaps) - sum(receptions)))             as receptions_per_non_reception
      , case
            when sum(receiving_yards * opp_adj.rec_yds_adj_ratio * team_adj.rec_yds_adj_ratio * nfl_adj.rec_yds_adj_ratio) > 0
                then (1.0 + sum(receiving_yards * opp_adj.rec_yds_adj_ratio * team_adj.rec_yds_adj_ratio)) / (.1 + (sum(receptions)))
            end                                                           as yards_per_reception
      , (.16 + sum(receiving_touchdowns * opp_adj.rec_tds_adj_ratio * team_adj.rec_tds_adj_ratio * nfl_adj.rec_tds_adj_ratio))
                / (3.1 + (sum(receptions) - sum(receiving_touchdowns)))   as rec_touchdowns_per_non_rec_touchdown
      , (1.38 + sum(rush_attempts * opp_adj.rush_share_adj_ratio * team_adj.rush_share_adj_ratio * nfl_adj.rush_share_adj_ratio))
                / (2.59 + (sum(team_snaps) - sum(rush_attempts)))         as rushs_per_non_rush
      , (7.6 + sum(pass_attempts * opp_adj.pass_share_adj_ratio * team_adj.pass_share_adj_ratio * nfl_adj.pass_share_adj_ratio))
                / (6.4 + (sum(team_snaps) - sum(pass_attempts)))          as passes_per_non_pass
      , (.36 + sum(completions * opp_adj.comp_pct_adj_ratio * team_adj.comp_pct_adj_ratio * nfl_adj.comp_pct_adj_ratio))
                / (.225 + (sum(pass_attempts) - sum(completions)))        as completions_per_non_completion
      , case
            when sum(rushing_yards * opp_adj.rush_yds_adj_ratio * team_adj.rush_yds_adj_ratio * nfl_adj.rush_yds_adj_ratio) > 0
                then (33.11 + sum(rushing_yards * opp_adj.rush_yds_adj_ratio * team_adj.rush_yds_adj_ratio * nfl_adj.rush_yds_adj_ratio)) / (7.85 + (sum(rush_attempts)))
            end                                                           as yards_per_rush
      , case
            when sum(passing_yards * opp_adj.pass_yds_adj_ratio * team_adj.pass_yds_adj_ratio * nfl_adj.pass_yds_adj_ratio) > 0
                then (7.374 + sum(passing_yards * opp_adj.pass_yds_adj_ratio * team_adj.pass_yds_adj_ratio * nfl_adj.pass_yds_adj_ratio)) / (1.2 * 0.62 + (sum(completions)))
            end                                                           as yards_per_completion
      , (.085 + sum(rushing_touchdowns * opp_adj.rush_tds_adj_ratio * team_adj.rush_tds_adj_ratio * nfl_adj.rush_tds_adj_ratio))
                / (3.97 + (sum(rush_attempts) - sum(rushing_touchdowns))) as rush_touchdowns_per_non_rush_touchdown
      , (.377 + sum(passing_touchdowns * opp_adj.pass_tds_adj_ratio * team_adj.pass_tds_adj_ratio * nfl_adj.pass_tds_adj_ratio))
                / (12.35 + (sum(completions) - sum(passing_touchdowns)))  as pass_touchdowns_per_non_pass_touchdown
    from cfb_game_logs                                      as gl
         left join cfb_opponent_strength_adjustment_metrics as opp_adj
                   on opp_adj.opponent_elo = coalesce(gl.opponent_elo, 1000) and opp_adj.adj_from_is_home_game = gl.is_home_game and opp_adj.position_group = gl.position_group
         left join cfb_team_strength_adjustment_metrics     as team_adj on team_adj.team_elo = coalesce(gl.team_elo, 1000) and team_adj.position_group = gl.position_group
         left join cfb_nfl_metrics_adjustment_dim           as nfl_adj on nfl_adj.position_group = gl.position_group
    where team_snaps between 40 and 100 and experience_yrs < 1
    group by
        1, 2, 3
    )
--   select round((1-1/(1+receptions_per_non_reception))*200)/200, count(*) from players_grouping where dropbacks > 250 group by 1;
   , weighted_mean as (
    select
        position_group
      , sum(ln(rushs_per_non_rush) * snaps) / sum(snaps)                     as ln_weighted_avg_rushes
      , sum(ln(yards_per_rush) * snaps) / sum(snaps)                         as ln_weighted_avg_rush_yds
      , sum(ln(rush_touchdowns_per_non_rush_touchdown) * snaps) / sum(snaps) as ln_weighted_avg_rush_tds
      , sum(ln(passes_per_non_pass) * snaps) / sum(snaps)                    as ln_weighted_avg_passes
      , sum(ln(completions_per_non_completion) * snaps) / sum(snaps)         as ln_weighted_avg_completions
      , sum(ln(yards_per_completion) * snaps) / sum(snaps)                   as ln_weighted_avg_pass_yds
      , sum(ln(pass_touchdowns_per_non_pass_touchdown) * snaps) / sum(snaps) as ln_weighted_avg_pass_tds
      , sum(ln(receptions_per_non_reception) * snaps) / sum(snaps)           as ln_weighted_avg_recs
      , sum(ln(yards_per_reception) * snaps) / sum(snaps)                    as ln_weighted_avg_rec_yds
      , sum(ln(rec_touchdowns_per_non_rec_touchdown) * snaps) / sum(snaps)   as ln_weighted_avg_rec_tds
    from players_grouping
    group by
        1
    )
   , position_group_log_norm_features as (
    select
        pg.position_group
        -- RECEIVING STATS
      , exp(sum(ln(receptions_per_non_reception) * snaps) / sum(snaps))                                                                                   as receptions_per_non_reception --weighted geo mean
      , exp(sqrt(sum(snaps * power(ln(receptions_per_non_reception) - wm.ln_weighted_avg_recs, 2)) / sum(snaps)))                                         as weighted_geo_stdev_recs
      , 1 - 1 / (1 + exp(sum(ln(receptions_per_non_reception) * snaps) / sum(snaps)))                                                                     as rec_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(receptions_per_non_reception) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(receptions_per_non_reception) - wm.ln_weighted_avg_recs, 2)) / sum(snaps))), 2.32))                       as rec_share_1st
      , 1 - 1 / (1 + exp(sum(ln(receptions_per_non_reception) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(receptions_per_non_reception) - wm.ln_weighted_avg_recs, 2)) / sum(snaps))), 2.32))                       as rec_share_99th
      , exp(sqrt(sum(snaps * power(ln(rec_touchdowns_per_non_rec_touchdown) - wm.ln_weighted_avg_rec_tds, 2)) / sum(snaps)))                              as weighted_geo_stdev_rec_tds
      , 1 - 1 / (1 + exp(sum(ln(rec_touchdowns_per_non_rec_touchdown) * snaps) / sum(snaps)))                                                             as rec_td_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(rec_touchdowns_per_non_rec_touchdown) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(rec_touchdowns_per_non_rec_touchdown) - wm.ln_weighted_avg_rec_tds, 2)) / sum(snaps))), 2.32))            as rec_td_share_1st
      , 1 - 1 / (1 + exp(sum(ln(rec_touchdowns_per_non_rec_touchdown) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(rec_touchdowns_per_non_rec_touchdown) - wm.ln_weighted_avg_rec_tds, 2)) / sum(snaps))), 2.32))            as rec_td_share_99th
      , exp(sqrt(sum(snaps * power(ln(yards_per_reception) - wm.ln_weighted_avg_rec_yds, 2)) / sum(snaps)))                                               as weighted_geo_stdev_rec_yds
      , 1 - 1 / (1 + exp(sum(ln(yards_per_reception) * snaps) / sum(snaps)))                                                                              as rec_yds_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(yards_per_reception) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(yards_per_reception) - wm.ln_weighted_avg_rec_yds, 2)) / sum(snaps))), 2.32))                             as rec_yds_share_1st
      , 1 - 1 / (1 + exp(sum(ln(yards_per_reception) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(yards_per_reception) - wm.ln_weighted_avg_rec_yds, 2)) / sum(snaps))), 2.32))                             as rec_yds_share_99th
        -- PASSING STATS:
      , exp(sqrt(sum(snaps * power(ln(passes_per_non_pass) - wm.ln_weighted_avg_passes, 2)) / sum(snaps)))                                                as weighted_geo_stdev_passes
      , 1 - 1 / (1 + exp(sum(ln(passes_per_non_pass) * snaps) / sum(snaps)))                                                                              as pass_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(passes_per_non_pass) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(passes_per_non_pass) - wm.ln_weighted_avg_passes, 2)) / sum(snaps))), 2.32))                              as pass_share_1st
      , 1 - 1 / (1 + exp(sum(ln(passes_per_non_pass) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(passes_per_non_pass) - wm.ln_weighted_avg_passes, 2)) / sum(snaps))), 2.32))                              as pass_share_99th
      , exp(sqrt(sum(snaps * power(ln(completions_per_non_completion) - wm.ln_weighted_avg_completions, 2)) / sum(snaps)))                                as weighted_geo_stdev_completions
      , 1 - 1 / (1 + exp(sum(ln(completions_per_non_completion) * snaps) / sum(snaps)))                                                                   as completion_pct --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(completions_per_non_completion) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(completions_per_non_completion) - wm.ln_weighted_avg_completions, 2)) / sum(snaps))), 2.32))              as completion_pct_1st
      , 1 - 1 / (1 + exp(sum(ln(completions_per_non_completion) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(completions_per_non_completion) - wm.ln_weighted_avg_completions, 2)) / sum(snaps))), 2.32))              as completion_pct_99th
      , exp(sqrt(sum(snaps * power(ln(pass_touchdowns_per_non_pass_touchdown) - wm.ln_weighted_avg_pass_tds, 2)) / sum(snaps))) * 1.001                   as weighted_geo_stdev_pass_tds
      , 1 - 1 / (1 + exp(sum(ln(pass_touchdowns_per_non_pass_touchdown) * snaps) / sum(snaps)))                                                           as pass_td_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(pass_touchdowns_per_non_pass_touchdown) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(pass_touchdowns_per_non_pass_touchdown) - wm.ln_weighted_avg_pass_tds, 2)) / sum(snaps))) * 1.001, 2.32)) as pass_td_share_1st
      , 1 - 1 / (1 + exp(sum(ln(pass_touchdowns_per_non_pass_touchdown) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(pass_touchdowns_per_non_pass_touchdown) - wm.ln_weighted_avg_pass_tds, 2)) / sum(snaps))) * 1.001, 2.32)) as pass_td_share_99th
      , exp(sqrt(sum(snaps * power(ln(yards_per_completion) - wm.ln_weighted_avg_pass_yds, 2)) / sum(snaps))) * 1.001                                     as weighted_geo_stdev_pass_yds
      , 1 - 1 / (1 + exp(sum(ln(yards_per_completion) * snaps) / sum(snaps)))                                                                             as pass_yds_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(yards_per_completion) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(yards_per_completion) - wm.ln_weighted_avg_pass_yds, 2)) / sum(snaps))) * 1.001, 2.32))                   as pass_yds_share_1st
      , 1 - 1 / (1 + exp(sum(ln(yards_per_completion) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(yards_per_completion) - wm.ln_weighted_avg_pass_yds, 2)) / sum(snaps))) * 1.001, 2.32))                   as pass_yds_share_99th
        -- RUSHING STATS:
      , exp(sqrt(sum(snaps * power(ln(rushs_per_non_rush) - wm.ln_weighted_avg_rushes, 2)) / sum(snaps)))                                                 as weighted_geo_stdev_rushes
      , 1 - 1 / (1 + exp(sum(ln(rushs_per_non_rush) * snaps) / sum(snaps)))                                                                               as rush_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(rushs_per_non_rush) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(rushs_per_non_rush) - wm.ln_weighted_avg_rushes, 2)) / sum(snaps))), 2.32))                               as rush_share_1st
      , 1 - 1 / (1 + exp(sum(ln(rushs_per_non_rush) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(rushs_per_non_rush) - wm.ln_weighted_avg_rushes, 2)) / sum(snaps))), 2.32))                               as rush_share_99th
      , exp(sqrt(sum(snaps * power(ln(rush_touchdowns_per_non_rush_touchdown) - wm.ln_weighted_avg_rush_tds, 2)) / sum(snaps)))                           as weighted_geo_stdev_rush_tds
      , 1 - 1 / (1 + exp(sum(ln(rush_touchdowns_per_non_rush_touchdown) * snaps) / sum(snaps)))                                                           as rush_td_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(rush_touchdowns_per_non_rush_touchdown) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(rush_touchdowns_per_non_rush_touchdown) - wm.ln_weighted_avg_rush_tds, 2)) / sum(snaps))), 2.32))         as rush_td_share_1st
      , 1 - 1 / (1 + exp(sum(ln(rush_touchdowns_per_non_rush_touchdown) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(rush_touchdowns_per_non_rush_touchdown) - wm.ln_weighted_avg_rush_tds, 2)) / sum(snaps))), 2.32))         as rush_td_share_99th
      , exp(sqrt(sum(snaps * power(ln(yards_per_rush) - wm.ln_weighted_avg_rush_yds, 2)) / sum(snaps)))                                                   as weighted_geo_stdev_rush_yds
      , 1 - 1 / (1 + exp(sum(ln(yards_per_rush) * snaps) / sum(snaps)))                                                                                   as rush_yds_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(yards_per_rush) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(yards_per_rush) - wm.ln_weighted_avg_rush_yds, 2)) / sum(snaps))), 2.32))                                 as rush_yds_share_1st
      , 1 - 1 / (1 + exp(sum(ln(yards_per_rush) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(yards_per_rush) - wm.ln_weighted_avg_rush_yds, 2)) / sum(snaps))), 2.32))                                 as rush_yds_share_99th
    from players_grouping   as pg
         join weighted_mean as wm on wm.position_group = pg.position_group
    group by
        1
    )
   , beta_parameters as (
    select *
        -- PASSING STATS
         , pass_share * ((pass_share * (1 - pass_share)) / (power((pass_share_99th - pass_share_1st) / 2, 2) / 12) - 1)                           as alpha_passes
         , (1 - pass_share) * ((pass_share * (1 - pass_share)) / (power((pass_share_99th - pass_share_1st) / 2, 2) / 12) - 1)                     as beta_passes_snaps
         , completion_pct * ((completion_pct * (1 - completion_pct)) / (power((completion_pct_99th - completion_pct_1st) / 2, 2) / 12) - 1)       as alpha_comps
         , (1 - completion_pct) * ((completion_pct * (1 - completion_pct)) / (power((completion_pct_99th - completion_pct_1st) / 2, 2) / 12) - 1) as beta_comps_passes
         , pass_td_share * ((pass_td_share * (1 - pass_td_share)) / (power((pass_td_share_99th - pass_td_share_1st) / 2, 2) / 12) - 1)            as alpha_pass_tds
         , (1 - pass_td_share) * ((pass_td_share * (1 - pass_td_share)) / (power((pass_td_share_99th - pass_td_share_1st) / 2, 2) / 12) - 1)      as beta_pass_tds_comps
         , pass_yds_share * ((pass_yds_share * (1 - pass_yds_share)) / (power((pass_yds_share_99th - pass_yds_share_1st) / 2, 2) / 12) - 1)       as alpha_pass_yds
         , (1 - pass_yds_share) * ((pass_yds_share * (1 - pass_yds_share)) / (power((pass_yds_share_99th - pass_yds_share_1st) / 2, 2) / 12) - 1) as beta_pass_yds_comps
        -- RECEIVING STATS
         , rec_share * ((rec_share * (1 - rec_share)) / (power((rec_share_99th - rec_share_1st) / 2, 2) / 12) - 1)                                as alpha_recs
         , (1 - rec_share) * ((rec_share * (1 - rec_share)) / (power((rec_share_99th - rec_share_1st) / 2, 2) / 12) - 1)                          as beta_recs_snaps
         , rec_td_share * ((rec_td_share * (1 - rec_td_share)) / (power((rec_td_share_99th - rec_td_share_1st) / 2, 2) / 12) - 1)                 as alpha_rec_tds
         , (1 - rec_td_share) * ((rec_td_share * (1 - rec_td_share)) / (power((rec_td_share_99th - rec_td_share_1st) / 2, 2) / 12) - 1)           as beta_rec_tds_recs
         , rec_yds_share * ((rec_yds_share * (1 - rec_yds_share)) / (power((rec_yds_share_99th - rec_yds_share_1st) / 2, 2) / 12) - 1)            as alpha_rec_yds
         , (1 - rec_yds_share) * ((rec_yds_share * (1 - rec_yds_share)) / (power((rec_yds_share_99th - rec_yds_share_1st) / 2, 2) / 12) - 1)      as beta_rec_yds_recs
        -- RUSHING STATS
         , rush_share * ((rush_share * (1 - rush_share)) / (power((rush_share_99th - rush_share_1st) / 2, 2) / 12) - 1)                           as alpha_rushes
         , (1 - rush_share) * ((rush_share * (1 - rush_share)) / (power((rush_share_99th - rush_share_1st) / 2, 2) / 12) - 1)                     as beta_rushes_snaps
         , rush_td_share * ((rush_td_share * (1 - rush_td_share)) / (power((rush_td_share_99th - rush_td_share_1st) / 2, 2) / 12) - 1)            as alpha_rush_tds
         , (1 - rush_td_share) * ((rush_td_share * (1 - rush_td_share)) / (power((rush_td_share_99th - rush_td_share_1st) / 2, 2) / 12) - 1)      as beta_rush_tds_rushes
         , rush_yds_share * ((rush_yds_share * (1 - rush_yds_share)) / (power((rush_yds_share_99th - rush_yds_share_1st) / 2, 2) / 12) - 1)       as alpha_rush_yds
         , (1 - rush_yds_share) * ((rush_yds_share * (1 - rush_yds_share)) / (power((rush_yds_share_99th - rush_yds_share_1st) / 2, 2) / 12) - 1) as beta_rush_yds_rushes
    from position_group_log_norm_features
    )
select *
from beta_parameters