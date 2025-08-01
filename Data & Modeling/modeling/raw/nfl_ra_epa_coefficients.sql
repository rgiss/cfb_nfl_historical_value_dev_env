drop table nfl_ra_epa_coefficients;
create table nfl_ra_epa_coefficients
(
    index                 int,
    position_group        varchar(255),
    pass_share            double precision,
    completion_percentage double precision,
    yards_per_completion  double precision,
    tds_per_completion    double precision,
    rush_share            double precision,
    yards_per_rush        double precision,
    tds_per_rush          double precision,
    epa_per_snap          double precision,
    reception_share       double precision,
    yards_per_reception   double precision,
    tds_per_reception     double precision,
    intercept             double precision
);
copy nfl_ra_epa_coefficients(index, position_group, snap_share, pass_share, completion_percentage, yards_per_completion, tds_per_completion, rush_share, yards_per_rush, tds_per_rush,
                             epa_per_snap, target_share, catch_percentage, yards_per_reception, tds_per_reception, intercept)
    from '/Users/riley.gisseman/Downloads/nfl_ra_epa_coefficients.csv'
    delimiter ','
    csv header;