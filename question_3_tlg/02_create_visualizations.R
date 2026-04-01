# Set working directory to project root
setwd("/cloud/project/brie-ads-assessment")

# load libraries
library(pharmaverseadam)
library(ggplot2)
library(dplyr)
library(purrr)
library(scales)

# Read in source ADaM datasets
adsl <- pharmaverseadam::adsl
adae <- pharmaverseadam::adae

# ======================================
# 1. Stacked Bar Chart
# ======================================

# Pre-process data
adae_plot <- adae %>%
  filter(
    # Safety analysis set
    SAFFL == "Y",
    !is.na(AESEV)
  ) %>%
  # Count AEs by treatment arm and severity
  count(ACTARM, AESEV)

# Define severity order for stacking (SEVERE at bottom, MILD at top)
adae_plot <- adae_plot %>%
  mutate(
    AESEV = factor(AESEV, levels = c("MILD", "MODERATE", "SEVERE"))
  )

# Build plot
ae_severity_plot <- ggplot(
  adae_plot,
  aes(x = ACTARM, y = n, fill = AESEV)
) +
  geom_bar(stat = "identity", position = "stack") +
  scale_fill_manual(
    values = c(
      "MILD"     = "#F8766D",   # pink/salmon
      "MODERATE" = "#00BA38",   # green
      "SEVERE"   = "#619CFF"    # blue
    )
  ) +
  labs(
    title = "AE severity distribution by treatment",
    x     = "Treatment Arm",
    y     = "Count of AEs",
    fill  = "Severity/Intensity"
  )

ae_severity_plot

# Save plot to output folder as png
ggsave(
  "question_3_tlg/output/stacked_bar_plot.png",
  plot   = ae_severity_plot,
  width  = 8,
  height = 6,
  dpi    = 300
)

# ======================================
# 2. Forest Plot
# ======================================

# Derive top 10 AEs with Clopper-Pearson CIs

# Derive the total number of subjects for denominator
n_subj <- adsl %>%
  filter(SAFFL == "Y") %>%
  summarise(n = n_distinct(USUBJID)) %>%
  pull(n) # extract n and store as a vector

# Count unique subjects per AETERM and calculate proportions and CIs
ae_forest <- adae %>%
  filter(
    SAFFL   == "Y",
    !is.na(AETERM)
  ) %>%
  # Count unique subjects per AE term
  group_by(AETERM) %>%
  summarise(n_ae = n_distinct(USUBJID)) %>%
  ungroup() %>% #remove grouping
  # Calculate percentage and Clopper-Pearson CIs
  mutate(
    pct      = n_ae / n_subj,
    # map_dbl loops through each n_ae value and runs binom.test() for each
    ci_lower = map_dbl(n_ae, ~ binom.test(.x, n_subj)$conf.int[1]),
    ci_upper = map_dbl(n_ae, ~ binom.test(.x, n_subj)$conf.int[2])
  ) %>%
  # Keep top 10 most frequent
  slice_max(order_by = n_ae, n = 10) %>%
  # Order ascending for plot (most frequent at top)
  arrange(pct) %>%
  # Convert AETERM to factor to maintain the order for the plot
  mutate(AETERM = factor(AETERM, levels = AETERM)) 

# Build the plot

ae_forest_plot <- ggplot(
  ae_forest,
  aes(x = pct, y = AETERM)
) +
  # Confidence interval lines
  geom_errorbar(
    aes(xmin = ci_lower, xmax = ci_upper),
    orientation = "y",    # makes it horizontal
    width     = 0.2,      # note: width not height in new syntax
    linewidth = 0.8
  ) +
  # Point estimates
  geom_point(size = 3) +
  # Format x axis as percentage
  scale_x_continuous(
    labels = percent_format(accuracy = 1),
    breaks = seq(0, 0.35, by = 0.10),
    limits = c(0, 0.30)
  ) +
  # Add title, sub-header, and axis- labels
  labs(
    title    = "Top 10 Most Frequent Adverse Events",
    subtitle = paste0("n = ", n_subj, " subjects; 95% Clopper-Pearson CIs"),
    x        = "Percentage of Patients (%)",
    y        = NULL # remove y axis label
  ) 

# Display plot
ae_forest_plot

# Save to output folder
ggsave(
  "question_3_tlg/output/ae_forest_plot.png",
  plot   = ae_forest_plot,
  width  = 9,
  height = 6,
  dpi    = 300
)