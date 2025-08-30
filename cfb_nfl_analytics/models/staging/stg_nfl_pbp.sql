{{
  config(
    materialized='table',
    schema='staging'
  )
}}

-- Staging model for NFL play-by-play data
-- Simple pass-through of all columns from the source

select *
from {{ source('raw', 'nfl_pbp_1999_2024') }}
where season >= 1999
