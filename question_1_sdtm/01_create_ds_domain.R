# Set working directory to project root
setwd("/cloud/project/brie-ads-assessment")

# Initialize libraries
library(sdtm.oak)
library(pharmaverseraw)
library(pharmaversesdtm)
library(dplyr)
library(tidyverse)

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
# Use conditional logic with sdtm.oak by using the calls multiple times sequentially
ds <- ds %>%
  # Update DSTERM per the eCRF -assign as OTHERSP when not missing OTHERSP
  assign_no_ct(
    raw_dat = condition_add(ds_raw, !is.na(OTHERSP)), #filter raw data
    raw_var = "OTHERSP",
    tgt_var = "DSTERM",
    id_vars = oak_id_vars()
  ) %>%
  # Map DSDECOD using controlled terminology and condition_add
  # If not missing OTHERSP then map from IT.DSDECOD
  assign_ct(
    raw_dat = condition_add(ds_raw, is.na(OTHERSP)), #filter raw data
    raw_var = "IT.DSDECOD",
    tgt_var = "DSDECOD",
    ct_spec = study_ct,
    ct_clst = "C66727",
    id_vars = oak_id_vars()
  ) %>%
  # Else map from OTHERSP
  assign_ct(
    raw_dat = condition_add(ds_raw, !is.na(OTHERSP)), #filter raw data
    raw_var = "OTHERSP",
    tgt_var = "DSDECOD",
    ct_spec = study_ct,
    ct_clst = "C66727",
    id_vars = oak_id_vars()
  ) %>%
  # Assign DSCAT without using controlled terminology (missing from the study_ct file)
  # Assign as PROTOCOL MILESTONE when IT.DSDECOD = Randomized
  hardcode_no_ct(
    raw_dat = condition_add(ds_raw, IT.DSDECOD == "Randomized"),
    raw_var = "IT.DSDECOD",
    tgt_var = "DSCAT",
    tgt_val = "PROTOCOL MILESTONE",
    id_vars = oak_id_vars()
  ) %>%
  # Else assign as DISPOSITION EVENT
   hardcode_no_ct(
    raw_dat = condition_add(ds_raw, IT.DSDECOD != "Randomized"),
    raw_var = "IT.DSDECOD",
    tgt_var = "DSCAT",
    tgt_val = "DISPOSITION EVENT",
    id_vars = oak_id_vars()
  ) %>%
  # If not missing OTHERSP override previous logic and assign as OTHER EVENT
   hardcode_no_ct(
    raw_dat = condition_add(ds_raw, !is.na(OTHERSP)),
    raw_var = "OTHERSP",
    tgt_var = "DSCAT",
    tgt_val = "OTHER EVENT",
    id_vars = oak_id_vars()
  ) 

# Map timing and visit variables
ds <- ds %>%
  # Map DSSTDTC using assign_datetime from IT.DSSTDAT in ISO8601 format
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = "IT.DSSTDAT",
    tgt_var = "DSSTDTC",
    raw_fmt = "mm-dd-yyyy",
    id_vars = oak_id_vars()
  ) %>%
  # Map DSDTC using assign_datetime from DSDTCOL and DSTMCOL in ISO8601 format
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = c("DSDTCOL", "DSTMCOL"),
    tgt_var = "DSDTC",
    raw_fmt = c(list("mm-dd-yyyy", "H:M"))
  ) %>%
  # Map VISIT from INSTANCE using assign_ct
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISIT",
    ct_spec = study_ct,
    ct_clst = "VISIT",
    id_vars = oak_id_vars()
  ) %>%
  # Map VISITNUM from INSTANCE using assign_ct
  # Note: CT needs to be updated to account for missing terms: "Ambul Ecg Removal", 
  # "Unscheduled 6.1", "Unscheduled 1.1", "Unscheduled 5.1", "Unscheduled 4.1", 
  # "Unscheduled 8.2", and "Unscheduled 13.1".
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISITNUM",
    ct_spec = study_ct,
    ct_clst = "VISITNUM",
    id_vars = oak_id_vars()
  ) 

# Derive/assign USUBJID, STUDYID, and DOMAIN using mutate from dplyr
ds <- ds %>%
  dplyr::mutate(
    STUDYID = "CDISCPILOT01", # ref DM dataset
    DOMAIN = "DS",
    USUBJID = paste0("01-", ds_raw$patient_number) #ref DM dataset
  ) %>%
  # Derive DSSTDY - day relative to treatment start
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
    rec_vars = c("USUBJID", "DSTERM", "DSDECOD", "DSCAT", "DSDTC", "DSSTDTC"))














