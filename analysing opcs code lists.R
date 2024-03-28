folder_path <- "C:/Users/GabrielHobro/OneDrive - NHS/Documents/New medical tech work/OPCS-4 files/"

library(dplyr)

codes_4_09 <- read.delim(
  paste0(
    folder_path,
    "OPCS409 Data files txt/OPCS49 CodesAndTitles Nov 2019 V1.0.txt"),
  header = FALSE, sep = "\t", dec = ".")

codes_4_10 <- read.delim(
  paste0(
    folder_path,
    "OPCS410 Data files txt/OPCS410 CodesAndTitles Nov 2022 V1.0.txt"),
  header = FALSE, sep = "\t", dec = ".")

names(codes_4_09) <- c("Code", "Desc")
names(codes_4_10) <- c("Code", "Desc")

codes_4_10_new <- codes_4_10 |>
  filter(!(Code %in% codes_4_09$Code))

nrow(filter(codes_4_10_new, nchar(Code) == 3))


opcs_408_changes <- pdf(file = paste0(folder_path, "OPCS408 Data files txt/FinalSummaryChangesOPCS47-OPCS48.pdf"))

toce_4_10 <- readxl::read_excel(
  paste0(
    folder_path,
    "OPCS410 Data files txt/OPCS10 ToCE Analysis Nov 2022 V1.0.xlsx")
)

length(intersect(codes_4_10[["Code"]], toce_4_10[["OPCS 4.10"]]))




