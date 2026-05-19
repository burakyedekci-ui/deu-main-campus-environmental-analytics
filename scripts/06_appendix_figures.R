source("scripts/00_config.R")

kampus <- readRDS(file.path(processed_dir, "kampus_clean.rds"))
fakulte <- readRDS(file.path(processed_dir, "fakulte_clean.rds"))

p_kampus_glcm <- ggplot(kampus, aes(x = glcm_contrast, y = glcm_homogeneity)) +
  geom_point(color = "#28D7D9", alpha = 0.55, size = 0.35) +
  labs(
    title = "DEU Main Campus",
    subtitle = "GLCM Contrast - Homogeneity dagilimi",
    x = "GLCM Contrast",
    y = "GLCM Homogeneity"
  ) +
  dark_theme()

save_plot(p_kampus_glcm, "11_kampus_glcm_contrast_homogeneity_sacilim.png", width = 13, height = 8)

correlation_df <- expand.grid(
  degisken_1 = variables,
  degisken_2 = variables,
  stringsAsFactors = FALSE
) %>%
  dplyr::as_tibble() %>%
  dplyr::rowwise() %>%
  dplyr::mutate(
    rho = suppressWarnings(cor(
      fakulte[[degisken_1]],
      fakulte[[degisken_2]],
      method = "spearman",
      use = "complete.obs"
    ))
  ) %>%
  dplyr::ungroup()

label_map <- c(
  ndvi = "NDVI",
  ndbi = "NDBI",
  glcm_contrast = "GLCM Contrast",
  glcm_homogeneity = "GLCM Homogeneity"
)

correlation_df <- correlation_df %>%
  dplyr::mutate(
    degisken_1 = factor(degisken_1, levels = variables, labels = label_map[variables]),
    degisken_2 = factor(degisken_2, levels = variables, labels = label_map[variables])
  )

p_correlation <- ggplot(correlation_df, aes(x = degisken_1, y = degisken_2, fill = rho)) +
  geom_tile(color = "black") +
  geom_text(aes(label = sprintf("%.2f", rho)), color = "white", size = 5) +
  scale_fill_gradient2(
    low = "#B11F3A",
    mid = "#222222",
    high = "#28D7D9",
    midpoint = 0,
    limits = c(-1, 1),
    name = "Spearman rho"
  ) +
  labs(title = "Tum Degiskenler Arasi Korelasyon Matrisi", x = NULL, y = NULL) +
  dark_theme() +
  theme(
    axis.text.x = element_text(angle = 20, hjust = 1, colour = "white"),
    axis.text.y = element_text(colour = "white")
  )

save_plot(p_correlation, "12_korelasyon_matrisi.png", width = 9, height = 7)
