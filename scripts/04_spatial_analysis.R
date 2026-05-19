source("scripts/00_config.R")

kampus <- readRDS(file.path(processed_dir, "kampus_clean.rds"))
fakulte <- readRDS(file.path(processed_dir, "fakulte_clean.rds"))

kampus_sf <- sf::st_as_sf(
  kampus,
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = FALSE
) %>%
  sf::st_transform(32635)

moran_single <- function(df_sf, degisken, seed, sample_n = 10000, k = 8) {
  set.seed(seed)
  n_take <- min(sample_n, nrow(df_sf))
  idx <- sample(seq_len(nrow(df_sf)), n_take, replace = FALSE)
  subset_sf <- df_sf[idx, ]
  xy <- sf::st_coordinates(subset_sf)

  knn <- spdep::knearneigh(xy, k = k)
  nb <- spdep::knn2nb(knn)
  lw <- spdep::nb2listw(nb, style = "W", zero.policy = TRUE)
  mt <- spdep::moran.test(subset_sf[[degisken]], lw, zero.policy = TRUE)

  tibble::tibble(
    degisken = degisken,
    seed = seed,
    n = n_take,
    moran_I = unname(mt$estimate[["Moran I statistic"]]),
    beklenen = unname(mt$estimate[["Expectation"]]),
    varyans = unname(mt$estimate[["Variance"]]),
    p = mt$p.value
  )
}

seeds <- c(101, 202, 303, 404, 505)

moran_repeats <- purrr::map_dfr(variables, function(v) {
  purrr::map_dfr(seeds, function(s) moran_single(kampus_sf, v, s, sample_n = 10000, k = 8))
})

moran_summary <- moran_repeats %>%
  dplyr::group_by(degisken) %>%
  dplyr::summarise(
    tekrar_sayisi = dplyr::n(),
    ortalama_I = mean(moran_I, na.rm = TRUE),
    min_I = min(moran_I, na.rm = TRUE),
    max_I = max(moran_I, na.rm = TRUE),
    aralik = max_I - min_I,
    .groups = "drop"
  )

fakulte_sf <- sf::st_as_sf(
  fakulte,
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = FALSE
) %>%
  sf::st_transform(32635)

xy_utm <- sf::st_coordinates(fakulte_sf)

fakulte_sf <- fakulte_sf %>%
  dplyr::mutate(
    x_utm = xy_utm[, 1],
    y_utm = xy_utm[, 2],
    blok_x = floor(x_utm / 30),
    blok_y = floor(y_utm / 30),
    blok_id = paste0(blok_x, "_", blok_y)
  )

block_labels <- fakulte_sf %>%
  sf::st_drop_geometry() %>%
  dplyr::count(blok_id, fakulte, name = "n_blok") %>%
  dplyr::group_by(blok_id) %>%
  dplyr::slice_max(order_by = n_blok, n = 1, with_ties = FALSE) %>%
  dplyr::ungroup() %>%
  dplyr::rename(fakulte_blok = fakulte)

fakulte_perm <- fakulte_sf %>%
  dplyr::left_join(block_labels, by = "blok_id")

block_perm_test <- function(df, degisken, n_perm = 999, seed = 999) {
  set.seed(seed)

  observed_H <- kruskal.test(
    as.formula(paste(degisken, "~ fakulte")),
    data = sf::st_drop_geometry(df)
  )$statistic[[1]]

  blocks <- df %>%
    sf::st_drop_geometry() %>%
    dplyr::distinct(blok_id, fakulte_blok)

  perm_H <- numeric(n_perm)

  for (i in seq_len(n_perm)) {
    new_labels <- sample(blocks$fakulte_blok, size = nrow(blocks), replace = FALSE)
    mapping <- tibble::tibble(blok_id = blocks$blok_id, fakulte_perm = new_labels)

    df_i <- df %>%
      sf::st_drop_geometry() %>%
      dplyr::select(blok_id, dplyr::all_of(degisken)) %>%
      dplyr::left_join(mapping, by = "blok_id")

    perm_H[i] <- kruskal.test(
      as.formula(paste(degisken, "~ fakulte_perm")),
      data = df_i
    )$statistic[[1]]
  }

  p_perm <- (sum(perm_H >= observed_H) + 1) / (n_perm + 1)

  tibble::tibble(
    degisken = degisken,
    H_gozlenen = observed_H,
    p_perm = p_perm
  )
}

perm_results <- purrr::map_dfr(variables, function(v) {
  block_perm_test(fakulte_perm, v, n_perm = 999, seed = 1000 + match(v, variables))
})

readr::write_csv(moran_repeats, file.path(table_dir, "07_moransI_tekrarlar.csv"))
readr::write_csv(moran_summary, file.path(table_dir, "08_moransI_ozet.csv"))
readr::write_csv(perm_results, file.path(table_dir, "09_mekansal_permutasyon.csv"))
