library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(DT)
library(plotly)
library(stats)
library(shinyWidgets)


# UI definition
ui <- fluidPage(
  titlePanel("Fantasy Football Player Analysis"),
  # Styling
  tags$head(
    tags$style(HTML("
      .plot-container {
        border: 1px solid #ddd;
        border-radius: 5px;
        padding: 10px;
        margin-bottom: 15px;
        background-color: white;
      }
      .control-panel {
        transition: all 0.3s ease;
        padding: 15px;
        background-color: #f8f9fa;
        border-radius: 5px;
        border: 1px solid #ddd;
        margin-bottom: 15px;
        display: block;
      }
      .control-panel a:hover {
        background-color: #e9ecef;
      }
      .player-controls {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
        margin-top: 10px;
      }
      .tab-content {
        padding-top: 15px;
      }
      .sidebar-controls {
        position: sticky;
        top: 20px;
      }
    "))
  ),

  tabsetPanel(
    id = "main_tabs",
    tabPanel(
      "Description",
      h3("Fantasy Football Player Analysis Tool"),
      p("This application allows you to analyze and compare fantasy football performance across players' careers."),
      br(),
      h4("Key Features:"),
      tags$ul(
        tags$li("Compare historical performance trajectories"),
        tags$li("View current player valuations"),
        tags$li("Analyze age-based performance trends")
      ),
      br(),
      img(src = "newplot.png", height = "auto", width = "600px"),
      br(),
      p("Navigate to the 'Historical Career Trajectory' tab to begin your analysis.")
    ),
    tabPanel(
      "Historical Career Trajectory",
      sidebarLayout(
        sidebarPanel(
          width = 3,
          div(class = "control-panel sidebar-controls",
            selectInput(
              "metric_select",
              "Select Metric to Plot:",
              choices = c(
                              "Fantasy Points Per Game" = "est_fantasy_points_per_game",
                              "Snap Share" = "est_snap_share",
                              "Passes Per Snap" = "est_passes_per_snap",
                              "Sacks Per Dropback" = "est_sacks_per_dropback",
                              "Completion %" = "est_completion_pct",
                              "TDs Per Completion" = "est_tds_per_completion",
                              "Yards Per Completion" = "est_yards_per_completion",
                              "Target Share" = "est_tgt_share",
                              "Catch %" = "est_catch_pct",
                              "Reception Share" = "est_rec_share",
                              "TDs Per Reception" = "est_touchdowns_per_reception",
                              "Yards Per Reception" = "est_yds_per_rec",
                              "Rushes Per Snap" = "est_rushes_per_snap",
                              "TDs Per Rush" = "est_touchdowns_per_rush",
                              "Yards Per Rush" = "est_yds_per_rush",
                              "Completions Per Game" = "est_completions_per_game",
                              "Pass Yards Per Game" = "est_pass_yards_per_game",
                              "Pass TDs Per Game" = "est_pass_td_per_game",
                              "Receptions Per Game" = "est_receptions_per_game",
                              "Receiving Yards Per Game" = "est_rec_yards_per_game",
                              "Receiving TDs Per Game" = "est_rec_tds_per_game",
                              "Rush Yards Per Game" = "est_rush_yards_per_game",
                              "Rush TDs Per Game" = "est_rush_tds_per_game",
                              "Passing Fantasy Pts/Game" = "est_passing_fantasy_points_per_game",
                              "Receiving Fantasy Pts/Game" = "est_receiving_fantasy_points_per_game",
                              "Rushing Fantasy Pts/Game" = "est_rushing_fantasy_points_per_game",
                              "Fantasy Pts/65 Snaps" = "est_fantasy_points_per_snap",
                              "Value Over Backup" = "est_value_over_roster_replacement",
                              "Value Over Waiver" = "est_value_over_waiver_replacement"
                            ),
                            selected = "est_fantasy_points_per_game"
                          ),

            h4("Player Selection"),
            # Player selector with Selectize
            selectizeInput(
              "player_select",
              "Search & Add Player:", 
              choices = NULL, 
              options = list(
                placeholder = 'Type a player name...',
                onInitialize = I('function() { this.$input.on("keydown", function(e) { if (e.keyCode === 13) e.preventDefault(); }); }')
              )
            ),
            hr(),
            h4("Current Players"),
            # Display and control selected players
            uiOutput("selected_players_ui"),
            hr(),
            h4("Plot Controls"),
            sliderInput("age_range", "Age Range:", 
                        min = 17, max = 47, value = c(17, 47), step = 1),
            checkboxInput("show_points", "Show Data Points", value = TRUE),

                      tags$div( # nolint
                        class = "control-panel",
                        # First toggle for scoring settings
                        div(actionLink("show_scoring", "Show/Hide Scoring Settings", 
                                       icon = icon("cog"))),

              conditionalPanel(
                condition = "input.show_scoring % 2 == 1",
                hr(),
                h4("Scoring Settings"),
                sliderInput("rec_yd_pts", "Points per Receiving Yard:",
                            min = 0.02, max = 0.1, value = 0.1, step = 0.01),
                sliderInput("rec_pts", "Points per Reception:",
                            min = 0, max = 1, value = 1, step = 0.5),
                sliderInput("rec_td_pts", "Points per Receiving TD:",
                            min = 4, max = 6, value = 6, step = 1),
                sliderInput("rush_yd_pts", "Points per Rushing Yard:",
                            min = 0.02, max = 0.1, value = 0.1, step = 0.01),
                sliderInput("rush_td_pts", "Points per Rushing TD:",
                            min = 4, max = 6, value = 6, step = 1),
                sliderInput("pass_yd_pts", "Points per Passing Yard:",
                            min = 0.02, max = 0.1, value = 0.04, step = 0.01),
                sliderInput("pass_td_pts", "Points per Passing TD:",
                            min = 4, max = 6, value = 4, step = 1),
                sliderInput("tight_end_prem", "Tight End Premium",
                            min = 0, max = 3, value = 0, step = 1)
              ),

              # Second toggle for league settings
                        div(actionLink("show_league", "Show/Hide League Settings",
                                       icon = icon("users"))),

              conditionalPanel(
                condition = "input.show_league % 2 == 1",
                hr(),
                h4("League Settings"),
                sliderInput("teams", "Number of Teams",
                            min = 4, max = 32, value = 10, step = 1),
                sliderInput("qb_spots", "Number of QB Starters",
                            min = 0, max = 3, value = 1, step = 1),
                sliderInput("rb_spots", "Number of RB Starters",
                            min = 0, max = 3, value = 2, step = 1),
                sliderInput("wr_spots", "Number of WR Starters",
                            min = 0, max = 3, value = 2, step = 1),
                sliderInput("te_spots", "Number of TE Starters",
                            min = 0, max = 3, value = 1, step = 1),
                sliderInput("flex_spots", "Number of Flex Starters",
                            min = 0, max = 5, value = 1, step = 1),
                sliderInput("superflex_spots", "Number of Superflex Starters",
                            min = 0, max = 5, value = 0, step = 1),
                sliderInput("bench_depth", "Number of Bench Spots",
                            min = 0, max = 30, value = 10, step = 1),
                sliderInput("ir_depth", "Number of IR Spots",
                            min = 0, max = 5, value = 2, step = 1),
                sliderInput("taxi_depth", "Number of Taxi Spots",
                            min = 0, max = 10, value = 2, step = 1)
              )
            )
          )
        ),
        mainPanel(
          width = 9,
          div(class = "plot-container",
            plotlyOutput("fantasy_plot", height = "600px")
          )
        )
      )
    ),
    tabPanel(
      "Current Player Values",
      div(class = "plot-container",
          DTOutput("current_player_table"))
    )
  )
)


# Server logic
server <- function(input, output, session) {
  # Load the data
  df <- reactive({
    # Read in the CSV file
    data <- read.csv("cfb_nfl_historical_value_estimate.csv")
    return(data)
  })

  # Initialize the app
  observe({
    player_display_names <- sort(unique(df()$player_display_name))
    updateSelectizeInput(session, "player_select", choices = player_display_names, selected = character(0))
  })

  # List to store selected players and their colors
  selected_players <- reactiveVal(list())

  # Add a player when button is clicked
  observeEvent(input$player_select, {
    req(input$player_select != "")

    player_display_name <- input$player_select
    current_players <- selected_players()

    if (!(player_display_name %in% names(current_players))) {
      player_data <- df() %>% filter(player_display_name == !!player_display_name)

      player_color <- if (nrow(player_data) == 0) "#999999"
      else tail(player_data$team_primary_color_hex, 1)

      current_players[[player_display_name]] <- list(color = player_color, visible = TRUE)
      selected_players(current_players)
    }

    updateSelectizeInput(session, "player_select", selected = character(0))

  }, ignoreInit = TRUE)

  # Generate UI for selected players
  output$selected_players_ui <- renderUI({
    players <- selected_players()
    if (length(players) == 0) {
      return(tags$div("No players selected. Add players to begin analysis."))
    }

    # Create a button for each player
    player_buttons <- lapply(names(players), function(player) {
      is_visible <- players[[player]]$visible
      player_color <- players[[player]]$color

      tags$div(class = "player-controls",
        actionButton(
          inputId = paste0("toggle_", gsub("[^a-zA-Z0-9]", "_", player)),
          label = player,
          style = if (is_visible) {
            paste0("background-color: ", player_color, "; color: white;")
          } else {
            "background-color: #f8f9fa; color: #6c757d; border: 1px dashed #ccc;"
          }
        ),
        actionButton(
          inputId = paste0("remove_", gsub("[^a-zA-Z0-9]", "_", player)),
          label = "✖",
          style = "margin-left: 5px;"
        )
      )
    })

    # Return the list of buttons
    div(class = "player-controls", player_buttons)
  })

  # Handle toggling player visibility
  observe({
    players <- names(selected_players())
    lapply(players, function(player) {
      button_id <- paste0("toggle_", gsub("[^a-zA-Z0-9]", "_", player))
      observeEvent(input[[button_id]], {
        current_players <- selected_players()
        current_players[[player]]$visible <- !current_players[[player]]$visible
        selected_players(current_players)
      }, ignoreInit = TRUE)

      remove_id <- paste0("remove_", gsub("[^a-zA-Z0-9]", "_", player))
      observeEvent(input[[remove_id]], {
        current_players <- selected_players()
        current_players[[player]] <- NULL
        selected_players(current_players)
      }, ignoreInit = TRUE)
    })
  })

  # Generate the plot with fixed dimensions

  custom_fantasy_points <- reactive({
    df() %>%
      mutate(
        custom_rec_pts = est_receptions_per_game * input$rec_pts,
        custom_rec_yd_pts = est_rec_yards_per_game * input$rec_yd_pts,
        custom_rec_td_pts = est_rec_tds_per_game * input$rec_td_pts,
        custom_rush_yd_pts = est_rush_yards_per_game * input$rush_yd_pts,
        custom_rush_td_pts = est_rush_tds_per_game * input$rush_td_pts,
        custom_pass_yd_pts = est_pass_yards_per_game * input$pass_yd_pts,
        custom_pass_td_pts = est_pass_td_per_game * input$pass_td_pts,
        custom_fantasy_points_per_game = 
          custom_rec_pts + custom_rec_yd_pts + custom_rec_td_pts +
          custom_rush_yd_pts + custom_rush_td_pts +
          custom_pass_yd_pts + custom_pass_td_pts
      )
  })

  output$fantasy_plot <- renderPlotly({
    req(input$metric_select)

    plot_data <- if (input$metric_select == "est_fantasy_points_per_game") {
      custom_fantasy_points() %>%
        mutate(plot_metric = custom_fantasy_points_per_game)

    } else if (input$metric_select == "est_fantasy_points_per_snap") {
      custom_fantasy_points() %>%
        mutate(
          plot_metric = custom_fantasy_points_per_game /
                        coalesce(est_snap_share, 1)
        )

    } else {
      df() %>%
        mutate(plot_metric = .data[[input$metric_select]])
    }

    players <- selected_players()

    # Get proper axis label from the selected metric
    y_label <- names(which(input$metric_select == c(
      "Fantasy Points Per Game" = "est_fantasy_points_per_game",
      "Snap Share" = "est_snap_share",
      "Passes Per Snap" = "est_passes_per_snap",
      "Sacks Per Dropback" = "est_sacks_per_dropback",
      "Completion %" = "est_completion_pct",
      "TDs Per Completion" = "est_tds_per_completion",
      "Yards Per Completion" = "est_yards_per_completion",
      "Target Share" = "est_tgt_share",
      "Catch %" = "est_catch_pct",
      "Reception Share" = "est_rec_share",
      "TDs Per Reception" = "est_touchdowns_per_reception",
      "Yards Per Reception" = "est_yds_per_rec",
      "Rushes Per Snap" = "est_rushes_per_snap",
      "TDs Per Rush" = "est_touchdowns_per_rush",
      "Yards Per Rush" = "est_yds_per_rush",
      "Completions Per Game" = "est_completions_per_game",
      "Pass Yards Per Game" = "est_pass_yards_per_game",
      "Pass TDs Per Game" = "est_pass_td_per_game",
      "Receptions Per Game" = "est_receptions_per_game",
      "Receiving Yards Per Game" = "est_rec_yards_per_game",
      "Receiving TDs Per Game" = "est_rec_tds_per_game",
      "Rush Yards Per Game" = "est_rush_yards_per_game",
      "Rush TDs Per Game" = "est_rush_tds_per_game",
      "Passing Fantasy Pts/Game" = "est_passing_fantasy_points_per_game",
      "Receiving Fantasy Pts/Game" = "est_receiving_fantasy_points_per_game",
      "Rushing Fantasy Pts/Game" = "est_rushing_fantasy_points_per_game",
      "Fantasy Pts/Snap" = "est_fantasy_points_per_snap",
      "Value Over Backup" = "est_value_over_roster_replacement",
      "Value Over Waiver" = "est_value_over_waiver_replacement"
    ))[1])

    if (length(players) == 0) {
      p <- ggplot() + 
        xlim(input$age_range[1], input$age_range[2]) +
        ylim(0, max(plot_data$plot_metric, na.rm = TRUE) * 1.1) +
        labs(
          title = paste(y_label, "vs. Age"),
          x = "Age",
          y = y_label
        ) +
        theme_minimal()
      return(ggplotly(p) %>% layout(autosize = FALSE, width = 900, height = 600))
    }

    # Initialize plot with dynamic y-axis
    p <- ggplot() +
      xlim(input$age_range[1], input$age_range[2]) +
      ylim(min(plot_data$plot_metric, na.rm = TRUE), max(plot_data$plot_metric, na.rm = TRUE)) +
      labs(
        title = paste(y_label, "vs. Age"),
        x = "Age",
        y = y_label
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 16, face = "bold"),
        axis.title = element_text(size = 14),
        panel.grid.major = element_line(color = "#e0e0e0"),
        panel.grid.minor = element_line(color = "#f0f0f0")
      )

    color_map <- sapply(players, function(x) x$color)
    names(color_map) <- names(players)

    for (player_display_name in names(players)) {
      if (players[[player_display_name]]$visible) {
        player_data <- plot_data %>% filter(player_display_name == !!player_display_name)

        # LOESS smoothing with fixed span of 0.7
        if (nrow(player_data) > 5) {
          loess_fit <- loess(plot_metric ~ approximate_age, data = player_data, span = 0.8)
          age_grid <- seq(min(player_data$approximate_age), max(player_data$approximate_age), length.out = 100)
          pred_data <- data.frame(
            approximate_age = age_grid,
            metric_value = predict(loess_fit, age_grid),
            player_display_name = player_display_name
          )
          p <- p + geom_line(
            data = pred_data,
            aes(x = approximate_age, y = metric_value, color = player_display_name),
            size = 1
          )
        }

        # Scatter points
        if (input$show_points) {
          p <- p + geom_point(
            data = player_data,
            aes(x = approximate_age, y = plot_metric, color = player_display_name),
            alpha = 0.5, size = 0.5
          )
        }
      }
    }

    p <- p + 
      geom_hline(
        yintercept = 0, 
        color = "black", 
        size = 0.5,
        linetype = "solid",
        alpha = 0.7
      ) +
      scale_color_manual(values = color_map)

    ggplotly(p) %>%
      layout(autosize = FALSE, width = 900, height = 600) %>%
      layout(legend = list(title = list(text = "Players")))
  })
  
output$current_player_table <- renderDT({
  # Filter for current (2024) players with no games remaining
  current_players <- df() %>% 
    filter(year == 2024, player_games_remaining == 0) %>%
    arrange(desc(est_value_over_roster_replacement))
  
  # Get historical data for these players (all years)
  historical_data <- df() %>%
    filter(player_display_name %in% current_players$player_display_name)
  
  # Create sparkline data using all historical data
  sparkline_data <- historical_data %>%
    group_by(player_display_name) %>%
    summarize(
      sparkline = list(
        list(
          values = est_value_over_roster_replacement,
          ages = approximate_age,
          minAge = 17,
          maxAge = 47,
          currentValue = last(est_value_over_roster_replacement)  # Get most recent value for coloring
        )
      )
    )
  
  # Join with current data
  current_data <- current_players %>%
    left_join(sparkline_data, by = "player_display_name") %>%
    select(
      player_display_name,
      team_abbreviation,
      position,
      sparkline,
      est_value_over_roster_replacement,
      est_value_over_waiver_replacement,
      est_fantasy_points_per_game,
      est_snap_share,
      est_tgt_share,
      est_rec_share,
      est_receptions_per_game,
      est_rec_yards_per_game,
      est_rush_yards_per_game,
      est_pass_yards_per_game
    )
  
  # Create the datatable
  datatable(
    current_data,
    extensions = c('Buttons', 'Responsive'),
    options = list(
      dom = 'Bfrtip',
      buttons = c('copy', 'csv', 'excel'),
      pageLength = 25,
      columnDefs = list(
        list(
          targets = 3, # Sparkline column
          render = JS(
            "function(data, type, row) {
              if (type === 'display' && data && data.values && data.values.length > 0) {
                // Create sparkline canvas
                var canvas = document.createElement('canvas');
                canvas.width = 120;
                canvas.height = 40;
                
                // Get context
                var ctx = canvas.getContext('2d');
                
                // Prepare data
                var values = data.values;
                var ages = data.ages;
                var minAge = data.minAge;
                var maxAge = data.maxAge;
                var currentValue = data.currentValue;
                
                // Calculate dimensions
                var padding = 5;
                var width = canvas.width - 2*padding;
                var height = canvas.height - 2*padding;
                
                // Normalize ages to x-coordinates
                var xCoords = ages.map(function(age) {
                  return padding + ((age - minAge)/(maxAge - minAge)) * width;
                });
                
                // Normalize values to y-coordinates
                var maxAbsValue = Math.max(1, Math.max(...values.map(Math.abs)));
                var yCoords = values.map(function(val) {
                  return padding + height/2 - (val/maxAbsValue) * (height/2);
                });
                
                // Draw zero line
                ctx.beginPath();
                ctx.moveTo(padding, padding + height/2);
                ctx.lineTo(padding + width, padding + height/2);
                ctx.strokeStyle = '#DDDDDD';
                ctx.lineWidth = 1;
                ctx.stroke();
                
                // Draw sparkline
                ctx.beginPath();
                ctx.moveTo(xCoords[0], yCoords[0]);
                for (var i = 1; i < values.length; i++) {
                  ctx.lineTo(xCoords[i], yCoords[i]);
                }
                ctx.strokeStyle = currentValue >= 0 ? '#2ECC40' : '#FF4136';
                ctx.lineWidth = 2;
                ctx.stroke();
                
                return canvas.outerHTML;
              }
              return '';
            }"
          )
        )
      )
    ),
    escape = FALSE,
    rownames = FALSE,
    colnames = c(
      'Player', 'Team', 'Pos', 'Value Trend', 
      'Value Over Backup', 'Value Over Waiver',
      'FP/G', 'Snap %', 'Target %', 'Rec %',
      'Rec/G', 'Rec Yds/G', 'Rush Yds/G', 'Pass Yds/G'
    )
  ) %>%
    formatRound(columns = 5:ncol(current_data), digits = 2) %>%
    formatStyle(
      'Value Over Backup',
      color = styleInterval(0, c('#FF4136', '#2ECC40')))
})
}

# Run the app
shinyApp(ui = ui, server = server)
