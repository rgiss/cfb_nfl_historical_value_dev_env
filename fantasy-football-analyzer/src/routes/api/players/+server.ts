import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getPool } from '$lib/server/db';

export const GET: RequestHandler = async () => {
  const pool = getPool();

  try {
    const result = await pool.query(`
      select
          team_primary_color_hex
        , player_display_name
        , position_group
        , team
        , league
        , year
        , week
        , approximate_age
        , true_age
        , player_game_number
        , player_games_remaining
        , player_season_game_number
        , player_season_games_remaining
        , est_snap_share
        , est_passes_per_snap
        , est_sacks_per_dropback
        , est_completion_pct
        , est_tds_per_completion
        , est_yards_per_completion
        , est_tgt_share
        , est_catch_pct
        , est_rec_share
        , est_touchdowns_per_reception
        , est_yds_per_rec
        , est_rushes_per_snap
        , est_touchdowns_per_rush
        , est_yds_per_rush
        , est_epa_per_snap
        , est_completions_per_game
        , est_pass_yards_per_game
        , est_pass_td_per_game
        , est_receptions_per_game
        , est_rec_yards_per_game
        , est_rec_tds_per_game
        , est_rush_yards_per_game
        , est_rush_tds_per_game
        , est_passing_fantasy_points_per_game
        , est_receiving_fantasy_points_per_game
        , est_rushing_fantasy_points_per_game
        , est_fantasy_points_per_snap
        , est_fantasy_points_per_game
        , est_epa
        , est_value_over_waiver_replacement
        , est_value_over_roster_replacement
      from public_marts.cfb_nfl_historical_value_estimate
      where position_group in ('QB', 'WR', 'RB', 'TE')
      order by player_display_name, year, week
    `);

    return json(result.rows);
  } catch (err) {
    console.error('Database query error:', err);
    return json({ error: 'Failed to fetch player data' }, { status: 500 });
  }
};
