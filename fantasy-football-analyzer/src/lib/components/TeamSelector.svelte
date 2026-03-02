<script lang="ts">
	import { createEventDispatcher } from 'svelte';

	const dispatch = createEventDispatcher<{
		teamSelected: { team: string; teamName: string };
	}>();

	let isOpen = false;
	let selectedTeam = '';

	// NFL team data with nflfastR logo URLs
	const nflTeams = [
		{ abbr: 'ARI', name: 'Arizona Cardinals', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/ari.png' },
		{ abbr: 'ATL', name: 'Atlanta Falcons', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/atl.png' },
		{ abbr: 'BAL', name: 'Baltimore Ravens', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/bal.png' },
		{ abbr: 'BUF', name: 'Buffalo Bills', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/buf.png' },
		{ abbr: 'CAR', name: 'Carolina Panthers', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/car.png' },
		{ abbr: 'CHI', name: 'Chicago Bears', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/chi.png' },
		{ abbr: 'CIN', name: 'Cincinnati Bengals', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/cin.png' },
		{ abbr: 'CLE', name: 'Cleveland Browns', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/cle.png' },
		{ abbr: 'DAL', name: 'Dallas Cowboys', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/dal.png' },
		{ abbr: 'DEN', name: 'Denver Broncos', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/den.png' },
		{ abbr: 'DET', name: 'Detroit Lions', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/det.png' },
		{ abbr: 'GB', name: 'Green Bay Packers', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/gb.png' },
		{ abbr: 'HOU', name: 'Houston Texans', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/hou.png' },
		{ abbr: 'IND', name: 'Indianapolis Colts', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/ind.png' },
		{ abbr: 'JAX', name: 'Jacksonville Jaguars', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/jax.png' },
		{ abbr: 'KC', name: 'Kansas City Chiefs', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/kc.png' },
		{ abbr: 'LV', name: 'Las Vegas Raiders', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/lv.png' },
		{ abbr: 'LAC', name: 'Los Angeles Chargers', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/lac.png' },
		{ abbr: 'LAR', name: 'Los Angeles Rams', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/lar.png' },
		{ abbr: 'MIA', name: 'Miami Dolphins', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/mia.png' },
		{ abbr: 'MIN', name: 'Minnesota Vikings', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/min.png' },
		{ abbr: 'NE', name: 'New England Patriots', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/ne.png' },
		{ abbr: 'NO', name: 'New Orleans Saints', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/no.png' },
		{ abbr: 'NYG', name: 'New York Giants', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/nyg.png' },
		{ abbr: 'NYJ', name: 'New York Jets', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/nyj.png' },
		{ abbr: 'PHI', name: 'Philadelphia Eagles', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/phi.png' },
		{ abbr: 'PIT', name: 'Pittsburgh Steelers', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/pit.png' },
		{ abbr: 'SF', name: 'San Francisco 49ers', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/sf.png' },
		{ abbr: 'SEA', name: 'Seattle Seahawks', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/sea.png' },
		{ abbr: 'TB', name: 'Tampa Bay Buccaneers', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/tb.png' },
		{ abbr: 'TEN', name: 'Tennessee Titans', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/ten.png' },
		{ abbr: 'WAS', name: 'Washington Commanders', logo: 'https://a.espncdn.com/i/teamlogos/nfl/500/wsh.png' }
	];

	function selectTeam(team: typeof nflTeams[0]) {
		selectedTeam = team.abbr;
		isOpen = false;
		dispatch('teamSelected', { 
			team: team.abbr, 
			teamName: team.name 
		});
	}

	function toggleDropdown() {
		isOpen = !isOpen;
	}

	// Close dropdown when clicking outside
	function handleClickOutside(event: MouseEvent) {
		const target = event.target as HTMLElement;
		if (!target.closest('.team-dropdown')) {
			isOpen = false;
		}
	}

	$: if (typeof window !== 'undefined') {
		if (isOpen) {
			window.addEventListener('click', handleClickOutside);
		} else {
			window.removeEventListener('click', handleClickOutside);
		}
	}
</script>

<div class="team-selector">
	<h4>Filter by NFL Team:</h4>
	<div class="team-dropdown">
		<button class="dropdown-toggle" on:click={toggleDropdown}>
			{#if selectedTeam}
				{@const team = nflTeams.find(t => t.abbr === selectedTeam)}
				{#if team}
					<img src={team.logo} alt={team.name} class="team-logo-small" />
					<span>{team.name}</span>
				{/if}
			{:else}
				<span>Select a team...</span>
			{/if}
			<span class="dropdown-arrow" class:open={isOpen}>▼</span>
		</button>

		{#if isOpen}
			<div class="dropdown-menu">
				<button 
					class="team-option clear-option"
					on:click={() => {
						selectedTeam = '';
						isOpen = false;
						dispatch('teamSelected', { team: '', teamName: '' });
					}}
				>
					<span>All Teams</span>
				</button>
				{#each nflTeams as team}
					<button 
						class="team-option"
						class:selected={selectedTeam === team.abbr}
						on:click={() => selectTeam(team)}
					>
						<img src={team.logo} alt={team.name} class="team-logo" />
						<span class="team-info">
							<span class="team-name">{team.name}</span>
							<span class="team-abbr">{team.abbr}</span>
						</span>
					</button>
				{/each}
			</div>
		{/if}
	</div>
</div>

<style>
	.team-selector {
		margin-bottom: 1.5rem;
	}

	h4 {
		margin: 0 0 0.5rem 0;
		color: #333;
		font-size: 1rem;
		font-weight: 600;
	}

	.team-dropdown {
		position: relative;
		width: 100%;
	}

	.dropdown-toggle {
		width: 100%;
		padding: 0.75rem;
		border: 1px solid #ddd;
		border-radius: 4px;
		background-color: white;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.9rem;
		transition: all 0.2s ease;
	}

	.dropdown-toggle:hover {
		border-color: #007bff;
		background-color: #f8f9fa;
	}

	.dropdown-toggle:focus {
		outline: none;
		border-color: #007bff;
		box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
	}

	.team-logo-small {
		width: 24px;
		height: 24px;
		object-fit: contain;
	}

	.dropdown-arrow {
		margin-left: auto;
		transition: transform 0.2s ease;
		font-size: 0.8rem;
		color: #666;
	}

	.dropdown-arrow.open {
		transform: rotate(180deg);
	}

	.dropdown-menu {
		position: absolute;
		top: 100%;
		left: 0;
		right: 0;
		background-color: white;
		border: 1px solid #ddd;
		border-top: none;
		border-radius: 0 0 4px 4px;
		max-height: 300px;
		overflow-y: auto;
		z-index: 1000;
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
	}

	.team-option {
		width: 100%;
		padding: 0.75rem;
		border: none;
		background-color: white;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 0.75rem;
		font-size: 0.9rem;
		transition: background-color 0.2s ease;
		text-align: left;
	}

	.team-option:hover {
		background-color: #f8f9fa;
	}

	.team-option.selected {
		background-color: #e3f2fd;
	}

	.clear-option {
		border-bottom: 1px solid #eee;
		font-weight: 600;
		color: #666;
	}

	.team-logo {
		width: 32px;
		height: 32px;
		object-fit: contain;
		flex-shrink: 0;
	}

	.team-info {
		display: flex;
		flex-direction: column;
		gap: 0.1rem;
	}

	.team-name {
		font-weight: 600;
		color: #333;
	}

	.team-abbr {
		font-size: 0.8rem;
		color: #666;
		font-weight: 500;
	}

	/* Scrollbar styling */
	.dropdown-menu::-webkit-scrollbar {
		width: 6px;
	}

	.dropdown-menu::-webkit-scrollbar-track {
		background: #f1f1f1;
	}

	.dropdown-menu::-webkit-scrollbar-thumb {
		background: #c1c1c1;
		border-radius: 3px;
	}

	.dropdown-menu::-webkit-scrollbar-thumb:hover {
		background: #a8a8a8;
	}
</style>
