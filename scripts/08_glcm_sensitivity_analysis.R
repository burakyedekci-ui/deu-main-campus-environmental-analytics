# ============================================================
# DEU Main Campus
# GLCM Pencere Boyutu Duyarlilik Analizi
#
# Girdi:
# data_raw/deu_fakulte_piksel_2024_tumdegiskenler.csv
# data_raw/deu_fakulte_glcm_5x5_2024.csv
#
# Cikti:
# tables/12_glcm_duyarlilik_fakulte_ozet.csv
# tables/13_glcm_duyarlilik_test_ozeti.csv
# ============================================================

source("scripts/00_config.R")

glcm_5x5_file <- file.path(raw_dir, "deu_fakulte_glcm_5x5_2024.csv")

if (!file.exists(fakulte_file)) {
  stop("Fakulte 3x3 GLCM dosyasi bulunamadi: ", fakulte_file)
}

if (!file.exists(glcm_5x5_file)) {
  stop("GLCM 5x5 duyarlilik dosyasi bulunamadi: ", glcm_5x5_file)
}

glcm_3x3 <- readr::read_csv(
  fakulte_file,
  show_col_types = FALSE
)

glcm_5x5 <- readr::read_csv(
  glcm_5x5_file,
  show_col_types = FALSE
)

required_glcm_3x3_columns <- c(
  "fakulte",
  "glcm_contrast",
  "glcm_homogeneity"
)

required_glcm_5x5_columns <- c(
  "fakulte",
  "glcm_contrast_5x5",
  "glcm_homogeneity_5x5"
)

missing_glcm_3x3_columns <- setdiff(
  required_glcm_3x3_columns,
  names(glcm_3x3)
)

if (length(missing_glcm_3x3_columns) > 0) {
  stop(
    "GLCM 3x3 verisinde eksik sutunlar var: ",
    paste(missing_glcm_3x3_columns, collapse = ", ")
  )
}

if (
  !"glcm_contrast_5x5" %in% names(glcm_5x5) &&
    "glcm_contrast" %in% names(glcm_5x5)
) {
  glcm_5x5 <- glcm_5x5 %>%
    dplyr::rename(glcm_contrast_5x5 = glcm_contrast)
}

if (
  !"glcm_homogeneity_5x5" %in% names(glcm_5x5) &&
    "glcm_homogeneity" %in% names(glcm_5x5)
) {
  glcm_5x5 <- glcm_5x5 %>%
    dplyr::rename(glcm_homogeneity_5x5 = glcm_homogeneity)
}

missing_glcm_5x5_columns <- setdiff(
  required_glcm_5x5_columns,
  names(glcm_5x5)
)

if (length(missing_glcm_5x5_columns) > 0) {
  stop(
    "GLCM 5x5 verisinde eksik sutunlar var: ",
    paste(missing_glcm_5x5_columns, collapse = ", ")
  )
}

glcm_3x3 <- glcm_3x3 %>%
  dplyr::mutate(
    glcm_contrast_3x3 = as.numeric(glcm_contrast),
    glcm_homogeneity_3x3 = as.numeric(glcm_homogeneity),
    fakulte = clean_faculty_names(fakulte)
  ) %>%
  dplyr::filter(!is.na(fakulte)) %>%
  dplyr::select(
    fakulte,
    glcm_contrast_3x3,
    glcm_homogeneity_3x3
  )

glcm_5x5 <- glcm_5x5 %>%
  dplyr::mutate(
    glcm_contrast_5x5 = as.numeric(glcm_contrast_5x5),
    glcm_homogeneity_5x5 = as.numeric(glcm_homogeneity_5x5),
    fakulte = clean_faculty_names(fakulte)
  ) %>%
  dplyr::filter(!is.na(fakulte)) %>%
  dplyr::select(
    fakulte,
    glcm_contrast_5x5,
    glcm_homogeneity_5x5
  )

