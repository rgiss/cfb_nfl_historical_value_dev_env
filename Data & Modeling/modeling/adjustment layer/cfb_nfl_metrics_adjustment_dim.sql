drop table cfb_nfl_metrics_adjustment_dim;
create table cfb_nfl_metrics_adjustment_dim as
with cfb_nfl_metrics_adjustment_dim as (
    select
        a.position_group
      , a.player_name
      , count(distinct a.game_id)                                                                                                                as adj_from_cohort_size
      , count(distinct b.game_id)                                                                                                                as adj_to_cohort_size
        --, 2 / (1 / count(distinct a.game_id) + 1 / count(distinct b.game_id)) as cohort_size
      , avg(a.fantasy_points_ppr)                                                                                                                as adj_from_fp_ppr
      , avg(b.fantasy_points_ppr)                                                                                                                as adj_to_fp_ppr
      , avg(a.epa + a_opp_adj.epa_factor + a_team_adj.epa_factor) / avg(a.team_snaps)                                                            as adj_from_epa
      , avg(b.epa) / avg(b.team_snaps)                                                                                                           as adj_to_epa
        -- RECEIVING
      , sum(a.receptions * a_opp_adj.rec_share_adj_ratio * a_team_adj.rec_share_adj_ratio) / nullif(sum(a.team_snaps - a.receptions), 0)         as adj_from_receptions_non_reception
      , sum(b.receptions) / nullif(sum(b.team_snaps - b.receptions), 0)                                                                          as adj_to_receptions_non_reception
      , sum(a.receiving_yards * a_opp_adj.rec_yds_adj_ratio * a_team_adj.rec_yds_adj_ratio)
                / nullif(sum(a.receptions), 0)                                                                                                   as adj_from_receiving_yards_per_reception
      , sum(b.receiving_yards) / nullif(sum(b.receptions), 0)                                                                                    as adj_to_receiving_yards_per_reception
      , sum(a.receiving_touchdowns * a_opp_adj.rec_tds_adj_ratio * a_team_adj.rec_tds_adj_ratio)
                / nullif(sum(a.receptions - a.receiving_touchdowns), 0)                                                                          as adj_from_receiving_touchdowns_per_non_receiving_touchdown
      , sum(b.receiving_touchdowns) / nullif(sum(b.receptions - b.receiving_touchdowns), 0)                                                      as adj_to_receiving_touchdowns_per_non_receiving_touchdown
        -- RUSHING
      , sum(a.rush_attempts * a_opp_adj.rush_share_adj_ratio * a_team_adj.rush_share_adj_ratio) / nullif(sum(a.team_snaps - a.rush_attempts), 0) as adj_from_rushes_per_non_rush
      , sum(b.rush_attempts) / nullif(sum(b.team_snaps - b.rush_attempts), 0)                                                                    as adj_to_rushes_per_non_rush
      , sum(a.rushing_yards * a_opp_adj.rush_yds_adj_ratio * a_team_adj.rush_yds_adj_ratio) / nullif(sum(a.rush_attempts), 0)                    as adj_from_rushing_yards_per_rush
      , sum(b.rushing_yards) / nullif(sum(b.rush_attempts), 0)                                                                                   as adj_to_rushing_yards_per_rush
      , sum(a.rushing_touchdowns * a_opp_adj.rush_tds_adj_ratio * a_team_adj.rush_tds_adj_ratio)
                / nullif(sum(a.rush_attempts - a.rushing_touchdowns), 0)                                                                         as adj_from_rushing_touchdowns_per_non_rushing_touchdown
      , sum(b.rushing_touchdowns) / nullif(sum(b.rush_attempts - b.rushing_touchdowns), 0)                                                       as adj_to_rushing_touchdowns_per_non_rushing_touchdown
        -- PASSING
      , case
            when a.position_group = 'QB'
                then sum(a.pass_attempts * a_opp_adj.pass_share_adj_ratio * a_team_adj.pass_share_adj_ratio) / nullif(sum(a.team_snaps - a.pass_attempts), 0)
            end                                                                                                                                  as adj_from_passes_per_non_pass
      , case
            when a.position_group = 'QB'
                then sum(b.pass_attempts) / nullif(sum(b.team_snaps - b.pass_attempts), 0)
            end                                                                                                                                  as adj_to_passes_per_non_pass
      , case
            when a.position_group = 'QB'
                then sum(a.completions * a_opp_adj.comp_pct_adj_ratio * a_team_adj.comp_pct_adj_ratio) / nullif(sum(a.pass_attempts - a.completions), 0)
            end                                                                                                                                  as adj_from_completions_per_non_completion
      , case
            when a.position_group = 'QB'
                then sum(b.completions) / nullif(sum(b.pass_attempts - b.completions), 0)
            end                                                                                                                                  as adj_to_completions_per_non_completion
      , case
            when a.position_group = 'QB'
                then sum(a.passing_yards * a_opp_adj.pass_yds_adj_ratio * a_team_adj.pass_yds_adj_ratio) / nullif(sum(a.completions), 0)
            end                                                                                                                                  as adj_from_passing_yards_per_completion
      , case
            when a.position_group = 'QB'
                then sum(b.passing_yards) / nullif(sum(b.completions), 0)
            end                                                                                                                                  as adj_to_passing_yards_per_completion
      , case
            when a.position_group = 'QB'
                then sum(a.passing_touchdowns * a_opp_adj.pass_tds_adj_ratio * a_team_adj.pass_tds_adj_ratio) / nullif(sum(a.completions - a.passing_touchdowns), 0)
            end                                                                                                                                  as adj_from_passing_touchdowns_per_non_passing_touchdown
      , case
            when a.position_group = 'QB'
                then sum(b.passing_touchdowns) / nullif(sum(b.completions - b.passing_touchdowns), 0)
            end                                                                                                                                  as adj_to_passing_touchdowns_per_non_passing_touchdown
    from cfb_game_logs                                       as a
         inner join nfl_game_logs                            as b
                    on a.player_display_name = b.player_display_name and (a.year = b.year - 1)
         inner join cfb_opponent_strength_adjustment_metrics as a_opp_adj
                    on a_opp_adj.position_group = a.position_group and coalesce(a_opp_adj.opponent_elo, 1000) = a.opponent_elo and a_opp_adj.adj_from_is_home_game = a.is_home_game
         inner join cfb_team_strength_adjustment_metrics     as a_team_adj
                    on a_team_adj.position_group = a.position_group and coalesce(a_team_adj.team_elo, 1000) = a.team_elo
    where
          b.game_id is not null
      and a.game_id is not null
      and a.position_group in ('WR', 'RB', 'QB', 'TE')
    group by
        1, 2
    having
          sum(a.receptions + a.pass_attempts + a.rush_attempts) > 0
      and sum(b.receptions + b.pass_attempts + b.rush_attempts) > 0
    )
