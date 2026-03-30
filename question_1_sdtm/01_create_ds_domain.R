# Initialize libraries
library(sdtm.oak)
library(pharmaverseraw)
library(pharmaversesdtm)
library(dplyr)

# Read in raw DS data 
ds_raw <- pharmaverseraw::ds_raw

# Read in SDTM DM data
dm <- pharmaversesdtm::dm

# Create oak_id_vars
ds_raw <- ds_raw %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "ds_raw"
  )