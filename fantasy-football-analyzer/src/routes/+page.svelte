<script lang="ts">
	import { onMount } from 'svelte';
	import PlayerSelector from '$lib/components/PlayerSelector.svelte';
	import MetricSelector from '$lib/components/MetricSelector.svelte';
	import TeamSelector from '$lib/components/TeamSelector.svelte';
	import FantasyPlot from '$lib/components/FantasyPlot.svelte';
	import PlayerTable from '$lib/components/PlayerTable.svelte';
	import ScoringSettings from '$lib/components/ScoringSettings.svelte';
	import LeagueSettings from '$lib/components/LeagueSettings.svelte';
	import PlotControls from '$lib/components/PlotControls.svelte';
	import { loadData, isLoading, error } from '$lib/stores/dataStore';
	import { showScoringSettings, showLeagueSettings } from '$lib/stores/settingsStore';
	import { selectedTeam } from '$lib/stores/playerStore';

	let activeTab = 'description';

	onMount(async () => {
		await loadData();
	});
</script>

<svelte:head>
	<title>Fantasy Football Player Analysis</title>
</svelte:head>

<div class="app-container">
	<header>
		<h1>Fantasy Football Player Analysis</h1>
	</header>

	{#if $error}
		<div class="error-message">
			<p>Error loading data: {$error}</p>
		</div>
	{/if}

	{#if $isLoading}
		<div class="loading-message">
			<p>Loading data...</p>
		</div>
	{:else}
		<nav class="tab-nav">
			<button 
				class="tab-button" 
				class:active={activeTab === 'description'}
				on:click={() => activeTab = 'description'}
			>
				Description
			</button>
			<button 
				class="tab-button" 
				class:active={activeTab === 'trajectory'}
				on:click={() => activeTab = 'trajectory'}
			>
				Historical Career Trajectory
			</button>
			<button 
				class="tab-button" 
				class:active={activeTab === 'values'}
				on:click={() => activeTab = 'values'}
			>
				Current Player Values
			</button>
		</nav>

		<div class="tab-content">
			{#if activeTab === 'description'}
				<div class="description-panel">
					<h3>Fantasy Football Player Analysis Tool</h3>
					<p>This application allows you to analyze and compare fantasy football performance across players' careers.</p>
					
					<h4>Key Features:</h4>
					<ul>
						<li>Compare historical performance trajectories</li>
						<li>View current player valuations</li>
						<li>Analyze age-based performance trends</li>
						<li>Customize scoring and league settings</li>
					</ul>
					
					<p>Navigate to the 'Historical Career Trajectory' tab to begin your analysis.</p>
				</div>

			{:else if activeTab === 'trajectory'}
				<div class="trajectory-panel">
					<aside class="sidebar">
						<div class="control-panel">
							<MetricSelector />
							<TeamSelector on:teamSelected={(e) => selectedTeam.set(e.detail.team)} />
							<PlayerSelector />
							<PlotControls />

							<div class="settings-toggles">
								<button 
									class="settings-toggle-btn"
									on:click={() => showScoringSettings.update(v => !v)}
								>
									{$showScoringSettings ? 'Hide' : 'Show'} Scoring Settings
								</button>
								{#if $showScoringSettings}
									<ScoringSettings />
								{/if}

								<button 
									class="settings-toggle-btn"
									on:click={() => showLeagueSettings.update(v => !v)}
								>
									{$showLeagueSettings ? 'Hide' : 'Show'} League Settings
								</button>
								{#if $showLeagueSettings}
									<LeagueSettings />
								{/if}
							</div>
						</div>
					</aside>

					<main class="main-content">
						<div class="plot-container">
							<FantasyPlot />
						</div>
					</main>
				</div>

			{:else if activeTab === 'values'}
				<div class="values-panel">
					<PlayerTable />
				</div>
			{/if}
		</div>
	{/if}
</div>

<style>
	.app-container {
		max-width: 1400px;
		margin: 0 auto;
		padding: 1rem;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
	}

	header {
		text-align: center;
		margin-bottom: 2rem;
	}

	h1 {
		color: #333;
		margin: 0;
	}

	.error-message, .loading-message {
		text-align: center;
		padding: 2rem;
		background-color: #f8f9fa;
		border-radius: 8px;
		margin: 1rem 0;
	}

	.error-message {
		background-color: #f8d7da;
		color: #721c24;
		border: 1px solid #f5c6cb;
	}

	.tab-nav {
		display: flex;
		border-bottom: 2px solid #e0e0e0;
		margin-bottom: 1rem;
	}

	.tab-button {
		padding: 0.75rem 1.5rem;
		border: none;
		background: none;
		cursor: pointer;
		font-size: 1rem;
		border-bottom: 3px solid transparent;
		transition: all 0.3s ease;
		color: #666;
	}

	.tab-button:hover {
		background-color: #f8f9fa;
		color: #333;
	}

	.tab-button.active {
		border-bottom-color: #007bff;
		color: #007bff;
		font-weight: 600;
	}

	.trajectory-panel {
		display: grid;
		grid-template-columns: 300px 1fr;
		gap: 1rem;
		min-height: 600px;
	}

	.sidebar {
		background-color: #f8f9fa;
		border-radius: 8px;
		padding: 1rem;
		border: 1px solid #ddd;
	}

	.control-panel {
		position: sticky;
		top: 20px;
	}

	.main-content {
		display: flex;
		flex-direction: column;
	}

	.plot-container {
		border: 1px solid #ddd;
		border-radius: 8px;
		padding: 1rem;
		background-color: white;
		min-height: 600px;
	}

	.description-panel, .values-panel {
		padding: 2rem;
		background-color: white;
		border-radius: 8px;
		border: 1px solid #ddd;
	}

	.settings-toggles {
		margin-top: 1.5rem;
	}

	.settings-toggle-btn {
		width: 100%;
		padding: 0.75rem;
		margin-bottom: 0.5rem;
		background-color: #007bff;
		color: white;
		border: none;
		border-radius: 4px;
		cursor: pointer;
		font-size: 0.9rem;
		transition: background-color 0.3s ease;
	}

	.settings-toggle-btn:hover {
		background-color: #0056b3;
	}

	h3 {
		color: #333;
		margin-bottom: 1rem;
	}

	h4 {
		margin: 1rem 0 0.5rem 0;
		color: #555;
	}

	ul {
		padding-left: 1.5rem;
	}

	li {
		margin-bottom: 0.5rem;
		color: #666;
	}

	p {
		color: #666;
		line-height: 1.6;
	}

	/* Responsive design */
	@media (max-width: 768px) {
		.trajectory-panel {
			grid-template-columns: 1fr;
			gap: 1rem;
		}
		
		.sidebar {
			position: relative;
		}
		
		.control-panel {
			position: static;
		}
	}
</style>
