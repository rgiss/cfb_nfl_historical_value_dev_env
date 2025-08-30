{{
  config(
    materialized='view',
    schema='staging'
  )
}}

-- Converted from: /Users/riley.gisseman/Downloads/cfb_nfl_dev_env/Data & Modeling/modeling/pre/cfb_conferences.sql
-- cfb_conferences

with conf_dim as (
    select distinct
        pos_team
      , year
      , offense_conference
      , count(*) over (partition by pos_team, year, offense_conference)::float / count(*) over (partition by pos_team, year)::float as pct
    from {{ source("raw", "college_football_play_by_play_data") }}
    )
select *
from conf_dim
where
    pct > 0.5