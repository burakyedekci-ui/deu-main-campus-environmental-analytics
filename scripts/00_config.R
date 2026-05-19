packages <- c(
  "readr", "dplyr", "tidyr", "purrr", "tibble", "ggplot2",
  "ggrepel", "FSA", "rstatix", "sf", "spdep"
)

missing_packages <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop(
    "Eksik paketler var: ",
    paste(missing_packages, collapse = ", "),
    "\nÖnce bu paketleri kurup scripti yeniden çalıştırın."
  )
}

invisible(lapply(packages, library, character.only = TRUE))

options(scipen = 999)
set.seed(42)

project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)

raw_dir <- file.path(project_root, "data_raw")
processed_dir <- file.path(project_root, "data_processed")
table_dir <- file.path(project_root, "tables")
figure_dir <- file.path(project_root, "figures")
output_dir <- file.path(project_root, "output")

for (dir_path in c(processed_dir, table_dir, figure_dir, output_dir)) {
  if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE)
}

kampus_file <- file.path(raw_dir, "deu_kampus_piksel_2024_tumdegiskenler.csv")
fakulte_file <- file.path(raw_dir, "deu_fakulte_piksel_2024_tumdegiskenler.csv")

required_columns <- c(
  "longitude", "latitude", "ndvi", "ndbi", "glcm_contrast", "glcm_homogeneity"
)

variables <- c("ndvi", "ndbi", "glcm_contrast", "glcm_homogeneity")

faculty_order <- c(
  "Guzel Sanatlar", "Fen Edebiyat", "Isletme", "Denizcilik",
  "Hukuk", "Muhendislik", "Mimarlik", "Turizm"
)

faculty_colors <- c(
  "Guzel Sanatlar" = "#D7263D",
  "Fen Edebiyat" = "#F49D37",
  "Isletme" = "#3F88C5",
  "Denizcilik" = "#1B998B",
  "Hukuk" = "#6A4C93",
  "Muhendislik" = "#2E86AB",
  "Mimarlik" = "#A23B72",
  "Turizm" = "#4CAF50"
)

clean_faculty_names <- function(x) {
  x <- trimws(as.character(x))
  x <- gsub("İ", "I", x, fixed = TRUE)
  x <- gsub("ı", "i", x, fixed = TRUE)
  x <- gsub("ü", "u", x, fixed = TRUE)
  x <- gsub("Ü", "U", x, fixed = TRUE)
  x <- gsub("ö", "o", x, fixed = TRUE)
  x <- gsub("Ö", "O", x, fixed = TRUE)
  x <- gsub("ş", "s", x, fixed = TRUE)
  x <- gsub("Ş", "S", x, fixed = TRUE)
  x <- gsub("ç", "c", x, fixed = TRUE)
  x <- gsub("Ç", "C", x, fixed = TRUE)
  x <- gsub("ğ", "g", x, fixed = TRUE)
  x <- gsub("Ğ", "G", x, fixed = TRUE)
  x <- gsub("-", " ", x)
  x <- gsub("[[:space:]]+", " ", x)
  x <- dplyr::case_when(
    x %in% c("Guzel Sanatlar", "Guzel Sanatlar Fakultesi") ~ "Guzel Sanatlar",
    x %in% c("Fen Edebiyat", "Fen Edebiyat Fakultesi") ~ "Fen Edebiyat",
    x %in% c("Isletme", "Isletme Fakultesi") ~ "Isletme",
    x %in% c("Denizcilik", "Denizcilik Fakultesi") ~ "Denizcilik",
    x %in% c("Hukuk", "Hukuk Fakultesi") ~ "Hukuk",
    x %in% c("Muhendislik", "Muhendislik Fakultesi") ~ "Muhendislik",
    x %in% c("Mimarlik", "Mimarlik Fakultesi") ~ "Mimarlik",
    x %in% c("Turizm", "Turizm Fakultesi") ~ "Turizm",
    TRUE ~ x
  )
  factor(x, levels = faculty_order)
}

dark_theme <- function() {
  theme_minimal(base_family = "sans") +
    theme(
      panel.background = element_rect(fill = "black", colour = NA),
      plot.background = element_rect(fill = "black", colour = NA),
      legend.background = element_rect(fill = "black", colour = NA),
      legend.key = element_rect(fill = "black", colour = NA),
      panel.grid.major = element_line(colour = "grey25", linewidth = 0.2),
      panel.grid.minor = element_blank(),
      axis.text = element_text(colour = "white"),
      axis.title = element_text(colour = "white"),
      plot.title = element_text(colour = "white", face = "bold", hjust = 0.5),
      plot.subtitle = element_text(colour = "grey80", hjust = 0.5),
      legend.text = element_text(colour = "white"),
      legend.title = element_text(colour = "white"),
      axis.line = element_line(colour = "grey50")
    )
}

save_plot <- function(plot, filename, width = 10, height = 7, dpi = 320) {
  ggsave(
    filename = file.path(figure_dir, filename),
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    bg = "black"
  )
}

effect_label <- function(x) {
  dplyr::case_when(
    x < 0.01 ~ "ihmal_edilebilir",
    x < 0.06 ~ "kucuk",
    x < 0.14 ~ "orta",
    TRUE ~ "buyuk"
  )
}
