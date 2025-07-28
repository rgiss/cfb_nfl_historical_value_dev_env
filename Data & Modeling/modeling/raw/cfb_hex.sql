drop table cfb_hex;
create table cfb_hex
(
    team_name     varchar(255),
    primary_color varchar(255)
);
copy cfb_hex(team_name, primary_color)
    from '/Users/riley.gisseman/Downloads/cfb_hex.csv'
    delimiter ','
    csv header;