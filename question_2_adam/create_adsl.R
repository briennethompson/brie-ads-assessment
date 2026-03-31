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

# Derive age grouping variables - AGEGR9 and AGEGR9N
# Create lookup table for AGEGR9/AGEGR9N
agegr9_lookup <- admiral::exprs(
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
    dataset = .,
    new_vars_prefix = "EXST",
    dtc = EXSTDTC,
    highest_imputation = "h",
    time_imputation = "00:00:00",
    flag_imputation = "time",
    ignore_seconds_flag = TRUE
  ) 

# Merge ex_ext with our working dataset to derive TRTSDTM/TRTSTMF
adsl <- adsl %>%
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
  )

