{{
  config(
    materialized='table',
    schema='base'
  )
}}

-- Beta priors for Bayesian updating of player performance metrics
-- These priors vary by position group and era (pre/post 2012)

select * from {{ source('raw', 'nfl_beta_priors') }}
