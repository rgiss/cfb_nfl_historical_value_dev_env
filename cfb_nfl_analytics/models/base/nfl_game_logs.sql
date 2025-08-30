{{
  config(
    materialized='table',
    schema='base'
  )
}}

-- Base model for NFL game logs
-- Aggregates player performance metrics by game from play-by-play data

with game_logs_union as (
    -- Receiving and Rushing stats
    select
        p.display_name as player_name,
        p.gsis_id,
        p.display_name || ': ' || right(p.gsis_id, 6) as player_display_name,
        p.position_group,
        n.game_id,
        n.posteam as team,
        n.defteam as opponent,
        extract(year from n.game_date::date - interval '45 days') as year,
        n.week,
        n.game_date,
        n.season_type,
        p.rookie_season,
        p.birth_date as birthdate,
        
        -- Calculate true date (season-adjusted)
        (n.game_date::date - make_date(extract(year from n.game_date::date - interval '45 days')::int, 9, 3))::float / 164
        + extract(year from n.game_date::date - interval '45 days') as true_date,
        
        -- Calculate age at game time
        (n.game_date::date - p.birth_date::date) / 365.25 as age,
        
        -- Calculate true age (career-adjusted)
        (make_date(
            least(
                coalesce(p.rookie_season, extract(year from current_date)::int),
                min(extract(year from n.game_date::date - interval '45 days')) over (partition by p.gsis_id)
            )::int, 9, 3
        ) - p.birth_date::date) / 365.25
        + (n.game_date::date - make_date(extract(year from n.game_date::date - interval '45 days')::int, 9, 3))::float / 164
        + extract(year from n.game_date::date - interval '45 days') 
        - least(
            coalesce(p.rookie_season, extract(year from current_date)::int),
            min(extract(year from n.game_date::date - interval '45 days')) over (partition by p.gsis_id)
        ) as true_age,
        
        -- Passing stats (all zeros for non-passers)
        0 as pass_attempts,
        0 as completions,
        0 as passing_yards,
        0 as passing_air_yards,
        0 as passing_touchdowns,
        0 as sacks_taken,
        
        -- Receiving stats
        coalesce(count(n.receiver_player_id), 0) as targets,
        sum(coalesce(n.complete_pass, 0)) as receptions,
        sum(coalesce(n.receiving_yards, 0)) as receiving_yards,
        sum(coalesce(n.air_yards, 0)) as air_yards,
        sum(coalesce(n.yards_after_catch, 0)) as yards_after_catch,
        sum(coalesce(n.pass_touchdown, 0)) as receiving_touchdowns,
        
        -- Rushing stats
        coalesce(count(n.rusher_player_id), 0) as rush_attempts,
        sum(coalesce(n.rushing_yards, 0)) as rushing_yards,
        sum(coalesce(n.rush_touchdown, 0)) as rushing_touchdowns,
        
        -- Other stats
        sum(case when n.two_point_conv_result = 'success' then 1 else 0 end) as twopt_conversions,
        sum(coalesce(n.fumble, 0)) as fumbles,
        sum(coalesce(n.fumble_lost, 0)) as fumbles_lost,
        0 as passing_interception,
        sum(coalesce(n.interception, 0)) as receiver_interception,
        0 as return_yards,
        0 as return_touchdowns,
        
        -- Advanced stats
        sum(coalesce(n.wpa, 0)) as wpa,
        sum(greatest(-0.5, least(0.5, case
            when n.posteam = n.home_team
                then ln(greatest(0.001, least(0.999, n.home_wp_post)) / (1 - greatest(0.001, least(0.999, n.home_wp_post))))
                    - ln(greatest(0.001, least(0.999, n.home_wp)) / (1 - greatest(0.001, least(0.999, n.home_wp))))
                else -(ln(greatest(0.001, least(0.999, n.home_wp_post)) / (1 - greatest(0.001, least(0.999, n.home_wp_post))))
                        - ln(greatest(0.001, least(0.999, n.home_wp)) / (1 - greatest(0.001, least(0.999, n.home_wp)))))
            end))) as logit_wpa,
        sum(coalesce(n.epa, 0)) as epa
        
    from {{ ref('stg_nfl_pbp') }} as n
    inner join {{ source('raw', 'nfl_players') }} as p 
        on p.gsis_id = coalesce(n.rusher_player_id, n.receiver_player_id)
    where n.qb_kneel = 0
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
    
    union all
    
    -- Passing stats
    select
        p.display_name as player_name,
        p.gsis_id,
        p.display_name || ': ' || right(p.gsis_id, 6) as player_display_name,
        p.position_group,
        n.game_id,
        n.posteam as team,
        n.defteam as opponent,
        extract(year from n.game_date::date - interval '45 days') as year,
        n.week,
        n.game_date,
        n.season_type,
        p.rookie_season,
        p.birth_date as birthdate,
        
        -- Calculate true date (season-adjusted)
        (n.game_date::date - make_date(extract(year from n.game_date::date - interval '45 days')::int, 9, 3))::float / 164
        + extract(year from n.game_date::date - interval '45 days') as true_date,
        
        -- Calculate age at game time
        (n.game_date::date - p.birth_date::date) / 365.25 as age,
        
        -- Calculate true age (career-adjusted)
        (make_date(
            least(
                coalesce(p.rookie_season, extract(year from current_date)::int),
                min(extract(year from n.game_date::date - interval '45 days')) over (partition by p.gsis_id)
            )::int, 9, 3
        ) - p.birth_date::date) / 365.25
        + (n.game_date::date - make_date(extract(year from n.game_date::date - interval '45 days')::int, 9, 3))::float / 164
        + extract(year from n.game_date::date - interval '45 days') 
        - least(
            coalesce(p.rookie_season, extract(year from current_date)::int),
            min(extract(year from n.game_date::date - interval '45 days')) over (partition by p.gsis_id)
        ) as true_age,
        
        -- Passing stats
        coalesce(sum(n.pass_attempt), 0) as pass_attempts,
        sum(coalesce(n.complete_pass, 0)) as completions,
        sum(coalesce(n.passing_yards, 0)) as passing_yards,
        sum(coalesce(n.air_yards, 0)) as passing_air_yards,
        sum(coalesce(n.pass_touchdown, 0)) as passing_touchdowns,
        count(n.sack) filter (where n.sack = 1) as sacks_taken,
        
        -- Receiving stats (all zeros for passers)
        0 as targets,
        0 as receptions,
        0 as receiving_yards,
        0 as air_yards,
        0 as yards_after_catch,
        0 as receiving_touchdowns,
        
        -- Rushing stats (zeros for non-QB rushers)
        0 as rush_attempts,
        0 as rushing_yards,
        0 as rushing_touchdowns,
        
        -- Other stats
        sum(case when n.two_point_conv_result = 'success' then 1 else 0 end) as twopt_conversions,
        0 as fumbles,
        0 as fumbles_lost,
        sum(coalesce(n.interception, 0)) as passing_interception,
        0 as receiver_interception,
        0 as return_yards,
        0 as return_touchdowns,
        
        -- Advanced stats
        sum(coalesce(n.wpa, 0)) as wpa,
        sum(greatest(-0.5, least(0.5, case
            when n.posteam = n.home_team
                then ln(greatest(0.001, least(0.999, n.home_wp_post)) / (1 - greatest(0.001, least(0.999, n.home_wp_post))))
                    - ln(greatest(0.001, least(0.999, n.home_wp)) / (1 - greatest(0.001, least(0.999, n.home_wp))))
                else -(ln(greatest(0.001, least(0.999, n.home_wp_post)) / (1 - greatest(0.001, least(0.999, n.home_wp_post))))
                        - ln(greatest(0.001, least(0.999, n.home_wp)) / (1 - greatest(0.001, least(0.999, n.home_wp)))))
            end))) as logit_wpa,
        sum(coalesce(n.epa, 0)) as epa
        
    from {{ ref('stg_nfl_pbp') }} as n
    inner join {{ source('raw', 'nfl_players') }} as p 
        on p.gsis_id = n.passer_player_id
    where n.qb_kneel = 0
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
),

