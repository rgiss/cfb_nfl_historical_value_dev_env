<script lang="ts">
	import { data } from '$lib/stores/dataStore';
	import { scoringSettings } from '$lib/stores/settingsStore';
	import { calculateCustomFantasyPoints } from '$lib/utils/dataProcessor';

	interface CurrentPlayerData {
		player_display_name: string;
		team_abbreviation: string;
		position: string;
		est_value_over_roster_replacement: number;
		est_value_over_waiver_replacement: number;
		custom_fantasy_points_per_game: number;
		est_snap_share: number;
		est_tgt_share: number;
		est_rec_share: number;
		est_receptions_per_game: number;
		est_rec_yards_per_game: number;
		est_rush_yards_per_game: number;
		est_pass_yards_per_game: number;
	}

	let currentPlayers: CurrentPlayerData[] = [];
	let sortColumn = 'est_value_over_roster_replacement';
	let sortDirection: 'asc' | 'desc' = 'desc';
	let searchTerm = '';

	$: {
		// Filter for current (2024) players with no games remaining
		const processedData = calculateCustomFantasyPoints($data, $scoringSettings);
		const filtered = processedData.filter(player => 
			player.year === 2024 && player.player_games_remaining === 0
		);

		// Apply search filter
		const searchFiltered = searchTerm 
			? filtered.filter(player => 
				player.player_display_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
				player.team_abbreviation.toLowerCase().includes(searchTerm.toLowerCase()) ||
				player.position.toLowerCase().includes(searchTerm.toLowerCase())
			)
			: filtered;

		// Sort the data
		currentPlayers = searchFiltered
			.map(player => ({
				player_display_name: player.player_display_name,
				team_abbreviation: player.team_abbreviation,
				position: player.position,
				est_value_over_roster_replacement: player.est_value_over_roster_replacement,
				est_value_over_waiver_replacement: player.est_value_over_waiver_replacement,
				custom_fantasy_points_per_game: player.custom_fantasy_points_per_game,
				est_snap_share: player.est_snap_share || 0,
				est_tgt_share: player.est_tgt_share || 0,
				est_rec_share: player.est_rec_share || 0,
				est_receptions_per_game: player.est_receptions_per_game || 0,
				est_rec_yards_per_game: player.est_rec_yards_per_game || 0,
				est_rush_yards_per_game: player.est_rush_yards_per_game || 0,
				est_pass_yards_per_game: player.est_pass_yards_per_game || 0
			}))
			.sort((a, b) => {
				const aVal = (a as any)[sortColumn];
				const bVal = (b as any)[sortColumn];
				
				if (sortDirection === 'asc') {
					return aVal - bVal;
				} else {
					return bVal - aVal;
				}
			});
	}

	function handleSort(column: string) {
		if (sortColumn === column) {
			sortDirection = sortDirection === 'asc' ? 'desc' : 'asc';
		} else {
			sortColumn = column;
			sortDirection = 'desc';
		}
	}

	function formatNumber(value: number, decimals: number = 2): string {
		return value.toFixed(decimals);
	}

	function exportToCsv() {
		const headers = [
			'Player', 'Team', 'Position', 'Value Over Backup', 'Value Over Waiver',
			'Fantasy Points/Game', 'Snap %', 'Target %', 'Reception %',
			'Receptions/Game', 'Receiving Yards/Game', 'Rushing Yards/Game', 'Passing Yards/Game'
		];

		const csvContent = [
			headers.join(','),
			...currentPlayers.map(player => [
				`"${player.player_display_name}"`,
				player.team_abbreviation,
				player.position,
				formatNumber(player.est_value_over_roster_replacement),
				formatNumber(player.est_value_over_waiver_replacement),
				formatNumber(player.custom_fantasy_points_per_game),
				formatNumber(player.est_snap_share),
				formatNumber(player.est_tgt_share),
				formatNumber(player.est_rec_share),
				formatNumber(player.est_receptions_per_game),
				formatNumber(player.est_rec_yards_per_game),
				formatNumber(player.est_rush_yards_per_game),
				formatNumber(player.est_pass_yards_per_game)
			].join(','))
		].join('\n');

		const blob = new Blob([csvContent], { type: 'text/csv' });
		const url = window.URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = 'current_player_values.csv';
		a.click();
		window.URL.revokeObjectURL(url);
	}
