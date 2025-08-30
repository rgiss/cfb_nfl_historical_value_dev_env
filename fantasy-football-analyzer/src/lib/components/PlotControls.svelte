<script lang="ts">
	import { ageRange, showPoints, selectedPlayers, removePlayer, togglePlayerVisibility, loessSpan } from '$lib/stores/playerStore';

	function sanitizeId(name: string): string {
		return name.replace(/[^a-zA-Z0-9]/g, '_');
	}
</script>

<div class="plot-controls">
	<h4>Current Players</h4>
	{#if $selectedPlayers.size === 0}
		<p class="no-players">No players selected. Add players to begin analysis.</p>
	{:else}
		<div class="player-list">
			{#each Array.from($selectedPlayers.entries()) as [playerName, playerData]}
				<div class="player-item">
					<button
						class="player-toggle"
						class:visible={playerData.visible}
						style:background-color={playerData.visible ? playerData.color : '#f8f9fa'}
						style:color={playerData.visible ? 'white' : '#6c757d'}
						style:border={playerData.visible ? 'none' : '1px dashed #ccc'}
						on:click={() => togglePlayerVisibility(playerName)}
						title="Toggle visibility"
					>
						{playerName}
					</button>
					<button
						class="remove-btn"
						on:click={() => removePlayer(playerName)}
						title="Remove player"
					>
						✖
					</button>
				</div>
			{/each}
		</div>
	{/if}

	<hr />

	<h4>Plot Controls</h4>
	<div class="control-group">
		<label for="age-range">Age Range:</label>
		<div class="range-container">
			<input
				id="age-range"
				type="range"
				min="17"
				max="47"
				bind:value={$ageRange[0]}
				class="range-input"
			/>
			<input
				type="range"
				min="17"
				max="47"
				bind:value={$ageRange[1]}
				class="range-input"
			/>
		</div>
		<div class="range-values">
			{$ageRange[0]} - {$ageRange[1]}
		</div>
	</div>

	<div class="control-group">
		<label class="checkbox-label">
			<input type="checkbox" bind:checked={$showPoints} />
			Show Data Points
		</label>
	</div>

	<div class="control-group">
		<label for="loess-span">Trend Line Smoothing:</label>
		<div class="range-container">
			<input
				id="loess-span"
				type="range"
				min="0.1"
				max="1.0"
				step="0.05"
				bind:value={$loessSpan}
				class="range-input"
			/>
		</div>
		<div class="range-values">
			{$loessSpan.toFixed(2)} (0.1=very smooth, 1.0=less smooth)
		</div>
	</div>
</div>

<style>
	.plot-controls {
		margin-bottom: 1.5rem;
	}

	h4 {
		margin: 0 0 0.5rem 0;
		color: #333;
		font-size: 1rem;
		font-weight: 600;
	}

	.no-players {
		color: #666;
		font-style: italic;
		font-size: 0.9rem;
		margin: 0.5rem 0;
	}

	.player-list {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		margin-bottom: 1rem;
	}

	.player-item {
		display: flex;
		gap: 0.5rem;
		align-items: center;
	}

	.player-toggle {
		flex: 1;
		padding: 0.5rem 0.75rem;
		border-radius: 4px;
		border: none;
		cursor: pointer;
		font-size: 0.9rem;
		font-weight: 500;
		transition: all 0.3s ease;
		min-height: 36px;
	}

	.player-toggle:hover {
		opacity: 0.9;
		transform: translateY(-1px);
	}

	.remove-btn {
		padding: 0.25rem 0.5rem;
		background-color: #dc3545;
		color: white;
		border: none;
		border-radius: 3px;
		cursor: pointer;
		font-size: 0.8rem;
		transition: background-color 0.3s ease;
	}

	.remove-btn:hover {
		background-color: #c82333;
	}

	hr {
		border: none;
		border-top: 1px solid #ddd;
		margin: 1rem 0;
	}

	.control-group {
		margin-bottom: 1rem;
	}

	label {
		display: block;
		margin-bottom: 0.25rem;
		color: #333;
		font-size: 0.9rem;
		font-weight: 500;
	}

	.range-container {
		position: relative;
		height: 20px;
		margin-bottom: 0.5rem;
	}

	.range-input {
		position: absolute;
		width: 100%;
		height: 20px;
		-webkit-appearance: none;
		appearance: none;
		background: transparent;
		pointer-events: none;
	}

	.range-input::-webkit-slider-track {
		width: 100%;
		height: 4px;
		background: #ddd;
		border-radius: 2px;
	}

	.range-input::-webkit-slider-thumb {
		-webkit-appearance: none;
		appearance: none;
		height: 16px;
		width: 16px;
		border-radius: 8px;
		background: #007bff;
		cursor: pointer;
		pointer-events: all;
		border: 2px solid white;
		box-shadow: 0 1px 3px rgba(0,0,0,0.3);
	}

	.range-input::-moz-range-track {
		width: 100%;
		height: 4px;
		background: #ddd;
		border-radius: 2px;
		border: none;
	}

	.range-input::-moz-range-thumb {
		height: 16px;
		width: 16px;
		border-radius: 8px;
		background: #007bff;
		cursor: pointer;
		pointer-events: all;
		border: 2px solid white;
		box-shadow: 0 1px 3px rgba(0,0,0,0.3);
	}

	.range-values {
		text-align: center;
		font-size: 0.8rem;
		color: #666;
		margin-top: 0.25rem;
	}

	.checkbox-label {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		cursor: pointer;
		margin-bottom: 0;
	}

	.checkbox-label input[type="checkbox"] {
		margin: 0;
	}
</style>
