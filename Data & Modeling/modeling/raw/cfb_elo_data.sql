drop table cfb_elo_data;
create table cfb_elo_data
(
    year       int,
    team       varchar,
    conference varchar,
    elo        int,
    week       int
);
copy cfb_elo_data(year, team, conference, elo, week)
    from '/Users/riley.gisseman/Downloads/elo_ratings_1999_2024.csv'
    delimiter ','
    csv header;