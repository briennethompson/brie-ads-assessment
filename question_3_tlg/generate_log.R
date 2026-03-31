# ============================================================================
# The below code is used to generate the log for create_adsl.R
# It can be executed from the console or from the program itself
# ============================================================================

# Set working directory
setwd("/cloud/project/brie-ads-assessment")

# Write log file to specified logs folder
#logrx::axecute(
#  "question_3_tlg/01_create_ae_summary_table.R",
#  log_name = "01_create_ae_summary_table.log",
#  log_path = "question_3_tlg/logs"
#)

logrx::axecute(
  "question_3_tlg/02_stacked_bar_plot.R",
  log_name = "02_stacked_bar_plot.log",
  log_path = "question_3_tlg/logs"
)