# Set working directory to project root
setwd("/cloud/project/brie-ads-assessment")

# Load reusable helper functions
source("utils/helper_functions.R")

# Load libraries
library(metacore)
library(metatools)
library(pharmaversesdtm)
library(admiral)
library(dplyr)
library(tidyr)
library(lubridate)
library(stringr)
library(haven)
library(testthat)

# Read in input SDTM data
dm <- pharmaversesdtm::dm
ds <- pharmaversesdtm::ds
ex <- pharmaversesdtm::ex
ae <- pharmaversesdtm::ae
vs <- pharmaversesdtm::vs
suppdm <- pharmaversesdtm::suppdm

# Reformat missing values to NA
dm <- convert_blanks_to_na(dm)
ds <- convert_blanks_to_na(ds)
ex <- convert_blanks_to_na(ex)
ae <- convert_blanks_to_na(ae)
vs <- convert_blanks_to_na(vs)
suppdm <- convert_blanks_to_na(suppdm)

# Combine parent and supplemental demog data
dm_suppdm <- combine_supp(dm, suppdm)

# Use combined demog data as basis for ADSL
adsl <- dm_suppdm %>%
  select(-DOMAIN)

# Derive age grouping variables - AGEGR9 and AGEGR9N
# Create lookup table for AGEGR9/AGEGR9N
agegr9_lookup <- exprs(
  ~condition,            ~AGEGR9, ~AGEGR9N,
  AGE < 18,                "<18",        1,
  between(AGE, 18, 50),  "18-50",        2,
  AGE > 50,                ">50",        3,
  is.na(AGE),          "Missing",        4
)

# Apply lookup table to working data to derive agecat vars
adsl <- adsl %>%
  derive_vars_cat(
    definition = agegr9_lookup
  )

# Derive datetime for treatment start (TRTSDTM) and imputation flag (TRTSTMF)
# Apply the imputation rule to EX
ex_ext <- ex %>%
  # Impute missing start times as the earliest time of the day
  derive_vars_dtm(
    new_vars_prefix = "EXST",
    dtc = EXSTDTC,
    highest_imputation = "h",
    time_imputation = "first",
    flag_imputation = "time",
    ignore_seconds_flag = TRUE
  ) %>%
  # Add derivation for TRTEDTM/TRTENMF for later derivation of LSTAVLDT
  derive_vars_dtm(
    new_vars_prefix = "EXEN",
    dtc = EXENDTC,
    highest_imputation = "h",
    time_imputation = "last",
    flag_imputation = "time",
    ignore_seconds_flag = TRUE
  )

# Merge ex_ext with our working dataset to derive TRTSDTM/TRTSTMF/TRTEDTM/TRTENMF
adsl <- adsl %>%
  # Treatment start datetime
  derive_vars_merged(
    dataset_add = ex_ext,
    # Derivation is only applied for a valid dose
    filter_add = (EXDOSE > 0 |
      (EXDOSE == 0 &
        str_detect(EXTRT, "PLACEBO"))) & !is.na(EXSTDTM),
    new_vars = exprs(TRTSDTM = EXSTDTM, TRTSTMF = EXSTTMF),
    order = exprs(EXSTDTM, EXSEQ),
    mode = "first",
    by_vars = exprs(STUDYID, USUBJID)
  ) %>%
  # Treatment end datetime
  derive_vars_merged(
    dataset_add = ex_ext,
    # Derivation is only applied for a valid dose
    filter_add = (EXDOSE > 0 |
      (EXDOSE == 0 &
        str_detect(EXTRT, "PLACEBO"))) & !is.na(EXENDTM),
    new_vars = exprs(TRTEDTM = EXENDTM, TRTETMF = EXENTMF),
    order = exprs(EXENDTM, EXSEQ),
    mode = "last",
    by_vars = exprs(STUDYID, USUBJID)
  )

# Derive ITTFL
adsl <- adsl %>%
  mutate(
    ITTFL = if_else(!is.na(ARM), "Y", "N")
  )

# Derive LSTALVDT from VS, AE, DS, and ADSL

# VS: Latest complete assessment date with valid result
vs_pre <- vs %>%
  filter(!is.na(VSSTRESN) | !is.na(VSSTRESC)) %>%
  get_last_date(VSDTC, "vsdt_max")

# AE: Last complete onset date
ae_pre <- get_last_date(ae, AESTDTC, "aestdt_max")

# DS: Last complete start date
ds_pre <- get_last_date(ds, DSSTDTC, "dsstdt_max")

# Last treatment date with valid dose
trt_pre <- adsl %>%
  mutate(trtedt_max = date(TRTEDTM)) %>%
  filter(!is.na(trtedt_max)) %>%
  select(USUBJID, trtedt_max)

# Merge all dates into ADSL and take max
adsl <- adsl %>%
  left_join(vs_pre, by = "USUBJID") %>%
  left_join(ae_pre, by = "USUBJID") %>%
  left_join(ds_pre, by = "USUBJID") %>%
  left_join(trt_pre, by = "USUBJID") %>%
  # Derive LSTALVDT as max of all four dates
  mutate(
    LSTALVDT = pmax(
      vsdt_max,
      aestdt_max,
      dsstdt_max,
      trtedt_max,
      na.rm = TRUE
    )
  ) %>%
  # # Drop intermediate variables
  select(-vsdt_max, -aestdt_max, -dsstdt_max, -trtedt_max)

# Add labels for newly derived variables
attr(adsl$AGEGR9, "label") <- "Pooled Age Group 9"
attr(adsl$AGEGR9N, "label") <- "Pooled Age Group 9 (N)"
attr(adsl$TRTSDTM, "label") <- "Datetime of First Exposure to Treatment"
attr(adsl$TRTSTMF, "label") <- "Time Imputation Flag for TRTSDTM"
attr(adsl$TRTEDTM, "label") <- "Datetime of Last Exposure to Treatment"
attr(adsl$TRTETMF, "label") <- "Time Imputation Flag for TRTEDTM"
attr(adsl$ITTFL, "label") <- "Intent-To-Treat Population Flag"
attr(adsl$LSTALVDT, "label") <- "Date of Last Known Alive"

# Add dataset label
attr(adsl, "label") <- "Subject-Level Analysis Dataset"

# Export final ADSL dataset as xpt
write_xpt(adsl, path = "question_2_adam/output/adsl.xpt")

# ============================================
# Add Tests - ADSL Validation
# ============================================

# Make sure ADSL has the expected structure
test_that("ADSL has one record per subject", {
  expect_equal(nrow(adsl), dplyr::n_distinct(adsl$USUBJID))
})

# Population Flag Tests
test_that("ITTFL only contains Y or N", {
  expect_true(all(adsl$ITTFL %in% c("Y", "N")))
})

test_that("ITTFL is never missing", {
  expect_false(any(is.na(adsl$ITTFL)))
})

test_that("ITTFL is Y when ARM is not missing", {
  expect_true(all(
    adsl$ITTFL == "Y" | is.na(adsl$ARM)
  ))
})

# Treatment Datetime Tests
test_that("TRTSDTM is before or equal to TRTEDTM", {
  treated <- adsl %>%
    filter(!is.na(TRTSDTM) & !is.na(TRTEDTM))
  expect_true(all(treated$TRTSDTM <= treated$TRTEDTM))
})

test_that("XPT output file exists", {
  expect_true(
    file.exists("question_2_adam/output/adsl.xpt")
  )
})
