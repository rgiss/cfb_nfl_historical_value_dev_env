drop table cfb_recruiting_data;
create table cfb_recruiting_data
(
    index                   int,
    id                      int,
    athlete_id              double precision,
    recruit_type            varchar(255),
    year                    int,
    ranking                 double precision,
    name                    varchar(255),
    school                  varchar(255),
    committed_to            varchar(255),
    position                varchar(255),
    height                  double precision,
    weight                  double precision,
    stars                   int,
    rating                  double precision,
    city                    varchar(255),
    state_province          varchar(255),
    country                 varchar(255),
    hometown_info_latitude  double precision,
    hometown_info_longitude double precision,
    hometown_info_fips_code double precision
);
copy cfb_recruiting_data(index, id, athlete_id, recruit_type, year, ranking, name, school, committed_to, position, height, weight, stars, rating, city, state_province, country,
                         hometown_info_latitude, hometown_info_longitude, hometown_info_fips_code)
    from '/Users/riley.gisseman/Downloads/cfb_recruiting_data.csv'
    delimiter ','
    csv header;