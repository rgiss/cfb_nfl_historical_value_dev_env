{{
  config(
    materialized='view',
    schema='staging'
  )
}}

-- Converted from: /Users/riley.gisseman/Downloads/cfb_nfl_dev_env/Data & Modeling/modeling/pre/cfb_clean_player_positions.sql
-- cfb_clean_player_positions


select
-- ISSUE: circular reference with cfb_game_logs. Use as static table
    player_name
  , year
  , case
        when sum(targets) + sum(pass_attempts) + sum(rush_attempts) < 0.01 * sum(team_snaps)
            then 'DEF/ST'
        when sum(targets) > sum(pass_attempts) + sum(rush_attempts)
            then 'WR'
        when sum(pass_attempts) > sum(targets) + sum(rush_attempts)
            then 'QB'
        when sum(rush_attempts) > sum(targets) + sum(pass_attempts)
            then 'RB'
            else 'OTHER'
        end as position
from base.cfb_game_logs
group by
    1, 2