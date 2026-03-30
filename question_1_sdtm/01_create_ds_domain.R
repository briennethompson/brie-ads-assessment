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

