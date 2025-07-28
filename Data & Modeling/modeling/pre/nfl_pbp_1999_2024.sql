drop table nfl_pbp_1999_2024;
create table nfl_pbp_1999_2024 as
select *
from nfl_pbp_1999_2023
union all
select *
from nfl_pbp_2024