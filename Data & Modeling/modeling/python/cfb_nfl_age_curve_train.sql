drop table cfb_nfl_age_curve_train;
create table cfb_nfl_age_curve_train as 
with cfb_nfl_age_curve_train_dim as (
    select
        player_display_name
      , year
      , gl.position_group
      , avg(true_age)                                                                                           as true_age
      , sum(team_snaps)                                                                                         as snaps
      , null                                                                                                    as snaps_per_non_snap
      , null                                                                                                    as targets_per_non_target
      , null                                                                                                    as receptions_per_target
      , (.37 + sum(receptions * opp_adj.rec_share_adj_ratio * team_adj.rec_share_adj_ratio * nfl_adj.rec_share_adj_ratio))
                / (6.9 + (sum(team_snaps) - sum(receptions)))                                                   as receptions_per_non_reception
      , case
            when sum(receiving_yards * opp_adj.rec_yds_adj_ratio * team_adj.rec_yds_adj_ratio * nfl_adj.rec_yds_adj_ratio) > 0
                then (1.0 + sum(receiving_yards * opp_adj.rec_yds_adj_ratio * team_adj.rec_yds_adj_ratio)) / (.1 + (sum(receptions)))
            end                                                                                                 as yards_per_reception
      , (.16 + sum(receiving_touchdowns * opp_adj.rec_tds_adj_ratio * team_adj.rec_tds_adj_ratio * nfl_adj.rec_tds_adj_ratio))
                / (3.1 + (sum(receptions) - sum(receiving_touchdowns)))                                         as rec_touchdowns_per_non_rec_touchdown
      , (1.38 + sum(rush_attempts * opp_adj.rush_share_adj_ratio * team_adj.rush_share_adj_ratio * nfl_adj.rush_share_adj_ratio))
                / (2.59 + (sum(team_snaps) - sum(rush_attempts)))                                               as rushs_per_non_rush
      , (7.6 + sum(pass_attempts * opp_adj.pass_share_adj_ratio * team_adj.pass_share_adj_ratio * nfl_adj.pass_share_adj_ratio))
                / (6.4 + (sum(team_snaps) - sum(pass_attempts)))                                                as passes_per_non_pass
      , (.36 + sum(completions * opp_adj.comp_pct_adj_ratio * team_adj.comp_pct_adj_ratio * nfl_adj.comp_pct_adj_ratio))
                / (.225 + (sum(pass_attempts) - sum(completions)))                                              as completions_per_non_completion
      , case
            when sum(rushing_yards * opp_adj.rush_yds_adj_ratio * team_adj.rush_yds_adj_ratio * nfl_adj.rush_yds_adj_ratio) > 0
                then (33.11 + sum(rushing_yards * opp_adj.rush_yds_adj_ratio * team_adj.rush_yds_adj_ratio * nfl_adj.rush_yds_adj_ratio)) / (7.85 + (sum(rush_attempts)))
            end                                                                                                 as yards_per_rush
      , case
            when sum(passing_yards * opp_adj.pass_yds_adj_ratio * team_adj.pass_yds_adj_ratio * nfl_adj.pass_yds_adj_ratio) > 0
                then (7.374 + sum(passing_yards * opp_adj.pass_yds_adj_ratio * team_adj.pass_yds_adj_ratio * nfl_adj.pass_yds_adj_ratio)) / (1.2 * 0.62 + (sum(completions)))
            end                                                                                                 as yards_per_completion
      , (.085 + sum(rushing_touchdowns * opp_adj.rush_tds_adj_ratio * team_adj.rush_tds_adj_ratio * nfl_adj.rush_tds_adj_ratio))
                / (3.97 + (sum(rush_attempts) - sum(rushing_touchdowns)))                                       as rush_touchdowns_per_non_rush_touchdown
      , (.377 + sum(passing_touchdowns * opp_adj.pass_tds_adj_ratio * team_adj.pass_tds_adj_ratio * nfl_adj.pass_tds_adj_ratio))
                / (12.35 + (sum(completions) - sum(passing_touchdowns)))                                        as pass_touchdowns_per_non_pass_touchdown
      , (sum(epa + opp_adj.epa_factor + team_adj.epa_factor + nfl_adj.epa_adjustment)) / (45 + sum(team_snaps)) as epa_per_snap
    from cfb_game_logs                                      as gl
         left join cfb_opponent_strength_adjustment_metrics as opp_adj
                   on opp_adj.opponent_elo = coalesce(gl.opponent_elo, 1000) and opp_adj.adj_from_is_home_game = gl.is_home_game and opp_adj.position_group = gl.position_group
         left join cfb_team_strength_adjustment_metrics     as team_adj on team_adj.team_elo = coalesce(gl.team_elo, 1000) and team_adj.position_group = gl.position_group
         left join cfb_nfl_metrics_adjustment_dim           as nfl_adj on nfl_adj.position_group = gl.position_group
    where
        team_snaps between 40 and 100
    --and experience_yrs < 1
    group by
        1, 2, 3
    union all
    select
        player_display_name
      , year
      , gl.position_group
      , avg(true_age)                                                                     as true_age
      , sum(team_snaps)                                                                   as snaps
      , (sum(snap_percent * team_snaps) + 1) / (1 + sum((1 - snap_percent) * team_snaps)) as snaps_per_non_snap
      , (3.7 + sum(targets))
                / (2 + (sum(snap_count) - sum(targets)))                                  as targets_per_non_target
      , (3.7 + sum(receptions))
                / (2 + (sum(targets) - sum(receptions)))                                  as receptions_per_target
      , (.37 + sum(receptions))
                / (6.9 + (sum(team_snaps) - sum(receptions)))                             as receptions_per_non_reception
      , case
            when sum(receiving_yards) > 0
                then (1.0 + sum(receiving_yards)) / (.1 + (sum(receptions)))
            end                                                                           as yards_per_reception
      , (.16 + sum(receiving_touchdowns))
                / (3.1 + (sum(receptions) - sum(receiving_touchdowns)))                   as rec_touchdowns_per_non_rec_touchdown
      , (1.38 + sum(rush_attempts))
                / (2.59 + (sum(team_snaps) - sum(rush_attempts)))                         as rushs_per_non_rush
      , (7.6 + sum(pass_attempts))
                / (6.4 + (sum(team_snaps) - sum(pass_attempts)))                          as passes_per_non_pass
      , (.36 + sum(completions))
                / (.225 + (sum(pass_attempts) - sum(completions)))                        as completions_per_non_completion
      , case
            when sum(rushing_yards) > 0
                then (33.11 + sum(rushing_yards)) / (7.85 + (sum(rush_attempts)))
            end                                                                           as yards_per_rush
      , case
            when sum(passing_yards) > 0
                then (7.374 + sum(passing_yards)) / (1.2 * 0.62 + (sum(completions)))
            end                                                                           as yards_per_completion
      , (.085 + sum(rushing_touchdowns))
                / (3.97 + (sum(rush_attempts) - sum(rushing_touchdowns)))                 as rush_touchdowns_per_non_rush_touchdown
      , (.377 + sum(passing_touchdowns))
                / (12.35 + (sum(completions) - sum(passing_touchdowns)))                  as pass_touchdowns_per_non_pass_touchdown
      , (sum(epa)) / (45 + sum(team_snaps))                                               as epa_per_snap
    from nfl_game_logs as gl
    where
        team_snaps between 40 and 100
    --and experience_yrs < 1
    group by
        1, 2, 3
    )
   , cfb_nfl_age_curve_train as (
    select
        a.player_display_name
      , a.year
      , a.position_group                                                                        as position_group
      , round((a.true_age) * 10) / 10                                                           as true_age
      , 2 / (1 / a.snaps + 1 / b.snaps)                                                         as snaps_weight
      , ln(b.snaps_per_non_snap / a.snaps_per_non_snap)                                         as snaps_per_non_snap_ln_delta
      --, ln(b.targets_per_non_target / a.targets_per_non_target)                                 as targets_per_non_target_ln_delta
      , ln(b.receptions_per_target / a.receptions_per_target)                                   as receptions_per_target_ln_delta
      , ln(b.receptions_per_non_reception / a.receptions_per_non_reception)                     as receptions_per_non_reception_ln_delta
      , ln(b.yards_per_reception / a.yards_per_reception)                                       as yards_per_reception_ln_delta
      , ln(b.rec_touchdowns_per_non_rec_touchdown / a.rec_touchdowns_per_non_rec_touchdown)     as rec_touchdowns_per_non_rec_touchdown_ln_delta
      , ln(b.rushs_per_non_rush / a.rushs_per_non_rush)                                         as rushs_per_non_rush_ln_delta
      , ln(b.passes_per_non_pass / a.passes_per_non_pass)                                       as passes_per_non_pass_ln_delta
      , ln(b.completions_per_non_completion / a.completions_per_non_completion)                 as completions_per_non_completion_ln_delta
      , ln(b.yards_per_rush / a.yards_per_rush)                                                 as yards_per_rush_ln_delta
      , ln(b.yards_per_completion / a.yards_per_completion)                                     as yards_per_completion_ln_delta
      , ln(b.rush_touchdowns_per_non_rush_touchdown / a.rush_touchdowns_per_non_rush_touchdown) as rush_touchdowns_per_non_rush_touchdown_ln_delta
      , ln(b.pass_touchdowns_per_non_pass_touchdown / a.pass_touchdowns_per_non_pass_touchdown) as pass_touchdowns_per_non_pass_touchdown_ln_delta
      , b.epa_per_snap - a.epa_per_snap                                                         as epa_per_snap_delta
    from cfb_nfl_age_curve_train_dim            as a
         inner join cfb_nfl_age_curve_train_dim as b on a.player_display_name = b.player_display_name and b.year = a.year + 1
    )
select *
from cfb_nfl_age_curve_train