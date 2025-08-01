drop table cfb_opponent_strength_adjustment_metrics;
create table cfb_opponent_strength_adjustment_metrics as
with cfb_opponent_strength_adjustment_dim as (
    select
        a.position_group
      , a.player_display_name
      , a.is_home_game                                                                      as adj_from_is_home_game
      , a.opponent_elo                                                                      as adj_from_opp_elo
      , b.opponent_elo                                                                      as adj_to_opp_elo
      , count(distinct a.game_id)                                                           as adj_from_cohort_size
      , count(distinct b.game_id)                                                           as adj_to_cohort_size
        --, 2 / (1 / count(distinct a.game_id) + 1 / count(distinct b.game_id)) as cohort_size
      , avg(a.fantasy_points_ppr)                                                           as adj_from_fp_ppr
      , avg(b.fantasy_points_ppr)                                                           as adj_to_fp_ppr
      , avg(a.epa) / avg(a.team_snaps)                                                      as adj_from_epa_per_snap
      , avg(b.epa) / avg(b.team_snaps)                                                      as adj_to_epa_per_snap
        -- RECEIVING
      , sum(a.receptions) / nullif(sum(a.team_snaps - a.receptions), 0)                     as adj_from_receptions_per_non_reception
      , sum(b.receptions) / nullif(sum(b.team_snaps - b.receptions), 0)                     as adj_to_receptions_per_non_reception
      , sum(a.receiving_yards) / nullif(sum(a.receptions), 0)                               as adj_from_receiving_yards_per_reception
      , sum(b.receiving_yards) / nullif(sum(b.receptions), 0)                               as adj_to_receiving_yards_per_reception
      , sum(a.receiving_touchdowns) / nullif(sum(a.receptions - a.receiving_touchdowns), 0) as adj_from_receiving_touchdowns_per_non_receiving_touchdown
      , sum(b.receiving_touchdowns) / nullif(sum(b.receptions - b.receiving_touchdowns), 0) as adj_to_receiving_touchdowns_per_non_receiving_touchdown
        -- RUSHING
      , sum(a.rush_attempts) / nullif(sum(a.team_snaps - a.rush_attempts), 0)               as adj_from_rushes_per_non_rush
      , sum(b.rush_attempts) / nullif(sum(b.team_snaps - b.rush_attempts), 0)               as adj_to_rushes_per_non_rush
      , sum(a.rushing_yards) / nullif(sum(a.rush_attempts), 0)                              as adj_from_rushing_yards_per_rush
      , sum(b.rushing_yards) / nullif(sum(b.rush_attempts), 0)                              as adj_to_rushing_yards_per_rush
      , sum(a.rushing_touchdowns) / nullif(sum(a.rush_attempts - a.rushing_touchdowns), 0)  as adj_from_rushing_touchdowns_per_non_rushing_touchdown
      , sum(b.rushing_touchdowns) / nullif(sum(b.rush_attempts - b.rushing_touchdowns), 0)  as adj_to_rushing_touchdowns_per_non_rushing_touchdown
        -- PASSING
      , sum(a.pass_attempts) / nullif(sum(a.team_snaps - a.pass_attempts), 0)               as adj_from_passes_per_non_pass
      , sum(b.pass_attempts) / nullif(sum(b.team_snaps - b.pass_attempts), 0)               as adj_to_passes_per_non_pass
      , sum(a.completions) / nullif(sum(a.pass_attempts - a.completions), 0)                as adj_from_completions_per_non_completion
      , sum(b.completions) / nullif(sum(b.pass_attempts - b.completions), 0)                as adj_to_completions_per_non_completion
      , sum(a.passing_yards) / nullif(sum(a.completions), 0)                                as adj_from_passing_yards_per_completion
      , sum(b.passing_yards) / nullif(sum(b.completions), 0)                                as adj_to_passing_yards_per_completion
      , sum(a.passing_touchdowns) / nullif(sum(a.completions - a.passing_touchdowns), 0)    as adj_from_passing_touchdowns_per_non_passing_touchdown
      , sum(b.passing_touchdowns) / nullif(sum(b.completions - b.passing_touchdowns), 0)    as adj_to_passing_touchdowns_per_non_passing_touchdown
    from cfb_game_logs            as a
         inner join cfb_game_logs as b
                    on a.player_display_name = b.player_display_name and a.team = b.team and a.year = b.year and a.game_id <> b.game_id
    where
          b.game_id is not null
      and a.game_id is not null
      and a.position_group in ('WR', 'RB', 'QB', 'TE')
      and a.team_snaps > 0
      and b.team_snaps > 0
    group by
        1, 2, 3, 4, 5
    having
          sum(a.receptions + a.pass_attempts + a.rush_attempts) > 0
      and sum(b.receptions + b.pass_attempts + b.rush_attempts) > 0
    )
   , cfb_opponent_strength_adjustment_agg as (
    select
        adj_to_opp_elo - adj_from_opp_elo as opponent_elo_difference
      , adj_from_is_home_game
      , position_group
        -- RECEIVING
      , (sum(sum(adj_to_receptions_per_non_reception * adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_receptions_per_non_reception * adj_from_cohort_size))
                    over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                          as receptions_per_non_reception_delta
      , (sum(sum(adj_to_receiving_yards_per_reception * adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_receiving_yards_per_reception * adj_from_cohort_size))
                    over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                          as receiving_yards_per_reception_delta
      , (sum(sum(adj_to_receiving_touchdowns_per_non_receiving_touchdown * adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_receiving_touchdowns_per_non_receiving_touchdown * adj_from_cohort_size))
                    over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                          as receiving_touchdowns_per_non_receiving_touchdown_delta

        -- RUSHING
      , (sum(sum(adj_to_rushes_per_non_rush * adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_rushes_per_non_rush * adj_from_cohort_size))
                    over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                          as rushes_per_non_rush_delta
      , (sum(sum(adj_to_rushing_yards_per_rush * adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_rushing_yards_per_rush * adj_from_cohort_size))
                    over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                          as rushing_yards_per_rush_delta
      , (sum(sum(adj_to_rushing_touchdowns_per_non_rushing_touchdown * adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_rushing_touchdowns_per_non_rushing_touchdown * adj_from_cohort_size))
                    over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                          as rushing_touchdowns_per_non_rushing_touchdown_delta

        -- PASSING
      , (sum(sum(adj_to_passes_per_non_pass * adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_passes_per_non_pass * adj_from_cohort_size))
                    over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                          as passes_per_non_pass_delta
      , (sum(sum(adj_to_completions_per_non_completion * adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_completions_per_non_completion * adj_from_cohort_size))
                    over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                          as completions_per_non_completion_delta
      , (sum(sum(adj_to_passing_yards_per_completion * adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_passing_yards_per_completion * adj_from_cohort_size))
                    over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                          as passing_yards_per_completion_delta
      , (sum(sum(adj_to_passing_touchdowns_per_non_passing_touchdown * adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_passing_touchdowns_per_non_passing_touchdown * adj_from_cohort_size))
                    over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                          as passing_touchdowns_per_non_passing_touchdown_delta


      , (sum(sum(adj_to_fp_ppr * adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_fp_ppr * adj_from_cohort_size))
                    over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                          as fp_delta
      , (sum(sum(adj_to_epa_per_snap * adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
--adj to ppr
            -
        (sum(sum(adj_from_epa_per_snap * adj_from_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
                / sum(sum(adj_from_cohort_size))
                  over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)))
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                          as epa_delta
      , (sum(sum((adj_to_opp_elo - adj_from_opp_elo) * adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size)) over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following))
                                          as true_opp_elo_delta
      , (sum(sum(adj_to_cohort_size))
         over (partition by adj_from_is_home_game, position_group order by adj_to_opp_elo - adj_from_opp_elo rows between 100 preceding and 100 following))
                                          as true_cohort_size
    from cfb_opponent_strength_adjustment_dim
    where
        adj_to_opp_elo - adj_from_opp_elo is not null
    group by
        1, 2, 3
    having
          sum(adj_to_cohort_size) > 5
      and sum(adj_from_cohort_size) > 5
    )
   , cfb_opponent_strength_adjustment_regression as (
    select
        position_group
      , adj_from_is_home_game
      , regr_slope(ln(nullif(fp_delta, 0)), true_opp_elo_delta)                                                   as fp_slope
      , regr_intercept(ln(nullif(fp_delta, 0)), true_opp_elo_delta)                                               as fp_intercept
      , regr_slope(epa_delta, true_opp_elo_delta)                                                                 as epa_slope
      , regr_intercept(epa_delta, true_opp_elo_delta)                                                             as epa_intercept
        -- RECEIVING
      , regr_slope(ln(nullif(receptions_per_non_reception_delta, 0)), true_opp_elo_delta)                         as rec_share_slope
      , regr_intercept(ln(nullif(receptions_per_non_reception_delta, 0)), true_opp_elo_delta)                     as rec_share_intercept
      , regr_slope(ln(nullif(receiving_yards_per_reception_delta, 0)), true_opp_elo_delta)                        as rec_yds_slope
      , regr_intercept(ln(nullif(receiving_yards_per_reception_delta, 0)), true_opp_elo_delta)                    as rec_yds_intercept
      , regr_slope(ln(nullif(receiving_touchdowns_per_non_receiving_touchdown_delta, 0)), true_opp_elo_delta)     as rec_tds_slope
      , regr_intercept(ln(nullif(receiving_touchdowns_per_non_receiving_touchdown_delta, 0)), true_opp_elo_delta) as rec_tds_intercept
        -- RUSHING
      , regr_slope(ln(nullif(rushes_per_non_rush_delta, 0)), true_opp_elo_delta)                                  as rush_share_slope
      , regr_intercept(ln(nullif(rushes_per_non_rush_delta, 0)), true_opp_elo_delta)                              as rush_share_intercept
      , regr_slope(ln(nullif(rushing_yards_per_rush_delta, 0)), true_opp_elo_delta)                               as rush_yds_slope
      , regr_intercept(ln(nullif(rushing_yards_per_rush_delta, 0)), true_opp_elo_delta)                           as rush_yds_intercept
      , regr_slope(ln(nullif(rushing_touchdowns_per_non_rushing_touchdown_delta, 0)), true_opp_elo_delta)         as rush_tds_slope
      , regr_intercept(ln(nullif(rushing_touchdowns_per_non_rushing_touchdown_delta, 0)), true_opp_elo_delta)     as rush_tds_intercept
        -- PASSING
      , regr_slope(ln(nullif(passes_per_non_pass_delta, 0)), true_opp_elo_delta)                                  as pass_share_slope
      , regr_intercept(ln(nullif(passes_per_non_pass_delta, 0)), true_opp_elo_delta)                              as pass_share_intercept
      , regr_slope(ln(nullif(completions_per_non_completion_delta, 0)), true_opp_elo_delta)                       as comp_pct_slope
      , regr_intercept(ln(nullif(completions_per_non_completion_delta, 0)), true_opp_elo_delta)                   as comp_pct_intercept
      , regr_slope(ln(nullif(passing_yards_per_completion_delta, 0)), true_opp_elo_delta)                         as pass_yds_slope
      , regr_intercept(ln(nullif(passing_yards_per_completion_delta, 0)), true_opp_elo_delta)                     as pass_yds_intercept
      , regr_slope(ln(nullif(passing_touchdowns_per_non_passing_touchdown_delta, 0)), true_opp_elo_delta)         as pass_tds_slope
      , regr_intercept(ln(nullif(passing_touchdowns_per_non_passing_touchdown_delta, 0)), true_opp_elo_delta)     as pass_tds_intercept
    from cfb_opponent_strength_adjustment_agg
    where
        true_opp_elo_delta between -400 and 400
    group by
        1, 2
    )
   , cfb_opponent_strength_adjustment_metrics as (
    select distinct
        adj_from_opp_elo                                                         as opponent_elo
      , r.position_group
      , r.adj_from_is_home_game
      , exp((2500 - adj_from_opp_elo) * fp_slope + fp_intercept)                 as fp_factor
      , (2500 - adj_from_opp_elo) * epa_slope + epa_intercept                    as epa_factor
        -- RECEIVING
      , exp((2500 - adj_from_opp_elo) * rec_share_slope + rec_share_intercept)   as rec_share_adj_ratio
      , exp((2500 - adj_from_opp_elo) * rec_yds_slope + rec_yds_intercept)       as rec_yds_adj_ratio
      , exp((2500 - adj_from_opp_elo) * rec_tds_slope + rec_tds_intercept)       as rec_tds_adj_ratio
        -- RUSHING
      , exp((2500 - adj_from_opp_elo) * rush_share_slope + rush_share_intercept) as rush_share_adj_ratio
      , exp((2500 - adj_from_opp_elo) * rush_yds_slope + rush_yds_intercept)     as rush_yds_adj_ratio
      , exp((2500 - adj_from_opp_elo) * rush_tds_slope + rush_tds_intercept)     as rush_tds_adj_ratio
        -- PASSING
      , exp((2500 - adj_from_opp_elo) * pass_share_slope + pass_share_intercept) as pass_share_adj_ratio
      , exp((2500 - adj_from_opp_elo) * comp_pct_slope + comp_pct_intercept)     as comp_pct_adj_ratio
      , exp((2500 - adj_from_opp_elo) * pass_yds_slope + pass_yds_intercept)     as pass_yds_adj_ratio
      , exp((2500 - adj_from_opp_elo) * pass_tds_slope + pass_tds_intercept)     as pass_tds_adj_ratio
    from cfb_opponent_strength_adjustment_dim
         full join cfb_opponent_strength_adjustment_regression as r on true
    )
select *
from cfb_opponent_strength_adjustment_metrics;