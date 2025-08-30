import type { PlayerData } from '../stores/dataStore';
import type { ScoringSettings } from '../stores/settingsStore';

export interface ProcessedPlayerData extends PlayerData {
  custom_fantasy_points_per_game: number;
  plot_metric: number;
}

// Calculate custom fantasy points based on scoring settings
export const calculateCustomFantasyPoints = (
  data: PlayerData[], 
  scoring: ScoringSettings
): ProcessedPlayerData[] => {
  return data.map(player => {
    const custom_rec_pts = (player.est_receptions_per_game || 0) * scoring.rec_pts;
    const custom_rec_yd_pts = (player.est_rec_yards_per_game || 0) * scoring.rec_yd_pts;
    const custom_rec_td_pts = (player.est_rec_tds_per_game || 0) * scoring.rec_td_pts;
    const custom_rush_yd_pts = (player.est_rush_yards_per_game || 0) * scoring.rush_yd_pts;
    const custom_rush_td_pts = (player.est_rush_tds_per_game || 0) * scoring.rush_td_pts;
    const custom_pass_yd_pts = (player.est_pass_yards_per_game || 0) * scoring.pass_yd_pts;
    const custom_pass_td_pts = (player.est_pass_td_per_game || 0) * scoring.pass_td_pts;
    
    // Add tight end premium if applicable
    const te_premium = player.position === 'TE' ? 
      (player.est_receptions_per_game || 0) * scoring.tight_end_prem : 0;
    
    const custom_fantasy_points_per_game = 
      custom_rec_pts + custom_rec_yd_pts + custom_rec_td_pts +
      custom_rush_yd_pts + custom_rush_td_pts +
      custom_pass_yd_pts + custom_pass_td_pts + te_premium;

    return {
      ...player,
      custom_fantasy_points_per_game,
      plot_metric: 0 // Will be set based on selected metric
    };
  });
};

// Get the plot metric value based on selected metric
export const getPlotMetric = (
  data: ProcessedPlayerData[], 
  metric: string, 
  scoring: ScoringSettings
): ProcessedPlayerData[] => {
  return data.map(player => {
    let plot_metric: number;
    
    if (metric === 'est_fantasy_points_per_game') {
      plot_metric = player.custom_fantasy_points_per_game;
    } else if (metric === 'est_fantasy_points_per_snap') {
      plot_metric = player.custom_fantasy_points_per_game / Math.max(player.est_snap_share || 1, 0.01);
    } else {
      plot_metric = (player as any)[metric] || 0;
    }
    
    return {
      ...player,
      plot_metric
    };
  });
};

// Filter data by age range
export const filterByAgeRange = (
  data: ProcessedPlayerData[], 
  ageRange: [number, number]
): ProcessedPlayerData[] => {
  return data.filter(player => 
    player.approximate_age >= ageRange[0] && 
    player.approximate_age <= ageRange[1]
  );
};

// Get the most recent team color for a player
export const getPlayerColor = (playerData: PlayerData[]): string => {
  if (playerData.length === 0) return '#999999';
  
  // Find the most recent entry with a valid color
  const sortedData = [...playerData].sort((a, b) => b.year - a.year);
  const recentData = sortedData.find(d => d.team_primary_color_hex);
  
  return recentData?.team_primary_color_hex || '#999999';
};

// Tricube weight function for LOESS
const tricubeWeight = (t: number): number => {
  if (Math.abs(t) >= 1) return 0;
  const abs_t = Math.abs(t);
  return Math.pow(1 - Math.pow(abs_t, 3), 3);
};

// Weighted least squares regression
const weightedRegression = (
  x: number[], 
  y: number[], 
  weights: number[], 
  targetX: number
): number => {
  let sumW = 0;
  let sumWX = 0;
  let sumWY = 0;
  let sumWXX = 0;
  let sumWXY = 0;
  
  for (let i = 0; i < x.length; i++) {
    const w = weights[i];
    sumW += w;
    sumWX += w * x[i];
    sumWY += w * y[i];
    sumWXX += w * x[i] * x[i];
    sumWXY += w * x[i] * y[i];
  }
  
  // Calculate linear regression coefficients
  const denominator = sumW * sumWXX - sumWX * sumWX;
  if (Math.abs(denominator) < 1e-12) {
    // Fallback to weighted mean if regression is degenerate
    return sumWY / sumW;
  }
  
  const a = (sumW * sumWXY - sumWX * sumWY) / denominator;
  const b = (sumWY * sumWXX - sumWX * sumWXY) / denominator;
  
  return a * targetX + b;
};

