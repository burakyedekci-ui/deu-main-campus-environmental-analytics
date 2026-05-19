source("scripts/00_config.R")

kampus <- readRDS(file.path(processed_dir, "kampus_clean.rds"))
fakulte <- readRDS(file.path(processed_dir, "fakulte_clean.rds"))

kampus_descriptive <- kampus %>%
  tidyr::pivot_longer(
    cols = dplyr::all_of(variables),
    names_to = "degisken",
    values_to = "deger"
  ) %>%
  dplyr::group_by(degisken) %>%
  dplyr::summarise(
    n = dplyr::n(),
    ortalama = mean(deger, na.rm = TRUE),
    medyan = median(deger, na.rm = TRUE),
    ss = sd(deger, na.rm = TRUE),
    min = min(deger, na.rm = TRUE),
    q1 = quantile(deger, 0.25, na.rm = TRUE),
    q3 = quantile(deger, 0.75, na.rm = TRUE),
    max = max(deger, na.rm = TRUE),
    .groups = "drop"
  )

faculty_descriptive <- fakulte %>%
  tidyr::pivot_longer(
    cols = dplyr::all_of(variables),
    names_to = "degisken",
    values_to = "deger"
  ) %>%
  dplyr::group_by(fakulte, degisken) %>%
  dplyr::summarise(
    n = dplyr::n(),
    ortalama = mean(deger, na.rm = TRUE),
    medyan = median(deger, na.rm = TRUE),
    ss = sd(deger, na.rm = TRUE),
    min = min(deger, na.rm = TRUE),
    q1 = quantile(deger, 0.25, na.rm = TRUE),
    q3 = quantile(deger, 0.75, na.rm = TRUE),
    max = max(deger, na.rm = TRUE),
    .groups = "drop"
  )

faculty_means <- fakulte %>%
  dplyr::group_by(fakulte) %>%
  dplyr::summarise(
    ort_ndvi = mean(ndvi, na.rm = TRUE),
    ort_ndbi = mean(ndbi, na.rm = TRUE),
    ort_contrast = mean(glcm_contrast, na.rm = TRUE),
    ort_homogeneity = mean(glcm_homogeneity, na.rm = TRUE),
    n = dplyr::n(),
    .groups = "drop"
  )

readr::write_csv(kampus_descriptive, file.path(table_dir, "01_kampus_betimleyici.csv"))
readr::write_csv(faculty_descriptive, file.path(table_dir, "02_fakulte_betimleyici.csv"))
readr::write_csv(faculty_means, file.path(table_dir, "03_fakulte_ortalamalari.csv"))
