drop table cfb_nfl_player_id_map;
create table cfb_nfl_player_id_map as
with player_id_trace as (
    select distinct
        np.gsis_id
      , np.display_name
      , ni.player_name                      as cfb_name
      , ni.player_name_id
      , max_pts
      , rank
      , coalesce(np.draft_year, np.rookie_season)
      , split_part(np.college_name, ';', 1) as college_name
      , count(*) over (partition by np.gsis_id)
    from nfl_players                   as np
         left join cfb_player_name_ids as ni
                   on lower(regexp_replace(replace(replace(replace(replace(replace(np.display_name, ' Jr.', ''), ' Sr.', ''), ' III', ''), ' IV', ''), ' II', '')
                       , '[^A-Za-z0-9]', '', 'g'))
                           = lower(regexp_replace(replace(replace(replace(replace(replace(ni.player_name, ' Jr.', ''), ' Sr.', ''), ' III', ''), ' IV', ''), ' II', '')
                           , '[^A-Za-z0-9]', '', 'g'))
                           and np.rookie_season between ni.year + 1 and ni.year + 2
                           and case
                                   when split_part(np.college_name, ';', 1) = 'Louisiana State'
                                       then 'LSU'
                                   when split_part(np.college_name, ';', 1) = 'Southern Methodist'
                                       then 'SMU'
                                   when split_part(np.college_name, ';', 1) = 'Brigham Young'
                                       then 'BYU'
                                   when split_part(np.college_name, ';', 1) = 'Southern California'
                                       then 'USC'
                                   when split_part(np.college_name, ';', 1) = 'Mississippi'
                                       then 'Ole Miss'
                                   when split_part(np.college_name, ';', 1) = 'Texas A&amp;M'
                                       then 'Texas A&M'
                                   when split_part(np.college_name, ';', 1) = 'Central Florida'
                                       then 'UCF'
                                   when split_part(np.college_name, ';', 1) = 'Texas-El Paso'
                                       then 'UTEP'
                                       else split_part(np.college_name, ';', 1)
                                   end = ni.final_team
         left join (
        select
            gsis_id
          , position_group
          , max(est_fantasy_points_value)                                                               as max_pts
          , row_number() over (partition by position_group order by max(est_fantasy_points_value) desc) as rank
        from nfl_historical_value_estimate
        group by
            1, 2
        )                              as a on a.gsis_id = np.gsis_id
    )
select *
from player_id_trace