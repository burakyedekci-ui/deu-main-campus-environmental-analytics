source("scripts/00_config.R")

kampus <- readRDS(file.path(processed_dir, "kampus_clean.rds"))
fakulte <- readRDS(file.path(processed_dir, "fakulte_clean.rds"))
faculty_means <- readr::read_csv(file.path(table_dir, "03_fakulte_ortalamalari.csv"), show_col_types = FALSE) %>%
  dplyr::mutate(fakulte = factor(fakulte, levels = faculty_order))

p_kampus <- ggplot(kampus, aes(x = ndvi, y = ndbi)) +
  geom_point(color = "#28D7D9", alpha = 0.55, size = 0.35) +
  labs(
    title = "DEU Main Campus",
    subtitle = paste0(format(nrow(kampus), big.mark = ".", decimal.mark = ","), " piksel"),
    x = "NDVI",
    y = "NDBI"
  ) +
  dark_theme()

save_plot(p_kampus, "01_kampus_ndvi_ndbi_sacilim.png", width = 13, height = 8)

p_fakulte <- ggplot(fakulte, aes(x = ndvi, y = ndbi, color = fakulte)) +
  geom_point(alpha = 0.70, size = 1.15) +
  scale_color_manual(values = faculty_colors) +
  labs(title = "Fakulte Modu", x = "NDVI", y = "NDBI", color = "Fakulte") +
  dark_theme() +
  theme(legend.position = "top")

save_plot(p_fakulte, "02_fakulte_ndvi_ndbi_sacilim.png", width = 13, height = 8)

p_spektral <- ggplot(
  faculty_means,
  aes(x = ort_ndvi, y = ort_ndbi, color = fakulte, label = fakulte)
) +
  geom_point(size = 4) +
  ggrepel::geom_text_repel(
    color = "white",
    box.padding = 0.35,
    point.padding = 0.25,
    segment.color = "grey70",
    size = 4
  ) +
  scale_color_manual(values = faculty_colors) +
  labs(
    title = "Fakulte Ortalamalari - Spektral Profil",
    x = "Ortalama NDVI",
    y = "Ortalama NDBI",
    color = "Fakulte"
  ) +
  dark_theme() +
  theme(legend.position = "none")

save_plot(p_spektral, "03_fakulte_ortalama_spektral.png", width = 10, height = 7)

p_dokusal <- ggplot(
  faculty_means,
  aes(x = ort_contrast, y = ort_homogeneity, color = fakulte, label = fakulte)
) +
  geom_point(size = 4) +
  ggrepel::geom_text_repel(
    color = "white",
    box.padding = 0.35,
    point.padding = 0.25,
    segment.color = "grey70",
    size = 4
  ) +
  scale_color_manual(values = faculty_colors) +
  labs(
    title = "Fakulte Ortalamalari - Dokusal Profil",
    x = "Ortalama GLCM Contrast",
    y = "Ortalama GLCM Homogeneity",
    color = "Fakulte"
  ) +
  dark_theme() +
  theme(legend.position = "none")

save_plot(p_dokusal, "04_fakulte_ortalama_dokusal.png", width = 10, height = 7)

make_violin <- function(data, variable_name, x_label) {
  ggplot(data, aes(x = .data[[variable_name]], y = fakulte, fill = fakulte)) +
    geom_violin(trim = FALSE, alpha = 0.95, color = NA) +
    scale_fill_manual(values = faculty_colors) +
    labs(title = paste0("Fakulte Dagilimi - ", x_label), x = x_label, y = NULL) +
    dark_theme() +
    theme(legend.position = "none")
}

save_plot(make_violin(fakulte, "ndvi", "NDVI"), "05_violin_ndvi.png", width = 11, height = 8)
save_plot(make_violin(fakulte, "ndbi", "NDBI"), "06_violin_ndbi.png", width = 11, height = 8)
save_plot(make_violin(fakulte, "glcm_contrast", "GLCM Contrast"), "07_violin_contrast.png", width = 11, height = 8)
save_plot(make_violin(fakulte, "glcm_homogeneity", "GLCM Homogeneity"), "08_violin_homogeneity.png", width = 11, height = 8)

strip_data <- fakulte %>%
  dplyr::arrange(fakulte, ndvi) %>%
  dplyr::group_by(fakulte) %>%
  dplyr::mutate(piksel_sira = dplyr::row_number()) %>%
  dplyr::ungroup()

p_strip_ndvi <- ggplot(strip_data, aes(x = piksel_sira, y = fakulte, fill = ndvi)) +
  geom_tile(height = 0.82) +
  scale_fill_gradientn(
    colours = c("#7A4A1D", "#A77F1C", "#D3B53B", "#8CC562", "#3E8E2E"),
    name = "NDVI"
  ) +
  labs(title = "Fakulte Bazli NDVI Piksel Seridi", x = "Siralanmis piksel", y = NULL) +
  dark_theme() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

save_plot(p_strip_ndvi, "09_ndvi_piksel_seridi.png", width = 15, height = 8)

strip_h <- fakulte %>%
  dplyr::arrange(fakulte, glcm_homogeneity) %>%
  dplyr::group_by(fakulte) %>%
  dplyr::mutate(piksel_sira = dplyr::row_number()) %>%
  dplyr::ungroup()

p_strip_h <- ggplot(strip_h, aes(x = piksel_sira, y = fakulte, fill = glcm_homogeneity)) +
  geom_tile(height = 0.82) +
  scale_fill_gradientn(
    colours = c("#16213E", "#1F4E79", "#2A9D8F", "#A7C957", "#F1FA8C"),
    name = "GLCM\nHomogeneity"
  ) +
  labs(title = "Fakulte Bazli Homogeneity Piksel Seridi", x = "Siralanmis piksel", y = NULL) +
  dark_theme() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

save_plot(p_strip_h, "10_homogeneity_piksel_seridi.png", width = 15, height = 8)
