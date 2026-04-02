# ============================================================
# File:    utils/plot_functions.R
# Purpose: Reusable plotting functions for clinical data
# ============================================================

# ============================================================
# Function 1: Preprocess data for stacked bar chart
# 
# Args:
#   data:        ADaM dataset 
#   pop_var:     Population flag variable 
#   arm_var:     Treatment arm variable (default: ACTARM)
#   cat_var:     Categorical variable
#   cat_levels:  Categorical levels in stacking order - bottom to top
#
# Returns:
#   Preprocessed dataframe ready for plotting
# ============================================================

preprocess_stacked_bar <- function(
    data,
    pop_var,
    arm_var    = "ACTARM",
    cat_var,
    cat_levels = NULL
) {
  # Preprocess data
  result <- data %>%
    # Filter to specified population and non-missing category
    filter(
      .data[[pop_var]] == "Y",
      !is.na(.data[[cat_var]])
    ) %>%
    # Count records by treatment arm and category
    count(.data[[arm_var]], .data[[cat_var]])
  
  # Apply factor ordering if cat_levels provided
  # Otherwise use order as it appears in the data
  if (!is.null(cat_levels)) {
    result <- result %>%
      mutate(
        "{cat_var}" := factor(.data[[cat_var]], levels = cat_levels)
      )
  }
  
  return(result)
}

# ============================================================
# Function 2: Build stacked bar chart
#
# Args:
#   data:       Preprocessed dataframe from preprocess_stacked_bar()
#   arm_var:    Treatment arm variable (default: ACTARM)
#   cat_var:    Category variable 
#   title:      Plot title
#   x_label:    X axis label
#   y_label:    Y axis label
#   fill_label: Legend label
#   colors:     Named vector of colors for each category level
#               If NULL colors are assigned automatically
#
# Returns:
#   ggplot object
# ============================================================

plot_stacked_bar <- function(
    data,
    arm_var    = "ACTARM",
    cat_var,
    title      = NULL,
    x_label    = "Treatment Arm",
    y_label     = "Count",
    fill_label = NULL,
    colors     = NULL
) {
  # Build base plot
  p <- ggplot2::ggplot(
    data,
    ggplot2::aes(
      x    = .data[[arm_var]],
      y    = n,
      fill = .data[[cat_var]]
    )
  ) +
    ggplot2::geom_bar(stat = "identity", position = "stack") +
    ggplot2::labs(
      title = title,
      x     = x_label,
      y     = y_label,
      fill  = fill_label
    )
  
  # Apply custom colors if provided
  # Otherwise ggplot2 assigns colors automatically
  if (!is.null(colors)) {
    p <- p + ggplot2::scale_fill_manual(values = colors)
  }
  
  return(p)
}