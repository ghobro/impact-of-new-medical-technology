# load libraries
library(DBI)
library(dplyr)
library(ggplot2)
library(stringr)
library(tidyr)
library(readxl)

# connect to UDAL patient level
con_udal_patient <- dbConnect(odbc::odbc(), "udal_patient_level",
                              timeout = 10)

# state the folder I'm working in
new_medical_tech_folder <- "C:/Users/gabriel.hobro/OneDrive - NHS/Documents/New medical tech work/"


# Load the table of coding equivalencies
toce <- readxl::read_excel(
  paste0(
    new_medical_tech_folder,
    "OPCS-4 files/OPCS410 Data files txt/OPCS10 ToCE Analysis Nov 2022 V1.0.xlsx"))

# filter to the codes that have no equivalencies in 4.2 (i.e. added since 4.3 in Apr-06)
# additionally remove the ones in Y and Z which are about methods and areas, respectively
toce_new <- toce |>
  filter(`OPCS 4.2`=="NONE" &
           !(substring(Description,1,1) %in% c("Y", "Z")))

# The resulting codes can be found in the 4.10 column
new_codes <- toce_new$`OPCS 4.10`

# need to remove the dot as it isn't in the HES data
new_codes <- stringr::str_remove(new_codes, "\\.")

# add the apostrophes
new_codes <- paste0("'", new_codes, "'")

# create a sql command which selects counts of those primary procedures by year
sql_command <- paste0(
  "select YEAR(OPDATE_01) as [year], OPERTN_01 as [primary_procedure], COUNT(*) as [n] ",
  "from [HESAPC].[vw_HESAPC] ",
  "where OPERTN_01 in (",
  paste(new_codes, collapse = ", "), # creates a list of all the codes delimited by commas
  ") and YEAR(OPDATE_01) between 2000 and 2022 group by YEAR(OPDATE_01), OPERTN_01")

# Run that query
new_procedure_counts <- DBI::dbGetQuery(
  con_udal_patient,
  sql_command)

# load the data on when code was introduced - from the HRG code grouper
# also includes the description of the operation
codes_by_version <- read_excel(
  paste0(
    new_medical_tech_folder,
    "Research/HRG4++202324+National+Costs+Grouper+Code+To+Group+v1.0.xlsx"),
  sheet = "OPCS")

#change the names
names(codes_by_version) <- c("code", "description", "version_introduced")

# join the data
new_procedure_counts_full <- left_join(
  new_procedure_counts,
  codes_by_version,
  by = c("primary_procedure" = "code"))

# Remove the codes from 4.10 as they only added in April 2023 so DQ poor in HES
new_procedure_counts_full <- new_procedure_counts_full |>
  filter(version_introduced != "4.10")

# re-organise the columns
new_procedure_counts_full <- new_procedure_counts_full |>
  select(year, primary_procedure, description, version_introduced, n)

# write the data
write.csv(new_procedure_counts_full,
          paste0(
            new_medical_tech_folder,
            "incidence of primary procedures since OPCS-4.2 (HES).csv"),
          row.names = FALSE)

# exploratory chart - incidence by version and year
# Interesting also to see the impact of filtering the end of the time frame
new_procedure_counts_full |>
  summarise(n = sum(n), .by = c(version_introduced, year)) |>
  ggplot(aes(x=year, y=n)) +
  geom_line() +
  scale_y_continuous(limits = c(0, NA),labels = scales::comma) +
  facet_wrap(~version_introduced, scales = "free_y") +
  labs(title = "Incidence of primary procedures over time by OPCS-4 version") +
  theme(axis.title = element_blank())

# exactly the same as above but with filter on year <2020
new_procedure_counts_full |>
  filter(year<=2020) |>
  summarise(n = sum(n), .by = c(version_introduced, year)) |>
  ggplot(aes(x=year, y=n)) +
  geom_line() +
  scale_y_continuous(limits = c(0, NA),labels = scales::comma) +
  facet_wrap(~version_introduced, scales = "free_y") +
  labs(title = "Incidence of primary procedures over time by OPCS-4 version",
       subtitle = "Year <= 2020") +
  theme(axis.title = element_blank())



# HES DQ ------------------------------------------------------------------

