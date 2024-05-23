library(DBI)
con <- dbConnect(odbc::odbc(), "prodtest", timeout = 10)

# Extract top 100 rows, all columns, no manipulation
apcs_data_cut <- DBI::dbGetQuery(
  con,
  "SELECT TOP 1000 * FROM [SUS_APC].[APCS_Core]")

