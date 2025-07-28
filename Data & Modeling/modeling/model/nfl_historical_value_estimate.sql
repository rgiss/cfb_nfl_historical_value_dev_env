drop table nfl_historical_value_estimate;
create table nfl_historical_value_estimate as
with base_stats as (
    select
                                                                                                        n.*
      ,                                                                                                 (sum(snap_percent * team_snaps * pow(0.15, -experience_dec)) over (partition by gsis_id order by game_date)
            + alpha_snaps * pow(0.15, -experience_dec))
                                                                                                                / (sum(case
                                                                                                                           when snap_percent is not null
                                                                                                                               then team_snaps
                                                                                                                           end * pow(0.15, -experience_dec))
                                                                                                                   over (partition by gsis_id order by game_date)
                + (alpha_snaps + beta_non_snaps) * pow(0.15, -experience_dec))         as est_snap_share
                                                                                                        -- PASSING STATS:
      ,                                                                                                 (sum(pass_attempts * pow(0.25, -experience_dec)) over (partition by gsis_id order by game_date)
            + alpha_passes * pow(0.25, -experience_dec))
                                                                                                                / (sum(coalesce(snap_count, team_snaps) * pow(0.25, -experience_dec))
                                                                                                                   over (partition by gsis_id order by game_date)
                + (alpha_passes + beta_passes_snaps) * pow(0.25, -experience_dec))     as est_passes_per_snap
                                                                                                        -- snap count estimates not as good for pre 2012
      ,                                                                                                 (sum(completions * pow(0.5, -experience_dec)) over (partition by gsis_id order by game_date)
            + alpha_comps * pow(0.5, -experience_dec))
                                                                                                                / (sum(pass_attempts * pow(0.5, -experience_dec)) over (partition by gsis_id order by game_date)
                + (alpha_comps + beta_comps_passes) * pow(0.5, -experience_dec))       as est_completion_pct
      ,                                                                                                 (sum(passing_touchdowns * pow(0.5, -experience_dec)) over (partition by gsis_id order by game_date)
            + alpha_pass_tds * pow(0.5, -experience_dec))
                                                                                                                / (sum(completions * pow(0.5, -experience_dec)) over (partition by gsis_id order by game_date)
                + (alpha_pass_tds + beta_pass_tds_comps) * pow(0.5, -experience_dec))  as est_tds_per_completion
      ,                                                                                                 (sum(passing_yards * pow(0.25, -experience_dec)) over (partition by gsis_id order by game_date)
            + alpha_pass_yds * pow(0.25, -experience_dec))
                                                                                                                / (sum(completions * pow(0.25, -experience_dec)) over (partition by gsis_id order by game_date)
                + (beta_pass_yds_comps) * pow(0.25, -experience_dec))                  as est_yards_per_completion
                                                                                                        -- RECEIVING STATS:
      ,                                                                                                 (sum(targets * pow(0.25, -experience_dec)) over (partition by gsis_id order by game_date)
            + alpha_tgts * pow(0.25, -experience_dec))
                                                                                                                / (sum(coalesce(snap_count, team_snaps) * pow(0.25, -experience_dec))
                                                                                                                   over (partition by gsis_id order by game_date)
                + (alpha_tgts + beta_tgts_snaps) * pow(0.25, -experience_dec))         as est_tgt_share
      ,                                                                                                 (sum(receptions * pow(0.25, -experience_dec)) over (partition by gsis_id order by game_date)
            + alpha_recs * pow(0.25, -experience_dec))
                                                                                                                / (sum(targets * pow(0.25, -experience_dec)) over (partition by gsis_id order by game_date)
                + (alpha_recs + beta_recs_tgts) * pow(0.25, -experience_dec))          as est_catch_pct -- too high from 2003-2008
      ,                                                                                                 (sum(receiving_touchdowns * pow(0.7, -experience_dec)) over (partition by gsis_id order by game_date)
            + alpha_rec_tds * pow(0.7, -experience_dec))
                                                                                                                / (sum(receptions * pow(0.7, -experience_dec)) over (partition by gsis_id order by game_date)
                + (alpha_rec_tds + beta_rec_tds_recs) * pow(0.7, -experience_dec))     as est_touchdowns_per_reception
      ,                                                                                                 (sum(receiving_yards * pow(0.5, -experience_dec)) over (partition by gsis_id order by game_date)
            + alpha_rec_yds * pow(0.5, -experience_dec))
                                                                                                                / (sum(receptions * pow(0.5, -experience_dec)) over (partition by gsis_id order by game_date)
                + (beta_rec_yds_recs) * pow(0.5, -experience_dec))                     as est_yds_per_rec
                                                                                                        -- RUSHING STATS:
      ,                                                                                                 (sum(rush_attempts * pow(0.25, -experience_dec)) over (partition by gsis_id order by game_date)
            + alpha_rushes * pow(0.25, -experience_dec))
                                                                                                                / (sum(coalesce(snap_count, team_snaps) * pow(0.25, -experience_dec))
                                                                                                                   over (partition by gsis_id order by game_date)
                + (alpha_rushes + beta_rushes_snaps) * pow(0.25, -experience_dec))     as est_rushes_per_snap
      ,                                                                                                 (sum(rushing_touchdowns * pow(0.7, -experience_dec)) over (partition by gsis_id order by game_date)
            + alpha_rush_tds * pow(0.7, -experience_dec))
                                                                                                                / (sum(rush_attempts * pow(0.7, -experience_dec)) over (partition by gsis_id order by game_date)
                + (alpha_rush_tds + beta_rush_tds_rushes) * pow(0.7, -experience_dec)) as est_touchdowns_per_rush
      ,                                                                                                 (sum(rushing_yards * pow(0.5, -experience_dec)) over (partition by gsis_id order by game_date)
            + alpha_rush_yds * pow(0.5, -experience_dec))
                                                                                                                / (sum(rush_attempts * pow(0.5, -experience_dec)) over (partition by gsis_id order by game_date)
                + (beta_rush_yds_rushes) * pow(0.5, -experience_dec))                  as est_yds_per_rush
      ,                                                                                                 (sum(epa * pow(0.7, -experience_dec)) over (partition by gsis_id order by game_date)
            - 30 * pow(0.7, -experience_dec))
                                                                                                                / (sum(team_snaps * pow(0.7, -experience_dec))
                                                                                                                   over (partition by gsis_id order by game_date)
                + (500) * pow(0.7, -experience_dec))                                   as est_epa_per_snap
    from nfl_game_logs              as n
         inner join nfl_beta_priors as b on b.position_group = n.position_group and b.since_2012 = (n.year >= 2012)
    )
