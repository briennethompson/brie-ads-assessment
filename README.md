# Brie Thompson - ADS Senior Programmer Assessment

R-based clinical programming assessment covering SDTM, ADaM, and TLF 
development using pharmaverse tools, with a bonus GenAI question in Python.

---

## Getting Started

To clone this Github repository in Posit Cloud:

1. Create a **New Project** in Posit Cloud
2. Open the terminal and run the below commands to clone the repository:
```bash
   cd /cloud/project
   git clone https://github.com/briennethompson/brie-ads-assessment.git
```

---

## Repository Structure

| Folder | Contents |
|--------|----------|
| `question_1_sdtm/` | SDTM DS domain creation using `sdtm.oak` |
| `question_2_adam/` | ADaM ADSL dataset creation using `admiral` |
| `question_3_tlg/`  | TLF outputs using `gtsummary` and `ggplot2` |
| `question_4/`      | Bonus GenAI clinical data assistant in Python |

---

## Question 1 - SDTM DS Domain
**Program:** `question_1_sdtm/01_create_ds_domain.R`  
**Input:** `pharmaverseraw::ds_raw`, `question_1_sdtm/sdtm_ct.csv`, `pharmaversesdtm::dm`  
**Output:** `question_1_sdtm/output/ds.xpt`  
**Log:** `question_1_sdtm/logs/01_create_ds_domain.log`

Creates the DS (Disposition) SDTM domain using `sdtm.oak`. 

---

## Question 2 - ADaM ADSL
**Program:** `question_2_adam/01_create_adsl.R`  
**Input:** `pharmaversesdtm` SDTM datasets (DM, DS, EX, AE, VS, SUPPDM)  
**Output:** `question_2_adam/output/adsl.xpt`  
**Log:** `question_2_adam/logs/01_create_adsl.log`

Creates the ADSL subject-level analysis dataset using `admiral`. 

---

## Question 3 - TLFs
**Program:** `01_create_ae_summary_table.R`, `02_create_visualizations.R`  
**Input:** `pharmaverseadam::adsl`, `pharmaverseadam::adae`    
**Outputs:** `question_3_tlg/output`
**Log:** `question_3_tlg/logs`

Three TLF outputs created using `gtsummary` and `ggplot2`:

| Output | Description |
|--------|-------------|
| `teae_summary_table.html` | Treatment emergent AE summary table by SOC and preferred term |
| `stacked_bar_plot.png` | AE severity distribution by treatment arm |
| `ae_forest_plot.png` | Top 10 most frequent AEs with 95% Clopper-Pearson CIs |

---

## Question 4 - GenAI Clinical Data Assistant
**Program:** `question_4/question_4.py`  
**Input:** `question_4/adae.csv`

A Python-based GenAI assistant that translates natural language questions 
into structured Pandas queries. Key features:
- Schema-aware LLM prompt design
- `ClinicalTrialDataAgent` class with mock and OpenAI LLM modes
- Maps user intent to AESEV, AESOC, or AETERM automatically
- Returns unique subject count and IDs matching the query

To run with mock LLM (no API key needed):
```bash
python3 question_4/question_4.py
```

To run with OpenAI API:
```python
agent = ClinicalTrialDataAgent(ae, use_mock=False)
```

---

## Tools & Packages

| Language | Packages |
|----------|----------|
| R | `sdtm.oak`, `admiral`, `pharmaverseraw`, `pharmaversesdtm`, `tidyverse`, `haven`, `gtsummary`, `ggplot2`, `logrx`, `testthat` |
| Python | `pandas`, `openai` |

---

## How to Run

### R Programs
Each program can be executed and logged individually using `logrx::axecute()`.
Run the following from the R console after setting the working directory:
```r
setwd("/cloud/project/brie-ads-assessment")

# Question 1 - DS Domain
logrx::axecute(
  "question_1_sdtm/01_create_ds_domain.R",
  log_name = "01_create_ds_domain.log",
  log_path = "question_1_sdtm/logs"
)

# Question 2 - ADSL
logrx::axecute(
  "question_2_adam/create_adsl.R",
  log_name = "create_adsl.log",
  log_path = "question_2_adam/logs"
)

# Question 3 - 01 Summary Table
logrx::axecute(
  "question_3_tlg/01_create_ae_summary_table.R",
  log_name = "01_create_ae_summary_table.log",
  log_path = "question_3_tlg/logs"
)

# Question 4 - 02 Visualizations
logrx::axecute(
  "question_3_tlg/02_create_visualizations.R",
  log_name = "02_create_visualizations.log",
  log_path = "question_3_tlg/logs"
)
```

### Python Program
Since Posit Cloud manages Python through `reticulate`, run from the R console:
```r
library(reticulate)
py_install("pandas")  # only needed on first run
source_python("question_4/question_4.py")
```

---

## Testing
Each R program includes `testthat` unit tests embedded at the end 
of the program that validate key derivations and outputs.