</script>

<div class="player-table-container">
	<div class="table-header">
		<h3>Current Player Values (2024)</h3>
		<div class="table-controls">
			<input
				type="text"
				bind:value={searchTerm}
				placeholder="Search players..."
				class="search-input"
			/>
			<button on:click={exportToCsv} class="export-btn">
				Export CSV
			</button>
		</div>
	</div>

	<div class="table-wrapper">
		<table class="player-table">
			<thead>
				<tr>
					<th>
						<button class="sort-btn" on:click={() => handleSort('player_display_name')}>
							Player
							{#if sortColumn === 'player_display_name'}
								<span class="sort-arrow">{sortDirection === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</button>
					</th>
					<th>
						<button class="sort-btn" on:click={() => handleSort('team_abbreviation')}>
							Team
							{#if sortColumn === 'team_abbreviation'}
								<span class="sort-arrow">{sortDirection === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</button>
					</th>
					<th>
						<button class="sort-btn" on:click={() => handleSort('position')}>
							Pos
							{#if sortColumn === 'position'}
								<span class="sort-arrow">{sortDirection === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</button>
					</th>
					<th>
						<button class="sort-btn" on:click={() => handleSort('est_value_over_roster_replacement')}>
							Value Over Backup
							{#if sortColumn === 'est_value_over_roster_replacement'}
								<span class="sort-arrow">{sortDirection === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</button>
					</th>
					<th>
						<button class="sort-btn" on:click={() => handleSort('est_value_over_waiver_replacement')}>
							Value Over Waiver
							{#if sortColumn === 'est_value_over_waiver_replacement'}
								<span class="sort-arrow">{sortDirection === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</button>
					</th>
					<th>
						<button class="sort-btn" on:click={() => handleSort('custom_fantasy_points_per_game')}>
							FP/G
							{#if sortColumn === 'custom_fantasy_points_per_game'}
								<span class="sort-arrow">{sortDirection === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</button>
					</th>
					<th>
						<button class="sort-btn" on:click={() => handleSort('est_snap_share')}>
							Snap %
							{#if sortColumn === 'est_snap_share'}
								<span class="sort-arrow">{sortDirection === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</button>
					</th>
					<th>
						<button class="sort-btn" on:click={() => handleSort('est_tgt_share')}>
							Target %
							{#if sortColumn === 'est_tgt_share'}
								<span class="sort-arrow">{sortDirection === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</button>
					</th>
					<th>
						<button class="sort-btn" on:click={() => handleSort('est_rec_share')}>
							Rec %
							{#if sortColumn === 'est_rec_share'}
								<span class="sort-arrow">{sortDirection === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</button>
					</th>
					<th>
						<button class="sort-btn" on:click={() => handleSort('est_receptions_per_game')}>
							Rec/G
							{#if sortColumn === 'est_receptions_per_game'}
								<span class="sort-arrow">{sortDirection === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</button>
					</th>
					<th>
						<button class="sort-btn" on:click={() => handleSort('est_rec_yards_per_game')}>
							Rec Yds/G
							{#if sortColumn === 'est_rec_yards_per_game'}
								<span class="sort-arrow">{sortDirection === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</button>
					</th>
					<th>
						<button class="sort-btn" on:click={() => handleSort('est_rush_yards_per_game')}>
							Rush Yds/G
							{#if sortColumn === 'est_rush_yards_per_game'}
								<span class="sort-arrow">{sortDirection === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</button>
					</th>
					<th>
						<button class="sort-btn" on:click={() => handleSort('est_pass_yards_per_game')}>
							Pass Yds/G
							{#if sortColumn === 'est_pass_yards_per_game'}
								<span class="sort-arrow">{sortDirection === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</button>
					</th>
				</tr>
			</thead>
			<tbody>
				{#each currentPlayers as player}
					<tr>
						<td class="player-name">{player.player_display_name}</td>
						<td>{player.team_abbreviation}</td>
						<td>{player.position}</td>
						<td class="number-cell" class:negative={player.est_value_over_roster_replacement < 0}>
							{formatNumber(player.est_value_over_roster_replacement)}
						</td>
						<td class="number-cell" class:negative={player.est_value_over_waiver_replacement < 0}>
							{formatNumber(player.est_value_over_waiver_replacement)}
						</td>
						<td class="number-cell">{formatNumber(player.custom_fantasy_points_per_game)}</td>
						<td class="number-cell">{formatNumber(player.est_snap_share)}</td>
						<td class="number-cell">{formatNumber(player.est_tgt_share)}</td>
						<td class="number-cell">{formatNumber(player.est_rec_share)}</td>
						<td class="number-cell">{formatNumber(player.est_receptions_per_game)}</td>
						<td class="number-cell">{formatNumber(player.est_rec_yards_per_game)}</td>
						<td class="number-cell">{formatNumber(player.est_rush_yards_per_game)}</td>
						<td class="number-cell">{formatNumber(player.est_pass_yards_per_game)}</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>

	<div class="table-footer">
		<p>Showing {currentPlayers.length} players</p>
	</div>
</div>

<style>
	.player-table-container {
		width: 100%;
		background: white;
		border-radius: 8px;
		box-shadow: 0 2px 4px rgba(0,0,0,0.1);
	}

	.table-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 1rem;
		border-bottom: 1px solid #ddd;
	}

	.table-header h3 {
		margin: 0;
		color: #333;
	}

	.table-controls {
		display: flex;
		gap: 1rem;
		align-items: center;
	}

	.search-input {
		padding: 0.5rem;
		border: 1px solid #ddd;
		border-radius: 4px;
		font-size: 0.9rem;
		width: 200px;
	}

	.search-input:focus {
		outline: none;
		border-color: #007bff;
		box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
	}

	.export-btn {
		padding: 0.5rem 1rem;
		background-color: #28a745;
		color: white;
		border: none;
		border-radius: 4px;
		cursor: pointer;
		font-size: 0.9rem;
		transition: background-color 0.3s ease;
	}

	.export-btn:hover {
		background-color: #218838;
	}

	.table-wrapper {
		overflow-x: auto;
		max-height: 600px;
		overflow-y: auto;
	}

	.player-table {
		width: 100%;
		border-collapse: collapse;
		font-size: 0.85rem;
	}

	.player-table th,
	.player-table td {
		padding: 0.5rem;
		border-bottom: 1px solid #eee;
		text-align: left;
	}

	.player-table th {
		background-color: #f8f9fa;
		font-weight: 600;
		position: sticky;
		top: 0;
		z-index: 10;
	}

	.sort-btn {
		background: none;
		border: none;
		cursor: pointer;
		font-weight: 600;
		font-size: 0.85rem;
		color: #333;
		display: flex;
		align-items: center;
		gap: 0.25rem;
		padding: 0;
		white-space: nowrap;
	}

	.sort-btn:hover {
		color: #007bff;
	}

	.sort-arrow {
		font-size: 0.7rem;
		color: #007bff;
	}

	.player-table tbody tr:hover {
		background-color: #f8f9fa;
	}

	.player-name {
		font-weight: 500;
		color: #333;
		min-width: 150px;
	}

	.number-cell {
		text-align: right;
		font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
		color: #2ECC40;
	}

	.number-cell.negative {
		color: #FF4136;
	}

	.table-footer {
		padding: 1rem;
		border-top: 1px solid #ddd;
		color: #666;
		font-size: 0.9rem;
	}

	.table-footer p {
		margin: 0;
	}

	/* Responsive design */
	@media (max-width: 768px) {
		.table-header {
			flex-direction: column;
			gap: 1rem;
			align-items: stretch;
		}

		.table-controls {
			justify-content: space-between;
		}

		.search-input {
			width: auto;
			flex: 1;
		}
	}
</style>