select *
     , est_passes_per_snap * est_completion_pct                                 as est_completions
     , est_passes_per_snap * est_completion_pct * est_yards_per_completion      as est_pass_yards
     , est_passes_per_snap * est_completion_pct * est_tds_per_completion        as est_pass_td
     , est_tgt_share * est_catch_pct                                            as est_receptions
     , est_tgt_share * est_catch_pct * est_yds_per_rec                          as est_rec_yards
     , est_tgt_share * est_catch_pct * est_touchdowns_per_reception             as est_rec_tds
     , est_rushes_per_snap * est_yds_per_rush                                   as est_rush_yards
     , est_rushes_per_snap * est_touchdowns_per_rush                            as est_rush_tds
     , est_passes_per_snap * est_completion_pct * est_yards_per_completion * 0.04
        + est_passes_per_snap * est_completion_pct * est_tds_per_completion * 6 as est_passing_fantasy_points_per_snap
     , est_tgt_share * est_catch_pct
        + est_tgt_share * est_catch_pct * est_yds_per_rec * 0.1
        + est_tgt_share * est_catch_pct * est_touchdowns_per_reception * 6      as est_receiving_fantasy_points_per_snap
     , est_rushes_per_snap * est_yds_per_rush * 0.1
        + est_rushes_per_snap * est_touchdowns_per_rush * 6                     as est_rushing_fantasy_points_per_snap
     , est_passes_per_snap * est_completion_pct * est_yards_per_completion * 0.04
        + est_passes_per_snap * est_completion_pct * est_tds_per_completion * 6
        + est_tgt_share * est_catch_pct
        + est_tgt_share * est_catch_pct * est_yds_per_rec * 0.1
        + est_tgt_share * est_catch_pct * est_touchdowns_per_reception * 6
        + est_rushes_per_snap * est_yds_per_rush * 0.1
        + est_rushes_per_snap * est_touchdowns_per_rush * 6                     as est_fantasy_points_per_snap
     , (est_passes_per_snap * est_completion_pct * est_yards_per_completion * 0.04
        + est_passes_per_snap * est_completion_pct * est_tds_per_completion * 6
        + est_tgt_share * est_catch_pct
        + est_tgt_share * est_catch_pct * est_yds_per_rec * 0.1
        + est_tgt_share * est_catch_pct * est_touchdowns_per_reception * 6
        + est_rushes_per_snap * est_yds_per_rush * 0.1
        + est_rushes_per_snap * est_touchdowns_per_rush * 6)
        * coalesce(est_snap_share, 1) * 65                                      as est_fantasy_points_value
from base_stats