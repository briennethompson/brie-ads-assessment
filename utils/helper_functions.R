# ============================================================
# Function: get_last_date
# Purpose:  Get last date per subject from a source dataset
#
# Args:
#   data:       Source dataset
#   dtc_var:    Date character variable (unquoted)
#   output_var: Name of output date variable (unquoted)
#
# Returns:
#   Dataset with USUBJID and last date per subject
# ============================================================

get_last_date <- function(data, dtc_var, output_var) {
  data %>%
    dplyr::mutate(temp_date = lubridate::date(
      admiral::convert_dtc_to_dtm({{ dtc_var }})
    )) %>%
    dplyr::filter(!is.na(temp_date)) %>%
    dplyr::group_by(USUBJID) %>%
    dplyr::summarise(
      {{ output_var }} := max(temp_date, na.rm = TRUE),
      .groups = "drop"
    )
}