drop table clean_cfb_player_names;
create table clean_cfb_player_names as
with player_names_cleaning as (
    select distinct

        replace(replace(replace(coalesce(
                                    --rb clause:
                                        trim(case
                                                 when coalesce(rush_player, rusher_player_name, fumble_player, fumble_player_name, play_text, text) ~* '^[A-Z]\.[A-Za-z]+ (rushed|scrambled)'
                                                     then substring(coalesce(rush_player, rusher_player_name, fumble_player, fumble_player_name, play_text, text) from
                                                                    '^([A-Z]\.[A-Za-z]+) (rushed|scrambled)')
                                                     else coalesce(rush_player, rusher_player_name, fumble_player, fumble_player_name)
                                                 end),
                                    --wr clause:
                                        trim(case
                                                 when replace(replace(regexp_replace(regexp_replace(
                                                                                             coalesce(receiver_player_name, target_player, reception_player, passer_player_name, play_text, text),
                                                                                             '.*Catch made by ([A-Z]\.[A-Za-z]+).*', '\1'), '.*intended for ([A-Z]\.[A-Za-z]+).*', '\1'),
                                                                      ' GOOD', ''), ' FAILED', '') ~* 'pass (complete|incomplete) to ([A-Z][A-Za-z]+(?: [A-Z][A-Za-z]+)+)'
                                                     then substring(replace(replace(regexp_replace(regexp_replace(
                                                                                                           coalesce(receiver_player_name, target_player, reception_player, passer_player_name, play_text, text),
                                                                                                           '.*Catch made by ([A-Z]\.[A-Za-z]+).*', '\1'),
                                                                                                   '.*intended for ([A-Z]\.[A-Za-z]+).*', '\1'), ' GOOD', ''), ' FAILED', '') from
                                                                    'to ([A-Z][A-Za-z]+(?: [A-Z][A-Za-z]+)+)')
                                                     else replace(replace(regexp_replace(regexp_replace(
                                                                                                 coalesce(receiver_player_name, target_player, reception_player, passer_player_name),
                                                                                                 '.*Catch made by ([A-Z]\.[A-Za-z]+).*', '\1'), '.*intended for ([A-Z]\.[A-Za-z]+).*', '\1'),
                                                                          ' GOOD', ''), ' FAILED', '')
                                                 end),
                                    --qb clause:
                                        trim(regexp_replace(regexp_replace(case
                                                                               when coalesce(passer_player_name, sack_taken_player, fumble_player, fumble_player_name, play_text, text)
                                                                                       ~* '^[A-Z]\.[A-Za-z]+ (steps back to pass|pass)'
                                                                                   then substring(
                                                                                       coalesce(passer_player_name, sack_taken_player, fumble_player, fumble_player_name, play_text, text)
                                                                                       from
                                                                                       '^([A-Z]\.[A-Za-z]+) (steps back to pass|pass)')
                                                                                   else coalesce(passer_player_name, sack_taken_player, fumble_player, fumble_player_name)
                                                                               end, ' (deep|slant|sideline|middle|screen)$', ''), '\s+pass\s+(incomplete|complete).*', ''))), ' KICK', ''),
                        ' End Zone', ''), '  ', ' ')                                                     as player_name

      , year
      , pos_team                                                                                         as team
      , count(*) over (partition by pos_team, year, replace(replace(replace(coalesce(
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
                                                                                             end),
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
                                                                                                        '\s+pass\s+(incomplete|complete).*', ''))), ' KICK', ''),
                                                                    ' End Zone', ''), '  ', ' '))::float as total_clean_count
    from college_football_play_by_play_data
    )
   , pre_clean as (
    select distinct
        player_name as pre_clean_player_name
      , year
      , team
      , case
            when player_name = 'JuJu Smith'
                then 'JuJu Smith-Schuster'
            when player_name = 'Patrick Mahomes II'
                then 'Patrick Mahomes'
            when player_name = 'Cameron Skattebo'
                then 'Cam Skattebo'
            when player_name = 'Ollie Gordon II'
                then 'Ollie Gordon'
            when player_name = 'Isaiah Jones'
                then 'Zay Jones'
            when player_name = 'Ricky White III'
                then 'Ricky White'
            when player_name = 'Nathaniel Dell'
                then 'Tank Dell'
            when player_name = 'Cam Ward'
                then 'Cameron Ward'
            when player_name = 'Raymell Rice'
                then 'Ray Rice'
            when player_name = 'Dont''e Thornton Jr.'
                then 'Dont''e Thornton'
            when player_name = 'Cameron Newton'
                then 'Cam Newton'
                else player_name
            end     as clean_player_name
      , total_clean_count
    from player_names_cleaning
    )
   , name_variations as (
    select
        pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count

    -- original form
    from pre_clean

    union all

    -- no spaces form
    select
        replace(pre_clean_player_name, ' ', '') as pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count
    from pre_clean

    union all

    -- last, first form
    select
        split_part(pre_clean_player_name, ' ', 2) || ', ' || split_part(pre_clean_player_name, ' ', 1) as pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count
    from pre_clean
    where
        pre_clean_player_name like '% %'

    union all

    -- last,first form
    select
        split_part(pre_clean_player_name, ' ', 2) || ',' || split_part(pre_clean_player_name, ' ', 1) as pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count
    from pre_clean
    where
        pre_clean_player_name like '% %'

    union all

    -- initial.lastname form (e.g., M.Hall)
    select
        left(split_part(pre_clean_player_name, ' ', 1), 1) || '.' || split_part(pre_clean_player_name, ' ', 2) as pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count
    from pre_clean
    where
        pre_clean_player_name like '% %'

    union all

    -- Last Name form (e.g., Hall)
    select
        split_part(pre_clean_player_name, ' ', 2) as pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count
    from pre_clean
    where
        pre_clean_player_name like '% %'
    union all

    -- Last Name form (e.g., Hall)
    select
        split_part(pre_clean_player_name, ' ', 2) || split_part(pre_clean_player_name, ' ', 3) as pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count
    from pre_clean
    where
        pre_clean_player_name like '% %'

    union all

    -- initial. lastname form (e.g., M. Hall)
    select
        left(split_part(pre_clean_player_name, ' ', 1), 1) || '. ' || split_part(pre_clean_player_name, ' ', 2) as pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count
    from pre_clean
    where
        pre_clean_player_name like '% %'

    union all

    -- initial. lastname form (e.g., M. Hall)
    select
        pre_clean_player_name || '.' as pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count
    from pre_clean
    where
        pre_clean_player_name like '% %'

    union all

    -- initial. lastname form (e.g., M. Hall)
    select
        left(split_part(pre_clean_player_name, ' ', 1), 1) || '. ' || split_part(pre_clean_player_name, ' ', 2) || '.' as pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count
    from pre_clean
    where
        pre_clean_player_name like '% %'

    union all

    -- initial. lastname form (e.g., M. Hall)
    select
        left(split_part(pre_clean_player_name, ' ', 1), 1) || '.' || split_part(pre_clean_player_name, ' ', 2) || '.' as pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count
    from pre_clean
    where
        pre_clean_player_name like '% %'
    union all

    -- initial. lastname form (e.g., M. Hall)
    select
        split_part(pre_clean_player_name, ' ', 2) || ', ' || left(split_part(pre_clean_player_name, ' ', 1), 1) || '.' as pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count
    from pre_clean
    where
        pre_clean_player_name like '% %'

    union all

    -- initial. lastname form (e.g., M. Hall)
    select
        split_part(pre_clean_player_name, ' ', 2) || ',' || left(split_part(pre_clean_player_name, ' ', 1), 1) || '.' as pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count
    from pre_clean
    where
        pre_clean_player_name like '% %'
    union all

    -- initial. lastname form (e.g., M. Hall)
    select
        pre_clean_player_name || '.' as pre_clean_player_name
      , clean_player_name
      , year
      , team
      , total_clean_count
    from pre_clean
    where
        pre_clean_player_name like '% %'
    )
   , cfb_player_names as (
    select distinct
        pre_clean_player_name
      , year
      , team
      , clean_player_name
      , total_clean_count
      , max(total_clean_count) over (partition by pre_clean_player_name, year, team) as max_total_clean_count
    from name_variations
    )
select *
from cfb_player_names
where
      total_clean_count = max_total_clean_count
  and clean_player_name ~ '^[A-Za-z .''-]+$'
  and max_total_clean_count > 1
  and clean_player_name not ilike '%TEAM%'
  and length(clean_player_name) between 6 and 25