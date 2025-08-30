import { writable } from 'svelte/store';
import Papa from 'papaparse';

export interface PlayerData {
  player_display_name: string;
  team_abbreviation: string;
  position: string;
  year: number;
  approximate_age: number;
  player_games_remaining: number;
  team_primary_color_hex: string;
  est_fantasy_points_per_game: number;
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
  est_value_over_roster_replacement: number;
  est_value_over_waiver_replacement: number;
}

export const data = writable<PlayerData[]>([]);
export const isLoading = writable(false);
export const error = writable<string | null>(null);

export const loadData = async (): Promise<void> => {
  isLoading.set(true);
  error.set(null);
  
  try {
    const response = await fetch('/cfb_nfl_historical_value_estimate.csv');
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const csvText = await response.text();
    
    const parsed = Papa.parse<PlayerData>(csvText, {
      header: true,
      dynamicTyping: true,
      skipEmptyLines: true,
      transformHeader: (header: string) => header.trim()
    });
    
    if (parsed.errors.length > 0) {
      console.warn('CSV parsing warnings:', parsed.errors);
    }
    
    // Filter out rows with missing critical data
    const cleanData = parsed.data.filter((row: any) => 
      row.player_display_name && 
      row.approximate_age && 
      typeof row.approximate_age === 'number'
    );
    
    data.set(cleanData);
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : 'Failed to load data';
    error.set(errorMessage);
    console.error('Error loading data:', err);
  } finally {
    isLoading.set(false);
  }
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
