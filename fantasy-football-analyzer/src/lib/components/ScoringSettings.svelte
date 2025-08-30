<script lang="ts">
	import { scoringSettings } from '$lib/stores/settingsStore';
</script>

<div class="scoring-settings">
	<h4>Scoring Settings</h4>
	
	<div class="setting-group">
		<label for="rec-yd-pts">Points per Receiving Yard:</label>
		<input
			id="rec-yd-pts"
			type="range"
			min="0.02"
			max="0.1"
			step="0.01"
			bind:value={$scoringSettings.rec_yd_pts}
			class="slider"
		/>
		<span class="value">{$scoringSettings.rec_yd_pts}</span>
	</div>

	<div class="setting-group">
		<label for="rec-pts">Points per Reception:</label>
		<input
			id="rec-pts"
			type="range"
			min="0"
			max="1"
			step="0.5"
			bind:value={$scoringSettings.rec_pts}
			class="slider"
		/>
		<span class="value">{$scoringSettings.rec_pts}</span>
	</div>

	<div class="setting-group">
		<label for="rec-td-pts">Points per Receiving TD:</label>
		<input
			id="rec-td-pts"
			type="range"
			min="4"
			max="6"
			step="1"
			bind:value={$scoringSettings.rec_td_pts}
			class="slider"
		/>
		<span class="value">{$scoringSettings.rec_td_pts}</span>
	</div>

	<div class="setting-group">
		<label for="rush-yd-pts">Points per Rushing Yard:</label>
		<input
			id="rush-yd-pts"
			type="range"
			min="0.02"
			max="0.1"
			step="0.01"
			bind:value={$scoringSettings.rush_yd_pts}
			class="slider"
		/>
		<span class="value">{$scoringSettings.rush_yd_pts}</span>
	</div>

	<div class="setting-group">
		<label for="rush-td-pts">Points per Rushing TD:</label>
		<input
			id="rush-td-pts"
			type="range"
			min="4"
			max="6"
			step="1"
			bind:value={$scoringSettings.rush_td_pts}
			class="slider"
		/>
		<span class="value">{$scoringSettings.rush_td_pts}</span>
	</div>

	<div class="setting-group">
		<label for="pass-yd-pts">Points per Passing Yard:</label>
		<input
			id="pass-yd-pts"
			type="range"
			min="0.02"
			max="0.1"
			step="0.01"
			bind:value={$scoringSettings.pass_yd_pts}
			class="slider"
		/>
		<span class="value">{$scoringSettings.pass_yd_pts}</span>
	</div>

	<div class="setting-group">
		<label for="pass-td-pts">Points per Passing TD:</label>
		<input
			id="pass-td-pts"
			type="range"
			min="4"
			max="6"
			step="1"
			bind:value={$scoringSettings.pass_td_pts}
			class="slider"
		/>
		<span class="value">{$scoringSettings.pass_td_pts}</span>
	</div>

	<div class="setting-group">
		<label for="te-prem">Tight End Premium:</label>
		<input
			id="te-prem"
			type="range"
			min="0"
			max="3"
			step="1"
			bind:value={$scoringSettings.tight_end_prem}
			class="slider"
		/>
		<span class="value">{$scoringSettings.tight_end_prem}</span>
	</div>
</div>

<style>
	.scoring-settings {
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
