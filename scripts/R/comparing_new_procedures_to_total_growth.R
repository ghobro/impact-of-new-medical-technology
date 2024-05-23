# In this script, we compare the rise in elective admissions and outpatient
# attendances over the period from 2009 to 2019 with the adoption curves of
# new procedure codes as they were added to the OPCS-4.

new_medical_tech_folder <- "C:/Users/gabriel.hobro/OneDrive - NHS/Documents/New medical tech work/"

# Total activity data -----------------------------------------------------

# Read in the data (copied from Track 1 NDG analysis)
sus_activity_data <- readxl::read_excel(
  paste0(new_medical_tech_folder, "Data/Hospital activity data (SUS).xlsx"))

# filter to opa and elective and year up to 2019
sus_opa_and_elective <- sus_activity_data |>
  filter(pod %in% c("IpElec", "opAtt"),
         yr <= 2019)

# re-group the data
sus_opa_and_elective <- sus_opa_and_elective |>
  summarise(activity = sum(activity), .by = c(yr, pod))

# Calculate additional activity each year
sus_opa_and_elective_growth <- sus_opa_and_elective |>
  mutate(additional_activity = activity - lag(activity, order_by = yr), .by = pod)

# new procedures data -----------------------------------------------------

# load in csvs containing the data on incidence of new procedures
sus_elective_procedures <- read.csv(
  paste0(new_medical_tech_folder,
         "incidence of primary procedures since OPCS-4.2 (SUS APCS elective_only).csv")
)

sus_outpatient_procedures <- read.csv(
  paste0(new_medical_tech_folder,
         "incidence of primary procedures since OPCS-4.2 (SUS OPA).csv")
)

# combine them together
elective_opa_new_procedures <- bind_rows(
  "IpElec" = sus_elective_procedures,
  "opAtt" = sus_outpatient_procedures,
  .id = "pod")



# comparison --------------------------------------------------------------

# we can start by stitching the two data frames together to enable a rudimentary
# analysis / visual comparison

# we filter to 2009 to 2019 and just count the activity associated with codes f
# from all OPCS-4 releases after 4.2
new_procedures_year_2009_2019 <- elective_opa_new_procedures |>
  filter(between(year, 2009, 2019)) |>
  summarise(n = sum(n), .by = c(pod, year))

# combine data together
full_data_comparison <- left_join(
  sus_opa_and_elective_growth,
  new_procedures_year_2009_2019,
  by = c("yr" = "year", "pod")) |>
  rename(new_procedures_activity = n) |>
  pivot_longer(cols = activity:new_procedures_activity)

# a simple plot:
ggplot(filter(full_data_comparison, name != "additional_activity"),
       aes(x=yr, y = value, colour = name)) +
  geom_line() +
  facet_wrap(~pod, scales = "free_y") +
  scale_x_continuous(breaks = scales::pretty_breaks()) +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = "Comparison of total activity and activity associated with new procedures",
       subtitle = "By OPCS-4 chapter")

# splitting by chapter
new_procedures_year_chapter_2009_2019 <- elective_opa_new_procedures |>
  filter(between(year, 2009, 2019)) |>
  summarise(n = sum(n), .by = c(pod, year, version_introduced))  |>
  mutate(yr = year, version_introduced = factor(version_introduced))

ggplot() +
  geom_col(data = new_procedures_year_chapter_2009_2019, aes(x=year, y=n, fill = version_introduced)) +
  geom_line(data = sus_opa_and_elective_growth, aes(x=yr,y=activity, color = "total activity")) +
  facet_wrap(~pod, scales = "free_y") +
  scale_x_continuous(breaks = scales::pretty_breaks()) +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(title = "Comparison of total activity and activity associated with new procedures",
       subtitle = "By OPCS-4 chapter")



# firstly with no
