import streamlit as st
import pandas as pd
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
import numpy as np
from scipy import stats
from sklearn.preprocessing import PolynomialFeatures
from sklearn.linear_model import LinearRegression
from sklearn.pipeline import Pipeline
import base64
from io import BytesIO

# Page config
st.set_page_config(
    page_title="Fantasy Football Player Analysis",
    page_icon="🏈",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .plot-container {
        border: 1px solid #ddd;
        border-radius: 5px;
        padding: 10px;
        margin-bottom: 15px;
        background-color: white;
    }
    .control-panel {
        padding: 15px;
        background-color: #f8f9fa;
        border-radius: 5px;
        border: 1px solid #ddd;
        margin-bottom: 15px;
    }
    .player-tag {
        display: inline-block;
        padding: 5px 10px;
        margin: 2px;
        border-radius: 15px;
        font-size: 12px;
        font-weight: bold;
        cursor: pointer;
    }
    .stSelectbox > div > div > div {
        background-color: white;
    }
</style>
""", unsafe_allow_html=True)

# Initialize session state
if 'selected_players' not in st.session_state:
    st.session_state.selected_players = {}
if 'player_visibility' not in st.session_state:
    st.session_state.player_visibility = {}

@st.cache_data
def load_data():
    """Load the fantasy football data"""
    try:
        df = pd.read_csv("cfb_nfl_historical_value_estimate.csv")
        return df
    except FileNotFoundError:
        st.error("Data file 'cfb_nfl_historical_value_estimate.csv' not found. Please ensure the file is in the same directory as this script.")
        return pd.DataFrame()

def calculate_custom_fantasy_points(df, scoring_settings):
    """Calculate custom fantasy points based on user settings"""
    df_custom = df.copy()
    df_custom['custom_fantasy_points_per_game'] = (
        df_custom['est_receptions_per_game'] * scoring_settings['rec_pts'] +
        df_custom['est_rec_yards_per_game'] * scoring_settings['rec_yd_pts'] +
        df_custom['est_rec_tds_per_game'] * scoring_settings['rec_td_pts'] +
        df_custom['est_rush_yards_per_game'] * scoring_settings['rush_yd_pts'] +
        df_custom['est_rush_tds_per_game'] * scoring_settings['rush_td_pts'] +
        df_custom['est_pass_yards_per_game'] * scoring_settings['pass_yd_pts'] +
        df_custom['est_pass_td_per_game'] * scoring_settings['pass_td_pts']
    )
    return df_custom

def create_loess_smoothing(x, y, span=0.7):
    """Create LOESS smoothing curve"""
    if len(x) < 5:
        return x, y
    
    # Sort by x values
    sorted_indices = np.argsort(x)
    x_sorted = np.array(x)[sorted_indices]
    y_sorted = np.array(y)[sorted_indices]
    
    # Create smoothed curve using polynomial regression as approximation
    try:
        # Use polynomial features for smoothing
        poly = PolynomialFeatures(degree=min(3, len(x_sorted)-1))
        model = Pipeline([('poly', poly), ('linear', LinearRegression())])
        
        x_reshaped = x_sorted.reshape(-1, 1)
        model.fit(x_reshaped, y_sorted)
        
        # Create prediction points
        x_smooth = np.linspace(x_sorted.min(), x_sorted.max(), 100)
        y_smooth = model.predict(x_smooth.reshape(-1, 1))
        
        return x_smooth, y_smooth
    except:
        return x_sorted, y_sorted

def create_sparkline_chart(values, ages, current_value):
    """Create a sparkline chart for the table"""
    fig = go.Figure()
    
    # Normalize ages for consistent x-axis
    min_age, max_age = 17, 47
    
    # Create the sparkline
    fig.add_trace(go.Scatter(
        x=ages,
        y=values,
        mode='lines',
        line=dict(
            color='#2ECC40' if current_value >= 0 else '#FF4136',
            width=2
        ),
        showlegend=False
    ))
    
    # Add zero line
    fig.add_hline(y=0, line_dash="dash", line_color="gray", opacity=0.5)
    
    # Update layout for sparkline
    fig.update_layout(
        width=120,
        height=40,
        margin=dict(l=0, r=0, t=0, b=0),
        xaxis=dict(showgrid=False, showticklabels=False, zeroline=False),
        yaxis=dict(showgrid=False, showticklabels=False, zeroline=False),
        plot_bgcolor='rgba(0,0,0,0)',
        paper_bgcolor='rgba(0,0,0,0)'
    )
    
    return fig

def main():
    st.title("Fantasy Football Player Analysis")
    
    # Load data
    df = load_data()
    if df.empty:
        return
    
    # Create tabs
    tab1, tab2, tab3 = st.tabs(["Description", "Historical Career Trajectory", "Current Player Values"])
    
    with tab1:
        st.header("Fantasy Football Player Analysis Tool")
        st.write("This application allows you to analyze and compare fantasy football performance across players' careers.")
        
        st.subheader("Key Features:")
        st.write("• Compare historical performance trajectories")
        st.write("• View current player valuations")
        st.write("• Analyze age-based performance trends")
        
        st.write("Navigate to the 'Historical Career Trajectory' tab to begin your analysis.")
    
    with tab2:
        # Sidebar controls
        with st.sidebar:
            st.header("Controls")
            
            # Metric selection
            metric_options = {
                "Fantasy Points Per Game": "est_fantasy_points_per_game",
                "Snap Share": "est_snap_share",
                "Passes Per Snap": "est_passes_per_snap",
                "Completion %": "est_completion_pct",
                "TDs Per Completion": "est_tds_per_completion",
                "Yards Per Completion": "est_yards_per_completion",
                "Target Share": "est_tgt_share",
                "Catch %": "est_catch_pct",
                "Reception Share": "est_rec_share",
                "TDs Per Reception": "est_touchdowns_per_reception",
                "Yards Per Reception": "est_yds_per_rec",
                "Rushes Per Snap": "est_rushes_per_snap",
                "TDs Per Rush": "est_touchdowns_per_rush",
                "Yards Per Rush": "est_yds_per_rush",
                "Completions Per Game": "est_completions_per_game",
                "Pass Yards Per Game": "est_pass_yards_per_game",
                "Pass TDs Per Game": "est_pass_td_per_game",
                "Receptions Per Game": "est_receptions_per_game",
                "Receiving Yards Per Game": "est_rec_yards_per_game",
                "Receiving TDs Per Game": "est_rec_tds_per_game",
                "Rush Yards Per Game": "est_rush_yards_per_game",
                "Rush TDs Per Game": "est_rush_tds_per_game",
                "Passing Fantasy Pts/Game": "est_passing_fantasy_points_per_game",
                "Receiving Fantasy Pts/Game": "est_receiving_fantasy_points_per_game",
                "Rushing Fantasy Pts/Game": "est_rushing_fantasy_points_per_game",
                "Fantasy Pts/Snap": "est_fantasy_points_per_snap",
                "Value Over Backup": "est_value_over_roster_replacement",
                "Value Over Waiver": "est_value_over_waiver_replacement"
            }
            
            selected_metric_name = st.selectbox(
                "Select Metric to Plot:",
                list(metric_options.keys()),
                index=0
            )
            selected_metric = metric_options[selected_metric_name]
            
            # Player selection
            st.subheader("Player Selection")
            
            # Get unique players
            players_list = sorted(df['player_display_name'].unique())
            
            # Player search and add
            new_player = st.selectbox(
                "Search & Add Player:",
                [""] + players_list,
                key="player_search"
            )
            
            if new_player and new_player not in st.session_state.selected_players:
                # Get player color from team
                player_data = df[df['player_display_name'] == new_player]
                if not player_data.empty:
                    player_color = player_data['team_primary_color_hex'].iloc[-1]
                else:
                    player_color = "#999999"
                
                st.session_state.selected_players[new_player] = player_color
                st.session_state.player_visibility[new_player] = True
                st.rerun()
            
            # Display selected players
            st.subheader("Current Players")
            if st.session_state.selected_players:
                for player in list(st.session_state.selected_players.keys()):
                    col1, col2, col3 = st.columns([3, 1, 1])
                    
                    with col1:
                        is_visible = st.session_state.player_visibility.get(player, True)
                        color = st.session_state.selected_players[player]
                        
                        if is_visible:
                            st.markdown(f'<div class="player-tag" style="background-color: {color}; color: white;">{player}</div>', unsafe_allow_html=True)
                        else:
                            st.markdown(f'<div class="player-tag" style="background-color: #f8f9fa; color: #6c757d; border: 1px dashed #ccc;">{player}</div>', unsafe_allow_html=True)
                    
                    with col2:
                        if st.button("👁️", key=f"toggle_{player}", help="Toggle visibility"):
                            st.session_state.player_visibility[player] = not st.session_state.player_visibility.get(player, True)
                            st.rerun()
                    
                    with col3:
                        if st.button("✖", key=f"remove_{player}", help="Remove player"):
                            del st.session_state.selected_players[player]
                            if player in st.session_state.player_visibility:
                                del st.session_state.player_visibility[player]
                            st.rerun()
            else:
                st.write("No players selected. Add players to begin analysis.")
            
            # Plot controls
            st.subheader("Plot Controls")
            age_range = st.slider("Age Range:", 17, 47, (17, 47))
            show_points = st.checkbox("Show Data Points", value=True)
            
            # Scoring settings
            with st.expander("Scoring Settings"):
                scoring_settings = {
                    'rec_yd_pts': st.slider("Points per Receiving Yard:", 0.02, 0.1, 0.1, 0.01),
                    'rec_pts': st.slider("Points per Reception:", 0.0, 1.0, 1.0, 0.5),
                    'rec_td_pts': st.slider("Points per Receiving TD:", 4, 6, 6, 1),
                    'rush_yd_pts': st.slider("Points per Rushing Yard:", 0.02, 0.1, 0.1, 0.01),
                    'rush_td_pts': st.slider("Points per Rushing TD:", 4, 6, 6, 1),
                    'pass_yd_pts': st.slider("Points per Passing Yard:", 0.02, 0.1, 0.05, 0.01),
                    'pass_td_pts': st.slider("Points per Passing TD:", 4, 6, 4, 1),
                    'tight_end_prem': st.slider("Tight End Premium:", 0, 3, 0, 1)
                }
            
            # League settings
            with st.expander("League Settings"):
                league_settings = {
                    'teams': st.slider("Number of Teams:", 4, 32, 10, 1),
                    'qb_spots': st.slider("Number of QB Starters:", 0, 3, 1, 1),
                    'rb_spots': st.slider("Number of RB Starters:", 0, 3, 2, 1),
                    'wr_spots': st.slider("Number of WR Starters:", 0, 3, 2, 1),
                    'te_spots': st.slider("Number of TE Starters:", 0, 3, 1, 1),
                    'flex_spots': st.slider("Number of Flex Starters:", 0, 5, 1, 1),
                    'superflex_spots': st.slider("Number of Superflex Starters:", 0, 5, 0, 1),
                    'bench_depth': st.slider("Number of Bench Spots:", 0, 30, 10, 1),
                    'ir_depth': st.slider("Number of IR Spots:", 0, 5, 2, 1),
                    'taxi_depth': st.slider("Number of Taxi Spots:", 0, 10, 2, 1)
                }
        
        # Main plot area
        st.subheader(f"{selected_metric_name} vs. Age")
        
        if st.session_state.selected_players:
            # Prepare data
            if selected_metric == "est_fantasy_points_per_game":
                plot_data = calculate_custom_fantasy_points(df, scoring_settings)
                plot_column = 'custom_fantasy_points_per_game'
            else:
                plot_data = df.copy()
                plot_column = selected_metric
            
            # Filter by age range
            plot_data = plot_data[
                (plot_data['true_age'] >= age_range[0]) & 
                (plot_data['true_age'] <= age_range[1])
            ]
            
            # Create plot
            fig = go.Figure()
            
            # Add zero line
            fig.add_hline(y=0, line_dash="solid", line_color="black", opacity=0.7, line_width=0.5)
            
            for player in st.session_state.selected_players:
                if st.session_state.player_visibility.get(player, True):
                    player_data = plot_data[plot_data['player_display_name'] == player]
                    
                    if not player_data.empty:
                        color = st.session_state.selected_players[player]
                        
                        # Add scatter points if enabled
                        if show_points:
                            fig.add_trace(go.Scatter(
                                x=player_data['true_age'],
                                y=player_data[plot_column],
                                mode='markers',
                                name=f"{player} (points)",
                                marker=dict(color=color, size=4, opacity=0.5),
                                showlegend=False
                            ))
                        
                        # Add smoothed line if enough data points
                        if len(player_data) > 5:
                            x_smooth, y_smooth = create_loess_smoothing(
                                player_data['true_age'].values,
                                player_data[plot_column].values
                            )
                            fig.add_trace(go.Scatter(
                                x=x_smooth,
                                y=y_smooth,
                                mode='lines',
                                name=player,
                                line=dict(color=color, width=2)
                            ))
            
            # Update layout
            fig.update_layout(
                title=f"{selected_metric_name} vs. Age",
                xaxis_title="Age",
                yaxis_title=selected_metric_name,
                height=600,
                hovermode='x unified',
                legend=dict(title="Players")
            )
            
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("Select players from the sidebar to begin analysis.")
    
    with tab3:
        st.header("Current Player Values")
        
        # Filter for current (2024) players
        current_players = df[
            (df['year'] == 2024) & (df['player_games_remaining'] == 0)
        ].sort_values('est_value_over_roster_replacement', ascending=False)
        
        if not current_players.empty:
            # Create display dataframe
            display_df = current_players[[
                'player_display_name', 'team', 'position_group',
                'est_value_over_roster_replacement', 'est_value_over_waiver_replacement',
                'est_fantasy_points_per_game', 'est_snap_share', 'est_tgt_share',
                'est_rec_share', 'est_receptions_per_game', 'est_rec_yards_per_game',
                'est_rush_yards_per_game', 'est_pass_yards_per_game'
            ]].copy()
            
            # Round numerical columns
            numerical_cols = display_df.select_dtypes(include=[np.number]).columns
            display_df[numerical_cols] = display_df[numerical_cols].round(2)
            
            # Rename columns for display
            display_df.columns = [
                'Player', 'Team', 'Pos', 'Value Over Backup', 'Value Over Waiver',
                'FP/G', 'Snap %', 'Target %', 'Rec %', 'Rec/G', 'Rec Yds/G',
                'Rush Yds/G', 'Pass Yds/G'
            ]
            
            
            # Color code Value Over Backup
            def highlight_value(val):
                if isinstance(val, (int, float)):
                    if val >= 0:
                        return 'background-color: #2ECC40; color: white'
                    else:
                        return 'background-color: #FF4136; color: white'
                return ''
            
            styled_df = display_df.style.applymap(highlight_value, subset=['Value Over Backup'])
            
            st.dataframe(styled_df, use_container_width=True, height=600)
            
            # Add download button
            csv = display_df.to_csv(index=False)
            st.download_button(
                label="Download CSV",
                data=csv,
                file_name="current_player_values.csv",
                mime="text/csv"
            )
        else:
            st.info("No current player data available.")

if __name__ == "__main__":
    main()