summarise_glcm <- function(data, contrast_col, homogeneity_col, pencere) {
  data %>%
    dplyr::transmute(
      fakulte,
      glcm_contrast = {{ contrast_col }},
      glcm_homogeneity = {{ homogeneity_col }}
    ) %>%
    tidyr::pivot_longer(
      cols = c(glcm_contrast, glcm_homogeneity),
      names_to = "degisken",
      values_to = "deger"
    ) %>%
    dplyr::group_by(fakulte, degisken) %>%
    dplyr::summarise(
      n = dplyr::n(),
      medyan = median(deger, na.rm = TRUE),
      ortalama = mean(deger, na.rm = TRUE),
      ss = sd(deger, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::group_by(degisken) %>%
    dplyr::arrange(medyan, .by_group = TRUE) %>%
    dplyr::mutate(sira = dplyr::row_number()) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(pencere = pencere)
}

glcm_3x3_ozet <- summarise_glcm(
  glcm_3x3,
  glcm_contrast_3x3,
  glcm_homogeneity_3x3,
  "3x3"
)

glcm_5x5_ozet <- summarise_glcm(
  glcm_5x5,
  glcm_contrast_5x5,
  glcm_homogeneity_5x5,
  "5x5"
)

glcm_duyarlilik_ozet <- glcm_3x3_ozet %>%
  dplyr::select(
    fakulte,
    degisken,
    n_3x3 = n,
    medyan_3x3 = medyan,
    ortalama_3x3 = ortalama,
    ss_3x3 = ss,
    sira_3x3 = sira
  ) %>%
  dplyr::left_join(
    glcm_5x5_ozet %>%
      dplyr::select(
        fakulte,
        degisken,
        n_5x5 = n,
        medyan_5x5 = medyan,
        ortalama_5x5 = ortalama,
        ss_5x5 = ss,
        sira_5x5 = sira
      ),
    by = c("fakulte", "degisken")
  ) %>%
  dplyr::mutate(
    medyan_farki = medyan_5x5 - medyan_3x3,
    ortalama_farki = ortalama_5x5 - ortalama_3x3,
    sira_farki = sira_5x5 - sira_3x3
  ) %>%
  dplyr::arrange(degisken, sira_3x3)

glcm_test_data <- dplyr::bind_rows(
  glcm_3x3 %>%
    dplyr::transmute(
      fakulte,
      glcm_contrast = glcm_contrast_3x3,
      glcm_homogeneity = glcm_homogeneity_3x3,
      pencere = "3x3"
    ),
  glcm_5x5 %>%
    dplyr::transmute(
      fakulte,
      glcm_contrast = glcm_contrast_5x5,
      glcm_homogeneity = glcm_homogeneity_5x5,
      pencere = "5x5"
    )
)

run_glcm_kw <- function(data, variable_name, pencere_name) {
  kw_formula <- stats::as.formula(paste(variable_name, "~ fakulte"))
  kw_result <- kruskal.test(kw_formula, data = data)

  eps_result <- rstatix::kruskal_effsize(
    data,
    kw_formula
  )

  tibble::tibble(
    pencere = pencere_name,
    degisken = variable_name,
    H = unname(kw_result$statistic),
    df = unname(kw_result$parameter),
    p = kw_result$p.value,
    effsize = eps_result$effsize,
    magnitude = eps_result$magnitude
  )
}

glcm_duyarlilik_test_ozeti <- glcm_test_data %>%
  dplyr::group_split(pencere) %>%
  purrr::map_dfr(function(data) {
    pencere_name <- unique(data$pencere)
    dplyr::bind_rows(
      run_glcm_kw(data, "glcm_contrast", pencere_name),
      run_glcm_kw(data, "glcm_homogeneity", pencere_name)
    )
  }) %>%
  dplyr::mutate(
    etki = effect_label(effsize)
  ) %>%
  dplyr::arrange(degisken, pencere)

readr::write_csv(
  glcm_duyarlilik_ozet,
  file.path(table_dir, "12_glcm_duyarlilik_fakulte_ozet.csv")
)

readr::write_csv(
  glcm_duyarlilik_test_ozeti,
  file.path(table_dir, "13_glcm_duyarlilik_test_ozeti.csv")
)

message("GLCM duyarlilik analizi tamamlandi.")
message("Cikti: ", file.path(table_dir, "12_glcm_duyarlilik_fakulte_ozet.csv"))
message("Cikti: ", file.path(table_dir, "13_glcm_duyarlilik_test_ozeti.csv"))
