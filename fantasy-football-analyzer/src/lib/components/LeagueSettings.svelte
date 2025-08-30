<script lang="ts">
	import { leagueSettings } from '$lib/stores/settingsStore';
</script>

<div class="league-settings">
	<h4>League Settings</h4>
	
	<div class="setting-group">
		<label for="teams">Number of Teams:</label>
		<input
			id="teams"
			type="range"
			min="4"
			max="32"
			step="1"
			bind:value={$leagueSettings.teams}
			class="slider"
		/>
		<span class="value">{$leagueSettings.teams}</span>
	</div>

	<div class="setting-group">
		<label for="qb-spots">Number of QB Starters:</label>
		<input
			id="qb-spots"
			type="range"
			min="0"
			max="3"
			step="1"
			bind:value={$leagueSettings.qb_spots}
			class="slider"
		/>
		<span class="value">{$leagueSettings.qb_spots}</span>
	</div>

	<div class="setting-group">
		<label for="rb-spots">Number of RB Starters:</label>
		<input
			id="rb-spots"
			type="range"
			min="0"
			max="3"
			step="1"
			bind:value={$leagueSettings.rb_spots}
			class="slider"
		/>
		<span class="value">{$leagueSettings.rb_spots}</span>
	</div>

	<div class="setting-group">
		<label for="wr-spots">Number of WR Starters:</label>
		<input
			id="wr-spots"
			type="range"
			min="0"
			max="3"
			step="1"
			bind:value={$leagueSettings.wr_spots}
			class="slider"
		/>
		<span class="value">{$leagueSettings.wr_spots}</span>
	</div>

	<div class="setting-group">
		<label for="te-spots">Number of TE Starters:</label>
		<input
			id="te-spots"
			type="range"
			min="0"
			max="3"
			step="1"
			bind:value={$leagueSettings.te_spots}
			class="slider"
		/>
		<span class="value">{$leagueSettings.te_spots}</span>
	</div>

	<div class="setting-group">
		<label for="flex-spots">Number of Flex Starters:</label>
		<input
			id="flex-spots"
			type="range"
			min="0"
			max="5"
			step="1"
			bind:value={$leagueSettings.flex_spots}
			class="slider"
		/>
		<span class="value">{$leagueSettings.flex_spots}</span>
	</div>

	<div class="setting-group">
		<label for="superflex-spots">Number of Superflex Starters:</label>
		<input
			id="superflex-spots"
			type="range"
			min="0"
			max="5"
			step="1"
			bind:value={$leagueSettings.superflex_spots}
			class="slider"
		/>
		<span class="value">{$leagueSettings.superflex_spots}</span>
	</div>

	<div class="setting-group">
		<label for="bench-depth">Number of Bench Spots:</label>
		<input
			id="bench-depth"
			type="range"
			min="0"
			max="30"
			step="1"
			bind:value={$leagueSettings.bench_depth}
			class="slider"
		/>
		<span class="value">{$leagueSettings.bench_depth}</span>
	</div>

	<div class="setting-group">
		<label for="ir-depth">Number of IR Spots:</label>
		<input
			id="ir-depth"
			type="range"
			min="0"
			max="5"
			step="1"
			bind:value={$leagueSettings.ir_depth}
			class="slider"
		/>
		<span class="value">{$leagueSettings.ir_depth}</span>
	</div>

	<div class="setting-group">
		<label for="taxi-depth">Number of Taxi Spots:</label>
		<input
			id="taxi-depth"
			type="range"
			min="0"
			max="10"
			step="1"
			bind:value={$leagueSettings.taxi_depth}
			class="slider"
		/>
		<span class="value">{$leagueSettings.taxi_depth}</span>
	</div>
</div>

<style>
	.league-settings {
		background-color: white;
		border: 1px solid #ddd;
		border-radius: 4px;
		padding: 1rem;
		margin-top: 0.5rem;
	}

	h4 {
		margin: 0 0 1rem 0;
		color: #333;
		font-size: 0.95rem;
		font-weight: 600;
	}

	.setting-group {
		margin-bottom: 1rem;
		display: grid;
		grid-template-columns: 1fr auto;
		gap: 0.5rem;
		align-items: center;
	}

	.setting-group:last-child {
		margin-bottom: 0;
	}

	label {
		font-size: 0.85rem;
		color: #555;
		font-weight: 500;
		grid-column: 1 / -1;
		margin-bottom: 0.25rem;
	}

	.slider {
		width: 100%;
		height: 4px;
		border-radius: 2px;
		background: #ddd;
		outline: none;
		-webkit-appearance: none;
		appearance: none;
	}

	.slider::-webkit-slider-thumb {
		-webkit-appearance: none;
		appearance: none;
		width: 16px;
		height: 16px;
		border-radius: 50%;
		background: #007bff;
		cursor: pointer;
		border: 2px solid white;
		box-shadow: 0 1px 3px rgba(0,0,0,0.3);
	}

	.slider::-moz-range-thumb {
		width: 16px;
		height: 16px;
		border-radius: 50%;
		background: #007bff;
		cursor: pointer;
		border: 2px solid white;
		box-shadow: 0 1px 3px rgba(0,0,0,0.3);
	}

	.value {
		font-size: 0.8rem;
		color: #007bff;
		font-weight: 600;
		min-width: 2rem;
		text-align: right;
	}
</style>
