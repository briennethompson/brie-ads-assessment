# Set working directory to project root
setwd("/cloud/project/brie-ads-assessment")

# Load libraries
library(pharmaverseraw)
library(pharmaversesdtm)
library(sdtm.oak)
library(dplyr)
library(haven)
library(readr)
library(testthat)

# Read in raw disposition data
ds_raw <- pharmaverseraw::ds_raw

# Read in SDTM DM (demog) data
dm <- pharmaversesdtm::dm

# Create oak_id_vars
ds_raw <- ds_raw %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "ds_raw"
  )

# Read in study controlled terminology file
study_ct <- read_csv("question_1_sdtm/sdtm_ct.csv")

# Map the topic variable IT.DSTERM to DS.DSTERM
ds <-
  assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "IT.DSTERM",
    tgt_var = "DSTERM",
    id_vars = oak_id_vars()
  )

# Map Qualifiers (DSDECOD AND DSCAT) and update DSTERM
ds <- ds %>%
  # Update DSTERM - assign as OTHERSP when not missing OTHERSP
  assign_no_ct(
    raw_dat = condition_add(ds_raw, !is.na(OTHERSP)), # filter raw data
    raw_var = "OTHERSP",
    tgt_var = "DSTERM",
    id_vars = oak_id_vars()
  ) %>%
  # Map DSDECOD - if OTHERSP is missing map from IT.DSDECOD
  assign_ct(
    raw_dat = condition_add(ds_raw, is.na(OTHERSP)), # filter raw data
    raw_var = "IT.DSDECOD",
    tgt_var = "DSDECOD",
    ct_spec = study_ct,
    ct_clst = "C66727",
    id_vars = oak_id_vars()
  ) %>%
  # Map DSDECOD - if OTHERSP is not missing map from OTHERSP
  assign_ct(
    raw_dat = condition_add(ds_raw, !is.na(OTHERSP)), # filter raw data
    raw_var = "OTHERSP",
    tgt_var = "DSDECOD",
    ct_spec = study_ct,
    ct_clst = "C66727",
    id_vars = oak_id_vars()
  ) %>%
  # Assign DSCAT - PROTOCOL MILESTONE when IT.DSDECOD = Randomized
  hardcode_no_ct(
    raw_dat = condition_add(ds_raw, IT.DSDECOD == "Randomized"),
    raw_var = "IT.DSDECOD",
    tgt_var = "DSCAT",
    tgt_val = "PROTOCOL MILESTONE",
    id_vars = oak_id_vars()
  ) %>%
  # Assign DSCAT - DISPOSITION EVENT when IT.DSDECOD != Randomized
  hardcode_no_ct(
    raw_dat = condition_add(ds_raw, IT.DSDECOD != "Randomized"),
    raw_var = "IT.DSDECOD",
    tgt_var = "DSCAT",
    tgt_val = "DISPOSITION EVENT",
    id_vars = oak_id_vars()
  ) %>%
  # Assign DSCAT - OTHER EVENT when OTHERSP is not missing
  hardcode_no_ct(
    raw_dat = condition_add(ds_raw, !is.na(OTHERSP)),
    raw_var = "OTHERSP",
    tgt_var = "DSCAT",
    tgt_val = "OTHER EVENT",
    id_vars = oak_id_vars()
  )

# Map timing and visit variables
ds <- ds %>%
  # Map DSSTDTC from IT.DSSTDAT in ISO8601 format
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = "IT.DSSTDAT",
    tgt_var = "DSSTDTC",
    raw_fmt = "mm-dd-yyyy",
    id_vars = oak_id_vars()
  ) %>%
  # Map DSDTC from DSDTCOL and DSTMCOL in ISO8601 format
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = c("DSDTCOL", "DSTMCOL"),
    tgt_var = "DSDTC",
    raw_fmt = c(list("mm-dd-yyyy", "H:M"))
  ) %>%
  # Map VISIT from INSTANCE using CT
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISIT",
    ct_spec = study_ct,
    ct_clst = "VISIT",
    id_vars = oak_id_vars()
  ) %>%
  # Map VISITNUM from INSTANCE using CT
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISITNUM",
    ct_spec = study_ct,
    ct_clst = "VISITNUM",
    id_vars = oak_id_vars()
  )

# Derive USUBJID, STUDYID, DOMAIN, DSSTDY and DSSEQ
ds <- ds %>%
  mutate(
    STUDYID = "CDISCPILOT01", # ref DM dataset
    DOMAIN = "DS",
    USUBJID = paste0("01-", ds_raw$patient_number) # ref DM dataset
  ) %>%
  # Derive DSSTDY - study day relative to treatment start
  derive_study_day(
    sdtm_in = .,
    dm_domain = dm,
    tgdt = "DSSTDTC",
    refdt = "RFXSTDTC",
    study_day_var = "DSSTDY",
    merge_key = "USUBJID"
  ) %>%
  # Derive sequence variable
  derive_seq(
    tgt_var = "DSSEQ",
    rec_vars = c("USUBJID", "DSTERM", "DSDECOD", "DSCAT", "DSDTC", "DSSTDTC")
  ) %>%
  # Reorder variables and drop oak_id_vars
  select(
    "STUDYID", "DOMAIN", "USUBJID", "DSSEQ", "DSTERM", "DSDECOD", "DSCAT",
    "VISITNUM", "VISIT", "DSDTC", "DSSTDTC", "DSSTDY"
  )


# Add variable labels
attr(ds$STUDYID, "label") <- "Study Identifier"
attr(ds$DOMAIN, "label") <- "Domain Abbreviation"
attr(ds$USUBJID, "label") <- "Unique Subject Identifier"
attr(ds$DSSEQ, "label") <- "Sequence Number"
attr(ds$DSTERM, "label") <- "Reported Term for the Disposition Event"
attr(ds$DSDECOD, "label") <- "Standardized Disposition Term"
attr(ds$DSCAT, "label") <- "Category for Disposition Event"
attr(ds$VISITNUM, "label") <- "Visit Number"
attr(ds$VISIT, "label") <- "Visit Name"
attr(ds$DSDTC, "label") <- "Date/Time of Collection"
attr(ds$DSSTDTC, "label") <- "Start Date/Time of Disposition Event"
attr(ds$DSSTDY, "label") <- "Study Day of Start of Disposition Event"

# Add dataset label
attr(ds, "label") <- "Disposition"

# Export final DS dataset as xpt
write_xpt(ds, path = "question_1_sdtm/output/ds.xpt")


# ============================================
# Add Tests - DS Domain Validation
# ============================================

test_that("DS domain has expected variables", {
  expected_vars <- c(
    "STUDYID", "DOMAIN", "USUBJID", "DSSEQ", "DSTERM",
    "DSDECOD", "DSCAT", "VISITNUM", "VISIT", "DSDTC",
    "DSSTDTC", "DSSTDY"
  )
  expect_equal(names(ds), expected_vars)
})

test_that("USUBJID is non missing", {
  expect_false(any(is.na(ds$USUBJID)))
})

test_that("DSSEQ is unique within USUBJID", {
  dupes <- ds %>%
    count(USUBJID, DSSEQ) %>%
    filter(n > 1)
  expect_equal(nrow(dupes), 0)
})

test_that("DSTERM is non missing", {
  expect_false(any(is.na(ds$DSTERM)))
})

test_that("XPT output file exists", {
  expect_true(file.exists("question_1_sdtm/output/ds.xpt"))
})
