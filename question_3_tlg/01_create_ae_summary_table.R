# Load libraries 
library(dplyr)
library(gtsummary)

# Read in source ADaM datasets
adsl <- pharmaverseadam::adsl
adae <- pharmaverseadam::adae

# Pre-process data
adae <- adae %>%
  filter(
    # safety population
    SAFFL == "Y",
    # treatment emergent AEs
    TRTEMFL == "Y"
  )

# Build table
tbl <- adae %>%
  tbl_hierarchical(
    variables = c(AESOC, AETERM),
    by = ACTARM,
    id = USUBJID,
    denominator = adsl,
    overall_row = TRUE,
    label = "..ard_hierarchical_overall.." ~ "Treatment Emergent AEs"
  ) %>%
  # Add total column
  add_overall(last = TRUE, col_label = "**Total**") %>%
  # Sort by descending frequency using total column
  sort_hierarchical(sort_by = "overall")

tbl