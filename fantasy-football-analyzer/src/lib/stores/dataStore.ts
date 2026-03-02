import { writable } from 'svelte/store';
import Papa from 'papaparse';

export interface PlayerData {
  player_display_name: string;
  team: string;
  position_group: string;
  position: string; // alias for position_group for component compatibility
  league: string;
  year: number;
  week: number;
  approximate_age: number;
  true_age: number;
  player_game_number: number;
  player_games_remaining: number;
  player_season_game_number: number;
  player_season_games_remaining: number;
  team_primary_color_hex: string;
  est_snap_share: number;
  est_passes_per_snap: number;
  est_sacks_per_dropback: number;
  est_completion_pct: number;
  est_tds_per_completion: number;
  est_yards_per_completion: number;
  est_tgt_share: number;
  est_catch_pct: number;
  est_rec_share: number;
  est_touchdowns_per_reception: number;
  est_yds_per_rec: number;
  est_rushes_per_snap: number;
  est_touchdowns_per_rush: number;
  est_yds_per_rush: number;
  est_epa_per_snap: number;
  est_epa: number;
  est_completions_per_game: number;
  est_pass_yards_per_game: number;
  est_pass_td_per_game: number;
  est_receptions_per_game: number;
  est_rec_yards_per_game: number;
  est_rec_tds_per_game: number;
  est_rush_yards_per_game: number;
  est_rush_tds_per_game: number;
  est_passing_fantasy_points_per_game: number;
  est_receiving_fantasy_points_per_game: number;
  est_rushing_fantasy_points_per_game: number;
  est_fantasy_points_per_snap: number;
  est_fantasy_points_per_game: number;
  est_value_over_roster_replacement: number;
  est_value_over_waiver_replacement: number;
}

export const data = writable<PlayerData[]>([]);
export const isLoading = writable(false);
export const error = writable<string | null>(null);

// Normalize a row from either API (snake_case) or CSV into PlayerData
const normalizeRow = (row: any): PlayerData => ({
  ...row,
  // Ensure position alias exists for component compatibility
  position: row.position_group || row.position,
  position_group: row.position_group || row.position,
  // Ensure team field exists (CSV may use team_abbreviation)
  team: row.team || row.team_abbreviation,
  // Cast numeric fields
  year: Number(row.year),
  week: Number(row.week),
  approximate_age: Number(row.approximate_age),
  true_age: Number(row.true_age),
  player_game_number: Number(row.player_game_number),
  player_games_remaining: Number(row.player_games_remaining),
  est_fantasy_points_per_game: Number(row.est_fantasy_points_per_game),
  est_snap_share: Number(row.est_snap_share),
  est_passes_per_snap: Number(row.est_passes_per_snap),
  est_sacks_per_dropback: Number(row.est_sacks_per_dropback),
  est_completion_pct: Number(row.est_completion_pct),
  est_tds_per_completion: Number(row.est_tds_per_completion),
  est_yards_per_completion: Number(row.est_yards_per_completion),
  est_tgt_share: Number(row.est_tgt_share),
  est_catch_pct: Number(row.est_catch_pct),
  est_rec_share: Number(row.est_rec_share),
  est_touchdowns_per_reception: Number(row.est_touchdowns_per_reception),
  est_yds_per_rec: Number(row.est_yds_per_rec),
  est_rushes_per_snap: Number(row.est_rushes_per_snap),
  est_touchdowns_per_rush: Number(row.est_touchdowns_per_rush),
  est_yds_per_rush: Number(row.est_yds_per_rush),
  est_epa_per_snap: Number(row.est_epa_per_snap),
  est_epa: Number(row.est_epa),
  est_value_over_roster_replacement: Number(row.est_value_over_roster_replacement),
  est_value_over_waiver_replacement: Number(row.est_value_over_waiver_replacement),
});

export const loadData = async (): Promise<void> => {
  isLoading.set(true);
  error.set(null);

  try {
    // Try API endpoint first (server-side PG connection)
    const apiResponse = await fetch('/api/players');
    if (apiResponse.ok) {
      const json = await apiResponse.json();
      if (Array.isArray(json)) {
        const cleanData = json
          .map(normalizeRow)
          .filter((row: PlayerData) =>
            row.player_display_name &&
            row.approximate_age &&
            !isNaN(row.approximate_age)
          );
        data.set(cleanData);
        return;
      }
    }

    // Fallback to static CSV for local dev without PG
    console.warn('API endpoint unavailable, falling back to static CSV');
    await loadFromCsv();
  } catch {
    // Fallback to CSV on any error
    try {
      await loadFromCsv();
    } catch (csvErr) {
      const errorMessage = csvErr instanceof Error ? csvErr.message : 'Failed to load data';
      error.set(errorMessage);
      console.error('Error loading data:', csvErr);
    }
  } finally {
    isLoading.set(false);
  }
};

const loadFromCsv = async (): Promise<void> => {
  const response = await fetch('/cfb_nfl_sample_data.csv');
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  const csvText = await response.text();

  const parsed = Papa.parse<PlayerData>(csvText, {
    header: true,
    dynamicTyping: true,
    skipEmptyLines: true,
    transformHeader: (header: string) => header.trim(),
    transform: (value: string) => {
      if (value === '' || value === 'NA' || value === 'NULL' || value === 'null') {
        return null;
      }
      return value;
    }
  });

  if (parsed.errors.length > 0) {
    console.warn('CSV parsing warnings:', parsed.errors);
  }

  const cleanData = parsed.data
    .map(normalizeRow)
    .filter((row: PlayerData) =>
      row.player_display_name &&
      row.approximate_age &&
      typeof row.approximate_age === 'number' &&
      !isNaN(row.approximate_age)
    );

  data.set(cleanData);
};

// Helper function to get unique player names
export const getPlayerNames = (playerData: PlayerData[]): string[] => {
  const names = new Set(playerData.map(d => d.player_display_name));
  return Array.from(names).sort();
};

// Helper function to get data for a specific player
export const getPlayerData = (playerData: PlayerData[], playerName: string): PlayerData[] => {
  return playerData.filter(d => d.player_display_name === playerName);
};
