<script lang="ts">
	import { onMount, afterUpdate } from 'svelte';
	import * as d3 from 'd3';
	import { data } from '$lib/stores/dataStore';
		import { 
		selectedPlayers, 
		selectedMetric, 
		ageRange, 
		showPoints,
		loessSpan
	} from '$lib/stores/playerStore';
	import { scoringSettings } from '$lib/stores/settingsStore';
	import { 
		calculateCustomFantasyPoints, 
		getPlotMetric, 
		filterByAgeRange,
		generateLoessRegression,
		getMetricLabel 
	} from '$lib/utils/dataProcessor';

	let svgElement: SVGSVGElement;
	let plotContainer: HTMLDivElement;

	// Chart dimensions
	const margin = { top: 20, right: 80, bottom: 50, left: 80 };
	let width = 800;
	let height = 500;
	let innerWidth: number;
	let innerHeight: number;

	$: innerWidth = width - margin.left - margin.right;
	$: innerHeight = height - margin.bottom - margin.top;

	// Reactive data processing
	$: processedData = calculateCustomFantasyPoints($data, $scoringSettings);
	$: plotData = getPlotMetric(processedData, $selectedMetric, $scoringSettings);
	$: filteredData = filterByAgeRange(plotData, $ageRange);
	$: metricLabel = getMetricLabel($selectedMetric);

	// Chart scales
	let xScale: d3.ScaleLinear<number, number>;
	let yScale: d3.ScaleLinear<number, number>;

	$: {
		if (filteredData.length > 0) {
			xScale = d3.scaleLinear()
				.domain($ageRange)
				.range([0, innerWidth]);

			const yExtent = d3.extent(filteredData, d => d.plot_metric) as [number, number];
			const yPadding = (yExtent[1] - yExtent[0]) * 0.1;
			
			yScale = d3.scaleLinear()
				.domain([
					Math.min(0, yExtent[0] - yPadding),
					yExtent[1] + yPadding
				])
				.range([innerHeight, 0]);
		}
	}

	// Line generator
	const line = d3.line<{age: number, value: number}>()
		.x(d => xScale(d.age))
		.y(d => yScale(d.value))
		.curve(d3.curveCardinal);

	function updateChart() {
		if (!svgElement || !xScale || !yScale) return;

		const svg = d3.select(svgElement);
		svg.selectAll("*").remove();

		// Create main group
		const g = svg
			.append("g")
			.attr("transform", `translate(${margin.left},${margin.top})`);

		// Add zero line
		g.append("line")
			.attr("x1", 0)
			.attr("x2", innerWidth)
			.attr("y1", yScale(0))
			.attr("y2", yScale(0))
			.attr("stroke", "#000")
			.attr("stroke-width", 0.5)
			.attr("opacity", 0.7);

		// Add grid lines
		const xAxis = d3.axisBottom(xScale)
			.tickSize(-innerHeight)
			.tickFormat(() => "");
		
		const yAxis = d3.axisLeft(yScale)
			.tickSize(-innerWidth)
			.tickFormat(() => "");

		g.append("g")
			.attr("class", "grid")
			.attr("transform", `translate(0,${innerHeight})`)
			.call(xAxis)
			.selectAll("line")
			.attr("stroke", "#e0e0e0")
			.attr("stroke-width", 1);

		g.append("g")
			.attr("class", "grid")
			.call(yAxis)
			.selectAll("line")
			.attr("stroke", "#f0f0f0")
			.attr("stroke-width", 1);

		// Plot data for each selected player
		for (const [playerName, playerInfo] of $selectedPlayers.entries()) {
			if (!playerInfo.visible) continue;

			const playerData = filteredData.filter(d => d.player_display_name === playerName);
			if (playerData.length === 0) continue;

			// Add LOESS regression line
			const regressionData = generateLoessRegression(playerData, $loessSpan);
			if (regressionData.length > 1) {
				g.append("path")
					.datum(regressionData)
					.attr("fill", "none")
					.attr("stroke", playerInfo.color)
					.attr("stroke-width", 2)
					.attr("d", line);
			}

			// Add scatter points if enabled
			if ($showPoints) {
				g.selectAll(`.points-${playerName.replace(/[^a-zA-Z0-9]/g, '_')}`)
					.data(playerData)
					.enter()
					.append("circle")
					.attr("class", `points-${playerName.replace(/[^a-zA-Z0-9]/g, '_')}`)
					.attr("cx", d => xScale(d.approximate_age))
					.attr("cy", d => yScale(d.plot_metric))
					.attr("r", 2)
					.attr("fill", playerInfo.color)
					.attr("opacity", 0.6)
					.append("title")
					.text(d => `${d.player_display_name}\nAge: ${d.approximate_age}\n${metricLabel}: ${d.plot_metric.toFixed(2)}\nYear: ${d.year}`);
			}
		}

		// Add axes
		g.append("g")
			.attr("transform", `translate(0,${innerHeight})`)
			.call(d3.axisBottom(xScale))
			.append("text")
			.attr("x", innerWidth / 2)
			.attr("y", 40)
			.attr("fill", "black")
			.style("text-anchor", "middle")
			.style("font-size", "14px")
			.text("Age");

		g.append("g")
			.call(d3.axisLeft(yScale))
			.append("text")
			.attr("transform", "rotate(-90)")
			.attr("y", -60)
			.attr("x", -innerHeight / 2)
			.attr("fill", "black")
			.style("text-anchor", "middle")
			.style("font-size", "14px")
			.text(metricLabel);

		// Add title
		svg.append("text")
			.attr("x", width / 2)
			.attr("y", 20)
			.attr("text-anchor", "middle")
			.style("font-size", "16px")
			.style("font-weight", "bold")
			.text(`${metricLabel} vs. Age`);

		// Add legend
		const legend = svg.append("g")
			.attr("class", "legend")
			.attr("transform", `translate(${width - margin.right + 10}, ${margin.top})`);

		let legendY = 0;
		for (const [playerName, playerInfo] of $selectedPlayers.entries()) {
			if (!playerInfo.visible) continue;

			const legendItem = legend.append("g")
				.attr("transform", `translate(0, ${legendY})`);

			legendItem.append("line")
				.attr("x1", 0)
				.attr("x2", 15)
				.attr("y1", 0)
				.attr("y2", 0)
				.attr("stroke", playerInfo.color)
				.attr("stroke-width", 2);

			legendItem.append("text")
				.attr("x", 20)
				.attr("y", 0)
				.attr("dy", "0.35em")
				.style("font-size", "12px")
				.text(playerName);

			legendY += 20;
		}
	}

	// Update chart when data changes
	$: if (svgElement && filteredData && $selectedPlayers) {
		updateChart();
	}

	onMount(() => {
		// Set initial dimensions based on container
		if (plotContainer) {
			const rect = plotContainer.getBoundingClientRect();
			width = Math.max(800, rect.width - 20);
			height = 500;
		}

		// Handle window resize
		const handleResize = () => {
			if (plotContainer) {
				const rect = plotContainer.getBoundingClientRect();
				width = Math.max(800, rect.width - 20);
				updateChart();
			}
		};

		window.addEventListener('resize', handleResize);
		
		return () => {
			window.removeEventListener('resize', handleResize);
		};
	});

	afterUpdate(() => {
		updateChart();
	});
</script>

<div bind:this={plotContainer} class="plot-container">
	{#if $selectedPlayers.size === 0}
		<div class="empty-state">
			<h3>No Players Selected</h3>
			<p>Add players using the search box to start analyzing their performance trajectories.</p>
		</div>
	{:else}
		<svg
			bind:this={svgElement}
			{width}
			{height}
			class="fantasy-plot"
		></svg>
	{/if}
</div>

<style>
	.plot-container {
		width: 100%;
		height: 100%;
		min-height: 500px;
		display: flex;
		align-items: center;
		justify-content: center;
		background-color: white;
	}

	.fantasy-plot {
		max-width: 100%;
		height: auto;
	}

	.empty-state {
		text-align: center;
		color: #666;
		padding: 2rem;
	}

	.empty-state h3 {
		margin: 0 0 1rem 0;
		color: #333;
	}

	.empty-state p {
		margin: 0;
		line-height: 1.5;
	}

	:global(.fantasy-plot .grid .domain) {
		stroke: none;
	}

	:global(.fantasy-plot .axis) {
		font-size: 12px;
	}

	:global(.fantasy-plot .legend text) {
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
	}
</style>