select
    position_group
  , coalesce((sum(adj_to_epa * adj_to_cohort_size) / sum(adj_to_cohort_size))
                     - (sum(adj_from_epa * adj_from_cohort_size) / sum(adj_from_cohort_size)), 1)                                              as epa_adjustment
    --RECEIVING
  , coalesce((sum(adj_to_receptions_non_reception * adj_to_cohort_size) / sum(adj_to_cohort_size))
                     / (sum(adj_from_receptions_non_reception * adj_from_cohort_size) / sum(adj_from_cohort_size)), 1)                         as rec_share_adj_ratio
  , coalesce((sum(adj_to_receiving_yards_per_reception * adj_to_cohort_size) / sum(adj_to_cohort_size))
                     / (sum(adj_from_receiving_yards_per_reception * adj_from_cohort_size) / sum(adj_from_cohort_size)), 1)                    as rec_yds_adj_ratio
  , coalesce((sum(adj_to_receiving_touchdowns_per_non_receiving_touchdown * adj_to_cohort_size) / sum(adj_to_cohort_size))
                     / (sum(adj_from_receiving_touchdowns_per_non_receiving_touchdown * adj_from_cohort_size) / sum(adj_from_cohort_size)), 1) as rec_tds_adj_ratio
    --RUSHING
  , coalesce((sum(adj_to_rushes_per_non_rush * adj_to_cohort_size) / sum(adj_to_cohort_size))
                     / (sum(adj_from_rushes_per_non_rush * adj_from_cohort_size) / sum(adj_from_cohort_size)), 1)                              as rush_share_adj_ratio
  , coalesce((sum(adj_to_rushing_yards_per_rush * adj_to_cohort_size) / sum(adj_to_cohort_size))
                     / (sum(adj_from_rushing_yards_per_rush * adj_from_cohort_size) / sum(adj_from_cohort_size)), 1)                           as rush_yds_adj_ratio
  , coalesce((sum(adj_to_rushing_touchdowns_per_non_rushing_touchdown * adj_to_cohort_size) / sum(adj_to_cohort_size))
                     / (sum(adj_from_rushing_touchdowns_per_non_rushing_touchdown * adj_from_cohort_size) / sum(adj_from_cohort_size)), 1)     as rush_tds_adj_ratio
    --PASSING
  , coalesce((sum(adj_to_passes_per_non_pass * adj_to_cohort_size) / sum(adj_to_cohort_size))
                     / (sum(adj_from_passes_per_non_pass * adj_from_cohort_size) / sum(adj_from_cohort_size)), 1)                              as pass_share_adj_ratio
  , coalesce((sum(adj_to_completions_per_non_completion * adj_to_cohort_size) / sum(adj_to_cohort_size))
                     / (sum(adj_from_completions_per_non_completion * adj_from_cohort_size) / sum(adj_from_cohort_size)), 1)                   as comp_pct_adj_ratio
  , coalesce((sum(adj_to_passing_yards_per_completion * adj_to_cohort_size) / sum(adj_to_cohort_size))
                     / (sum(adj_from_passing_yards_per_completion * adj_from_cohort_size) / sum(adj_from_cohort_size)), 1)                     as pass_yds_adj_ratio
  , coalesce((sum(adj_to_passing_touchdowns_per_non_passing_touchdown * adj_to_cohort_size) / sum(adj_to_cohort_size))
                     / (sum(adj_from_passing_touchdowns_per_non_passing_touchdown * adj_from_cohort_size) / sum(adj_from_cohort_size)), 1)     as pass_tds_adj_ratio
from cfb_nfl_metrics_adjustment_dim
group by
    1;