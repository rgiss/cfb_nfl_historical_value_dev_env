<script lang="ts">
	import { selectedMetric, metricOptions } from '$lib/stores/playerStore';
</script>

<div class="metric-selector">
	<h4>Select Metric to Plot:</h4>
	<select bind:value={$selectedMetric} class="metric-select">
		{#each metricOptions as option}
			<option value={option.value}>{option.label}</option>
		{/each}
	</select>
</div>

<style>
	.metric-selector {
		margin-bottom: 1.5rem;
	}

	h4 {
		margin: 0 0 0.5rem 0;
		color: #333;
		font-size: 1rem;
		font-weight: 600;
	}

	.metric-select {
		width: 100%;
		padding: 0.5rem;
		border: 1px solid #ddd;
		border-radius: 4px;
		background-color: white;
		font-size: 0.9rem;
		color: #333;
	}

	.metric-select:focus {
		outline: none;
		border-color: #007bff;
		box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
	}
</style>
