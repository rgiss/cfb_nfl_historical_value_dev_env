drop table nfl_historical_replacement_player;
create table nfl_historical_replacement_player as
with dim as (
    select
        year
      , week
      , true_date
      , est_fantasy_points_per_game
      , position_group
      , row_number() over (partition by week, year, position_group order by est_fantasy_points_per_game desc) as rank
    from cfb_nfl_historical_value_estimate
    where
          league = 'nfl'
      and position_group in ('WR', 'RB', 'TE', 'QB')
      and week < 17
    )
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
--, est_fantasy_points_per_game as replacement_level
from dim
group by
    1, 2