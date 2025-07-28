drop table cfb_conferences;
create table cfb_conferences as
with conf_dim as (
    select distinct
        pos_team
      , year
      , offense_conference
      , count(*) over (partition by pos_team, year, offense_conference)::float / count(*) over (partition by pos_team, year)::float as pct
    from college_football_play_by_play_data
    )
select *
from conf_dim
where
    pct > 0.5