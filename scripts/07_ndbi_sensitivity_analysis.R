# ============================================================
# DEU Main Campus
# NDBI Yeniden Ornekleme Duyarlilik Analizi
#
# Girdi:
# data_raw/deu_fakulte_ndbi_duyarlilik_2024.csv
#
# Cikti:
# tables/10_ndbi_duyarlilik_fakulte_ozet.csv
# tables/11_ndbi_duyarlilik_test_ozeti.csv
# ============================================================

source("scripts/00_config.R")

ndbi_duyarlilik_file <- file.path(
  raw_dir,
  "deu_fakulte_ndbi_duyarlilik_2024.csv"
)

if (!file.exists(ndbi_duyarlilik_file)) {
  stop("NDBI duyarlilik dosyasi bulunamadi: ", ndbi_duyarlilik_file)
}

ndbi_duyarlilik <- readr::read_csv(
  ndbi_duyarlilik_file,
  show_col_types = FALSE
)

required_ndbi_columns <- c(
  "fakulte",
  "ndbi_nearest",
  "ndbi_bilinear"
)

missing_ndbi_columns <- setdiff(
  required_ndbi_columns,
  names(ndbi_duyarlilik)
)

if (length(missing_ndbi_columns) > 0) {
  stop(
    "NDBI duyarlilik verisinde eksik sutunlar var: ",
    paste(missing_ndbi_columns, collapse = ", ")
  )
}

ndbi_duyarlilik <- ndbi_duyarlilik %>%
  dplyr::mutate(
    ndbi_nearest = as.numeric(ndbi_nearest),
    ndbi_bilinear = as.numeric(ndbi_bilinear),
    fakulte = clean_faculty_names(fakulte)
  ) %>%
  dplyr::filter(!is.na(fakulte))

ndbi_duyarlilik_ozet <- ndbi_duyarlilik %>%
  dplyr::group_by(fakulte) %>%
  dplyr::summarise(
    n = dplyr::n(),
    nearest_mdn = median(ndbi_nearest, na.rm = TRUE),
    bilinear_mdn = median(ndbi_bilinear, na.rm = TRUE),
    fark_mdn = bilinear_mdn - nearest_mdn,
    nearest_mean = mean(ndbi_nearest, na.rm = TRUE),
    bilinear_mean = mean(ndbi_bilinear, na.rm = TRUE),
    fark_mean = bilinear_mean - nearest_mean,
    .groups = "drop"
  )

nearest_rank <- ndbi_duyarlilik_ozet %>%
  dplyr::arrange(nearest_mdn) %>%
  dplyr::mutate(nearest_sira = dplyr::row_number()) %>%
  dplyr::select(fakulte, nearest_sira)

bilinear_rank <- ndbi_duyarlilik_ozet %>%
  dplyr::arrange(bilinear_mdn) %>%
  dplyr::mutate(bilinear_sira = dplyr::row_number()) %>%
  dplyr::select(fakulte, bilinear_sira)

ndbi_duyarlilik_ozet <- ndbi_duyarlilik_ozet %>%
  dplyr::left_join(nearest_rank, by = "fakulte") %>%
  dplyr::left_join(bilinear_rank, by = "fakulte") %>%
  dplyr::mutate(
    sira_farki = bilinear_sira - nearest_sira
  ) %>%
  dplyr::arrange(nearest_sira)

kw_ndbi_nearest <- kruskal.test(
  ndbi_nearest ~ fakulte,
  data = ndbi_duyarlilik
)

kw_ndbi_bilinear <- kruskal.test(
  ndbi_bilinear ~ fakulte,
  data = ndbi_duyarlilik
)

eps_ndbi_nearest <- rstatix::kruskal_effsize(
  ndbi_duyarlilik,
  ndbi_nearest ~ fakulte
) %>%
  dplyr::mutate(yontem = "nearest")

eps_ndbi_bilinear <- rstatix::kruskal_effsize(
  ndbi_duyarlilik,
  ndbi_bilinear ~ fakulte
) %>%
  dplyr::mutate(yontem = "bilinear")

eps_ndbi_duyarlilik <- dplyr::bind_rows(
  eps_ndbi_nearest,
  eps_ndbi_bilinear
) %>%
  dplyr::select(yontem, effsize, magnitude)

ndbi_duyarlilik_test_ozeti <- tibble::tibble(
  yontem = c("nearest", "bilinear"),
  H = c(
    unname(kw_ndbi_nearest$statistic),
    unname(kw_ndbi_bilinear$statistic)
  ),
  df = c(
    unname(kw_ndbi_nearest$parameter),
    unname(kw_ndbi_bilinear$parameter)
  ),
  p = c(
    kw_ndbi_nearest$p.value,
    kw_ndbi_bilinear$p.value
  )
) %>%
  dplyr::left_join(eps_ndbi_duyarlilik, by = "yontem") %>%
  dplyr::mutate(
    etki = effect_label(effsize)
  )

readr::write_csv(
  ndbi_duyarlilik_ozet,
  file.path(table_dir, "10_ndbi_duyarlilik_fakulte_ozet.csv")
)

readr::write_csv(
  ndbi_duyarlilik_test_ozeti,
  file.path(table_dir, "11_ndbi_duyarlilik_test_ozeti.csv")
)

message("NDBI duyarlilik analizi tamamlandi.")
message("Cikti: ", file.path(table_dir, "10_ndbi_duyarlilik_fakulte_ozet.csv"))
message("Cikti: ", file.path(table_dir, "11_ndbi_duyarlilik_test_ozeti.csv"))
