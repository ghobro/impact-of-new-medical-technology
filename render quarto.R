# This will render the quarto file with the date that it was rendered in its
# name

quarto::quarto_render(
  input = "impact of new procedures report.qmd",
  output = paste(Sys.Date(), "impact of new procedures.html"))
