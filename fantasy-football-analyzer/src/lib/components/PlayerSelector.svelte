<script lang="ts">
	import { data, getPlayerNames, getPlayerData } from '$lib/stores/dataStore';
	import { selectedPlayers, addPlayer, selectedTeam } from '$lib/stores/playerStore';
	import { getPlayerColor, filterByTeam } from '$lib/utils/dataProcessor';
	import { onMount } from 'svelte';

	let searchTerm = '';
	let filteredPlayers: string[] = [];
	let showDropdown = false;
	let selectedIndex = -1; // Track which item is highlighted
	let searchInput: HTMLInputElement; // Reference to the input element
	let dropdownContainer: HTMLDivElement; // Reference to the dropdown container

	// Close dropdown when clicking outside
	function handleClickOutside(event: MouseEvent) {
		if (dropdownContainer && !dropdownContainer.contains(event.target as Node)) {
			showDropdown = false;
			selectedIndex = -1;
		}
	}

	onMount(() => {
		document.addEventListener('click', handleClickOutside);
		return () => {
			document.removeEventListener('click', handleClickOutside);
		};
	});

	$: {
		if (searchTerm.length > 0) {
			// First filter by team if a team is selected
			let teamFilteredData = $selectedTeam ? filterByTeam($data, $selectedTeam) : $data;
			
			const playerNames = getPlayerNames(teamFilteredData);
			filteredPlayers = playerNames
				.filter(name => 
					name.toLowerCase().includes(searchTerm.toLowerCase())
				)
				.slice(0, 10); // Limit to 10 results
			showDropdown = filteredPlayers.length > 0;
			selectedIndex = -1; // Reset selection when search changes
		} else {
			filteredPlayers = [];
			showDropdown = false;
			selectedIndex = -1;
		}
	}

	function selectPlayer(playerName: string) {
		if (!$selectedPlayers.has(playerName)) {
			const playerData = getPlayerData($data, playerName);
			const color = getPlayerColor(playerData);
			addPlayer(playerName, color);
		}
		searchTerm = '';
		showDropdown = false;
		selectedIndex = -1;
		searchInput?.focus(); // Keep focus on input for continued searching
	}

	function handleKeydown(event: KeyboardEvent) {
		if (!showDropdown || filteredPlayers.length === 0) {
			if (event.key === 'Enter' && filteredPlayers.length > 0) {
				selectPlayer(filteredPlayers[0]);
			}
			return;
		}

		switch (event.key) {
			case 'ArrowDown':
				event.preventDefault();
				selectedIndex = selectedIndex < filteredPlayers.length - 1 ? selectedIndex + 1 : 0;
				break;
			case 'ArrowUp':
				event.preventDefault();
				selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : filteredPlayers.length - 1;
				break;
			case 'Enter':
				event.preventDefault();
				if (selectedIndex >= 0 && selectedIndex < filteredPlayers.length) {
					selectPlayer(filteredPlayers[selectedIndex]);
				} else if (filteredPlayers.length > 0) {
					selectPlayer(filteredPlayers[0]);
				}
				break;
			case 'Escape':
				event.preventDefault();
				showDropdown = false;
				selectedIndex = -1;
				break;
		}
	}
</script>

<div class="player-selector">
	<h4>Player Selection</h4>
	<div class="search-container" bind:this={dropdownContainer}>
		<input
			type="text"
			bind:value={searchTerm}
			bind:this={searchInput}
			on:keydown={handleKeydown}
			placeholder="Type a player name..."
			class="player-search"
		/>
		{#if showDropdown}
			<div class="dropdown">
				{#each filteredPlayers as player, index}
					<button
						type="button"
						class="dropdown-item"
						class:highlighted={index === selectedIndex}
						on:click={() => selectPlayer(player)}
						on:mouseenter={() => selectedIndex = index}
					>
						{player}
					</button>
				{/each}
			</div>
		{/if}
	</div>
</div>

<style>
	.player-selector {
		margin-bottom: 1.5rem;
	}

	h4 {
		margin: 0 0 0.5rem 0;
		color: #333;
		font-size: 1rem;
		font-weight: 600;
	}

	.search-container {
		position: relative;
	}

	.player-search {
		width: 100%;
		padding: 0.5rem;
		border: 1px solid #ddd;
		border-radius: 4px;
		background-color: white;
		font-size: 0.9rem;
		color: #333;
		box-sizing: border-box;
	}

	.player-search:focus {
		outline: none;
		border-color: #007bff;
		box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
	}

	.dropdown {
		position: absolute;
		top: 100%;
		left: 0;
		right: 0;
		background: white;
		border: 1px solid #ddd;
		border-top: none;
		border-radius: 0 0 4px 4px;
		max-height: 200px;
		overflow-y: auto;
		z-index: 1000;
		box-shadow: 0 2px 4px rgba(0,0,0,0.1);
	}

	.dropdown-item {
		width: 100%;
		padding: 0.5rem;
		border: none;
		background: none;
		text-align: left;
		cursor: pointer;
		font-size: 0.9rem;
		color: #333;
		transition: background-color 0.2s ease;
	}

	.dropdown-item:hover:not(.highlighted) {
		background-color: #f8f9fa;
	}

	.dropdown-item:focus {
		outline: none;
		background-color: #e9ecef;
	}

	.dropdown-item.highlighted {
		background-color: #007bff;
		color: white;
	}

	.dropdown-item.highlighted:hover {
		background-color: #0056b3;
	}
</style>
