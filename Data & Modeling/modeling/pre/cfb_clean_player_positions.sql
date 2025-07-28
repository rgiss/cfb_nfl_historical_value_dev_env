
drop table cfb_clean_player_positions;
create table cfb_clean_player_positions as
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
from cfb_game_logs
group by
    1, 2