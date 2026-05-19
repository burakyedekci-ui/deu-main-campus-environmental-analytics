source("scripts/00_config.R")

if (!file.exists(kampus_file)) stop("Kampus dosyasi bulunamadi: ", kampus_file)
if (!file.exists(fakulte_file)) stop("Fakulte dosyasi bulunamadi: ", fakulte_file)

kampus <- readr::read_csv(kampus_file, show_col_types = FALSE)
fakulte <- readr::read_csv(fakulte_file, show_col_types = FALSE)

missing_kampus <- setdiff(required_columns, names(kampus))
missing_fakulte <- setdiff(c(required_columns, "fakulte"), names(fakulte))

if (length(missing_kampus) > 0) {
  stop("Kampus verisinde eksik sutunlar var: ", paste(missing_kampus, collapse = ", "))
}
if (length(missing_fakulte) > 0) {
  stop("Fakulte verisinde eksik sutunlar var: ", paste(missing_fakulte, collapse = ", "))
}

kampus <- kampus %>%
  dplyr::mutate(dplyr::across(dplyr::all_of(required_columns), as.numeric))

fakulte <- fakulte %>%
  dplyr::mutate(
    dplyr::across(dplyr::all_of(required_columns), as.numeric),
    fakulte = clean_faculty_names(fakulte)
  ) %>%
  dplyr::filter(!is.na(fakulte))

saveRDS(kampus, file.path(processed_dir, "kampus_clean.rds"))
saveRDS(fakulte, file.path(processed_dir, "fakulte_clean.rds"))

message("Hazirlandi: ", nrow(kampus), " kampus pikseli, ", nrow(fakulte), " fakulte pikseli")
