drop table nfl_snap_counts_2012_2024;
create table nfl_snap_counts_2012_2024
(
    index         int,
    game_id       varchar(255),
    pfr_game_id   varchar(255),
    year          int,
    season_type   varchar(255),
    week          float,
    player_name   varchar(255),
    pfr_player_id varchar(255),
    position      varchar(255),
    team          varchar(255),
    opponent      varchar(255),
    offense_snaps int,
    offense_pct   float,
    defense_snaps int,
    defense_pct   float,
    st_snaps      int,
    st_pct        float
);
copy nfl_snap_counts_2012_2024(index, game_id, pfr_game_id, year, season_type, week, player_name, pfr_player_id, position, team, opponent, offense_snaps, offense_pct, defense_snaps,
                               defense_pct, st_snaps, st_pct)
    from '/Users/riley.gisseman/Downloads/nfl_snap_counts_2012_2024.csv'
    delimiter ','
    csv header;