# ============================================================================
# The below code is used to generate the log for create_adsl.R
# It can be executed from the console or from the program itself
# ============================================================================

# Set working directory
setwd("/cloud/project/brie-ads-assessment")

# Write log file to specified logs folder
logrx::axecute(
  "question_2_adam/create_adsl.R",
  log_name = "create_adsl.log",
  log_path = "question_2_adam/logs"
)