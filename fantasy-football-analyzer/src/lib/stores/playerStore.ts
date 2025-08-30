import { writable } from 'svelte/store';

export interface SelectedPlayer {
  color: string;
  visible: boolean;
}

export const selectedPlayers = writable<Map<string, SelectedPlayer>>(new Map());
export const selectedMetric = writable<string>('est_fantasy_points_per_game');
export const ageRange = writable<[number, number]>([17, 47]);
export const showPoints = writable<boolean>(true);
export const loessSpan = writable<number>(0.8); // LOESS smoothing parameter (0.1 = very smooth, 1.0 = less smooth)

// Helper functions for managing selected players
export const addPlayer = (playerName: string, color: string, visible: boolean = true): void => {
  selectedPlayers.update(players => {
    const newPlayers = new Map(players);
    newPlayers.set(playerName, { color, visible });
    return newPlayers;
  });
};

export const removePlayer = (playerName: string): void => {
  selectedPlayers.update(players => {
    const newPlayers = new Map(players);
    newPlayers.delete(playerName);
    return newPlayers;
  });
};

export const togglePlayerVisibility = (playerName: string): void => {
  selectedPlayers.update(players => {
    const newPlayers = new Map(players);
    const player = newPlayers.get(playerName);
    if (player) {
      player.visible = !player.visible;
      newPlayers.set(playerName, player);
    }
    return newPlayers;
  });
};

export const clearAllPlayers = (): void => {
  selectedPlayers.set(new Map());
};

// Metric options matching the R Shiny app
export const metricOptions = [
  { value: 'est_fantasy_points_per_game', label: 'Fantasy Points Per Game' },
  { value: 'est_snap_share', label: 'Snap Share' },
  { value: 'est_passes_per_snap', label: 'Passes Per Snap' },
  { value: 'est_sacks_per_dropback', label: 'Sacks Per Dropback' },
  { value: 'est_completion_pct', label: 'Completion %' },
  { value: 'est_tds_per_completion', label: 'TDs Per Completion' },
  { value: 'est_yards_per_completion', label: 'Yards Per Completion' },
  { value: 'est_tgt_share', label: 'Target Share' },
  { value: 'est_catch_pct', label: 'Catch %' },
  { value: 'est_rec_share', label: 'Reception Share' },
  { value: 'est_touchdowns_per_reception', label: 'TDs Per Reception' },
  { value: 'est_yds_per_rec', label: 'Yards Per Reception' },
  { value: 'est_rushes_per_snap', label: 'Rushes Per Snap' },
  { value: 'est_touchdowns_per_rush', label: 'TDs Per Rush' },
  { value: 'est_yds_per_rush', label: 'Yards Per Rush' },
  { value: 'est_completions_per_game', label: 'Completions Per Game' },
  { value: 'est_pass_yards_per_game', label: 'Pass Yards Per Game' },
  { value: 'est_pass_td_per_game', label: 'Pass TDs Per Game' },
  { value: 'est_receptions_per_game', label: 'Receptions Per Game' },
  { value: 'est_rec_yards_per_game', label: 'Receiving Yards Per Game' },
  { value: 'est_rec_tds_per_game', label: 'Receiving TDs Per Game' },
  { value: 'est_rush_yards_per_game', label: 'Rush Yards Per Game' },
  { value: 'est_rush_tds_per_game', label: 'Rush TDs Per Game' },
  { value: 'est_passing_fantasy_points_per_game', label: 'Passing Fantasy Pts/Game' },
  { value: 'est_receiving_fantasy_points_per_game', label: 'Receiving Fantasy Pts/Game' },
  { value: 'est_rushing_fantasy_points_per_game', label: 'Rushing Fantasy Pts/Game' },
  { value: 'est_fantasy_points_per_snap', label: 'Fantasy Pts/65 Snaps' },
  { value: 'est_value_over_roster_replacement', label: 'Value Over Backup' },
  { value: 'est_value_over_waiver_replacement', label: 'Value Over Waiver' }
];