// Generate LOESS regression for a player's data
export const generateLoessRegression = (
  playerData: ProcessedPlayerData[], 
  span: number = 0.8
): { age: number; value: number }[] => {
  if (playerData.length < 3) return [];
  
  // Sort by age
  const sortedData = [...playerData].sort((a, b) => a.approximate_age - b.approximate_age);
  const x = sortedData.map(d => d.approximate_age);
  const y = sortedData.map(d => d.plot_metric);
  
  const result: { age: number; value: number }[] = [];
  const n = sortedData.length;
  const k = Math.max(3, Math.floor(n * span)); // Number of neighbors to consider
  
  // Generate smooth curve points
  const ageRange = x[x.length - 1] - x[0];
  const numPoints = Math.max(n, 20); // At least 20 points for smooth curve
  
  for (let i = 0; i < numPoints; i++) {
    const targetAge = x[0] + (ageRange * i) / (numPoints - 1);
    
    // Calculate distances from target point
    const distances = x.map(xi => Math.abs(xi - targetAge));
    
    // Find the k nearest neighbors
    const sortedIndices = distances
      .map((d, idx) => ({ distance: d, index: idx }))
      .sort((a, b) => a.distance - b.distance)
      .slice(0, k);
    
    // Calculate weights using tricube function
    const maxDistance = Math.max(...sortedIndices.map(si => si.distance));
    const weights = new Array(n).fill(0);
    
    for (const { distance, index } of sortedIndices) {
      if (maxDistance > 0) {
        weights[index] = tricubeWeight(distance / maxDistance);
      } else {
        weights[index] = 1; // All points are at the same x-value
      }
    }
    
    // Fit weighted regression and predict
    const predictedValue = weightedRegression(x, y, weights, targetAge);
    
    result.push({
      age: targetAge,
      value: predictedValue
    });
  }
  
  return result;
};

// Get label for metric
export const getMetricLabel = (metric: string): string => {
  const labels: Record<string, string> = {
    'est_fantasy_points_per_game': 'Fantasy Points Per Game',
    'est_snap_share': 'Snap Share',
    'est_passes_per_snap': 'Passes Per Snap',
    'est_sacks_per_dropback': 'Sacks Per Dropback',
    'est_completion_pct': 'Completion %',
    'est_tds_per_completion': 'TDs Per Completion',
    'est_yards_per_completion': 'Yards Per Completion',
    'est_tgt_share': 'Target Share',
    'est_catch_pct': 'Catch %',
    'est_rec_share': 'Reception Share',
    'est_touchdowns_per_reception': 'TDs Per Reception',
    'est_yds_per_rec': 'Yards Per Reception',
    'est_rushes_per_snap': 'Rushes Per Snap',
    'est_touchdowns_per_rush': 'TDs Per Rush',
    'est_yds_per_rush': 'Yards Per Rush',
    'est_completions_per_game': 'Completions Per Game',
    'est_pass_yards_per_game': 'Pass Yards Per Game',
    'est_pass_td_per_game': 'Pass TDs Per Game',
    'est_receptions_per_game': 'Receptions Per Game',
    'est_rec_yards_per_game': 'Receiving Yards Per Game',
    'est_rec_tds_per_game': 'Receiving TDs Per Game',
    'est_rush_yards_per_game': 'Rush Yards Per Game',
    'est_rush_tds_per_game': 'Rush TDs Per Game',
    'est_passing_fantasy_points_per_game': 'Passing Fantasy Pts/Game',
    'est_receiving_fantasy_points_per_game': 'Receiving Fantasy Pts/Game',
    'est_rushing_fantasy_points_per_game': 'Rushing Fantasy Pts/Game',
    'est_fantasy_points_per_snap': 'Fantasy Pts/Snap',
    'est_value_over_roster_replacement': 'Value Over Backup',
    'est_value_over_waiver_replacement': 'Value Over Waiver'
  };
  
  return labels[metric] || metric;
};
