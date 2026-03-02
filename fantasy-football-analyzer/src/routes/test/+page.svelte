<script lang="ts">
	import { onMount } from 'svelte';
	import { generateLoessRegression } from '$lib/utils/dataProcessor';
	import type { ProcessedPlayerData } from '$lib/utils/dataProcessor';

	let testResults: { age: number; value: number }[] = [];

	onMount(() => {
		// Create test data with some realistic player performance curve including nulls
		const testData: ProcessedPlayerData[] = [
			{ approximate_age: 22, plot_metric: 8.5 } as ProcessedPlayerData,
			{ approximate_age: 23, plot_metric: 12.2 } as ProcessedPlayerData,
			{ approximate_age: 24, plot_metric: null as any } as ProcessedPlayerData, // Missing data point
			{ approximate_age: 25, plot_metric: 18.1 } as ProcessedPlayerData,
			{ approximate_age: 26, plot_metric: 19.5 } as ProcessedPlayerData,
			{ approximate_age: 27, plot_metric: 0 } as ProcessedPlayerData, // Zero (should be filtered)
			{ approximate_age: 28, plot_metric: 19.8 } as ProcessedPlayerData,
			{ approximate_age: 29, plot_metric: undefined as any } as ProcessedPlayerData, // Missing data point
			{ approximate_age: 30, plot_metric: 17.2 } as ProcessedPlayerData,
			{ approximate_age: 31, plot_metric: 15.1 } as ProcessedPlayerData,
			{ approximate_age: 32, plot_metric: 12.8 } as ProcessedPlayerData,
		];

		console.log('Original test data:', testData);
		testResults = generateLoessRegression(testData, 0.7);
		console.log('LOESS Test Results:', testResults);
	});
</script>

<h1>LOESS Test Page</h1>
<p>Testing the improved LOESS regression implementation with null value handling.</p>
<p><strong>Test includes:</strong> null values, undefined values, and zeros (all should be filtered out)</p>

{#if testResults.length > 0}
	<div>
		<h3>Test Results ({testResults.length} points generated):</h3>
		<div style="font-family: monospace; font-size: 12px;">
			{#each testResults as point, i}
				<div>Point {i + 1}: Age {point.age.toFixed(1)} → Value {point.value.toFixed(2)}</div>
			{/each}
		</div>
	</div>
{:else}
	<p>Loading test...</p>
{/if}

<p><a href="/">← Back to main app</a></p>
