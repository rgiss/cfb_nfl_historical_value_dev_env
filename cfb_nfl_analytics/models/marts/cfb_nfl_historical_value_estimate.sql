{{
  config(
    materialized='table',
    schema='marts'
  )
}}

-- cfb_nfl_historical_value_estimate
-- Ported from DataGrip SQL with age curve, recruiting prior, and replacement value logic

with union_game_logs as (
    select distinct
        gl.player_name
      , gl.gsis_id
      , coalesce(gl.player_display_name, gl.player_name || ': ' || gl.player_name_id) as player_display_name
      , gl.position_group
      , rd.stars                                                                       as recruit_stars
      , rd.ranking                                                                     as recruit_ranking
      , rd.rating                                                                      as recruit_rating
      , gl.game_id::varchar(255)                                                       as game_id
      , 'cfb'                                                                          as league
      , gl.team
      , gl.opponent
      , gl.team_elo
      , gl.opponent_elo
      , gl.is_home_game
      , gl.year::float                                                                 as year
      , gl.week
      , gl.approximate_date                                                            as approximate_date
      , gl.season::float                                                               as season
      , gl.true_date
      , gl.experience_yrs
      , gl.experience_dec
      , gl.approximate_age
      , coalesce(gl.true_age +
        case
            when gl.player_name = 'Tetairoa McMillan'
                then 0.3
            when gl.player_name = 'Travis Hunter'
                then 0.2
            when gl.player_name = 'Jayden Higgins'
                then 0.8
            when gl.player_name = 'Jaylin Noel'
                then -0.2
            when gl.player_name = 'Colston Loveland'
                then -0.9
            when gl.player_name = 'Emeka Egbuka'
                then -0.4
            when gl.player_name = 'Xavier Restrepo'
                then -0.7
            when gl.player_name = 'Harold Fannin Jr.'
                then -1
            when gl.player_name = 'Tez Johnson'
                then -0.8
            when gl.player_name = 'Gunnar Helm'
                then -1
            when gl.player_name = 'Matthew Golden'
                then -0.1
            when gl.player_name = 'Jack Bech'
                then 0
            when gl.player_name = 'Tre Harris'
                then 0
            when gl.player_name = 'Luther Burden III'
                then 0
            when gl.player_name = 'Dont''e Thornton'
                then -0.2
                else 0
            end)
                                                                                       as true_age
      , gl.player_game_number
      , gl.player_games_remaining
      , gl.player_season_game_number
      , gl.player_season_games_remaining
      , gl.player_dropbacks
      , gl.team_dropbacks
      , gl.team_snaps
      , null::float                                                                    as snap_percent
      , null::float                                                                    as snap_count
      , gl.pass_attempts
      , gl.completions
      , gl.completion_percentage
      , gl.passing_yards
      , gl.passing_yards_per_completion
      , gl.passing_yards_per_attempt
      , gl.passing_air_yards
      , gl.passing_air_yards_per_attempt
      , gl.passing_touchdowns
      , gl.passing_touchdowns_per_attempt
      , gl.sacks_taken
      , gl.sacks_per_dropback
      , gl.targets
      , gl.receptions
      , gl.receiving_yards
      , gl.air_yards::float                                                            as air_yards
      , gl.yards_after_catch::float                                                    as yards_after_catch
      , gl.receiving_touchdowns
      , gl.rush_attempts
      , gl.rushing_yards
      , gl.rushing_touchdowns
      , gl.twopt_conversions::float                                                    as twopt_conversions
      , gl.fumbles
      , gl.fumbles_lost
      , gl.passing_interception
      , gl.receiver_interception
      , gl.return_yards
      , gl.return_touchdowns
      , gl.epa
      , gl.fantasy_points_std
      , gl.fantasy_points_half_ppr
      , gl.fantasy_points_ppr
      , gl.fantasy_points_t
    from {{ ref("cfb_game_logs") }} as gl
         left join {{ source("raw", "cfb_recruiting_data") }} as rd
                   on gl.player_name = rd.name and gl.team = rd.committed_to and gl.year = rd.year
    union all
    select
        player_name
      , gsis_id
      , player_display_name
      , position_group
      , null  as recruit_stars
      , null  as recruit_ranking
      , null  as recruit_rating
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
    from {{ ref("nfl_game_logs") }}
    where
        gsis_id <> '00-0021306'
    )
   , game_logs as (
    select *
         , min(approximate_date) over (partition by player_display_name)::date as first_date
    from union_game_logs
    )
   , base_stats as (
    select
                       n.*
      ,                (sum(snap_count
            * pow(0.3, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            + nfl.alpha_snaps * pow(0.3, -(true_date - 1999)))
                               / (
                    sum(snap_count / nullif(snap_percent, 0) *
                pow(0.3, -(true_date - 1999)))
                    over (partition by player_display_name order by approximate_date)
                    + (nfl.alpha_snaps + nfl.beta_non_snaps) *
                pow(0.3, -(true_date - 1999)))                                                                          as est_snap_share

                       -- PASSING STATS:

      ,                (sum(
                        pass_attempts
                                * coalesce(opp_adj.pass_share_adj_ratio, 1)
                                * coalesce(team_adj.pass_share_adj_ratio, 1)
                                * coalesce(nfl_adj.pass_share_adj_ratio, 1)
                                / coalesce(age_c.total_pass_share_change, 1)
                                * pow(0.25, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            * coalesce(age_c.total_pass_share_change, 1)
            + coalesce((cfb.alpha_passes + cfb.beta_passes_snaps) * recr_adj.pass_share, cfb.alpha_passes, nfl.alpha_passes)
                * pow(0.25, -(true_date - 1999)))
                               / (
                    sum(
                    pass_attempts
                            * coalesce(opp_adj.pass_share_adj_ratio, 1)
                            * coalesce(team_adj.pass_share_adj_ratio, 1)
                            * coalesce(nfl_adj.pass_share_adj_ratio, 1)
                            / coalesce(age_c.total_pass_share_change, 1)
                            *
                        pow(0.25, -(true_date - 1999)))
                    over (partition by player_display_name order by approximate_date)
                    * coalesce(age_c.total_pass_share_change, 1) +
                        sum(((coalesce(snap_count, team_snaps) - pass_attempts)) *
                    pow(0.25, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
                    + (coalesce(cfb.alpha_passes, nfl.alpha_passes) +
                coalesce(cfb.beta_passes_snaps, nfl.beta_passes_snaps))
                    *
                pow(0.25, -(true_date - 1999)))                                                                         as est_passes_per_snap
      ,                (sum(
                        sacks_taken
                                * coalesce(opp_adj.sack_share_adj_ratio, 1)
                                * coalesce(team_adj.sack_share_adj_ratio, 1)
                                * coalesce(nfl_adj.sack_share_adj_ratio, 1)
                                * pow(0.25, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            + coalesce((cfb.alpha_sacks + cfb.beta_sacks_dropbacks) * recr_adj.sack_share, cfb.alpha_sacks, nfl.alpha_sacks)
                * pow(0.25, -(true_date - 1999)))
                               / (
                    sum(
                    sacks_taken
                            * coalesce(opp_adj.sack_share_adj_ratio, 1)
                            * coalesce(team_adj.sack_share_adj_ratio, 1)
                            * coalesce(nfl_adj.sack_share_adj_ratio, 1)
                            *
                        pow(0.25, -(true_date - 1999)))
                    over (partition by player_display_name order by approximate_date) +
                        sum(((player_dropbacks - sacks_taken)) *
                    pow(0.25, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
                    + (coalesce(cfb.alpha_sacks, nfl.alpha_sacks) +
                coalesce(cfb.beta_sacks_dropbacks, nfl.beta_sacks_dropbacks))
                    *
                pow(0.25, -(true_date - 1999)))                                                                         as est_sacks_per_dropback
                       -- snap count estimates not as good for pre 2012
      ,                (sum(
                        completions
                                * coalesce(opp_adj.comp_pct_adj_ratio, 1)
                                * coalesce(team_adj.comp_pct_adj_ratio, 1)
                                * coalesce(nfl_adj.comp_pct_adj_ratio, 1)
                                / coalesce(age_c.total_comp_pct_change, 1)
                                * pow(0.5, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            * coalesce(age_c.total_comp_pct_change, 1)
            + coalesce((cfb.alpha_comps + cfb.beta_comps_passes) * (recr_adj.comp_pct / (1 + recr_adj.comp_pct)),
                       cfb.alpha_comps,
                       nfl.alpha_comps)
                * pow(0.5, -(true_date - 1999)))
                               / (
                    sum((pass_attempts - completions) *
                pow(0.5, -(true_date - 1999)))
                    over (partition by player_display_name order by approximate_date)
                    +
                        sum(((completions
                        * coalesce(opp_adj.comp_pct_adj_ratio, 1)
                        * coalesce(team_adj.comp_pct_adj_ratio, 1)
                        * coalesce(nfl_adj.comp_pct_adj_ratio, 1)
                        / coalesce(age_c.total_comp_pct_change, 1)
                    )) *
                    pow(0.5, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
                        * coalesce(age_c.total_comp_pct_change, 1)
                    + (coalesce(cfb.alpha_comps, nfl.alpha_comps) +
                coalesce(cfb.beta_comps_passes, nfl.beta_comps_passes))
                    *
                pow(0.5, -(true_date - 1999)))                                                                          as est_completion_pct
      ,                (sum(
                        passing_touchdowns
                                * coalesce(opp_adj.pass_tds_adj_ratio, 1)
                                * coalesce(team_adj.pass_tds_adj_ratio, 1)
                                * coalesce(nfl_adj.pass_tds_adj_ratio, 1)
                                / coalesce(age_c.total_pass_tds_change, 1)
                                * pow(0.5, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            * coalesce(age_c.total_pass_tds_change, 1)
            + coalesce((cfb.alpha_pass_tds + cfb.beta_pass_tds_comps) * recr_adj.pass_tds,
                       cfb.alpha_pass_tds,
                       nfl.alpha_pass_tds)
                * pow(0.5, -(true_date - 1999)))
                               / (sum(
                        passing_touchdowns
                                * coalesce(opp_adj.pass_tds_adj_ratio, 1)
                                * coalesce(team_adj.pass_tds_adj_ratio, 1)
                                * coalesce(nfl_adj.pass_tds_adj_ratio, 1)
                                / coalesce(age_c.total_pass_tds_change, 1)
                                * pow(0.5, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
                * coalesce(age_c.total_pass_tds_change, 1) +
                    sum(
                    ((completions - passing_touchdowns)) *
                        pow(0.5, -(true_date - 1999)))
                    over (partition by player_display_name order by approximate_date)
                + (coalesce(cfb.alpha_pass_tds, nfl.alpha_pass_tds) +
                coalesce(cfb.beta_pass_tds_comps, nfl.beta_pass_tds_comps))
                    *
                pow(0.5, -(true_date - 1999)))                                                                          as est_tds_per_completion
      ,                (sum(
                        passing_yards
                                * coalesce(opp_adj.pass_yds_adj_ratio, 1)
                                * coalesce(team_adj.pass_yds_adj_ratio, 1)
                                * coalesce(nfl_adj.pass_yds_adj_ratio, 1)
                                / coalesce(age_c.total_yds_per_comp_change, 1)
                                * pow(0.25, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            * coalesce(age_c.total_yds_per_comp_change, 1)
            + coalesce(cfb.beta_pass_yds_comps * recr_adj.pass_yards, cfb.alpha_pass_yds, nfl.alpha_pass_yds) *
            pow(0.25, -(true_date - 1999)))
                               / (sum(
                        completions
                                * pow(0.25, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
                + coalesce(cfb.beta_pass_yds_comps, nfl.beta_pass_yds_comps) *
                pow(0.25, -(true_date - 1999)))                                                                         as est_yards_per_completion

                       -- RECEIVING STATS:

      ,                (sum(
                        targets
                                * pow(0.6, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            + nfl.alpha_tgts * pow(0.6, -(true_date - 1999)))
                               / (
                    sum(coalesce(snap_count, team_snaps) *
                pow(0.6, -(true_date - 1999)))
                    over (partition by player_display_name order by approximate_date)
                    + (nfl.alpha_tgts + nfl.beta_tgts_snaps) *
                pow(0.6, -(true_date - 1999)))                                                                          as est_tgt_share
      ,                (sum(
                        receptions
                                * pow(0.6, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            + nfl.alpha_recs * pow(0.6, -(true_date - 1999)))
                               / (sum(
                        targets
                                * pow(0.6, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
                + (nfl.alpha_recs + nfl.beta_recs_tgts)
                    *
                pow(0.6, -(true_date - 1999)))                                                                          as est_catch_pct -- too high from 2003-2008
      ,                (sum(
                        receptions
                                * coalesce(opp_adj.rec_share_adj_ratio, 1)
                                * coalesce(team_adj.rec_share_adj_ratio, 1)
                                * coalesce(nfl_adj.rec_share_adj_ratio, 1)
                                / coalesce(age_c.total_rec_share_change, 1)
                                * pow(0.6, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            * coalesce(age_c.total_rec_share_change, 1)
            + coalesce((cfb.alpha_recs + cfb.beta_recs_snaps) * recr_adj.rec_share, cfb.alpha_recs, nfl.alpha_rec_snaps)
                * pow(0.6, -(true_date - 1999)))
                               / (
                    sum(
                    receptions
                            * coalesce(opp_adj.rec_share_adj_ratio, 1)
                            * coalesce(team_adj.rec_share_adj_ratio, 1)
                            * coalesce(nfl_adj.rec_share_adj_ratio, 1)
                            / coalesce(age_c.total_rec_share_change, 1)
                            *
                        pow(0.6, -(true_date - 1999)))
                    over (partition by player_display_name order by approximate_date)
                    * coalesce(age_c.total_rec_share_change, 1) +
                        sum(((team_snaps - receptions)) *
                    pow(0.6, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
                    + coalesce(cfb.beta_recs_snaps, nfl.beta_rec_snaps) *
                pow(0.6, -(true_date - 1999)))                                                                          as est_rec_share
      ,                (sum(
                        receiving_touchdowns
                                * coalesce(opp_adj.rec_tds_adj_ratio, 1)
                                * coalesce(team_adj.rec_tds_adj_ratio, 1)
                                * coalesce(nfl_adj.rec_tds_adj_ratio, 1)
                                / coalesce(age_c.total_rec_tds_change, 1)
                                * pow(0.7, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            * coalesce(age_c.total_rec_tds_change, 1)
            + coalesce((cfb.alpha_rec_tds + cfb.beta_rec_tds_recs) * recr_adj.rec_tds, cfb.alpha_rec_tds, nfl.alpha_rec_tds)
                * pow(0.7, -(true_date - 1999)))
                               / (
                    sum(
                    receiving_touchdowns
                            * coalesce(opp_adj.rec_tds_adj_ratio, 1)
                            * coalesce(team_adj.rec_tds_adj_ratio, 1)
                            * coalesce(nfl_adj.rec_tds_adj_ratio, 1)
                            / coalesce(age_c.total_rec_tds_change, 1)
                            * pow(0.7, -(true_date - 1999)))
                    over (partition by player_display_name order by approximate_date)
                    * coalesce(age_c.total_rec_tds_change, 1) +
                        sum(((receptions - receiving_touchdowns)) *
                    pow(0.7, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
                    + (coalesce(cfb.alpha_rec_tds, nfl.alpha_rec_tds) +
                coalesce(cfb.beta_rec_tds_recs, nfl.beta_rec_tds_recs))
                    *
                pow(0.7, -(true_date - 1999)))                                                                          as est_touchdowns_per_reception
      ,                (sum(
                        receiving_yards
                                * coalesce(opp_adj.rec_yds_adj_ratio, 1)
                                * coalesce(team_adj.rec_yds_adj_ratio, 1)
                                * coalesce(nfl_adj.rec_yds_adj_ratio, 1)
                                / coalesce(age_c.total_yds_per_rec_change, 1)
                                * pow(0.5, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            * coalesce(age_c.total_yds_per_rec_change, 1)
            + coalesce(cfb.beta_rec_yds_recs * recr_adj.rec_yards, cfb.alpha_rec_yds, nfl.alpha_rec_yds) *
            pow(0.5, -(true_date - 1999)))
                               / (sum(
                        receptions
                                * pow(0.5, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
                + coalesce(cfb.beta_rec_yds_recs, nfl.beta_rec_yds_recs) *
                pow(0.5, -(true_date - 1999)))                                                                          as est_yds_per_rec

                       -- RUSHING STATS:

      ,                (sum(
                        rush_attempts
                                * coalesce(opp_adj.rush_share_adj_ratio, 1)
                                * coalesce(team_adj.rush_share_adj_ratio, 1)
                                * coalesce(nfl_adj.rush_share_adj_ratio, 1)
                                / coalesce(age_c.total_rush_share_change, 1)
                                * pow(0.25, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            * coalesce(age_c.total_rush_share_change, 1)
            + coalesce((cfb.alpha_rushes + cfb.beta_rushes_snaps) * recr_adj.rush_share, cfb.alpha_rushes, nfl.alpha_rushes)
                * pow(0.25, -(true_date - 1999)))
                               / (
                    sum(
                    rush_attempts
                            * coalesce(opp_adj.rush_share_adj_ratio, 1)
                            * coalesce(team_adj.rush_share_adj_ratio, 1)
                            * coalesce(nfl_adj.rush_share_adj_ratio, 1)
                            / coalesce(age_c.total_rush_share_change, 1)
                            *
                        pow(0.25, -(true_date - 1999)))
                    over (partition by player_display_name order by approximate_date)
                    * coalesce(age_c.total_rush_share_change, 1) +
                        sum(((coalesce(snap_count, team_snaps) - rush_attempts)) *
                    pow(0.25, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
                    + (coalesce(cfb.alpha_rushes, nfl.alpha_rushes) +
                coalesce(cfb.beta_rushes_snaps, nfl.beta_rushes_snaps))
                    *
                pow(0.25, -(true_date - 1999)))                                                                         as est_rushes_per_snap
      ,                (sum(
                        rushing_touchdowns
                                * coalesce(opp_adj.rush_tds_adj_ratio, 1)
                                * coalesce(team_adj.rush_tds_adj_ratio, 1)
                                * coalesce(nfl_adj.rush_tds_adj_ratio, 1)
                                / coalesce(age_c.total_rush_tds_change, 1)
                                * pow(0.7, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            * coalesce(age_c.total_rush_tds_change, 1)
            + coalesce((cfb.alpha_rush_tds + cfb.beta_rush_tds_rushes) * recr_adj.rush_tds,
                       cfb.alpha_rush_tds,
                       nfl.alpha_rush_tds)
                * pow(0.7, -(true_date - 1999)))
                               / (
                    sum(
                    rushing_touchdowns
                            * coalesce(opp_adj.rush_tds_adj_ratio, 1)
                            * coalesce(team_adj.rush_tds_adj_ratio, 1)
                            * coalesce(nfl_adj.rush_tds_adj_ratio, 1)
                            / coalesce(age_c.total_rush_tds_change, 1)
                            * pow(0.7, -(true_date - 1999)))
                    over (partition by player_display_name order by approximate_date)
                    * coalesce(age_c.total_rush_tds_change, 1) +
                        sum(((rush_attempts - rushing_touchdowns)) *
                    pow(0.7, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
                    + (coalesce(cfb.alpha_rush_tds, nfl.alpha_rush_tds) +
                coalesce(cfb.beta_rush_tds_rushes, nfl.beta_rush_tds_rushes))
                    *
                pow(0.7, -(true_date - 1999)))                                                                          as est_touchdowns_per_rush
      ,                (sum(
                        rushing_yards
                                * coalesce(opp_adj.rush_yds_adj_ratio, 1)
                                * coalesce(team_adj.rush_yds_adj_ratio, 1)
                                * coalesce(nfl_adj.rush_yds_adj_ratio, 1)
                                / coalesce(age_c.total_yds_per_rush_change, 1)
                                * pow(0.5, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            * coalesce(age_c.total_yds_per_rush_change, 1)
            + coalesce(cfb.beta_rush_yds_rushes * recr_adj.rush_tds, cfb.alpha_rush_yds, nfl.alpha_rush_yds) *
            pow(0.5, -(true_date - 1999)))
                               / (sum(
                        rush_attempts
                                * pow(0.5, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
                + coalesce(cfb.beta_rush_yds_rushes, nfl.beta_rush_yds_rushes) *
                pow(0.5, -(true_date - 1999)))                                                                          as est_yds_per_rush
      ,                (sum(
                        ((epa / nullif(team_snaps, 0))
                                + coalesce(opp_adj.epa_factor, 0)
                                + coalesce(team_adj.epa_factor, 0)
                                + coalesce(nfl_adj.epa_adjustment, 0)
                                - coalesce(age_c.total_epa_change, 0))
                                * nullif(team_snaps, 0)
                                * pow(0.7, -(true_date - 1999)))
                        over (partition by player_display_name order by approximate_date)
            + coalesce(age_c.total_epa_change, 0)
            + coalesce(cfb.alpha_epa, nfl.alpha_epa) * pow(0.7, -(true_date - 1999)))
                               / (
                    sum(nullif(team_snaps, 0) *
                pow(0.7, -(true_date - 1999)))
                    over (partition by player_display_name order by approximate_date)
                    + coalesce(cfb.beta_epa_snaps, nfl.beta_epa_snaps) *
                pow(0.7, -(true_date - 1999)))                                                                          as est_epa_per_snap
    from game_logs                                             as n
         left join {{ ref("nfl_beta_priors") }}                          as nfl on nfl.position_group = n.position_group and nfl.since_2012 = (n.year >= 2012) and n.league = 'nfl'
         left join {{ ref("cfb_beta_priors") }}                          as cfb on cfb.position_group = n.position_group and n.league = 'cfb'
         left join {{ ref("nfl_beta_priors") }}                          as prior on prior.position_group = n.position_group and prior.since_2012 = true
         left join {{ ref("cfb_opponent_strength_adjustment_metrics") }} as opp_adj
                   on opp_adj.adj_from_is_home_game = n.is_home_game and opp_adj.position_group = n.position_group and opp_adj.opponent_elo = coalesce(n.opponent_elo, 1000)
                           and n.league = 'cfb'
         left join {{ ref("cfb_team_strength_adjustment_metrics") }}     as team_adj on team_adj.position_group = n.position_group and team_adj.team_elo = coalesce(n.team_elo, 1000) and n.league = 'cfb'
         left join {{ ref("cfb_nfl_metrics_adjustment_dim") }}           as nfl_adj on nfl_adj.position_group = n.position_group and n.league = 'cfb'
         left join {{ source("raw", "cfb_nfl_total_age_curve") }}        as age_c on age_c.position_group = n.position_group and
                   age_c.true_age = round(n.true_age * 10) / 10
         left join {{ source("raw", "cfb_recruiting_prior_adjustment") }} as recr_adj
                   on recr_adj.position_group = n.position_group and
                       recr_adj.rating = n.recruit_rating
    )
   , value_estimates as (
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
      , (est_passes_per_snap * ra_epa.pass_share
            + est_completion_pct * ra_epa.completion_percentage
            + est_yards_per_completion * ra_epa.yards_per_completion
            + est_tds_per_completion * ra_epa.tds_per_completion
            + est_rushes_per_snap * ra_epa.rush_share
            + est_yds_per_rush * ra_epa.yards_per_rush
            + est_touchdowns_per_rush * ra_epa.tds_per_rush
            + est_rec_share * ra_epa.reception_share
            + est_yds_per_rec * ra_epa.yards_per_reception
            + est_touchdowns_per_reception * ra_epa.tds_per_reception
            + ra_epa.intercept)
                                                                                                                                            as est_epa
    from base_stats                        as b
         left join {{ source("raw", "nfl_hex") }} on nfl_hex.team_code = b.team
         left join {{ source("raw", "cfb_hex") }} on cfb_hex.team_name = b.team
         left join {{ source("raw", "nfl_ra_epa_coefficients") }} as ra_epa on ra_epa.position_group = b.position_group
    )
   , replacement_dim as (
    select
        year
      , week
      , true_date
      , est_fantasy_points_per_game
      , position_group
      , row_number()
        over (partition by week, year, position_group order by est_fantasy_points_per_game desc) as rank
    from value_estimates
    where
          league = 'nfl'
      and position_group in ('WR', 'RB', 'TE', 'QB')
      and week < 17
    )
   , replacement_levels as (
    select
        position_group
      , year
      , avg(case
                when position_group = 'QB'
                        and round(13) = rank
                    then est_fantasy_points_per_game
                when position_group = 'WR'
                        and round(27 * 1 + 3) = rank
                    then est_fantasy_points_per_game
                when position_group = 'RB'
                        and round(23 * 1 + 3) = rank
                    then est_fantasy_points_per_game
                when position_group = 'TE'
                        and round(10 * 1 + 3) = rank
                    then est_fantasy_points_per_game
                end) as starter_replacement_level
      , avg(case
                when position_group = 'QB'
                        and round(10 * 2.43) = rank
                    then est_fantasy_points_per_game
                when position_group = 'WR'
                        and round(27 * 2.43) = rank
                    then est_fantasy_points_per_game
                when position_group = 'RB'
                        and round(23 * 2.43) = rank
                    then est_fantasy_points_per_game
                when position_group = 'TE'
                        and round(10 * 2.43) = rank
                    then est_fantasy_points_per_game
                end) as waiver_replacement_level
    from replacement_dim
    group by
        1, 2
    )
select
    e.*
  , e.est_fantasy_points_per_game - rp.waiver_replacement_level    as est_value_over_waiver_replacement
  , e.est_fantasy_points_per_game - rp.starter_replacement_level   as est_value_over_roster_replacement
from value_estimates           as e
     left join replacement_levels as rp on rp.year = e.year and rp.position_group = e.position_group
