# The below code is used to generate the log for 01_create_ds_domain.R. It can be
# executed from the command line or from the program itself

# Set working directory
setwd("/cloud/project/brie-ads-assessment")

# Write log file to specified logs folder
logrx::axecute(
  "question_1_sdtm/01_create_ds_domain.R",
  log_name = "01_create_ds_domain.log",
  log_path = "question_1_sdtm/logs"
)