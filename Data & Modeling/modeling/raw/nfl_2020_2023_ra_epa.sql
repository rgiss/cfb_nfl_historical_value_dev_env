drop table nfl_2020_2023_ra_epa;
create table nfl_2020_2023_ra_epa
(
    index               int,
    gsis_id             varchar(255),
    ra_epa_per_play     double precision,
    play_count          int,
    ra_epa_total_impact double precision,
    display_name        varchar(255),
    position_group      varchar(255)
);
copy nfl_2020_2023_ra_epa(index, gsis_id, ra_epa_per_play, play_count, ra_epa_total_impact, display_name, position_group)
    from '/Users/riley.gisseman/Downloads/nfl_RA-EPA.csv'
    delimiter ','
    csv header;