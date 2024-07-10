# a comparison of all the data cuts...

hes_strategy_unit <- readxl::read_excel(
  here("data", "hes_output_sw_SUenv_240529.xlsx")
  ) |>
  summarise(n=sum(n), .by = c("year", "pod"))

hes_udal <- readxl::read_excel(
  here("data", "hes_output_udal_240529.xlsx")
  ) |>
  summarise(n=sum(n), .by = c("year", "pod"))

sus_udal_elective <- read.csv(
  here("data", "incidence of primary procedures since OPCS-4.2 (SUS APCS elective_only).csv")
  )
sus_udal_outpatient <- read.csv((
  here("data", "incidence of primary procedures since OPCS-4.2 (SUS OPA).csv"))
  )

sus_udal <- dplyr::bind_rows(
  "elective inpatients" = sus_udal_elective,
  "outpatient attendances" = sus_udal_outpatient,
  .id = "pod"
  ) |>
  summarise(n=sum(n), .by = c("year", "pod")
            )

# Combine all together
all_data_compared <- bind_rows(
  "hes_su" = hes_strategy_unit,
  "hes_udal" = hes_udal,
  "sus_udal" = sus_udal,
  .id = "data_source") |>
  filter(between(year, 2006, 2019))

write.csv(all_data_compared,
          here("data", "procedures_data_sources_comparison.csv"))


all_data_compared_plot <- ggplot(all_data_compared, aes(x=year, y=n, colour = data_source)) +
  geom_line(size = 1) +
  facet_wrap(~pod, scales = "free_y") +
  scale_y_continuous(labels = scales::comma) +
  NHSRtheme::theme_nhs() +
  NHSRtheme::scale_colour_nhs()

plotly::ggplotly(all_data_compared_plot)
