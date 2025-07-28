drop table cfb_team_strength_adjustment_metrics;
create table cfb_team_strength_adjustment_metrics as
with cfb_team_strength_adjustment_dim as (
    select
        a.position_group
      , a.player_name
      , a.team_elo                                                                                 as adj_from_team_elo
      , b.team_elo                                                                                 as adj_to_team_elo
      , count(distinct a.game_id)                                                                  as adj_from_cohort_size
      , count(distinct b.game_id)                                                                  as adj_to_cohort_size
        --, 2 / (1 / count(distinct a.game_id) + 1 / count(distinct b.game_id)) as cohort_size
      , avg(a.fantasy_points_ppr)                                                                  as adj_from_fp_ppr
      , avg(b.fantasy_points_ppr)                                                                  as adj_to_fp_ppr
        -- RECEIVING
      , sum(a.receptions * a_opp_adj.rec_share_adj_ratio) / nullif(sum(a.team_snaps - a.receptions), 0)           as adj_from_receptions_non_reception
      , sum(b.receptions * b_opp_adj.rec_share_adj_ratio) / nullif(sum(b.team_snaps - b.receptions), 0)           as adj_to_receptions_non_reception
      , sum(a.receiving_yards * a_opp_adj.rec_yds_adj_ratio) / nullif(sum(a.receptions), 0)        as adj_from_receiving_yards_per_reception
      , sum(b.receiving_yards * b_opp_adj.rec_yds_adj_ratio) / nullif(sum(b.receptions), 0)        as adj_to_receiving_yards_per_reception
      , sum(a.receiving_touchdowns * a_opp_adj.rec_tds_adj_ratio) / nullif(sum(a.receptions), 0)   as adj_from_receiving_touchdowns_per_reception
      , sum(b.receiving_touchdowns * b_opp_adj.rec_tds_adj_ratio) / nullif(sum(b.receptions), 0)   as adj_to_receiving_touchdowns_per_reception
        -- RUSHING
      , sum(a.rush_attempts * a_opp_adj.rush_share_adj_ratio) / nullif(sum(a.team_snaps - a.rush_attempts), 0)       as adj_from_rushes_per_non_rush
      , sum(b.rush_attempts * b_opp_adj.rush_share_adj_ratio) / nullif(sum(b.team_snaps - b.rush_attempts), 0)       as adj_to_rushes_per_non_rush
      , sum(a.rushing_yards * a_opp_adj.rush_yds_adj_ratio) / nullif(sum(a.rush_attempts), 0)      as adj_from_rushing_yards_per_rush
      , sum(b.rushing_yards * b_opp_adj.rush_yds_adj_ratio) / nullif(sum(b.rush_attempts), 0)      as adj_to_rushing_yards_per_rush
      , sum(a.rushing_touchdowns * a_opp_adj.rush_tds_adj_ratio) / nullif(sum(a.rush_attempts), 0) as adj_from_rushing_touchdowns_per_rush
      , sum(b.rushing_touchdowns * b_opp_adj.rush_tds_adj_ratio) / nullif(sum(b.rush_attempts), 0) as adj_to_rushing_touchdowns_per_rush
        -- PASSING
      , case
            when a.position_group = 'QB'
                then sum(a.pass_attempts * a_opp_adj.pass_share_adj_ratio) / nullif(sum(a.team_snaps - a.pass_attempts), 0)
            end                                                                                    as adj_from_passes_per_non_pass
      , case
            when a.position_group = 'QB'
                then sum(b.pass_attempts * b_opp_adj.pass_share_adj_ratio) / nullif(sum(b.team_snaps - b.pass_attempts), 0)
            end                                                                                    as adj_to_passes_per_non_pass
      , case
            when a.position_group = 'QB'
                then sum(a.completions * a_opp_adj.comp_pct_adj_ratio) / nullif(sum(a.pass_attempts - a.completions), 0)
            end                                                                                    as adj_from_completions_per_non_completion
      , case
            when a.position_group = 'QB'
                then sum(b.completions * b_opp_adj.comp_pct_adj_ratio) / nullif(sum(b.pass_attempts - b.completions), 0)
            end                                                                                    as adj_to_completions_per_non_completion
      , case
            when a.position_group = 'QB'
                then sum(a.passing_yards * a_opp_adj.pass_yds_adj_ratio) / nullif(sum(a.completions), 0)
            end                                                                                    as adj_from_passing_yards_per_completion
      , case
            when a.position_group = 'QB'
                then sum(b.passing_yards * b_opp_adj.pass_yds_adj_ratio) / nullif(sum(b.completions), 0)
            end                                                                                    as adj_to_passing_yards_per_completion
      , case
            when a.position_group = 'QB'
                then sum(a.passing_touchdowns * a_opp_adj.pass_tds_adj_ratio) / nullif(sum(a.completions), 0)
            end                                                                                    as adj_from_passing_touchdowns_per_completion
      , case
            when a.position_group = 'QB'
                then sum(b.passing_touchdowns * b_opp_adj.pass_tds_adj_ratio) / nullif(sum(b.completions), 0)
            end                                                                                    as adj_to_passing_touchdowns_per_completion
    from cfb_game_logs                                       as a
         inner join cfb_game_logs                            as b
                    on a.player_name = b.player_name and a.team != b.team and ((a.year = b.year + 1) or (a.year = b.year - 1)) and a.game_id <> b.game_id
                            and a.position_group = b.position_group
         inner join cfb_opponent_strength_adjustment_metrics as a_opp_adj
                    on a_opp_adj.position_group = a.position_group and a_opp_adj.opponent_elo = a.opponent_elo and a_opp_adj.adj_from_is_home_game = a.is_home_game
         inner join cfb_opponent_strength_adjustment_metrics as b_opp_adj
                    on b_opp_adj.position_group = b.position_group and b_opp_adj.opponent_elo = b.opponent_elo and b_opp_adj.adj_from_is_home_game = b.is_home_game
    where
          b.game_id is not null
      and a.game_id is not null
      and a.position_group in ('WR', 'RB', 'QB', 'TE')
    group by
        1, 2, 3, 4
    having
          sum(a.receptions + a.pass_attempts + a.rush_attempts) > 0
      and sum(b.receptions + b.pass_attempts + b.rush_attempts) > 0
    )
   , cfb_team_strength_adjustment_agg as (
    select
        adj_to_team_elo - adj_from_team_elo as team_elo_difference
      , position_group
        -- RECEIVING
      , (sum(sum(adj_from_receptions_non_reception * adj_to_cohort_size))
         over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_receptions_non_reception * adj_from_cohort_size))
                    over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                            as receptions_per_non_reception_delta
      , (sum(sum(adj_to_receiving_yards_per_reception * adj_to_cohort_size))
         over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_receiving_yards_per_reception * adj_from_cohort_size))
                    over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                            as receiving_yards_per_reception_delta
      , (sum(sum(adj_to_receiving_touchdowns_per_reception * adj_to_cohort_size))
         over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_receiving_touchdowns_per_reception * adj_from_cohort_size))
                    over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                            as receiving_touchdowns_per_reception_delta

        -- RUSHING
      , (sum(sum(adj_to_rushes_per_non_rush * adj_to_cohort_size))
         over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_rushes_per_non_rush * adj_from_cohort_size))
                    over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                            as rushes_per_non_rush_delta
      , (sum(sum(adj_to_rushing_yards_per_rush * adj_to_cohort_size))
         over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_rushing_yards_per_rush * adj_from_cohort_size))
                    over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                            as rushing_yards_per_rush_delta
      , (sum(sum(adj_to_rushing_touchdowns_per_rush * adj_to_cohort_size))
         over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_rushing_touchdowns_per_rush * adj_from_cohort_size))
                    over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                            as rushing_touchdowns_per_rush_delta

        -- PASSING
      , (sum(sum(adj_to_passes_per_non_pass * adj_to_cohort_size))
         over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_passes_per_non_pass * adj_from_cohort_size))
                    over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                            as passes_per_non_pass_delta
      , (sum(sum(adj_to_completions_per_non_completion * adj_to_cohort_size))
         over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_completions_per_non_completion * adj_from_cohort_size))
                    over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                            as completions_per_non_completion_delta
      , (sum(sum(adj_to_passing_yards_per_completion * adj_to_cohort_size))
         over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_passing_yards_per_completion * adj_from_cohort_size))
                    over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                            as passing_yards_per_completion_delta
      , (sum(sum(adj_to_passing_touchdowns_per_completion * adj_to_cohort_size))
         over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_passing_touchdowns_per_completion * adj_from_cohort_size))
                    over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                            as passing_touchdowns_per_completion_delta


      , (sum(sum(adj_to_fp_ppr * adj_to_cohort_size))
         over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size))
              over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following))
