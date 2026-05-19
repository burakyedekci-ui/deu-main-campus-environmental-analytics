source("scripts/00_config.R")

fakulte <- readRDS(file.path(processed_dir, "fakulte_clean.rds"))

kw_results <- purrr::map_dfr(variables, function(v) {
  form <- as.formula(paste(v, "~ fakulte"))
  kw <- kruskal.test(form, data = fakulte)
  eff <- rstatix::kruskal_effsize(fakulte, form)

  tibble::tibble(
    degisken = v,
    H = unname(kw$statistic),
    df = unname(kw$parameter),
    p = kw$p.value,
    epsilon2 = eff$effsize[1],
    etki = effect_label(eff$effsize[1])
  )
})

dunn_results <- purrr::map_dfr(variables, function(v) {
  form <- as.formula(paste(v, "~ fakulte"))
  dt <- suppressMessages(FSA::dunnTest(form, data = fakulte, method = "bh")$res)

  dt %>%
    tibble::as_tibble() %>%
    dplyr::transmute(
      degisken = v,
      karsilastirma = Comparison,
      z = Z,
      p_ham = P.unadj,
      p_bh = P.adj
    )
})

pairs <- combn(variables, 2, simplify = FALSE)

spearman_results <- purrr::map_dfr(pairs, function(x) {
  test <- suppressWarnings(
    cor.test(fakulte[[x[1]]], fakulte[[x[2]]], method = "spearman", exact = FALSE)
  )

  tibble::tibble(
    degisken_1 = x[1],
    degisken_2 = x[2],
    rho = unname(test$estimate),
    p = test$p.value
  )
})

readr::write_csv(kw_results, file.path(table_dir, "04_kruskal_wallis.csv"))
readr::write_csv(dunn_results, file.path(table_dir, "05_dunn_bh.csv"))
readr::write_csv(spearman_results, file.path(table_dir, "06_spearman.csv"))
