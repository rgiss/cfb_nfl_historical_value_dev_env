drop table nfl_hex;
create table nfl_hex
(
    team_code       varchar(255),
    team_name       varchar(255),
    primary_color   varchar(255),
    secondary_color varchar(255),
    tertiary_color  varchar(255),
    fourth_color    varchar(255),
    fifth_color     varchar(255)
);
copy nfl_hex(team_code, team_name, primary_color, secondary_color, tertiary_color, fourth_color, fifth_color)
    from '/Users/riley.gisseman/Downloads/nfl_hex.csv'
    delimiter ','
    csv header;