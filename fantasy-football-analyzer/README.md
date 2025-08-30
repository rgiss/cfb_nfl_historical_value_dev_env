# Fantasy Football Player Analysis - Svelte App

A modern web application for analyzing fantasy football player performance, built with SvelteKit. This is a Svelte conversion of the original R Shiny application.

## Features

### 🏈 Player Analysis
- Search and add players to analyze their performance trajectories
- Compare multiple players on the same chart
- Toggle player visibility and remove players dynamically
- Age-based performance trend analysis

### 📊 Interactive Visualizations
- Historical career trajectory plots using D3.js
- LOESS regression smoothing for trend analysis
- Customizable age range filtering
- Hover tooltips with detailed player information
- Responsive chart design

### ⚙️ Customizable Settings
- **Scoring Settings**: Adjust points for receiving/rushing/passing yards, touchdowns, and receptions
- **League Settings**: Configure team counts, starting positions, bench depth, etc.
- **Tight End Premium**: Additional points for tight end receptions

### 📈 Performance Metrics
Choose from 29 different performance metrics including:
- Fantasy Points Per Game
- Snap Share
- Target Share, Reception Share
- Yards per reception/rush/completion
- Touchdowns per game
- Value over replacement metrics
- And many more...

### 📋 Current Player Values
- Sortable table of 2024 player valuations
- Export data to CSV
- Search and filter functionality
- Color-coded positive/negative values

## Tech Stack

- **Frontend**: SvelteKit with TypeScript
- **Visualization**: D3.js for charts and graphs
- **Data Processing**: Papa Parse for CSV handling
- **Styling**: Custom CSS with responsive design
- **Build Tool**: Vite

## Project Structure

```
src/
├── lib/
│   ├── components/          # Reusable Svelte components
│   │   ├── FantasyPlot.svelte      # Main visualization component
│   │   ├── PlayerSelector.svelte   # Player search and selection
│   │   ├── MetricSelector.svelte   # Performance metric chooser
│   │   ├── PlotControls.svelte     # Age range and display controls
│   │   ├── PlayerTable.svelte      # Current player values table
│   │   ├── ScoringSettings.svelte  # Fantasy scoring configuration
│   │   └── LeagueSettings.svelte   # League format settings
│   ├── stores/              # Svelte stores for state management
│   │   ├── dataStore.ts            # CSV data loading and processing
│   │   ├── playerStore.ts          # Selected players and metrics
│   │   └── settingsStore.ts        # Scoring and league settings
│   └── utils/               # Utility functions
│       └── dataProcessor.ts        # Data transformation and calculations
├── routes/
│   └── +page.svelte        # Main application page
└── static/
    └── cfb_nfl_historical_value_estimate.csv  # Player data
```

## Development

### Prerequisites
- Node.js 18+
- npm or yarn

### Installation
```bash
cd fantasy-football-analyzer
npm install
```

### Development Server
```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to view the application.

### Build for Production
```bash
npm run build
npm run preview
```

## Data

The application uses historical NFL and college football player data from 1999-2024, including:
- Player performance metrics by season
- Age-adjusted statistics
- Team colors for visualization
- Fantasy point projections
- Value over replacement calculations

## Key Differences from R Shiny Version

### Advantages of Svelte Implementation:
1. **Performance**: Faster loading and more responsive interactions
2. **Modern UI**: Better mobile responsiveness and cleaner design
3. **Type Safety**: Full TypeScript support for better development experience
4. **Deployment**: Easy deployment to any static hosting service
5. **Maintainability**: Cleaner component architecture and separation of concerns

### Feature Parity:
- ✅ All major functionality from the R Shiny app has been replicated
- ✅ Interactive plotting with multiple players
- ✅ Customizable scoring and league settings
- ✅ Player value tables with export functionality
- ✅ Age range filtering and point toggling

## Usage

1. **Navigate to "Historical Career Trajectory"** tab
2. **Select a performance metric** from the dropdown
3. **Search and add players** using the player selector
4. **Adjust age range** and toggle data points as needed
5. **Customize scoring settings** to match your league
6. **View current player values** in the dedicated tab

## Contributing

This project was converted from an R Shiny application to provide a modern web interface for fantasy football analysis. Contributions are welcome!

## License

This project is for educational and analytical purposes.
