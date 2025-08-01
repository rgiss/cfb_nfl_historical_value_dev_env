drop table nfl_beta_priors;
create table nfl_beta_priors as
with players_grouping as (
    select
        player_name
      , year
      , position_group
      , year >= 2012                                                                                        as since_2012
      , sum(coalesce(snap_count, team_snaps))                                                               as snaps
      , (13.8 + sum(rush_attempts)) / (25.9 + (sum(coalesce(snap_count, team_snaps)) - sum(rush_attempts))) as rushs_per_non_rush
      , (76 + sum(pass_attempts)) / (64 + (sum(coalesce(snap_count, team_snaps)) - sum(pass_attempts)))     as passes_per_non_pass
      , (6 + sum(targets)) / (69 + (sum(coalesce(snap_count, team_snaps)) - sum(targets)))                  as targets_per_non_target
      , (3.6 + sum(receptions)) / (2.25 + (sum(targets) - sum(receptions)))                                 as receptions_per_non_reception
      , (3.6 + sum(receptions)) / (69 + (sum(team_snaps) - sum(receptions)))                                as receptions_per_non_reception_snap
      , (3.6 + sum(completions)) / (2.25 + (sum(pass_attempts) - sum(completions)))                         as completions_per_non_completion
      , (10 + sum(receiving_yards)) / (1 + (sum(receptions)))                                               as yards_per_reception
      , (331.1 + sum(rushing_yards)) / (78.5 + (sum(rush_attempts)))                                        as yards_per_rush
      , (73.74 + sum(passing_yards)) / (12 * 0.62 + (sum(completions)))                                     as yards_per_completion
      , (1.6 + sum(receiving_touchdowns)) / (31 + (sum(receptions) - sum(receiving_touchdowns)))            as rec_touchdowns_per_non_rec_touchdown
      , (0.85 + sum(rushing_touchdowns)) / (39.7 + (sum(rush_attempts) - sum(rushing_touchdowns)))          as rush_touchdowns_per_non_rush_touchdown
      , (3.77 + sum(passing_touchdowns)) / (123.5 + (sum(completions) - sum(passing_touchdowns)))           as pass_touchdowns_per_non_pass_touchdown
      , (1 + sum(snap_percent * team_snaps)) / (1.5 + sum(team_snaps * (1 - snap_percent)))                 as snaps_per_non_snap
      , (sum(epa)) / (45 + sum(team_snaps))                                           as epa_per_snap
    from nfl_game_logs
    where
          experience_dec < 1
      and position_group in ('WR', 'QB', 'TE', 'RB')
    group by
        1, 2, 3, 4
    having
        sum(coalesce(snap_count, team_snaps)) > 100
    )
   , weighted_mean as (
    select
        position_group
      , since_2012
      , sum(ln(snaps_per_non_snap) * snaps) / sum(snaps)                     as ln_weighted_avg_snaps
      , sum(ln(rushs_per_non_rush) * snaps) / sum(snaps)                     as ln_weighted_avg_rushes
      , sum(ln(yards_per_rush) * snaps) / sum(snaps)                         as ln_weighted_avg_rush_yds
      , sum(ln(rush_touchdowns_per_non_rush_touchdown) * snaps) / sum(snaps) as ln_weighted_avg_rush_tds
      , sum(ln(passes_per_non_pass) * snaps) / sum(snaps)                    as ln_weighted_avg_passes
      , sum(ln(completions_per_non_completion) * snaps) / sum(snaps)         as ln_weighted_avg_completions
      , sum(ln(yards_per_completion) * snaps) / sum(snaps)                   as ln_weighted_avg_pass_yds
      , sum(ln(pass_touchdowns_per_non_pass_touchdown) * snaps) / sum(snaps) as ln_weighted_avg_pass_tds
      , sum(ln(targets_per_non_target) * snaps) / sum(snaps)                 as ln_weighted_avg_tgts
      , sum(ln(receptions_per_non_reception) * snaps) / sum(snaps)           as ln_weighted_avg_recs
      , sum(ln(receptions_per_non_reception_snap) * snaps) / sum(snaps)      as ln_weighted_avg_recs_snaps
      , sum(ln(yards_per_reception) * snaps) / sum(snaps)                    as ln_weighted_avg_rec_yds
      , sum(ln(rec_touchdowns_per_non_rec_touchdown) * snaps) / sum(snaps)   as ln_weighted_avg_rec_tds
      , sum(epa_per_snap * snaps) / sum(snaps)                               as weighted_avg_epa_per_snap
    from players_grouping
    group by
        1, 2
    )
   , position_group_log_norm_features as (
    select
        pg.position_group
      , pg.since_2012
        -- SNAPS:
      , exp(sqrt(sum(snaps * power(ln(snaps_per_non_snap) - wm.ln_weighted_avg_snaps, 2)) / sum(snaps)))                                                  as weighted_geo_stdev_snap_pct
      , 1 - 1 / (1 + exp(sum(ln(snaps_per_non_snap) * snaps) / sum(snaps)))                                                                               as snap_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(snaps_per_non_snap) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(snaps_per_non_snap) - wm.ln_weighted_avg_snaps, 2)) / sum(snaps))), 2.32))                                as snap_percent_1st
      , 1 - 1 / (1 + exp(sum(ln(snaps_per_non_snap) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(snaps_per_non_snap) - wm.ln_weighted_avg_snaps, 2)) / sum(snaps))), 2.32))                                as snap_percent_99th
        -- RECEIVING STATS:
      , exp(sqrt(sum(snaps * power(ln(targets_per_non_target) - wm.ln_weighted_avg_tgts, 2)) / sum(snaps)))                                               as weighted_geo_stdev_tgts
      , 1 - 1 / (1 + exp(sum(ln(targets_per_non_target) * snaps) / sum(snaps)))                                                                           as target_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(targets_per_non_target) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(targets_per_non_target) - wm.ln_weighted_avg_tgts, 2)) / sum(snaps))), 2.32))                             as target_share_1st
      , 1 - 1 / (1 + exp(sum(ln(targets_per_non_target) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(targets_per_non_target) - wm.ln_weighted_avg_tgts, 2)) / sum(snaps))), 2.32))                             as target_share_99th
      , exp(sqrt(sum(snaps * power(ln(receptions_per_non_reception_snap) - wm.ln_weighted_avg_recs_snaps, 2)) / sum(snaps)))                              as weighted_geo_stdev_rec_snaps
      , 1 - 1 / (1 + exp(sum(ln(receptions_per_non_reception_snap) * snaps) / sum(snaps)))                                                                as rec_snap_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(receptions_per_non_reception_snap) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(receptions_per_non_reception_snap) - wm.ln_weighted_avg_recs_snaps, 2)) / sum(snaps))), 2.32))            as rec_snap_share_1st
      , 1 - 1 / (1 + exp(sum(ln(receptions_per_non_reception_snap) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(receptions_per_non_reception_snap) - wm.ln_weighted_avg_recs_snaps, 2)) / sum(snaps))), 2.32))            as rec_snap_share_99th
      , exp(sqrt(sum(snaps * power(ln(rec_touchdowns_per_non_rec_touchdown) - wm.ln_weighted_avg_rec_tds, 2)) / sum(snaps)))                              as weighted_geo_stdev_rec_tds
      , 1 - 1 / (1 + exp(sum(ln(rec_touchdowns_per_non_rec_touchdown) * snaps) / sum(snaps)))                                                             as rec_td_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(rec_touchdowns_per_non_rec_touchdown) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(rec_touchdowns_per_non_rec_touchdown) - wm.ln_weighted_avg_rec_tds, 2)) / sum(snaps))), 2.32))            as rec_td_share_1st
      , 1 - 1 / (1 + exp(sum(ln(rec_touchdowns_per_non_rec_touchdown) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(rec_touchdowns_per_non_rec_touchdown) - wm.ln_weighted_avg_rec_tds, 2)) / sum(snaps))), 2.32))            as rec_td_share_99th
      , exp(sqrt(sum(snaps * power(ln(receptions_per_non_reception) - wm.ln_weighted_avg_recs, 2)) / sum(snaps)))                                         as weighted_geo_stdev_recs
      , 1 - 1 / (1 + exp(sum(ln(receptions_per_non_reception) * snaps) / sum(snaps)))                                                                     as rec_share --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(ln(receptions_per_non_reception) * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(ln(receptions_per_non_reception) - wm.ln_weighted_avg_recs, 2)) / sum(snaps))), 2.32))                       as rec_share_1st
      , 1 - 1 / (1 + exp(sum(ln(receptions_per_non_reception) * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(ln(receptions_per_non_reception) - wm.ln_weighted_avg_recs, 2)) / sum(snaps))), 2.32))                       as rec_share_99th
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
      , exp(sqrt(sum(snaps * power(epa_per_snap - wm.weighted_avg_epa_per_snap, 2)) / sum(snaps)))                                                        as weighted_geo_stdev_epa
      , 1 - 1 / (1 + exp(sum(epa_per_snap * snaps) / sum(snaps)))                                                                                         as epa_per_snap --weighted geo mean between 0 and 1
      , 1 - 1 / (1 + exp(sum(epa_per_snap * snaps) / sum(snaps))
            / pow(exp(sqrt(sum(snaps * power(epa_per_snap - wm.weighted_avg_epa_per_snap, 2)) / sum(snaps))), 2.32))                                      as epa_per_snap_1st
      , 1 - 1 / (1 + exp(sum(epa_per_snap * snaps) / sum(snaps))
            * pow(exp(sqrt(sum(snaps * power(epa_per_snap - wm.weighted_avg_epa_per_snap, 2)) / sum(snaps))), 2.32))                                      as epa_per_snap_99th
    from players_grouping   as pg
         join weighted_mean as wm on wm.position_group = pg.position_group and wm.since_2012 = pg.since_2012
    group by
        1, 2
    )
   , beta_parameters as (
    select *
        -- SNAPS:
         , snap_share * ((snap_share * (1 - snap_share)) / (power((snap_percent_99th - snap_percent_1st) / 2, 2) / 12) - 1)                       as alpha_snaps
         , (1 - snap_share) * ((snap_share * (1 - snap_share)) / (power((snap_percent_99th - snap_percent_1st) / 2, 2) / 12) - 1)                 as beta_non_snaps
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
         , target_share * ((target_share * (1 - target_share)) / (power((target_share_99th - target_share_1st) / 2, 2) / 12) - 1)                 as alpha_tgts
         , (1 - target_share) * ((target_share * (1 - target_share)) / (power((target_share_99th - target_share_1st) / 2, 2) / 12) - 1)           as beta_tgts_snaps
         , rec_snap_share * ((rec_snap_share * (1 - rec_snap_share)) / (power((rec_snap_share_99th - rec_snap_share_1st) / 2, 2) / 12) - 1)       as alpha_rec_snaps
         , (1 - rec_snap_share) * ((rec_snap_share * (1 - rec_snap_share)) / (power((rec_snap_share_99th - rec_snap_share_1st) / 2, 2) / 12) - 1) as beta_rec_snaps
         , rec_td_share * ((rec_td_share * (1 - rec_td_share)) / (power((rec_td_share_99th - rec_td_share_1st) / 2, 2) / 12) - 1)                 as alpha_rec_tds
         , (1 - rec_td_share) * ((rec_td_share * (1 - rec_td_share)) / (power((rec_td_share_99th - rec_td_share_1st) / 2, 2) / 12) - 1)           as beta_rec_tds_recs
         , rec_share * ((rec_share * (1 - rec_share)) / (power((rec_share_99th - rec_share_1st) / 2, 2) / 12) - 1)                                as alpha_recs
         , (1 - rec_share) * ((rec_share * (1 - rec_share)) / (power((rec_share_99th - rec_share_1st) / 2, 2) / 12) - 1)                          as beta_recs_tgts
         , rec_yds_share * ((rec_yds_share * (1 - rec_yds_share)) / (power((rec_yds_share_99th - rec_yds_share_1st) / 2, 2) / 12) - 1)            as alpha_rec_yds
         , (1 - rec_yds_share) * ((rec_yds_share * (1 - rec_yds_share)) / (power((rec_yds_share_99th - rec_yds_share_1st) / 2, 2) / 12) - 1)      as beta_rec_yds_recs
        -- RUSHING STATS
         , rush_share * ((rush_share * (1 - rush_share)) / (power((rush_share_99th - rush_share_1st) / 2, 2) / 12) - 1)                           as alpha_rushes
         , (1 - rush_share) * ((rush_share * (1 - rush_share)) / (power((rush_share_99th - rush_share_1st) / 2, 2) / 12) - 1)                     as beta_rushes_snaps
         , rush_td_share * ((rush_td_share * (1 - rush_td_share)) / (power((rush_td_share_99th - rush_td_share_1st) / 2, 2) / 12) - 1)            as alpha_rush_tds
         , (1 - rush_td_share) * ((rush_td_share * (1 - rush_td_share)) / (power((rush_td_share_99th - rush_td_share_1st) / 2, 2) / 12) - 1)      as beta_rush_tds_rushes
         , rush_yds_share * ((rush_yds_share * (1 - rush_yds_share)) / (power((rush_yds_share_99th - rush_yds_share_1st) / 2, 2) / 12) - 1)       as alpha_rush_yds
         , (1 - rush_yds_share) * ((rush_yds_share * (1 - rush_yds_share)) / (power((rush_yds_share_99th - rush_yds_share_1st) / 2, 2) / 12) - 1) as beta_rush_yds_rushes
         , ((1 - epa_per_snap) * ((epa_per_snap * (1 - epa_per_snap)) / (power((epa_per_snap_99th - epa_per_snap_1st) / 2, 2) / 12) - 1)
            + epa_per_snap * ((epa_per_snap * (1 - epa_per_snap)) / (power((epa_per_snap_99th - epa_per_snap_1st) / 2, 2) / 12) - 1))             as beta_epa_snaps
         , ln((epa_per_snap * ((epa_per_snap * (1 - epa_per_snap)) / (power((epa_per_snap_99th - epa_per_snap_1st) / 2, 2) / 12) - 1))
            / ((1 - epa_per_snap) * ((epa_per_snap * (1 - epa_per_snap)) / (power((epa_per_snap_99th - epa_per_snap_1st) / 2, 2) / 12) - 1)))
            * ((1 - epa_per_snap) * ((epa_per_snap * (1 - epa_per_snap)) / (power((epa_per_snap_99th - epa_per_snap_1st) / 2, 2) / 12) - 1)
                + epa_per_snap * ((epa_per_snap * (1 - epa_per_snap)) / (power((epa_per_snap_99th - epa_per_snap_1st) / 2, 2) / 12) - 1))         as alpha_epa
    from position_group_log_norm_features
    )
select *
from beta_parameters