library(DBI)
library(readtext)
library(dplyr)
library(ggplot2)
library(stringr)
library(tidyr)

# connext to UDAL patient level
con_udal_patient <- dbConnect(odbc::odbc(), "udal_patient_level",
                              timeout = 10)



# Load the script for the lookup table ------------------------------------

dim_procedures_lookup_tbl_script <- readtext::readtext("HESMART Dim_Procedure.sql")

dim_procedures_lookup_tbl <- DBI::dbGetQuery(
  con_udal_patient,
  dim_procedures_lookup_tbl_script$text)

# just filter to the four digit codes
dim_procedures_lookup_tbl <- dim_procedures_lookup_tbl |>
  filter(nchar(Procedure_Code)==4)

# a table showing new procedures for version 6 to 9 by chapter
new_procedures_by_chapter_version_tbl <- dim_procedures_lookup_tbl |>
  filter(Min_OPCS_Version > "4.5") |>
  count(Min_OPCS_Version,Chapter_Code, Chapter_Description) |>
  pivot_wider(names_from = Min_OPCS_Version, values_from = n, values_fill=0) |>
  arrange(Chapter_Code)

# ggplot a bar chart
new_procedures_by_chapter_version_tbl |>
  pivot_longer(cols = `4.6`:`4.9`, names_to = "Min_OPCS_Version", values_to = "n") |>
  ggplot(aes(x=Chapter_Code, y=n, fill = Chapter_Code)) +
  geom_col() +
  facet_wrap(~Min_OPCS_Version) +
  labs(title = "New procedures by chapter",
       subtitle = "OPCS versions 4.6-4.10")


# Load the SQL script for the counts of procedures by time
counts_procedures_scipt <- readtext::readtext("counts of primary procedures by time and opcs version.sql")

# Run the SCL script for the counts of procedures by time
primary_proc_year_month_chapter_opcs_version <- DBI::dbGetQuery(
  con_udal_patient,
  counts_procedures_scipt$text)

# check the data
glimpse(primary_proc_year_month_chapter_opcs_version)

# Some formatting
primary_proc_year_month_chapter_opcs_version <- primary_proc_year_month_chapter_opcs_version |>
  # just the first 3 digits from OPCS version
  mutate(Min_OPCS_Version = str_sub(Min_OPCS_Version,1,3)) |>
  # format the date so that e.g. 1 April 2009 is "Apr-09"
  mutate(OPCS_Release_Date = format(OPCS_Release_Date, '%b-%y'))

# ignore the first opcs since don't know which were actually released with that...
primary_proc_year_month_chapter_opcs_version_4.6_plus <- primary_proc_year_month_chapter_opcs_version |>
  filter(Min_OPCS_Version > "4.5")

# A basic chart -
primary_proc_year_month_chapter_opcs_version_4.6_plus |>
  summarise(n = sum(Count), .by = c(Min_OPCS_Version, Year, Chapter_Code)) |>
  arrange(Min_OPCS_Version,Year, Chapter_Code) |>
  ggplot(aes(x=Year, y=n, fill = Chapter_Code)) +
  geom_col() +
  facet_wrap(~Min_OPCS_Version) +
  labs(title="Counts of primary procedures by year and chapter",
       subtitle="OPCS Versions 4.6-4.10")






