drop table cfb_game_logs;
create table cfb_game_logs as
with game_logs_union as (
    --receiver/rusher game logs
    select
        cpn.clean_player_name                                                   as player_name
      , cpni.player_name_id                                                     as player_name_id
      , null                                                                    as position_group
      , cpni.final_team
      , n.game_id
      , n.pos_team                                                              as team
      , n.def_pos_team                                                          as opponent
        --, n.offense_conference
        --, n.defense_conference
      , n.pos_team = n.home                                                     as is_home_game
      , n.year
      , n.week
      , make_date(n.year, 8, 28) + round(reg.week_dec * 135) * interval '1 day' as approximate_date
      , null                                                                    as season
      , cpni.freshman_year
      , cpni.final_year
      , cpni.manual_birthdate                                                   as manual_birthdate
      , reg.year_game                                                           as true_date
      , n.year - cpni.freshman_year                                             as experience_yrs
      , reg.year_game - cpni.freshman_year                                      as experience_dec
      , 0                                                                       as pass_attempts
      , 0                                                                       as completions
      , 0                                                                       as passing_yards
      , 0                                                                       as passing_air_yards
      , 0                                                                       as passing_touchdowns
      , 0                                                                       as sacks_taken
      , coalesce(count(coalesce(n.receiver_player_name, n.reception_player, n.target_player, trim(case
                                                                                                      when play_text ~* 'Catch made by ([A-Z]\.[A-Za-z]+)'
                                                                                                          then regexp_replace(play_text, '.*Catch made by ([A-Z]\.[A-Za-z]+).*', '\1')
                                                                                                      when play_text ~* 'intended for ([A-Z]\.[A-Za-z]+)'
                                                                                                          then regexp_replace(play_text, '.*intended for ([A-Z]\.[A-Za-z]+).*', '\1')
                                                                                                      when play_text ~* 'pass (complete|incomplete) to ([A-Z][A-Za-z]+(?: [A-Z][A-Za-z]+)+)'
                                                                                                          then substring(play_text from 'to ([A-Z][A-Za-z]+(?: [A-Z][A-Za-z]+)+)')
                                                                                                      when play_text ~* '^[A-Z]\.[A-Za-z]+ (rushed|scrambled)'
                                                                                                          then substring(play_text from '^([A-Z]\.[A-Za-z]+) (rushed|scrambled)')
                                                                                                          else receiver_player_name
                                                                                                      end)
        , trim(case
                   when text ~* 'Catch made by ([A-Z]\.[A-Za-z]+)'
                       then regexp_replace(text, '.*Catch made by ([A-Z]\.[A-Za-z]+).*', '\1')
                   when text ~* 'intended for ([A-Z]\.[A-Za-z]+)'
                       then regexp_replace(text, '.*intended for ([A-Z]\.[A-Za-z]+).*', '\1')
                   when text ~* 'pass (complete|incomplete) to ([A-Z][A-Za-z]+(?: [A-Z][A-Za-z]+)+)'
                       then substring(text from 'to ([A-Z][A-Za-z]+(?: [A-Z][A-Za-z]+)+)')
                   when text ~* '^[A-Z]\.[A-Za-z]+ (rushed|scrambled)'
                       then substring(text from '^([A-Z]\.[A-Za-z]+) (rushed|scrambled)')
                       else receiver_player_name
                   end))), 0)                                                   as targets
      , sum(coalesce(n.completion, 0))                                          as receptions
      , sum(coalesce(n.yards_gained * n.completion, 0))                         as receiving_yards
      , null                                                                    as air_yards
      , null                                                                    as yards_after_catch
      , sum(coalesce(n.touchdown::int * n.completion, 0))                       as receiving_touchdowns
      , coalesce(count(n.yds_rushed), 0)                                        as rush_attempts
      , sum(coalesce(n.yds_rushed, 0))                                          as rushing_yards
      , sum(coalesce(n.rush_td, 0))                                             as rushing_touchdowns
      , null                                                                    as twopt_conversions
      , sum(coalesce(n.fumble_vec, 0))                                          as fumbles
      , sum(coalesce(n.fumble_vec * case
                                        when n.pos_team = n.lead_pos_team
                                            then 0
                                            else 1
                                        end, 0))                                as fumbles_lost
      , 0                                                                       as passing_interception
      , sum(coalesce(n.int, 0))                                                 as receiver_interception
      , 0                                                                       as return_yards
      , 0                                                                       as return_touchdowns
      , sum(coalesce(n.wpa, 0))                                                 as wpa
      , sum(coalesce(n.epa, 0))                                                 as epa
    --, avg(coalesce(n.firstd_by_yards, 0) - coalesce(c_init.conversion_rate, 0) + coalesce(c_post.conversion_rate, 0)) as first_downs_added
    --, sum(greatest(n.yards_gained - n.distance, 0))                                                                   as plus_yards_added
    from college_football_play_by_play_data          as n
         left join ncaaf_season_games_regularization as reg on reg.pos_team = n.pos_team and reg.game_id = n.game_id
         inner join clean_cfb_player_names           as cpn
                    on cpn.pre_clean_player_name = replace(replace(replace(coalesce(
                                                                               --rb clause:
                                                                                   trim(case
                                                                                            when coalesce(rush_player, rusher_player_name, fumble_player, fumble_player_name, play_text, text)
                                                                                                    ~* '^[A-Z]\.[A-Za-z]+ (rushed|scrambled)'
                                                                                                then substring(
                                                                                                    coalesce(rush_player, rusher_player_name, fumble_player, fumble_player_name, play_text, text)
                                                                                                    from
                                                                                                    '^([A-Z]\.[A-Za-z]+) (rushed|scrambled)')
                                                                                                else coalesce(rush_player, rusher_player_name, fumble_player, fumble_player_name)
                                                                                            end),
                                                                               --wr clause:
                                                                                   trim(case
                                                                                            when replace(replace(regexp_replace(regexp_replace(
                                                                                                                                        coalesce(receiver_player_name, target_player, reception_player, passer_player_name, play_text, text),
                                                                                                                                        '.*Catch made by ([A-Z]\.[A-Za-z]+).*', '\1'),
                                                                                                                                '.*intended for ([A-Z]\.[A-Za-z]+).*', '\1'),
                                                                                                                 ' GOOD', ''), ' FAILED', '')
                                                                                                    ~* 'pass (complete|incomplete) to ([A-Z][A-Za-z]+(?: [A-Z][A-Za-z]+)+)'
                                                                                                then substring(replace(replace(regexp_replace(regexp_replace(
                                                                                                                                                      coalesce(receiver_player_name, target_player, reception_player, passer_player_name, play_text, text),
                                                                                                                                                      '.*Catch made by ([A-Z]\.[A-Za-z]+).*',
                                                                                                                                                      '\1'),
                                                                                                                                              '.*intended for ([A-Z]\.[A-Za-z]+).*', '\1'),
                                                                                                                               ' GOOD', ''), ' FAILED', '') from
                                                                                                               'to ([A-Z][A-Za-z]+(?: [A-Z][A-Za-z]+)+)')
                                                                                                else replace(replace(regexp_replace(regexp_replace(
                                                                                                                                            coalesce(receiver_player_name, target_player, reception_player, passer_player_name),
                                                                                                                                            '.*Catch made by ([A-Z]\.[A-Za-z]+).*', '\1'),
                                                                                                                                    '.*intended for ([A-Z]\.[A-Za-z]+).*', '\1'),
                                                                                                                     ' GOOD', ''), ' FAILED', '')
                                                                                            end)), ' KICK', ''),
                                                                   ' End Zone', ''), '  ', ' ')
                            and cpn.year = n.year and cpn.team = n.pos_team
         left join cfb_player_name_ids               as cpni on cpni.player_name = cpn.clean_player_name and cpni.team = n.pos_team and cpni.year = cpn.year
    /*left join conversion_rate_by_down_distance  as c_init on c_init.down = n.down and c_init.ydstogo = n.distance and case
                          when n.down = 4
                              then 'go'
                              else 'slow'
                          end = c_init.type
    left join conversion_rate_by_down_distance  as c_post on c_post.down = least(n.down + 1, 4) and c_post.ydstogo = n.distance - n.yards_gained and case
                                                         when n.down = 4
                                                             then 'go'
                                                             else 'slow'
                                                         end = c_post.type*/
    where
          penalty_no_play = false
      and yards_gained < 101
    group by
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
    union all
    --passer game logs
    select
        cpn.clean_player_name                                                   as player_name
      , cpni.player_name_id                                                     as player_name_id
      , null                                                                    as position_group
      , cpni.final_team
      , n.game_id
      , n.pos_team                                                              as team
      , n.def_pos_team                                                          as opponent
        --, n.offense_conference
        --, n.defense_conference
      , n.pos_team = n.home                                                     as is_home_game
      , n.year
      , n.week
      , make_date(n.year, 8, 28) + round(reg.week_dec * 135) * interval '1 day' as approximate_date
      , null                                                                    as season
      , cpni.freshman_year                                                      as freshman_year
      , cpni.final_year
      , cpni.manual_birthdate                                                   as manual_birthdate
      , reg.year_game                                                           as true_date
      , n.year - cpni.freshman_year                                             as experience_yrs
      , reg.year_game - cpni.freshman_year                                      as experience_dec
      , sum(coalesce(n.pass_attempt::float, 0))                                 as pass_attempts
      , sum(coalesce(n.completion, 0))                                          as completions
      , sum(coalesce(n.yards_gained * n.pass_attempt::float, 0))                as passing_yards
      , 0                                                                       as passing_air_yards
      , sum(coalesce(n.pass_td, 0))                                             as passing_touchdowns
      , sum(coalesce(n.sack_vec, 0))                                            as sacks_taken
      , 0                                                                       as targets
      , 0                                                                       as receptions
      , 0                                                                       as receiving_yards
      , null                                                                    as air_yards
      , null                                                                    as yards_after_catch
      , 0                                                                       as receiving_touchdowns
      , 0                                                                       as rush_attempts
      , sum(coalesce(n.yds_rushed, 0))                                          as rushing_yards
      , 0                                                                       as rushing_touchdowns
      , null                                                                    as twopt_conversions
      , sum(coalesce(n.fumble_vec, 0))                                          as fumbles
      , sum(coalesce(n.fumble_vec * case
                                        when n.pos_team = n.lead_pos_team
                                            then 0
                                            else 1
                                        end, 0))                                as fumbles_lost
      , sum(coalesce(n.int, 0))                                                 as passing_interception
      , 0                                                                       as receiver_interception
      , 0                                                                       as return_yards
      , 0                                                                       as return_touchdowns
      , sum(coalesce(n.wpa, 0))                                                 as wpa
      , sum(coalesce(n.epa, 0))                                                 as epa
    --, avg(coalesce(n.firstd_by_yards, 0) - coalesce(c_init.conversion_rate, 0) + coalesce(c_post.conversion_rate, 0)) as first_downs_added
    --, sum(greatest(n.yards_gained - n.distance, 0))                                                                   as plus_yards_added
    from college_football_play_by_play_data          as n
         left join ncaaf_season_games_regularization as reg on reg.pos_team = n.pos_team and reg.game_id = n.game_id
         inner join clean_cfb_player_names           as cpn
                    on cpn.pre_clean_player_name = replace(replace(replace(
                                                                       --qb clause:
                                                                           trim(regexp_replace(regexp_replace(case
                                                                                                                  when coalesce(passer_player_name, sack_taken_player, fumble_player, fumble_player_name, play_text, text)
                                                                                                                          ~* '^[A-Z]\.[A-Za-z]+ (steps back to pass|pass)'
                                                                                                                      then substring(
                                                                                                                          coalesce(passer_player_name, sack_taken_player, fumble_player, fumble_player_name, play_text, text)
                                                                                                                          from
                                                                                                                          '^([A-Z]\.[A-Za-z]+) (steps back to pass|pass)')
                                                                                                                      else coalesce(passer_player_name, sack_taken_player, fumble_player, fumble_player_name)
                                                                                                                  end, ' (deep|slant|sideline|middle|screen)$', ''),
                                                                                               '\s+pass\s+(incomplete|complete).*', '')), ' KICK', ''),
                                                                   ' End Zone', ''), '  ', ' ')
                            and cpn.year = n.year and cpn.team = n.pos_team
         left join cfb_player_name_ids               as cpni on cpni.player_name = cpn.clean_player_name and cpni.team = n.pos_team and cpni.year = cpn.year
    /*left join conversion_rate_by_down_distance  as c_init on c_init.down = n.down and c_init.ydstogo = n.distance and case
                          when n.down = 4
                              then 'go'
                              else 'slow'
                          end = c_init.type
    left join conversion_rate_by_down_distance  as c_post on c_post.down = least(n.down + 1, 4) and c_post.ydstogo = n.distance - n.yards_gained and case
                                                         when n.down = 4
                                                             then 'go'
                                                             else 'slow'
                                                         end = c_post.type*/
    where
          penalty_no_play = false
      and yards_gained < 101
    group by
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
    union all
    select
        cpn.clean_player_name                                                   as player_name
      , cpni.player_name_id                                                     as player_name_id
      , null                                                                    as position_group
      , cpni.final_team
      , n.game_id
      , n.def_pos_team                                                          as team
      , n.pos_team                                                              as opponent
        --, n.defense_conference
        --, n.offense_conference
      , n.def_pos_team = n.home                                                 as is_home_game
      , n.year
      , n.week
      , make_date(n.year, 8, 28) + round(reg.week_dec * 135) * interval '1 day' as approximate_date
      , null                                                                    as season
      , cpni.freshman_year                                                      as freshman_year
      , cpni.final_year
      , cpni.manual_birthdate                                                   as manual_birthdate
      , reg.year_game                                                           as true_date
      , n.year - cpni.freshman_year                                             as experience_yrs
      , reg.year_game - cpni.freshman_year                                      as experience_dec
      , 0                                                                       as pass_attempts --attempts overestimating                                    as pass_attempts
      , 0                                                                       as completions
      , 0                                                                       as passing_yards
      , 0                                                                       as passing_air_yards
      , 0                                                                       as passing_touchdowns
      , 0                                                                       as sacks_taken
      , 0                                                                       as targets
      , 0                                                                       as receptions
      , 0                                                                       as receiving_yards
      , null                                                                    as receiving_air_yards
      , null                                                                    as receiving_yards_after_catch
      , 0                                                                       as receiving_touchdowns
      , 0                                                                       as rush_attempts
      , 0                                                                       as rushing_yards
      , 0                                                                       as rushing_touchdowns
      , null                                                                    as twopt_conversions
      , 0                                                                       as fumbles
      , 0                                                                       as fumbles_lost
      , 0                                                                       as passing_interception
      , 0                                                                       as receiver_interception
      , sum(coalesce(n.yds_kickoff_return, n.yds_punt_return, 0))               as return_yards
      , sum(coalesce(n.touchdown::float, 0))                                    as return_touchdowns
      , sum(coalesce(n.wpa, 0))                                                 as wpa
      , sum(coalesce(n.epa, 0))                                                 as epa
    --false --, 0                                                         as first_downs_added
    --, 0                                                         as plus_yards_added
    from college_football_play_by_play_data          as n
         left join ncaaf_season_games_regularization as reg on reg.pos_team = n.def_pos_team and reg.game_id = n.game_id
         inner join clean_cfb_player_names           as cpn
                    on cpn.pre_clean_player_name = coalesce(n.punt_returner_player_name, n.kickoff_returner_player_name)
                            and cpn.year = n.year and cpn.team = n.def_pos_team
         left join cfb_player_name_ids               as cpni on cpni.player_name = cpn.clean_player_name and cpni.team = n.def_pos_team and cpni.year = cpn.year
    /*left join conversion_rate_by_down_distance  as c_init on c_init.down = n.down and c_init.ydstogo = n.distance and case
                          when n.down = 4
                              then 'go'
                              else 'slow'
                          end = c_init.type
    left join conversion_rate_by_down_distance  as c_post on c_post.down = least(n.down + 1, 4) and c_post.ydstogo = n.distance - n.yards_gained and case
                                                         when n.down = 4
                                                             then 'go'
                                                             else 'slow'
                                                         end = c_post.type*/
    where
          penalty_no_play = false
      and yards_gained < 101
    group by
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
    )
