# load libraries
library(ggplot2)
library(dplyr)

# Read in source ADaM datasets
adsl <- pharmaverseadam::adsl
adae <- pharmaverseadam::adae

# Pre-process data
adae_plot <- adae %>%
  filter(
    # Safety analysis set
    SAFFL == "Y",
    !is.na(AESEV)
  ) %>%
  # Count AEs by treatment arm and severity
  dplyr::count(ACTARM, AESEV)