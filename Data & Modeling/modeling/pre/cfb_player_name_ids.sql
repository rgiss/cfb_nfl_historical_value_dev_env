drop table cfb_player_name_ids;
create table cfb_player_name_ids as
with player_years as (
    select distinct
        player_name
      , year
      , team
      , position_group
    from cfb_game_logs
    )
   , player_histories as (
    select distinct
        a.player_name
      , a.year
      , a.team
      , a.position_group
      , count(b.year) over (partition by a.player_name, a.team, a.year, a.position_group)                 as joins
      , min(coalesce(b.year, a.year)) over (partition by a.player_name, a.team, a.year, a.position_group) as min_year
    from player_years           as a
         left join nfl_players  as np on np.display_name = a.player_name and a.year + 1 = np.draft_year
            and case
                    when split_part(np.college_name, ';', 1) = 'Louisiana State'
                        then 'LSU'
                    when split_part(np.college_name, ';', 1) = 'Southern Methodist'
                        then 'SMU'
                    when split_part(np.college_name, ';', 1) = 'N.C. State'
                        then 'NC State'
                    when split_part(np.college_name, ';', 1) = 'Brigham Young'
                        then 'BYU'
                    when split_part(np.college_name, ';', 1) = 'Southern California'
                        then 'USC'
                    when split_part(np.college_name, ';', 1) = 'Mississippi'
                        then 'Ole Miss'
                    when split_part(np.college_name, ';', 1) = 'Texas A&amp;M'
                        then 'Texas A&M'
                        else split_part(np.college_name, ';', 1)
                    end = a.team
         left join player_years as b on a.player_name = b.player_name and b.year between a.year - 2 and a.year - 1 and (a.team = b.team or a.position_group = b.position_group)-- and np.display_name is null
    )
   , player_name_ids as (
    select
                count(case
                          when joins = 0
                              then 1
                          end) over (partition by player_name order by min_year) as player_name_id
      ,         *
    from player_histories
    )
   , player_id_careers as (
    select *
         , case
               when player_name = 'Jeremiah Smith' and player_name_id = 1
                   then '2005-11-29'::date
               when player_name = 'Ryan Williams' and player_name_id = 5
                   then '2007-02-09'::date
               when player_name = 'Cam Coleman' and player_name_id = 2
                   then '2006-08-14'::date
               when player_name = 'T.J. Moore' and player_name_id = 1
                   then '2006-04-14'::date
               when player_name = 'Ryan Wingo' and player_name_id = 1
                   then '2006-02-15'::date
               when player_name = 'Gatlin Bair' and player_name_id = 1
                   then '2006-03-14'::date
               when player_name = 'Perry Thompson' and player_name_id = 1
                   then '2006-07-14'::date
               when player_name = 'Mike Matthews' and player_name_id = 1
                   then '2005-10-25'::date
               when player_name = 'Bryant Wesco' and player_name_id = 1
                   then '2005-09-22'::date
               when player_name = 'Courtney Crutchfield' and player_name_id = 1
                   then '2005-09-28'::date
               when player_name = 'Jeremiyah Love' and player_name_id = 1
                   then '2005-05-31'::date
               when player_name = 'LaNorris Sellers' and player_name_id = 1
                   then '2005-06-23'::date
               when player_name = 'DJ Lagway' and player_name_id = 1
                   then '2005-08-13'::date
               when player_name = 'Garrett Nussmeier' and player_name_id = 1
                   then '2002-02-07'::date
               when player_name = 'Nicholas Singleton' and player_name_id = 1
                   then '2004-01-06'::date
               when player_name = 'Cade Klubnik' and player_name_id = 1
                   then '2003-10-03'::date
               when player_name = 'Carnell Tate' and player_name_id = 1
                   then '2005-01-19'::date
               when player_name = 'Drew Allar' and player_name_id = 1
                   then '2004-03-08'::date
               when player_name = 'Jordyn Tyson' and player_name_id = 1
                   then '2004-08-12'::date
               when player_name = 'Sam Leavitt' and player_name_id = 1
                   then '2004-12-20'::date
               when player_name = 'Justice Haynes' and player_name_id = 1
                   then '2004-08-23'::date
               when player_name = 'Makai Lemon' and player_name_id = 1
                   then '2004-06-02'::date
               when player_name = 'Dylan Raiola' and player_name_id = 1
                   then '2005-05-09'::date
               when player_name = 'Nico Iamaleava' and player_name_id = 1
                   then '2004-09-02'::date
               when player_name = 'Arch Manning' and player_name_id = 1
                   then '2004-04-27'::date
               when player_name = 'Julian Sayin' and player_name_id = 1
                   then '2005-07-23'::date
               when player_name = 'Jaydn Ott' and player_name_id = 1
                   then '2002-12-16'::date
               when player_name = 'Zachariah Branch' and player_name_id = 1
                   then '2004-03-29'::date
               when player_name = 'Cam Skattebo' and player_name_id = 1
                   then '2002-02-05'::date
               when player_name = 'Travis Hunter' and player_name_id = 1
                   then '2003-03-15'::date
               when player_name = 'RJ Harvey' and player_name_id = 1
                   then '2001-02-04'::date
               when player_name = 'TreVeyon Henderson' and player_name_id = 1
                   then '2002-10-22'::date
               when player_name = 'Quinshon Judkins' and player_name_id = 1
                   then '2003-10-29'::date
               when player_name = 'Luther Burden III' and player_name_id = 1
                   then '2003-12-12'::date
               end                                                   as manual_birthdate
         , min(year) over (partition by player_name, player_name_id) as freshman_year
         , max(year) over (partition by player_name, player_name_id) as final_year
    from player_name_ids
    )
select
    a.*
  , b.team as final_team
from player_id_careers           as a
     left join player_id_careers as b on a.player_name = b.player_name and a.player_name_id = b.player_name_id and a.final_year = b.year