select
    glu.player_name
  , np.gsis_id                                                                                                                     as gsis_id
  , glu.final_team
  , glu.player_name_id
  , coalesce(np.display_name, glu.player_name) || ': ' || coalesce(right(np.gsis_id, 6), final_team)                               as player_display_name
  , coalesce(np.position_group, pp.position)                                                                                       as position_group
  , game_id
  , glu.team
  , opponent
    -- , cc.offense_conference
    -- , defense_conference
  , elo.elo                                                                                                                        as team_elo
  , opp_elo.elo                                                                                                                    as opponent_elo
  , glu.is_home_game
  , glu.year
  , glu.week
  , approximate_date
  , season
  , true_date
  , freshman_year
  , final_year
  , experience_yrs
  , experience_dec
  , (approximate_date::date - coalesce(np.birth_date::date, glu.manual_birthdate)) / 365.25                                        as approximate_age
  , coalesce(true_date::float + 240::float / 365::float
                     - (left(coalesce(np.birth_date::date, glu.manual_birthdate)::text, 4)::float + (substr(coalesce(np.birth_date::date, glu.manual_birthdate)::text, 6, 2)::float - 1) / 12
            + (substr(coalesce(np.birth_date::date, glu.manual_birthdate)::text, 9, 2)::float) / 365)::float, experience_dec + 19) as true_age
  , row_number() over (partition by glu.player_name, glu.player_name_id order by true_date)                                        as player_game_number
  , row_number() over (partition by glu.player_name, glu.player_name_id order by true_date desc) - 1                               as player_games_remaining
  , row_number() over (partition by glu.player_name, glu.player_name_id, glu.year order by true_date)                              as player_season_game_number
  , row_number() over (partition by glu.player_name, glu.player_name_id, glu.year order by true_date desc) - 1                     as player_season_games_remaining
  , max(glu.year) over (partition by glu.player_name, glu.player_name_id) = max(glu.year) over (partition by true)                 as is_active
  , sum(pass_attempts) + sum(case
                                 when coalesce(np.position_group, pp.position) = 'QB'
                                     then rush_attempts
                                     else 0
                                 end)
            + sum(sacks_taken)                                                                                                     as player_dropbacks
  , sum(sum(pass_attempts) + sum(case
                                     when coalesce(np.position_group, pp.position) = 'QB'
                                         then rush_attempts
                                         else 0
                                     end)
        + sum(sacks_taken))
    over (partition by glu.team, true_date)                                                                                        as team_dropbacks
  , sum(sum(pass_attempts) + sum(rush_attempts)
        + sum(sacks_taken))
    over (partition by glu.team, true_date)                                                                                        as team_snaps
  , case
        when coalesce(np.position_group, pp.position) = 'QB'
            then least(1, sum(pass_attempts) + sum(rush_attempts) + sum(sacks_taken)
                / (1 + sum(sum(pass_attempts) + sum(case
                                                        when coalesce(np.position_group, pp.position) = 'QB'
                                                            then rush_attempts
                                                            else 0
                                                        end) + sum(sacks_taken)) over (partition by glu.team, true_date)))
        when coalesce(np.position_group, pp.position) = 'RB'
            then least(sum(rush_attempts) / (1 + sum(sum(rush_attempts)) over (partition by glu.team, true_date) * 0.68 + 0.15), 1)
        when coalesce(np.position_group, pp.position) = 'WR'
            then least(1 - 1 / (1 + exp(10.5 * sum(receptions) / (1 + sum(sum(pass_attempts)) over (partition by glu.team, true_date))) * 0.84), 1)
        when coalesce(np.position_group, pp.position) = 'TE'
            then least(1 - 1 / (1 + exp(10.5 * sum(receptions) / (1 + sum(sum(pass_attempts)) over (partition by glu.team, true_date))) * 0.84), 1)
        end                                                                                                                        as snap_percent
  , sum(pass_attempts)                                                                                                             as pass_attempts
  , sum(completions)                                                                                                               as completions
  , sum(completions) / nullif(sum(pass_attempts), 0)                                                                               as completion_percentage
  , sum(passing_yards)                                                                                                             as passing_yards
  , sum(passing_yards) / nullif(sum(completions), 0)                                                                               as passing_yards_per_completion
  , sum(passing_yards) / nullif(sum(pass_attempts), 0)                                                                             as passing_yards_per_attempt
  , sum(passing_air_yards)                                                                                                         as passing_air_yards
  , sum(passing_air_yards) / nullif(sum(pass_attempts), 0)                                                                         as passing_air_yards_per_attempt
  , sum(passing_touchdowns)                                                                                                        as passing_touchdowns
  , sum(passing_touchdowns) / nullif(sum(pass_attempts), 0)                                                                        as passing_touchdowns_per_attempt
  , sum(sacks_taken)                                                                                                               as sacks_taken
  , sum(sacks_taken) / nullif(sum(pass_attempts) + sum(case
                                                           when pp.position = 'QB'
                                                               then rush_attempts
                                                               else 0
                                                           end) + sum(sacks_taken),
                              0)                                                                                                   as sacks_per_dropback
  , sum(targets)                                                                                                                   as targets
  , sum(receptions)                                                                                                                as receptions
  , sum(receiving_yards)                                                                                                           as receiving_yards
  , null                                                                                                                           as air_yards
  , null                                                                                                                           as yards_after_catch
  , sum(receiving_touchdowns)                                                                                                      as receiving_touchdowns
  , sum(rush_attempts)                                                                                                             as rush_attempts
  , sum(rushing_yards)                                                                                                             as rushing_yards
  , sum(rushing_touchdowns)                                                                                                        as rushing_touchdowns
  , null                                                                                                                           as twopt_conversions
  , sum(fumbles)                                                                                                                   as fumbles
  , sum(fumbles_lost)                                                                                                              as fumbles_lost
  , sum(passing_interception)                                                                                                      as passing_interception
  , sum(receiver_interception)                                                                                                     as receiver_interception
  , sum(return_yards)                                                                                                              as return_yards
  , sum(return_touchdowns)                                                                                                         as return_touchdowns
  , sum(epa)                                                                                                                       as epa
  , sum(wpa)                                                                                                                       as wpa
    --, sum(first_downs_added)                                                             as first_downs_added
    --, sum(plus_yards_added)                                                              as plus_yards_added
  , sum(passing_yards) * 0.04 + sum(receiving_yards) * 0.1 + sum(rushing_yards) * 0.1
            + sum(passing_touchdowns) * 4 + sum(rushing_touchdowns) * 6 + sum(receiving_touchdowns) * 6
            - sum(passing_interception) * 2
            - sum(fumbles_lost) * 2                                                                                                as fantasy_points_std
  , sum(passing_yards) * 0.04 + sum(receiving_yards) * 0.1 + sum(rushing_yards) * 0.1 + sum(receptions) * 0.5
            + sum(passing_touchdowns) * 4 + sum(rushing_touchdowns) * 6 + sum(receiving_touchdowns) * 6
            - sum(passing_interception) * 2
            - sum(fumbles_lost) * 2                                                                                                as fantasy_points_half_ppr
  , sum(passing_yards) * 0.04 + sum(receiving_yards) * 0.1 + sum(rushing_yards) * 0.1 + sum(receptions)
            + sum(passing_touchdowns) * 4 + sum(rushing_touchdowns) * 6 + sum(receiving_touchdowns) * 6
            - sum(passing_interception) * 2
            - sum(fumbles_lost) * 2                                                                                                as fantasy_points_ppr
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
            + sum(return_touchdowns) * 6                                                                                           as fantasy_points_t
from game_logs_union                      as glu
     inner join cfb_conferences           as cc on cc.pos_team = glu.team and cc.year = glu.year
     left join cfb_clean_player_positions as pp on pp.year = glu.year and pp.player_name = glu.player_name
     left join cfb_nfl_player_id_map      as map on map.cfb_name = glu.player_name and map.player_name_id = glu.player_name_id
     left join nfl_players                as np on np.gsis_id = map.gsis_id
     left join cfb_elo_data               as elo on elo.team = glu.team and elo.year = glu.year and elo.week = case
                                                                                                                   when glu.week = 1
                                                                                                                       then 13
                                                                                                                       else glu.week
                                                                                                                   end
     left join cfb_elo_data               as opp_elo on opp_elo.team = glu.opponent and opp_elo.year = glu.year and opp_elo.week = case
                                                                                                                                       when glu.week = 1
                                                                                                                                           then 13
                                                                                                                                           else glu.week
                                                                                                                                       end
group by
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23