# there appears to be a massive rise in 2021 and very little data in HES prior to 20009
# Just going to look at the raw counts of episodes by year
episode_counts_hes_apc <- DBI::dbGetQuery(
  con_udal_patient,
  "select
    year(admidate_derived) as year,
    count(*) as count
  from
    [HESAPC].[vw_HESAPC]
  where
    year(admidate_derived) >= 2000
  group by
    year(admidate_derived)")

# simple plot
ggplot(episode_counts_hes_apc) +
  geom_col(aes(x=year, y=count)) +
  ggtitle("Episode counts in HES APC by year since 2000")


# Comparing to SUS data ---------------------------------------------------

con_udal_warehouse <- dbConnect(odbc::odbc(), dsn="udal_warehouse", timeout = 10)

episode_counts_sus_apc <- DBI::dbGetQuery(
  con_udal_warehouse,
  "select
    year([Admission_Date]) as year,
    count(*) as count
  from
    [SUS_APC].[APCE_Core]
  where
    year([Admission_Date]) >= 2000
  group by
    year([Admission_Date])")

# simple plot
ggplot(episode_counts_sus_apc) +
  geom_col(aes(x=year, y=count)) +
  ggtitle("Episode counts in SUS APC by year since 2000")


spell_counts_sus_apc <- DBI::dbGetQuery(
  con_udal_warehouse,
  "select
    year([Admission_Date]) as year,
    count(*) as count
  from
    [SUS_APC].[APCS_Core]
  where
    year([Admission_Date]) >= 2000
  group by
    year([Admission_Date])")

# simple plot
ggplot(spell_counts_sus_apc) +
  geom_col(aes(x=year, y=count)) +
  ggtitle("Spell counts in SUS APC by year since 2000")

# Comparing the SUS and HES side by side...
glimpse(episode_counts_hes_apc)
glimpse(episode_counts_sus_apc)

plotly::ggplotly(bind_rows(hes = episode_counts_hes_apc,
          sus = episode_counts_sus_apc,
          .id = "source") |>
  ggplot(aes(x=year, y=count, fill=source)) +
  geom_col(position = "dodge") +
  ggtitle("Episode counts in SUS and HES APC by year since 2000"))


# Using SUS APC Episodes data instead of HES ------------------------------

# Quickly checking how the figures compare using SUS instead of HES

# just using a single procedure code "A847"




A847_counts_sus_apc <- DBI::dbGetQuery(
  con_udal_warehouse,
  "select
    year([Episode_Start_Date]) as year,
    [Der_Primary_Procedure_Code] as [primary_procedure],
    count(*) as [n]
  from
    [SUS_APC].[APCE_Core]
  where
    year([Episode_Start_Date]) >= 2000
    and [Der_Primary_Procedure_Code] = 'A847'
  group by
    year([Episode_Start_Date]),
    [Der_Primary_Procedure_Code]",
    )

A847_counts_hes_apc <- new_procedure_counts_full |>
  filter(primary_procedure=="A847") |>
  select(!c(description, version_introduced))

ggplot(
  bind_rows(
    hes = A847_counts_hes_apc,
    sus = A847_counts_sus_apc,
    .id = "data_source"),
  aes(x=year, y = n, colour = data_source)) +
  geom_line() +
  ggtitle("Counts of A84.7 as primary procedure for SUS and HES")

# mirror each other ver closely then divert after 2020
# must be a DQ issue in HES post covid (or just coincidence post 2020)

# To do
# - see what happens if using proc table

# this would mainly be important if we're interested in the specific date
# question about the length of procedures and whether or not there would be
# significant difference between the episode start and procedure date

episode_length_sus <- DBI::dbGetQuery(
  con_udal_warehouse,
  "select
	  year([Episode_Start_Date]) as [episode_year],
	  cast(avg(DATEDIFF(day, [Episode_Start_Date], [Episode_End_Date])) as float) AS [episode_length]
  from
	  [SUS_APC].[APCE_Core]
  where
  	year([Episode_Start_Date]) between 2009 and 2022
  group by
  	year([Episode_Start_Date])
  order by
    year([Episode_Start_Date]);")

# generally a difference of around 2 days or so

A847_counts_sus_apc_proc <- DBI::dbGetQuery(
  con_udal_warehouse,
  "select
    year([Primary_Procedure_Date]) as [year],
    [Primary_Procedure_Code] as [primary_procedure],
    count(*) as [n]
  from
    [SUS_APC].[APCE_Proc]
  where
    year([Primary_Procedure_Date]) >= 2000
    and [Primary_Procedure_Code] = 'A847'
  group by
    year([Primary_Procedure_Date]),
    [Primary_Procedure_Code]"
)

ggplot(
  bind_rows(
    hes = A847_counts_hes_apc,
    sus = A847_counts_sus_apc,
    sus_proc = A847_counts_sus_apc_proc,
    .id = "data_source"),
  aes(x=year, y = n, colour = data_source)) +
  geom_line() +
  ggtitle("Counts of A84.7 as primary procedure for SUS and HES")


# re-run the whole analysis using SUS (main episodes table or proc) -------

# creating the sql command
sql_command_sus <- paste0(
  "select YEAR([Primary_Procedure_Date]) as [year], [Primary_Procedure_Code] as [primary_procedure], COUNT(*) as [n] ",
  "from [SUS_APC].[APCE_Proc] ",
  "where [Primary_Procedure_Code] in (",
  paste(new_codes, collapse = ", "), # creates a list of all the codes delimited by commas
  ") and YEAR([Primary_Procedure_Date]) between 2000 and 2022 group by YEAR([Primary_Procedure_Date]), [Primary_Procedure_Code]")

# executing it
new_procedure_counts_sus <- DBI::dbGetQuery(
  con_udal_warehouse,
  sql_command_sus)

# join the data on when code was introduced - from the HRG code grouper
new_procedure_counts_sus_full <- left_join(
  new_procedure_counts_sus,
  codes_by_version,
  by = c("primary_procedure" = "code"))

# Remove the codes from 4.10 as they only added in April 2023 so DQ poor in HES
new_procedure_counts_sus_full <- new_procedure_counts_sus_full |>
  filter(version_introduced != "4.10")

# re-organise the columns
new_procedure_counts_sus_full <- new_procedure_counts_sus_full |>
  select(year, primary_procedure, description, version_introduced, n)

# write the data
write.csv(new_procedure_counts_sus_full,
          paste0(
            new_medical_tech_folder,
            "incidence of primary procedures since OPCS-4.2 (SUS).csv"),
          row.names = FALSE)

# exploratory chart - incidence by version and year
# Interesting also to see the impact of filtering the end of the time frame
bind_rows(hes = new_procedure_counts_full,
          sus = new_procedure_counts_sus_full,
          .id = "data_source") |>
  summarise(n = sum(n), .by = c(data_source, version_introduced, year)) |>
  ggplot(aes(x=year, y=n, colour = data_source)) +
  geom_line() +
  scale_y_continuous(limits = c(0, NA),labels = scales::comma) +
  facet_wrap(~version_introduced, scales = "free_y") +
  labs(title = "Incidence of primary procedures over time by OPCS-4 version for SUS and HES") +
  theme(axis.title = element_blank())

# exactly the same as above but with filter on year <2020
bind_rows(hes = new_procedure_counts_full,
          sus = new_procedure_counts_sus_full,
          .id = "data_source") |>
  filter(year <= 2020) |>
  summarise(n = sum(n), .by = c(data_source, version_introduced, year)) |>
  ggplot(aes(x=year, y=n, colour = data_source)) +
  geom_line() +
  scale_y_continuous(limits = c(0, NA),labels = scales::comma) +
  facet_wrap(~version_introduced, scales = "free_y") +
  labs(title = "Incidence of primary procedures over time by OPCS-4 version for SUS and HES",
       subtitle = "year <= 2020") +
  theme(axis.title = element_blank())


# SUS APCS ----------------------------------------------------------------

# We may want to use spells data in SUS
# There is an issue here in the way that episodes are combined into spells
# We can look at a particular spell (ID: 1704950529596981363) in both APCE and
# APCS to see how it works

# this is using the episodes data
sus_proc_episodes_vs_spells_1 <- DBI::dbGetQuery(
  con_udal_warehouse,
  "SELECT
      [Admission_Method]
      ,[Admission_Date]
      ,[Der_Spell_ID]
      ,[Episode_Number]
      ,[Der_Primary_Procedure_Code]
      ,[Der_Procedure_Code_2]
      ,[Der_Procedure_Code_3]
      ,[Der_Procedure_Code_4]
      ,[Der_Procedure_Code_5]
      ,[Der_Procedure_Code_6]
      ,[Der_Procedure_Code_7]
      ,[Der_Procedure_Code_8]
      ,[Der_Procedure_Code_9]
      ,[Der_Procedure_Code_10]
      ,[Der_Procedure_Code_11]
      ,[Der_Procedure_Code_12]
      ,[Der_Procedure_Code_13]
      ,[Der_Procedure_Code_14]
      ,[Der_Procedure_Code_15]
      ,[Der_Procedure_Code_16]
      ,[Der_Procedure_Code_17]
      ,[Der_Procedure_Code_18]
      ,[Der_Procedure_Code_19]
      ,[Der_Procedure_Code_20]
      ,[Der_Procedure_Code_21]
      ,[Der_Procedure_Code_22]
      ,[Der_Procedure_Code_23]
      ,[Der_Procedure_Code_24]
      ,[Der_Procedure_Count]
      ,[Der_Procedure_All]
  FROM [SUS_APC].[APCE_Core]
  where [Der_Spell_ID] = '1704950529596981363'
  order by [Episode_Number]"
)

# this is using the spells data (i.e. there'll be a single row)
sus_proc_episodes_vs_spells_2 <- DBI::dbGetQuery(
  con_udal_warehouse,
  "SELECT
	[Der_Spell_ID],
	[Der_Episode_Count],
	[Admission_Method],
  cast([Admission_Date] as date) as [Admission_Date],
	[Der_Procedure_Count],
  [Der_Procedure_All]
 FROM
	[SUS_APC].[APCS_Core]
where
	--[Der_Procedure_Count] > 0 and
	[Der_Spell_ID] = '1704950529596981363'"
)

glimpse(sus_proc_episodes_vs_spells_1)
glimpse(sus_proc_episodes_vs_spells_2)

# So, we can see that where a spell comprises multiple episodes with procedures,
# they are all added to a single column where "||" delimits the episodes and the
# specific procedures are delimited by commas.
#
# That means that there is not necessarily a primary procedure that can be
# mapped on a one-to-one basis with any given multi-episode spell.

# In the case of the specific example above, you can see that there were 5
# episodes within the spell, 3 of which involved procedures, but the ordering of
# the episodes within the `Der_Procedure_All` column is based simply on the
# episode number (which is presumably to do with time rather than hierarchy),
# which means gives no rationale for choosing any one of the three primary
# procedures over the others.

## Potential solution: focus on elective cases (including day cases)

# What is the number of episodes per spell for elective vs non-elective admissions?

sus_spells_episode_count_by_pod <- DBI::dbGetQuery(
  con_udal_warehouse,
  "SELECT
    case
      when left([Admission_Method], 1) = \'1\' then \'IpElec\'
      when left([Admission_Method], 1) = \'3\' then \'IpMat\'
      else \'IpEmer\'
      end as [pod],
	  case
	    when [Der_Episode_Count] = 1 then \'Single episode\'
	    else \'Multiple episodes\'
	    end as [episode_count],
    COUNT(*) as [count]
  FROM
	  [SUS_APC].[APCS_Core]
	WHERE
	  year([Admission_Date]) between 2011 and 2019
	GROUP BY
	  case
      when left([Admission_Method], 1) = \'1\' then \'IpElec\'
      when left([Admission_Method], 1) = \'3\' then \'IpMat\'
      else \'IpEmer\'
      end,
    case
	    when [Der_Episode_Count] = 1 then \'Single episode\'
	    else \'Multiple episodes\'
	    end"
  )

sus_spells_episode_count_by_pod <- sus_spells_episode_count_by_pod |>
  arrange(pod) |>
  mutate(prop = count / sum(count), .by = pod)

ggplot(
  sus_spells_episode_count_by_pod,
  aes(x = pod, y = prop, fill = episode_count)) +
  geom_col(position = "fill")

# We can see that >99% of elective admissions are one epsiode.
# This is starkly different to emergency admissions, of which ~28% comprise multiple episodes.

View(sus_spells_episode_count_by_pod_wide)


# Analysis with SUS elective spells ---------------------------------------

# This is designed to take the primary procedure (can look at all procedures
# later) from elective spells in SUS. For now we just look at the 4-digit code
# after the initial "\\".
# NB this in theory should be nearly identical to simple using the episodes data
# since we're filtering to elective which are almost always single episodes
sql_command_sus_apcs <- paste0(
  "select year([Admission_Date]) as [year], substring(Der_Procedure_All,3,4) as [primary_procedure], COUNT(*) as [n] ",
  "from [SUS_APC].[APCS_Core] ",
  "where substring(Der_Procedure_All,3,4) in (",
  paste(new_codes, collapse = ", "), # creates a list of all the codes delimited by commas
  ") and year([Admission_Date]) between 2000 and 2022 ",
  "and left([Admission_Method], 1) = \'1\' ",
  "group by year([Admission_Date]), substring(Der_Procedure_All,3,4)")

# Run that query
new_procedure_counts_sus_elective_apcs <- DBI::dbGetQuery(
  con_udal_warehouse,
  sql_command_sus_apcs)

# join the data on OPCS versions
new_procedure_counts_sus_elective_apcs_full <- left_join(
  new_procedure_counts_sus_elective_apcs,
  codes_by_version,
  by = c("primary_procedure" = "code"))

# Remove the codes from 4.10 as they only added in April 2023 so DQ poor in HES
new_procedure_counts_sus_elective_apcs_full <- new_procedure_counts_sus_elective_apcs_full |>
  filter(version_introduced != "4.10")

# re-organise the columns
new_procedure_counts_sus_elective_apcs_full <- new_procedure_counts_sus_elective_apcs_full |>
  select(year, primary_procedure, description, version_introduced, n)

# write the data
write.csv(new_procedure_counts_sus_elective_apcs_full,
          paste0(
            new_medical_tech_folder,
            "incidence of primary procedures since OPCS-4.2 (SUS APCS elective_only).csv"),
          row.names = FALSE)

# exploratory chart - incidence by version and year
# Interesting also to see the impact of filtering the end of the time frame
new_procedure_counts_sus_elective_apcs_full |>
  summarise(n = sum(n), .by = c(version_introduced, year)) |>
  ggplot(aes(x=year, y=n)) +
  geom_line() +
  scale_y_continuous(limits = c(0, NA),labels = scales::comma) +
  facet_wrap(~version_introduced, scales = "free_y") +
  labs(title = "Incidence of primary procedures over time by OPCS-4 version",
       subtitle = "SUS APCS Elective Admissions only") +
  theme(axis.title = element_blank())


# SUS APCE vs APCS for elective -------------------------------------------

# in theory the data should be almost identical when using elective admissions,
# given that they are practically always one episode only

# the next section will be identical to previous, except for using the episodes
# data which means primary procedure is already in its own column

sql_command_sus_apce <- paste0(
  "select year([Admission_Date]) as [year], [Der_Primary_Procedure_Code] as [primary_procedure], COUNT(*) as [n] ",
  "from [SUS_APC].[APCE_Core] ",
  "where [Der_Primary_Procedure_Code] in (",
  paste(new_codes, collapse = ", "), # creates a list of all the codes delimited by commas
  ") and year([Admission_Date]) between 2000 and 2022 ",
  "and left([Admission_Method], 1) = \'1\' ",
  "group by year([Admission_Date]), [Der_Primary_Procedure_Code]")

# Run that query
new_procedure_counts_sus_elective_apce <- DBI::dbGetQuery(
  con_udal_warehouse,
  sql_command_sus_apce)

# join the data on OPCS versions
new_procedure_counts_sus_elective_apce_full <- left_join(
  new_procedure_counts_sus_elective_apce,
  codes_by_version,
  by = c("primary_procedure" = "code"))

# Remove the codes from 4.10 as they only added in April 2023 so DQ poor in HES
new_procedure_counts_sus_elective_apce_full <- new_procedure_counts_sus_elective_apce_full |>
  filter(version_introduced != "4.10")

# re-organise the columns
new_procedure_counts_sus_elective_apce_full <- new_procedure_counts_sus_elective_apce_full |>
  select(year, primary_procedure, description, version_introduced, n)

# write the data
write.csv(new_procedure_counts_sus_elective_apce_full,
          paste0(
            new_medical_tech_folder,
            "incidence of primary procedures since OPCS-4.2 (SUS APCE elective_only).csv"),
          row.names = FALSE)

new_procedure_counts_sus_elective_apce_vs_apcs <- bind_rows(
  apcs = new_procedure_counts_sus_elective_apcs_full,
  apce = new_procedure_counts_sus_elective_apce_full,
  .id = "data")


# exploratory chart - incidence by version and year
# Interesting also to see the impact of filtering the end of the time frame
new_procedure_counts_sus_elective_apce_vs_apcs |>
  summarise(n = sum(n), .by = c(data,version_introduced, year)) |>
  ggplot(aes(x=year, y=n, colour = data)) +
  geom_line() +
  scale_y_continuous(limits = c(0, NA),labels = scales::comma) +
  facet_wrap(~version_introduced, scales = "free_y") +
  labs(title = "Incidence of primary procedures over time by OPCS-4 version",
       subtitle = "SUS APCE vs APCS, Elective Admissions only") +
  theme(axis.title = element_blank())




