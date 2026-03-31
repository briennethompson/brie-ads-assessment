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

# Define severity order for stacking (SEVERE at bottom, MILD at top)
adae_plot <- adae_plot %>%
  dplyr::mutate(
    AESEV = factor(AESEV, levels = c("MILD", "MODERATE", "SEVERE"))
  )

# Build plot
ae_severity_plot <- ggplot2::ggplot(
  adae_plot,
  ggplot2::aes(x = ACTARM, y = n, fill = AESEV)
) +
  ggplot2::geom_bar(stat = "identity", position = "stack") +
  ggplot2::scale_fill_manual(
    values = c(
      "MILD"     = "#F8766D",   # pink/salmon
      "MODERATE" = "#00BA38",   # green
      "SEVERE"   = "#619CFF"    # blue
    )
  ) +
  ggplot2::labs(
    title = "AE severity distribution by treatment",
    x     = "Treatment Arm",
    y     = "Count of AEs",
    fill  = "Severity/Intensity"
  )

ae_severity_plot

# Save plot to output folder as png
ggplot2::ggsave(
  "question_3_tlg/output/02_stacked_bar_plot.png",
  plot   = ae_severity_plot,
  width  = 8,
  height = 6,
  dpi    = 300
)