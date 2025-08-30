{{
  config(
    materialized='table',
    schema='marts'
  )
}}

-- Historical value estimates for NFL players
-- Uses Bayesian updating with beta priors to estimate future performance

with base_stats as (
    select
        n.*,
        
        -- Estimated snap share using exponential decay
        (sum(n.snap_percent * n.team_snaps * pow(0.15, -n.experience_dec)) 
         over (partition by n.gsis_id order by n.game_date)
         + b.alpha_snaps * pow(0.15, -n.experience_dec))
        / (sum(case when n.snap_percent is not null then n.team_snaps end * pow(0.15, -n.experience_dec))
           over (partition by n.gsis_id order by n.game_date)
           + (b.alpha_snaps + b.beta_non_snaps) * pow(0.15, -n.experience_dec)) as est_snap_share,
        
        -- PASSING STATS:
        -- Estimated passes per snap
        (sum(n.pass_attempts * pow(0.25, -n.experience_dec)) 
         over (partition by n.gsis_id order by n.game_date)
         + b.alpha_passes * pow(0.25, -n.experience_dec))
        / (sum(coalesce(n.snap_count, n.team_snaps) * pow(0.25, -n.experience_dec))
           over (partition by n.gsis_id order by n.game_date)
           + (b.alpha_passes + b.beta_passes_snaps) * pow(0.25, -n.experience_dec)) as est_passes_per_snap,
        
        -- Estimated completion percentage
        (sum(n.completions * pow(0.5, -n.experience_dec)) 
         over (partition by n.gsis_id order by n.game_date)
         + b.alpha_comps * pow(0.5, -n.experience_dec))
        / (sum(n.pass_attempts * pow(0.5, -n.experience_dec)) 
           over (partition by n.gsis_id order by n.game_date)
           + (b.alpha_comps + b.beta_comps_passes) * pow(0.5, -n.experience_dec)) as est_completion_pct,
        
        -- Estimated TDs per completion
        (sum(n.passing_touchdowns * pow(0.5, -n.experience_dec)) 
         over (partition by n.gsis_id order by n.game_date)
         + b.alpha_pass_tds * pow(0.5, -n.experience_dec))
        / (sum(n.completions * pow(0.5, -n.experience_dec)) 
           over (partition by n.gsis_id order by n.game_date)
           + (b.alpha_pass_tds + b.beta_pass_tds_comps) * pow(0.5, -n.experience_dec)) as est_tds_per_completion,
        
        -- Estimated yards per completion
        (sum(n.passing_yards * pow(0.25, -n.experience_dec)) 
         over (partition by n.gsis_id order by n.game_date)
         + b.alpha_pass_yds * pow(0.25, -n.experience_dec))
        / (sum(n.completions * pow(0.25, -n.experience_dec)) 
           over (partition by n.gsis_id order by n.game_date)
           + b.beta_pass_yds_comps * pow(0.25, -n.experience_dec)) as est_yards_per_completion,
        
        -- RECEIVING STATS:
        -- Estimated target share
        (sum(n.targets * pow(0.25, -n.experience_dec)) 
         over (partition by n.gsis_id order by n.game_date)
         + b.alpha_tgts * pow(0.25, -n.experience_dec))
        / (sum(coalesce(n.snap_count, n.team_snaps) * pow(0.25, -n.experience_dec))
           over (partition by n.gsis_id order by n.game_date)
           + (b.alpha_tgts + b.beta_tgts_snaps) * pow(0.25, -n.experience_dec)) as est_tgt_share,
        
        -- Estimated catch percentage
        (sum(n.receptions * pow(0.25, -n.experience_dec)) 
         over (partition by n.gsis_id order by n.game_date)
         + b.alpha_recs * pow(0.25, -n.experience_dec))
        / (sum(n.targets * pow(0.25, -n.experience_dec)) 
           over (partition by n.gsis_id order by n.game_date)
           + (b.alpha_recs + b.beta_recs_tgts) * pow(0.25, -n.experience_dec)) as est_catch_pct,
        
        -- Estimated TDs per reception
        (sum(n.receiving_touchdowns * pow(0.7, -n.experience_dec)) 
         over (partition by n.gsis_id order by n.game_date)
         + b.alpha_rec_tds * pow(0.7, -n.experience_dec))
        / (sum(n.receptions * pow(0.7, -n.experience_dec)) 
           over (partition by n.gsis_id order by n.game_date)
           + (b.alpha_rec_tds + b.beta_rec_tds_recs) * pow(0.7, -n.experience_dec)) as est_touchdowns_per_reception,
        
        -- Estimated yards per reception
        (sum(n.receiving_yards * pow(0.5, -n.experience_dec)) 
         over (partition by n.gsis_id order by n.game_date)
         + b.alpha_rec_yds * pow(0.5, -n.experience_dec))
        / (sum(n.receptions * pow(0.5, -n.experience_dec)) 
           over (partition by n.gsis_id order by n.game_date)
           + b.beta_rec_yds_recs * pow(0.5, -n.experience_dec)) as est_yds_per_rec,
        
        -- RUSHING STATS:
        -- Estimated rushes per snap
        (sum(n.rush_attempts * pow(0.25, -n.experience_dec)) 
         over (partition by n.gsis_id order by n.game_date)
         + b.alpha_rushes * pow(0.25, -n.experience_dec))
        / (sum(coalesce(n.snap_count, n.team_snaps) * pow(0.25, -n.experience_dec))
           over (partition by n.gsis_id order by n.game_date)
           + (b.alpha_rushes + b.beta_rushes_snaps) * pow(0.25, -n.experience_dec)) as est_rushes_per_snap,
        
        -- Estimated TDs per rush
        (sum(n.rushing_touchdowns * pow(0.7, -n.experience_dec)) 
         over (partition by n.gsis_id order by n.game_date)
         + b.alpha_rush_tds * pow(0.7, -n.experience_dec))
        / (sum(n.rush_attempts * pow(0.7, -n.experience_dec)) 
           over (partition by n.gsis_id order by n.game_date)
           + (b.alpha_rush_tds + b.beta_rush_tds_rushes) * pow(0.7, -n.experience_dec)) as est_touchdowns_per_rush,
        
        -- Estimated yards per rush
        (sum(n.rushing_yards * pow(0.5, -n.experience_dec)) 
         over (partition by n.gsis_id order by n.game_date)
         + b.alpha_rush_yds * pow(0.5, -n.experience_dec))
        / (sum(n.rush_attempts * pow(0.5, -n.experience_dec)) 
           over (partition by n.gsis_id order by n.game_date)
           + b.beta_rush_yds_rushes * pow(0.5, -n.experience_dec)) as est_yds_per_rush,
        
        -- Estimated EPA per snap
        (sum(n.epa * pow(0.7, -n.experience_dec)) 
         over (partition by n.gsis_id order by n.game_date)
         - b.alpha_epa * pow(0.7, -n.experience_dec))
        / (sum(n.team_snaps * pow(0.7, -n.experience_dec))
           over (partition by n.gsis_id order by n.game_date)
           + b.beta_epa_snaps * pow(0.7, -n.experience_dec)) as est_epa_per_snap
           
    from {{ ref('nfl_game_logs') }} as n
    inner join {{ ref('nfl_beta_priors') }} as b 
        on b.position_group = n.position_group 
        and b.since_2012 = (n.year >= 2012)
),

