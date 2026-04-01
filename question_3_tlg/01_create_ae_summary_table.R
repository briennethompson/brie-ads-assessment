# Set working directory to project root
setwd("/cloud/project/brie-ads-assessment")

# Load libraries
library(pharmaverseadam)
library(dplyr)
library(gtsummary)
library(gt)
library(testthat)

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
  sort_hierarchical(sort_by = "overall") %>%
  # Add title
  modify_caption("**Table 1. Treatment Emergent Adverse Events by System Organ Class and Preferred Term**")

# Export as HTML
tbl %>%
  as_gt() %>%
  gtsave("question_3_tlg/output/teae_summary_table.html")

# ============================================
# Add Tests
# ============================================

test_that("Table has expected treatment arms", {
  expect_true("Xanomeline High Dose" %in% unique(adae$ACTARM))
})

test_that("Only safety population included", {
  expect_true(all(adae$SAFFL == "Y"))
})

test_that("Only treatment emergent AEs included", {
  expect_true(all(adae$TRTEMFL == "Y"))
})

test_that("HTML output file exists", {
  expect_true(
    file.exists("question_3_tlg/output/teae_summary_table.html")
  )
})