final as (
    select
        glu.player_name,
        glu.gsis_id,
        glu.player_display_name,
        glu.position_group,
        glu.game_id,
        glu.team,
        glu.opponent,
        glu.year,
        glu.week,
        glu.game_date,
        glu.season_type,
        glu.true_date,
        glu.rookie_season,
        glu.age,
        glu.true_age,
        
        -- Career progression metrics
        row_number() over (partition by glu.player_name order by glu.true_date) as player_game_number,
        row_number() over (partition by glu.player_name order by glu.true_date desc) - 1 as player_games_remaining,
        row_number() over (partition by glu.player_name, glu.year order by glu.true_date) as player_season_game_number,
        row_number() over (partition by glu.player_name, glu.year order by glu.true_date desc) - 1 as player_season_games_remaining,
        
        -- Experience calculations
        glu.year - least(
            glu.rookie_season,
            min(glu.year) over (partition by glu.gsis_id)
        ) as experience_yrs,
        
        (glu.game_date::date - make_date(glu.year::int, 9, 3))::float / 164
        + glu.year - least(
            glu.rookie_season,
            min(glu.year) over (partition by glu.gsis_id)
        ) as experience_dec,
        
        -- Aggregated stats
        sum(glu.pass_attempts) as pass_attempts,
        sum(glu.completions) as completions,
        case 
            when sum(glu.pass_attempts) > 0 
            then sum(glu.completions)::float / sum(glu.pass_attempts) 
            else null 
        end as completion_percentage,
        sum(glu.passing_yards) as passing_yards,
        sum(glu.passing_air_yards) as passing_air_yards,
        sum(glu.passing_touchdowns) as passing_touchdowns,
        sum(glu.sacks_taken) as sacks_taken,
        sum(glu.targets) as targets,
        sum(glu.receptions) as receptions,
        sum(glu.receiving_yards) as receiving_yards,
        sum(glu.air_yards) as air_yards,
        sum(glu.yards_after_catch) as yards_after_catch,
        sum(glu.receiving_touchdowns) as receiving_touchdowns,
        sum(glu.rush_attempts) as rush_attempts,
        sum(glu.rushing_yards) as rushing_yards,
        sum(glu.rushing_touchdowns) as rushing_touchdowns,
        sum(glu.twopt_conversions) as twopt_conversions,
        sum(glu.fumbles) as fumbles,
        sum(glu.fumbles_lost) as fumbles_lost,
        sum(glu.passing_interception) as passing_interception,
        sum(glu.receiver_interception) as receiver_interception,
        sum(glu.return_yards) as return_yards,
        sum(glu.return_touchdowns) as return_touchdowns,
        sum(glu.wpa) as wpa,
        sum(glu.logit_wpa) as logit_wpa,
        sum(glu.epa) as epa,
        
        -- Fantasy points calculations
        sum(glu.passing_yards) * 0.04 + sum(glu.receiving_yards) * 0.1 + sum(glu.rushing_yards) * 0.1
        + sum(glu.passing_touchdowns) * 4 + sum(glu.rushing_touchdowns) * 6 + sum(glu.receiving_touchdowns) * 6
        - sum(glu.passing_interception) * 2 - sum(glu.fumbles_lost) * 2 as fantasy_points_std,
        
        sum(glu.passing_yards) * 0.04 + sum(glu.receiving_yards) * 0.1 + sum(glu.rushing_yards) * 0.1 + sum(glu.receptions) * 0.5
        + sum(glu.passing_touchdowns) * 4 + sum(glu.rushing_touchdowns) * 6 + sum(glu.receiving_touchdowns) * 6
        - sum(glu.passing_interception) * 2 - sum(glu.fumbles_lost) * 2 as fantasy_points_half_ppr,
        
        sum(glu.passing_yards) * 0.04 + sum(glu.receiving_yards) * 0.1 + sum(glu.rushing_yards) * 0.1 + sum(glu.receptions)
        + sum(glu.passing_touchdowns) * 4 + sum(glu.rushing_touchdowns) * 6 + sum(glu.receiving_touchdowns) * 6
        - sum(glu.passing_interception) * 2 - sum(glu.fumbles_lost) * 2 as fantasy_points_ppr
        
    from game_logs_union as glu
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
)

select * from final
