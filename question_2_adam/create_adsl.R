# Set working directory to project root
setwd("/cloud/project/brie-ads-assessment")

# Load libraries
library(metacore)
library(metatools)
library(pharmaversesdtm)
library(admiral)
library(xportr)
library(dplyr)
library(tidyr)
library(lubridate)
library(stringr)

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
dm_suppdm <- metatools::combine_supp(dm, suppdm)

# Use combined demog data as basis for ADSL
adsl <- dm_suppdm %>%
  select(-DOMAIN)
