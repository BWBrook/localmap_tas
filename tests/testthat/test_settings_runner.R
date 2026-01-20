testthat::test_that("apply_settings_to_config updates paths and filters layers", {
  cfg <- localmap::cfg_read(profile = "jc")

  tmp_dir <- tempdir()
  input_dir <- file.path(tmp_dir, "input")
  dir.create(input_dir, recursive = TRUE, showWarnings = FALSE)
  site_path <- file.path(input_dir, "site.csv")
  utils::write.csv(
    data.frame(
      site = c("s1", "s2"),
      lat = c(-42.0, -42.1),
      lon = c(146.0, 146.1)
    ),
    site_path,
    row.names = FALSE
  )

  settings <- list(
    project = "testproj",
    input_dir = input_dir,
    site_file = "site.csv",
    central_site = "s1",
    outputs = list(dir = file.path(tmp_dir, "outputs")),
    layers = list(include = c("orthophoto")),
    analysis_layers = list(include = c("dem"))
  )

  cfg2 <- localmap:::apply_settings_to_config(cfg, settings)

  testthat::expect_equal(
    cfg2$data$camera_sites$jc$site_path,
    file.path(input_dir, "site.csv")
  )
  testthat::expect_equal(cfg2$data$camera_sites$central_site, "s1")
  testthat::expect_true(startsWith(
    cfg2$data$overview_map$output_path,
    file.path(tmp_dir, "outputs")
  ))
  layer_ids <- vapply(cfg2$data$layers, function(layer) layer$id, character(1))
  testthat::expect_true(all(layer_ids %in% c("orthophoto_arcgis")))
  analysis_suffixes <- vapply(cfg2$data$analysis_layers, function(layer) {
    sub("^[^_]+_", "", layer$id)
  }, character(1))
  testthat::expect_true(all(analysis_suffixes %in% c("dem")))
})
