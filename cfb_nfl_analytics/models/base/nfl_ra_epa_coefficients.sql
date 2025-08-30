{{
  config(
    materialized='table',
    schema='base'
  )
}}

-- Regression coefficients for converting player metrics to EPA/replacement
-- Used in the historical value estimation model

select * from {{ source('raw', 'nfl_ra_epa_coefficients') }}
