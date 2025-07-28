drop table nfl_game_logs;
create table nfl_game_logs as
with game_logs_union as (
    select
        p.display_name as player_name
      , p.gsis_id
      , p.display_name || ': ' || right(gsis_id, 6)                                                                                                                                             as player_display_name
      , p.position_group
      , n.game_id
      , n.posteam     as team
      , n.defteam     as opponent
      , left(cast(n.game_date::date - interval '45 days' as text), 4)::int                                                                                                                      as year
      , n.week
      , n.game_date
      , n.season_type
      , p.rookie_season
      , p.birth_date  as birthdate
      , (n.game_date::date - make_date(left(cast(n.game_date::date - interval '45 days' as text), 4)::int, 9, 3))::float / 164
                + left(cast(n.game_date::date - interval '45 days' as text), 4)::int                                                                                                            as true_date
      , (n.game_date::date - p.birth_date::date) / 365.25                                                                                                                                       as age
      , (make_date(least(coalesce(p.rookie_season, left(current_date::text, 4)::int),
                         min(left(cast(game_date::date - interval '45 days' as text), 4)::int) over (partition by p.gsis_id))::int, 9, 3) - p.birth_date::date) / 365.25
                + (game_date::date - make_date(left(cast(game_date::date - interval '45 days' as text), 4)::int, 9, 3))::float / 164
                + left(cast(game_date::date - interval '45 days' as text), 4)::int - least(coalesce(p.rookie_season, left(current_date::text, 4)::int),
                                                                                           min(left(cast(game_date::date - interval '45 days' as text), 4)::int) over (partition by p.gsis_id)) as true_age
      , 0             as pass_attempts
      , 0             as completions
      , 0             as passing_yards
      , 0             as passing_air_yards
      , 0             as passing_touchdowns
      , 0             as sacks_taken
      , coalesce(count(n.receiver_player_id), 0)                                                                                                                                                as targets
      , sum(coalesce(n.complete_pass, 0))                                                                                                                                                       as receptions
      , sum(coalesce(n.receiving_yards, 0))                                                                                                                                                     as receiving_yards
      , sum(coalesce(n.air_yards, 0))                                                                                                                                                           as air_yards
      , sum(coalesce(n.yards_after_catch, 0))                                                                                                                                                   as yards_after_catch
      , sum(coalesce(n.pass_touchdown, 0))                                                                                                                                                      as receiving_touchdowns
      , coalesce(count(n.rusher_player_id), 0)                                                                                                                                                  as rush_attempts
      , sum(coalesce(n.rushing_yards, 0))                                                                                                                                                       as rushing_yards
      , sum(coalesce(n.rush_touchdown, 0))                                                                                                                                                      as rushing_touchdowns
      , sum(case
                when n.two_point_conv_result = 'success'
                    then 1
                    else 0
                end)  as twopt_conversions
      , sum(coalesce(n.fumble, 0))                                                                                                                                                              as fumbles
      , sum(coalesce(n.fumble_lost, 0))                                                                                                                                                         as fumbles_lost
      , 0             as passing_interception
      , sum(coalesce(n.interception, 0))                                                                                                                                                        as receiver_interception
      , 0             as return_yards
      , 0             as return_touchdowns
      , sum(coalesce(n.wpa, 0))                                                                                                                                                                 as wpa
      , sum(greatest(-0.5, least(0.5, case
                                          when posteam = home_team
                                              then ln(greatest(0.001, least(0.999, home_wp_post)) / (1 - greatest(0.001, least(0.999, home_wp_post))))
                                                  - ln(greatest(0.001, least(0.999, home_wp)) / (1 - greatest(0.001, least(0.999, home_wp))))
                                              else -(ln(greatest(0.001, least(0.999, home_wp_post)) / (1 - greatest(0.001, least(0.999, home_wp_post))))
                                                      - ln(greatest(0.001, least(0.999, home_wp)) / (1 - greatest(0.001, least(0.999, home_wp)))))
                                          end)))                                                                                                                                                as logit_wpa
      , sum(coalesce(n.epa, 0))                                                                                                                                                                 as epa/*
      , avg(coalesce(n.first_down, 0) - coalesce(c_init.conversion_rate, 0) + coalesce(c_post.conversion_rate, 0))                                                                              as first_downs_added
      , sum(greatest(n.yards_gained - n.ydstogo, 0))                                            as plus_yards_added*/
    from nfl_pbp_1999_2024      as n
         inner join nfl_players as p on p.gsis_id = coalesce(rusher_player_id, receiver_player_id)/*
         left join conversion_rate_by_down_distance as c_init on c_init.down = n.down and c_init.ydstogo = n.ydstogo and case
                             when n.down = 4
                                 then 'go'
                                 else 'slow'
                             end = c_init.type
         left join conversion_rate_by_down_distance as c_post on c_post.down = least(n.down + 1, 4) and c_post.ydstogo = n.ydstogo - n.yards_gained and case
                                                            when n.down = 4
                                                                then 'go'
                                                                else 'slow'
                                                            end = c_post.type*/
    where
        qb_kneel = 0
    group by
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
    union all
    select
        p.display_name as player_name
      , p.gsis_id
      , replace(replace(replace(p.display_name, ' Jr.', ''), '''', ''), '.', '') || ': ' || right(gsis_id, 6)                                                                                   as player_display_name
      , p.position_group
      , n.game_id
      , n.posteam     as team
      , n.defteam     as opponent
      , left(cast(n.game_date::date - interval '45 days' as text), 4)::int                                                                                                                      as year
      , n.week
      , n.game_date
      , n.season_type
      , p.rookie_season
      , p.birth_date  as birthdate
      , (n.game_date::date - make_date(left(cast(n.game_date::date - interval '45 days' as text), 4)::int, 9, 3))::float / 164
                + left(cast(n.game_date::date - interval '45 days' as text), 4)::int                                                                                                            as true_date
      , (n.game_date::date - p.birth_date::date) / 365.25                                                                                                                                       as age
      , (make_date(least(coalesce(p.rookie_season, left(current_date::text, 4)::int),
                         min(left(cast(game_date::date - interval '45 days' as text), 4)::int) over (partition by p.gsis_id))::int, 9, 3) - p.birth_date::date) / 365.25
                + (game_date::date - make_date(left(cast(game_date::date - interval '45 days' as text), 4)::int, 9, 3))::float / 164
                + left(cast(game_date::date - interval '45 days' as text), 4)::int - least(coalesce(p.rookie_season, left(current_date::text, 4)::int),
                                                                                           min(left(cast(game_date::date - interval '45 days' as text), 4)::int) over (partition by p.gsis_id)) as true_age
      , coalesce(sum(n.pass_attempt), 0)                                                                                                                                                        as pass_attempts --attempts overestimating                                    as pass_attempts
      , sum(coalesce(n.complete_pass, 0))                                                                                                                                                       as completions
      , sum(coalesce(n.passing_yards))                                                                                                                                                          as passing_yards
      , sum(coalesce(n.air_yards))                                                                                                                                                              as passing_air_yards
      , sum(coalesce(n.pass_touchdown, 0))                                                                                                                                                      as passing_touchdowns
      , count(sack_player_id)                                                                                                                                                                   as sacks_taken
      , 0             as targets
      , 0             as receptions
      , 0             as receiving_yards
      , 0             as receiving_air_yards
      , 0             as receiving_yards_after_catch
      , 0             as receiving_touchdowns
      , 0             as rush_attempts
      , 0             as rushing_yards
      , 0             as rushing_touchdowns
      , sum(case
                when n.two_point_conv_result = 'success'
                    then 1
                    else 0
                end)  as twopt_conversions
      , 0             as fumbles
      , 0             as fumbles_lost
      , sum(coalesce(n.interception, 0))                                                                                                                                                        as passing_interception
      , 0             as receiver_interception
      , 0             as return_yards
      , 0             as return_touchdowns
      , sum(coalesce(n.wpa, 0))                                                                                                                                                                 as wpa
      , sum(greatest(-0.5, least(0.5, case
                                          when posteam = home_team
                                              then ln(greatest(0.001, least(0.999, home_wp_post)) / (1 - greatest(0.001, least(0.999, home_wp_post))))
                                                  - ln(greatest(0.001, least(0.999, home_wp)) / (1 - greatest(0.001, least(0.999, home_wp))))
                                              else -(ln(greatest(0.001, least(0.999, home_wp_post)) / (1 - greatest(0.001, least(0.999, home_wp_post))))
                                                      - ln(greatest(0.001, least(0.999, home_wp)) / (1 - greatest(0.001, least(0.999, home_wp)))))
                                          end)))                                                                                                                                                as logit_wpa
      , sum(coalesce(n.epa, 0))                                                                                                                                                                 as epa/*
      , avg(coalesce(n.first_down, 0) - coalesce(c_init.conversion_rate, 0) + coalesce(c_post.conversion_rate, 0))                                                                              as first_downs_added
      , sum(greatest(n.yards_gained - n.ydstogo, 0))                                            as plus_yards_added*/
    from nfl_pbp_1999_2024      as n
         inner join nfl_players as p on p.gsis_id = passer_player_id/*
         left join conversion_rate_by_down_distance as c_init on c_init.down = n.down and c_init.ydstogo = n.ydstogo and case
                             when n.down = 4
                                 then 'go'
                                 else 'slow'
                             end = c_init.type
         left join conversion_rate_by_down_distance as c_post on c_post.down = least(n.down + 1, 4) and c_post.ydstogo = n.ydstogo - n.yards_gained and case
                                                            when n.down = 4
                                                                then 'go'
                                                                else 'slow'
                                                            end = c_post.type*/
    where
        qb_kneel = 0
    group by
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
    union all
    select
        p.display_name as player_name
      , p.gsis_id
      , replace(replace(replace(p.display_name, ' Jr.', ''), '''', ''), '.', '') || ': ' || right(gsis_id, 6)                                                                                   as player_display_name
      , p.position_group
      , n.game_id
      , coalesce(n.return_team, n.defteam)                                                                                                                                                      as team
      , case
            when n.posteam = coalesce(n.return_team, n.defteam)
                then n.defteam
                else n.posteam
            end       as opponent
      , left(cast(n.game_date::date - interval '45 days' as text), 4)::int                                                                                                                      as year
      , n.week
      , n.game_date
      , n.season_type
      , p.rookie_season
      , p.birth_date  as birthdate
      , (n.game_date::date - make_date(left(cast(n.game_date::date - interval '45 days' as text), 4)::int, 9, 3))::float / 164
                + left(cast(n.game_date::date - interval '45 days' as text), 4)::int                                                                                                            as true_date
      , (n.game_date::date - p.birth_date::date) / 365.25                                                                                                                                       as age
      , (make_date(least(coalesce(p.rookie_season, left(current_date::text, 4)::int),
                         min(left(cast(game_date::date - interval '45 days' as text), 4)::int) over (partition by p.gsis_id))::int, 9, 3) - p.birth_date::date) / 365.25
                + (game_date::date - make_date(left(cast(game_date::date - interval '45 days' as text), 4)::int, 9, 3))::float / 164
                + left(cast(game_date::date - interval '45 days' as text), 4)::int - least(coalesce(p.rookie_season, left(current_date::text, 4)::int),
                                                                                           min(left(cast(game_date::date - interval '45 days' as text), 4)::int) over (partition by p.gsis_id)) as true_age
      , 0             as pass_attempts --attempts overestimating                                    as pass_attempts
      , 0             as completions
      , 0             as passing_yards
      , 0             as passing_air_yards
      , 0             as passing_touchdowns
      , 0             as sacks_taken
      , 0             as targets
      , 0             as receptions
      , 0             as receiving_yards
      , 0             as receiving_air_yards
      , 0             as receiving_yards_after_catch
      , 0             as receiving_touchdowns
      , 0             as rush_attempts
      , 0             as rushing_yards
      , 0             as rushing_touchdowns
      , 0             as twopt_conversions
      , 0             as fumbles
      , 0             as fumbles_lost
      , 0             as passing_interception
      , 0             as receiver_interception
      , sum(coalesce(n.return_yards, 0))                                                                                                                                                        as return_yards
      , sum(coalesce(n.return_touchdown, 0))                                                                                                                                                    as return_touchdowns
      , sum(coalesce(n.wpa, 0))                                                                                                                                                                 as wpa
      , sum(greatest(-0.5, least(0.5, case
                                          when posteam = home_team
                                              then ln(greatest(0.001, least(0.999, home_wp_post)) / (1 - greatest(0.001, least(0.999, home_wp_post))))
                                                  - ln(greatest(0.001, least(0.999, home_wp)) / (1 - greatest(0.001, least(0.999, home_wp))))
                                              else -(ln(greatest(0.001, least(0.999, home_wp_post)) / (1 - greatest(0.001, least(0.999, home_wp_post))))
                                                      - ln(greatest(0.001, least(0.999, home_wp)) / (1 - greatest(0.001, least(0.999, home_wp)))))
                                          end)))                                                                                                                                                as logit_wpa
      , sum(coalesce(n.epa, 0))                                                                                                                                                                 as epa/*
      , 0         as first_downs_added
      , 0         as plus_yards_added*/
    from nfl_pbp_1999_2024      as n
         inner join nfl_players as p on p.gsis_id = coalesce(kickoff_returner_player_id, punt_returner_player_id)/*
         left join conversion_rate_by_down_distance as c_init on c_init.down = n.down and c_init.ydstogo = n.ydstogo and case
                             when n.down = 4
                                 then 'go'
                                 else 'slow'
                             end = c_init.type
         left join conversion_rate_by_down_distance as c_post on c_post.down = least(n.down + 1, 4) and c_post.ydstogo = n.ydstogo - n.yards_gained and case
                                                            when n.down = 4
                                                                then 'go'
                                                                else 'slow'
                                                            end = c_post.type*/
    group by
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
    )
select
    glu.player_name
  , gsis_id
  , glu.player_display_name
  , position_group
  , glu.game_id
  , glu.team
  , hex.primary_color                                                                                                                                                                     as team_primary_color_hex
  , hex.secondary_color                                                                                                                                                                   as team_secondary_color_hex
  , glu.opponent
  , glu.year
  , glu.week
  , game_date
  , glu.season_type
  , true_date
  , rookie_season
  , age
  , true_age
  , row_number() over (partition by glu.player_name order by true_date)                                                                                                                   as player_game_number
  , row_number() over (partition by glu.player_name order by true_date desc) - 1                                                                                                          as player_games_remaining
  , row_number() over (partition by glu.player_name, glu.year order by true_date)                                                                                                         as player_season_game_number
  , row_number() over (partition by glu.player_name, glu.year order by true_date desc) - 1                                                                                                as player_season_games_remaining
  , left(cast(game_date::date - interval '45 days' as text), 4)::int - least(rookie_season,
                                                                             min(left(cast(game_date::date - interval '45 days' as text), 4)::int) over (partition by gsis_id))           as experience_yrs
  , (game_date::date - make_date(left(cast(game_date::date - interval '45 days' as text), 4)::int, 9, 3))::float / 164
            + left(cast(game_date::date - interval '45 days' as text), 4)::int - least(rookie_season,
                                                                                       min(left(cast(game_date::date - interval '45 days' as text), 4)::int) over (partition by gsis_id)) as experience_dec
  , max(offense_snaps)                                                                                                                                                                    as snap_count
  , max(offense_pct)                                                                                                                                                                      as snap_percent
  , sum(pass_attempts) + sum(case
                                 when position_group = 'QB'
                                     then rush_attempts
                                     else 0
                                 end)
            + sum(sacks_taken)                                                                                                                                                            as player_dropbacks
  , sum(sum(pass_attempts) + sum(case
                                     when position_group = 'QB'
                                         then rush_attempts
                                         else 0
                                     end)
        + sum(sacks_taken))
    over (partition by glu.team, game_date)                                                                                                                                               as team_dropbacks
  , sum(sum(pass_attempts) + sum(rush_attempts)
        + sum(sacks_taken))
    over (partition by glu.team, game_date)                                                                                                                                               as team_snaps
  , sum(pass_attempts)                                                                                                                                                                    as pass_attempts
  , sum(completions)                                                                                                                                                                      as completions
  , sum(completions) / nullif(sum(pass_attempts), 0)                                                                                                                                      as completion_percentage
  , sum(passing_yards)                                                                                                                                                                    as passing_yards
  , sum(passing_yards) / nullif(sum(completions), 0)                                                                                                                                      as passing_yards_per_completion
  , sum(passing_yards) / nullif(sum(pass_attempts), 0)                                                                                                                                    as passing_yards_per_attempt
  , sum(passing_air_yards)                                                                                                                                                                as passing_air_yards
  , sum(passing_air_yards) / nullif(sum(pass_attempts), 0)                                                                                                                                as passing_air_yards_per_attempt
  , sum(passing_touchdowns)                                                                                                                                                               as passing_touchdowns
  , sum(passing_touchdowns) / nullif(sum(pass_attempts), 0)                                                                                                                               as passing_touchdowns_per_attempt
  , sum(sacks_taken)                                                                                                                                                                      as sacks_taken
  , sum(sacks_taken) / nullif(sum(pass_attempts) + sum(case
                                                           when position_group = 'QB'
                                                               then rush_attempts
                                                               else 0
                                                           end) + sum(sacks_taken),
                              0)                                                                                                                                                          as sacks_per_dropback
  , sum(targets)as targets
  , sum(receptions)                                                                                                                                                                       as receptions
  , sum(receiving_yards)                                                                                                                                                                  as receiving_yards
  , sum(air_yards)                                                                                                                                                                        as air_yards
  , sum(yards_after_catch)                                                                                                                                                                as yards_after_catch
  , sum(receiving_touchdowns)                                                                                                                                                             as receiving_touchdowns
  , sum(rush_attempts)                                                                                                                                                                    as rush_attempts
  , sum(rushing_yards)                                                                                                                                                                    as rushing_yards
  , sum(rushing_touchdowns)                                                                                                                                                               as rushing_touchdowns
  , sum(twopt_conversions)                                                                                                                                                                as twopt_conversions
  , sum(fumbles)as fumbles
  , sum(fumbles_lost)                                                                                                                                                                     as fumbles_lost
  , sum(passing_interception)                                                                                                                                                             as passing_interception
  , sum(receiver_interception)                                                                                                                                                            as receiver_interception
  , sum(return_yards)                                                                                                                                                                     as return_yards
  , sum(return_touchdowns)                                                                                                                                                                as return_touchdowns
  , sum(wpa)    as wpa
  , sum(logit_wpa)                                                                                                                                                                        as logit_wpa
  , sum(epa)    as epa/*
  , sum(first_downs_added)                                                             as first_downs_added
  , sum(plus_yards_added)                                                              as plus_yards_added*/
  , sum(passing_yards) * 0.04 + sum(receiving_yards) * 0.1 + sum(rushing_yards) * 0.1
            + sum(passing_touchdowns) * 4 + sum(rushing_touchdowns) * 6 + sum(receiving_touchdowns) * 6
            - sum(passing_interception) * 2
            - sum(fumbles_lost) * 2                                                                                                                                                       as fantasy_points_std
  , sum(passing_yards) * 0.04 + sum(receiving_yards) * 0.1 + sum(rushing_yards) * 0.1 + sum(receptions) * 0.5
            + sum(passing_touchdowns) * 4 + sum(rushing_touchdowns) * 6 + sum(receiving_touchdowns) * 6
            - sum(passing_interception) * 2
            - sum(fumbles_lost) * 2                                                                                                                                                       as fantasy_points_half_ppr
  , sum(passing_yards) * 0.04 + sum(receiving_yards) * 0.1 + sum(rushing_yards) * 0.1 + sum(receptions)
            + sum(passing_touchdowns) * 4 + sum(rushing_touchdowns) * 6 + sum(receiving_touchdowns) * 6
            - sum(passing_interception) * 2
            - sum(fumbles_lost) * 2                                                                                                                                                       as fantasy_points_ppr
  , sum(passing_yards) * 0.04 + sum(receiving_yards) * 0.1 + sum(rushing_yards) * 0.1 + sum(receptions)
            + sum(passing_touchdowns) * 6 + sum(rushing_touchdowns) * 6 + sum(receiving_touchdowns) * 6
            - sum(passing_interception) * 2 - sum(fumbles_lost) * 2
            + case
                  when sum(coalesce(passing_yards, 0)) > 400
                      then 6
                      else 0
                  end
            + case
                  when sum(coalesce(rushing_yards, 0)) > 100
                      then 3
                      else 0
                  end
            + case
                  when sum(coalesce(rushing_yards, 0)) > 200
                      then 3
                      else 0
                  end
            + case
                  when sum(coalesce(receiving_yards, 0)) > 100
                      then 3
                      else 0
                  end
            + case
                  when sum(coalesce(receiving_yards, 0)) > 200
                      then 3
                      else 0
                  end + sum(return_yards) * 0.04
            + sum(return_touchdowns) * 6                                                                                                                                                  as fantasy_points_t
from game_logs_union                     as glu
     left join nfl_snap_counts_2012_2024 as sc on trim(lower(replace(replace(replace(replace(sc.player_name, '''', ''), ' III', ''), ' Jr.', ''), ' Sr.', '')))
        = trim(lower(replace(replace(replace(replace(glu.player_name, '''', ''), ' III', ''), ' Jr.', ''), ' Sr.', ''))) and sc.game_id = glu.game_id and case
                                                                                                                                                              when sc.position = 'FB'
                                                                                                                                                                  then 'HB'
                                                                                                                                                                  else sc.position
                                                                                                                                                              end = glu.position_group
     left join nfl_hex                   as hex on hex.team_code = glu.team
--where position_group in ('WR','TE','RB','QB')
group by
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17