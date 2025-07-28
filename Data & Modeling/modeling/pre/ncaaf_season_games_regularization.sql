drop table ncaaf_season_games_regularization;
create table ncaaf_season_games_regularization as
with games as (
    select distinct
        year         as year
      , week
      , pos_team     as pos_team
      , def_pos_team as opp_team
      , game_id
    from college_football_play_by_play_data
    )
select
    year
  , week
  , pos_team
  , opp_team
  , game_id
  , case
        when week = 1
            then count(game_id) over (partition by year, pos_team order by game_id)::float / (1 + count(game_id) over (partition by year, pos_team)::float) + year
            else year + week::float / 17
        end as year_game
  , case
        when week = 1
            then count(game_id) over (partition by year, pos_team order by game_id)::float / (1 + count(game_id) over (partition by year, pos_team)::float)
            else week::float / 17
        end as week_dec
from games;