--adj to ppr
                /
            nullif((sum(sum(adj_from_fp_ppr * adj_from_cohort_size))
                    over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
                    / sum(sum(adj_from_cohort_size))
                      over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)), 0)
            --adj from ppr
-- to / from  = ratio (2 is  to > from! 0.5 is from > to.
                                            as fp_delta
      , (sum(sum((adj_to_team_elo - adj_from_team_elo) * adj_to_cohort_size))
         over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following)
            / sum(sum(adj_to_cohort_size)) over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following))
                                            as true_team_elo_delta
      , (sum(sum(adj_to_cohort_size))
         over (partition by position_group order by adj_to_team_elo - adj_from_team_elo rows between 100 preceding and 100 following))
                                            as true_cohort_size
    from cfb_team_strength_adjustment_dim
    where
        adj_to_team_elo - adj_from_team_elo is not null
    group by
        1, 2
    having
        sum(adj_to_cohort_size) > 5
    )
   , cfb_team_strength_adjustment_regression as (
    select
        position_group
      , regr_slope(ln(nullif(fp_delta, 0)), true_team_elo_delta)                                     as fp_slope
      , regr_intercept(ln(nullif(fp_delta, 0)), true_team_elo_delta)                                 as fp_intercept
        -- RECEIVING
      , regr_slope(ln(nullif(receptions_per_non_reception_delta, 0)), true_team_elo_delta)                    as rec_share_slope
      , regr_intercept(ln(nullif(receptions_per_non_reception_delta, 0)), true_team_elo_delta)                as rec_share_intercept
      , regr_slope(ln(nullif(receiving_yards_per_reception_delta, 0)), true_team_elo_delta)          as rec_yds_slope
      , regr_intercept(ln(nullif(receiving_yards_per_reception_delta, 0)), true_team_elo_delta)      as rec_yds_intercept
      , regr_slope(ln(nullif(receiving_touchdowns_per_reception_delta, 0)), true_team_elo_delta)     as rec_tds_slope
      , regr_intercept(ln(nullif(receiving_touchdowns_per_reception_delta, 0)), true_team_elo_delta) as rec_tds_intercept
        -- RUSHING
      , regr_slope(ln(nullif(rushes_per_non_rush_delta, 0)), true_team_elo_delta)                        as rush_share_slope
      , regr_intercept(ln(nullif(rushes_per_non_rush_delta, 0)), true_team_elo_delta)                    as rush_share_intercept
      , regr_slope(ln(nullif(rushing_yards_per_rush_delta, 0)), true_team_elo_delta)                 as rush_yds_slope
      , regr_intercept(ln(nullif(rushing_yards_per_rush_delta, 0)), true_team_elo_delta)             as rush_yds_intercept
      , regr_slope(ln(nullif(rushing_touchdowns_per_rush_delta, 0)), true_team_elo_delta)            as rush_tds_slope
      , regr_intercept(ln(nullif(rushing_touchdowns_per_rush_delta, 0)), true_team_elo_delta)        as rush_tds_intercept
        -- PASSING
      , regr_slope(ln(nullif(passes_per_non_pass_delta, 0)), true_team_elo_delta)                        as pass_share_slope
      , regr_intercept(ln(nullif(passes_per_non_pass_delta, 0)), true_team_elo_delta)                    as pass_share_intercept
      , regr_slope(ln(nullif(completions_per_non_completion_delta, 0)), true_team_elo_delta)                   as comp_pct_slope
      , regr_intercept(ln(nullif(completions_per_non_completion_delta, 0)), true_team_elo_delta)               as comp_pct_intercept
      , regr_slope(ln(nullif(passing_yards_per_completion_delta, 0)), true_team_elo_delta)           as pass_yds_slope
      , regr_intercept(ln(nullif(passing_yards_per_completion_delta, 0)), true_team_elo_delta)       as pass_yds_intercept
      , regr_slope(ln(nullif(passing_touchdowns_per_completion_delta, 0)), true_team_elo_delta)      as pass_tds_slope
      , regr_intercept(ln(nullif(passing_touchdowns_per_completion_delta, 0)), true_team_elo_delta)  as pass_tds_intercept
    from cfb_team_strength_adjustment_agg
    where
        true_team_elo_delta between -400 and 400
    group by
        1
    )
   , cfb_team_strength_adjustment_metrics as (
    select distinct
        spine.team_elo                                                                      as team_elo
      , r.position_group
      , exp((2500 - spine.team_elo) * fp_slope + fp_intercept)                              as fp_factor
        -- RECEIVING
      , exp((2500 - spine.team_elo) * rec_share_slope + rec_share_intercept)                as rec_share_adj_ratio
      , exp((2500 - spine.team_elo) * rec_yds_slope + rec_yds_intercept)                    as rec_yds_adj_ratio
      , exp((2500 - spine.team_elo) * rec_tds_slope + rec_tds_intercept)                    as rec_tds_adj_ratio
        -- RUSHING
      , case
            when r.position_group = 'TE'
                then 1
                else exp((2500 - spine.team_elo) * rush_share_slope + rush_share_intercept)
            end                                                                             as rush_share_adj_ratio
      , case
            when r.position_group = 'TE'
                then 1
                else exp((2500 - spine.team_elo) * rush_yds_slope + rush_yds_intercept)
            end                                                                             as rush_yds_adj_ratio
      , case
            when r.position_group = 'TE'
                then 1
                else exp((2500 - spine.team_elo) * rush_tds_slope + rush_tds_intercept)
            end                                                                             as rush_tds_adj_ratio
        -- PASSING
      , coalesce(exp((2500 - spine.team_elo) * pass_share_slope + pass_share_intercept), 1) as pass_share_adj_ratio
      , coalesce(exp((2500 - spine.team_elo) * comp_pct_slope + comp_pct_intercept), 1)     as comp_pct_adj_ratio
      , coalesce(exp((2500 - spine.team_elo) * pass_yds_slope + pass_yds_intercept), 1)     as pass_yds_adj_ratio
      , coalesce(exp((2500 - spine.team_elo) * pass_tds_slope + pass_tds_intercept), 1)     as pass_tds_adj_ratio
    from (
             select distinct
                 team_elo
             from cfb_game_logs
             )                                             as spine
         full join cfb_team_strength_adjustment_regression as r on true
    )
select *
from cfb_team_strength_adjustment_metrics;