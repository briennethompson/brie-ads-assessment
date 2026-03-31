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

# Map Qualifiers (DSDECOD AND DSCAT)
ds <- ds %>%
  # Map DSDECOD using controlled terminology and condition_add
  assign_ct(
    raw_dat = condition_add(ds_raw, is.na(OTHERSP)), #filter raw data
    raw_var = "IT.DSDECOD",
    tgt_var = "DSDECOD",
    ct_spec = study_ct,
    ct_clst = "C66727",
    id_vars = oak_id_vars()
  ) %>%
  # Map DSCAT without using controlled terminology (missing from the study_ct file) and condition_add
  hardcode_no_ct(
    raw_dat = condition_add(ds_raw, IT.DSDECOD == "Randomized"),
    raw_var = "IT.DSDECOD",
    tgt_var = "DSCAT",
    tgt_val = "PROTOCOL MILESTONE",
    id_vars = oak_id_vars()
  ) %>%
  # it doesn't seem that condition_add can handle multiple conditions so DSCAT is broken into 2 calls
   hardcode_no_ct(
    raw_dat = condition_add(ds_raw, IT.DSDECOD != "Randomized"),
    raw_var = "IT.DSDECOD",
    tgt_var = "DSCAT",
    tgt_val = "DISPOSITION EVENT",
    id_vars = oak_id_vars()
  )









