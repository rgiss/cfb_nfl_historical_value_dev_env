import { writable } from 'svelte/store';

export interface ScoringSettings {
  rec_yd_pts: number;
  rec_pts: number;
  rec_td_pts: number;
  rush_yd_pts: number;
  rush_td_pts: number;
  pass_yd_pts: number;
  pass_td_pts: number;
  tight_end_prem: number;
}

export interface LeagueSettings {
  teams: number;
  qb_spots: number;
  rb_spots: number;
  wr_spots: number;
  te_spots: number;
  flex_spots: number;
  superflex_spots: number;
  bench_depth: number;
  ir_depth: number;
  taxi_depth: number;
}

// Default scoring settings (matching R Shiny app defaults)
export const scoringSettings = writable<ScoringSettings>({
  rec_yd_pts: 0.1,
  rec_pts: 1,
  rec_td_pts: 6,
  rush_yd_pts: 0.1,
  rush_td_pts: 6,
  pass_yd_pts: 0.04,
  pass_td_pts: 4,
  tight_end_prem: 0
});

// Default league settings (matching R Shiny app defaults)
export const leagueSettings = writable<LeagueSettings>({
  teams: 10,
  qb_spots: 1,
  rb_spots: 2,
  wr_spots: 2,
  te_spots: 1,
  flex_spots: 1,
  superflex_spots: 0,
  bench_depth: 10,
  ir_depth: 2,
  taxi_depth: 2
});

// UI state for collapsible settings panels
export const showScoringSettings = writable<boolean>(false);
export const showLeagueSettings = writable<boolean>(false);