calculations as (
    select
        b.*,
        
        -- Derived passing metrics
        b.est_passes_per_snap * b.est_completion_pct as est_completions,
        b.est_passes_per_snap * b.est_completion_pct * b.est_yards_per_completion as est_pass_yards,
        b.est_passes_per_snap * b.est_completion_pct * b.est_tds_per_completion as est_pass_td,
        
        -- Derived receiving metrics
        b.est_tgt_share * b.est_catch_pct as est_receptions,
        b.est_tgt_share * b.est_catch_pct * b.est_yds_per_rec as est_rec_yards,
        b.est_tgt_share * b.est_catch_pct * b.est_touchdowns_per_reception as est_rec_tds,
        
        -- Derived rushing metrics
        b.est_rushes_per_snap * b.est_yds_per_rush as est_rush_yards,
        b.est_rushes_per_snap * b.est_touchdowns_per_rush as est_rush_tds,
        
        -- Fantasy points per snap by category
        b.est_passes_per_snap * b.est_completion_pct * b.est_yards_per_completion * 0.04
        + b.est_passes_per_snap * b.est_completion_pct * b.est_tds_per_completion * 6 as est_passing_fantasy_points_per_snap,
        
        b.est_tgt_share * b.est_catch_pct
        + b.est_tgt_share * b.est_catch_pct * b.est_yds_per_rec * 0.1
        + b.est_tgt_share * b.est_catch_pct * b.est_touchdowns_per_reception * 6 as est_receiving_fantasy_points_per_snap,
        
        b.est_rushes_per_snap * b.est_yds_per_rush * 0.1
        + b.est_rushes_per_snap * b.est_touchdowns_per_rush * 6 as est_rushing_fantasy_points_per_snap
        
    from base_stats as b
),

final as (
    select
        c.*,
        
        -- Total fantasy points per snap
        c.est_passing_fantasy_points_per_snap 
        + c.est_receiving_fantasy_points_per_snap 
        + c.est_rushing_fantasy_points_per_snap as est_fantasy_points_per_snap,
        
        -- Fantasy points value (per 65 snaps)
        (c.est_passing_fantasy_points_per_snap 
         + c.est_receiving_fantasy_points_per_snap 
         + c.est_rushing_fantasy_points_per_snap)
        * coalesce(c.est_snap_share, 1) * 65 as est_fantasy_points_value,
        
        -- RA EPA value (if coefficients available)
        case 
            when ra_epa.position_group is not null then
                65 * (c.est_snap_share * ra_epa.snap_share
                    + c.est_passes_per_snap * ra_epa.pass_share
                    + c.est_completion_pct * ra_epa.completion_percentage
                    + c.est_yards_per_completion * ra_epa.yards_per_completion
                    + c.est_tds_per_completion * ra_epa.tds_per_completion
                    + c.est_rushes_per_snap * ra_epa.rush_share
                    + c.est_yds_per_rush * ra_epa.yards_per_rush
                    + c.est_touchdowns_per_rush * ra_epa.tds_per_rush
                    + c.est_tgt_share * ra_epa.target_share
                    + c.est_catch_pct * ra_epa.catch_percentage
                    + c.est_yds_per_rec * ra_epa.yards_per_reception
                    + c.est_touchdowns_per_reception * ra_epa.tds_per_reception
                    + c.est_epa_per_snap * ra_epa.epa_per_snap
                    + ra_epa.intercept)
            else null
        end as est_ra_epa_or_per_65_snaps
        
    from calculations as c
    left join {{ ref('nfl_ra_epa_coefficients') }} as ra_epa 
        on ra_epa.position_group = c.position_group
)

select * from final
