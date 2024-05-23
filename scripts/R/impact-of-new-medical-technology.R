# This is an attempt at calculating the impact of new medical technology on
# hospital activity. We use SUS APCS data (hospital inpatient admissions)

# load the libraries
library(readxl)
library(tidyverse)

data_path <- "C:/Users/GabrielHobro/OneDrive - NHS/Documents/New medical tech work/Data/"

# We start with a sample of the raw data first, which will be used to design a
# SQL script which will do the manipulations directly on the UDAL table
apcs_sample <- readxl::read_excel(paste0(data_path, "apcs_core_sample.xlsx"))

# glimpse the fields
glimpse(apcs_sample)

# Reduct the number of columns for ease of analysis and add pod flag
apcs_sample_1 <- apcs_sample |>
  dplyr::select(
    # Keep spell ID for identifying unique spells
    spell_id = Der_Spell_ID,
    age = Age_At_CDS_Activity_Date,
    sex = Sex,
    # Keep admission method for splitting by pod
    Admission_Method,
    Admission_Date,
    Der_Diagnosis_All,
    Der_Procedure_Count,
    Der_Procedure_All) |>
  mutate(pod = case_when(startsWith(Admission_Method,"1") ~ "IpElec",
                         startsWith(Admission_Method,"2") ~ "IpEmer",
                         startsWith(Admission_Method,"3*") ~ "IpMat",
                         TRUE ~ "Other")) |>
  janitor::clean_names()

# Check again
head(apcs_sample_1)

# The field `der_procedure_all` has the procedure codes, if there is more than
# one then it is delimited by a comma - we use a tidyverse function separate_rows().
# We also remove the "||"
apcs_sample_2 <- apcs_sample_1 |>
  # get rid of the blanks
  filter(!is.na(der_procedure_all)) |>
  tidyr::separate_rows(der_procedure_all, sep=",") |>
  # rename since we only have one code per row now
  dplyr::rename(der_procedure = der_procedure_all) |>
  dplyr::mutate(der_procedure = str_replace(der_procedure, "\\|\\|", ""))


# Now have one row per procedure and spell - let's organise by date
apcs_sample_2 <- apcs_sample_2 |>
  arrange(admission_date)

# identify the first instance of different codes
apcs_sample_3 <- apcs_sample_2 |>
  mutate(first_procedure = !duplicated(der_procedure))

# What we can do next is just count the instance per year and pod
apcs_sample_3 |>
  group_by(year = lubridate::year(admission_date),
           pod) |>
  summarise(new_procedures = sum(first_procedure)) |>
  pivot_wider(names_from = pod,
              values_from = new_procedures,
              values_fill = 0)


# next step :
# - identify a "lean-in" period where we establish a baseline
# - introduce a flag for the procedure to remain its "new" classification (e.g. 3 years)
# - count the number of spells by various cuts of new activity
# - perhaps calculate the bed days
# - then show to Steve for discussion...


