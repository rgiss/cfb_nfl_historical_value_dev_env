{{
  config(
    materialized='view',
    schema='staging'
  )
}}

-- Staging model that combines historical and current NFL play-by-play data
-- This replaces the original union of separate historical/current tables

select *
from {{ source('raw', 'nfl_pbp_1999_2024') }}
where season >= 1999