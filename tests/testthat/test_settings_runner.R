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

  cfg2 <- localmap:::apply_settings_to_config(
    cfg,
    settings,
    base_profile = "jc"
  )

  testthat::expect_equal(
    cfg2$data$camera_sites$jc$site_path,
    file.path(input_dir, "site.csv")
  )
  testthat::expect_equal(cfg2$data$camera_sites$central_site, "s1")
  testthat::expect_equal(
    cfg2$data$overview_map$output_path,
    file.path(tmp_dir, "outputs", "maps", "overview_map.png")
  )
  layer_ids <- vapply(cfg2$data$layers, function(layer) layer$id, character(1))
  testthat::expect_true(all(layer_ids %in% c("orthophoto_arcgis")))
  analysis_suffixes <- vapply(cfg2$data$analysis_layers, function(layer) {
    sub("^[^_]+_", "", layer$id)
  }, character(1))
  testthat::expect_true(all(analysis_suffixes %in% c("dem")))
})

testthat::test_that("run_settings restores env vars after running cfg target", {
  testthat::skip_if_not_installed("targets")
  script_path <- normalizePath(file.path("..", "..", "_targets.R"), mustWork = FALSE)
  if (!file.exists(script_path)) {
    testthat::skip("Project target script is not available in installed-package checks.")
  }

  old_env <- Sys.getenv(c("LOCALMAP_CONFIG_PATH", "R_CONFIG_ACTIVE"), unset = "")

  tmp_dir <- tempfile("settings_run")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  input_dir <- file.path(tmp_dir, "input")
  dir.create(input_dir)
  utils::write.csv(
    data.frame(site = c("s1"), lat = c(-42.0), lon = c(146.0)),
    file.path(input_dir, "site.csv"),
    row.names = FALSE
  )

  output_dir <- file.path(tmp_dir, "outputs")
  settings_path <- file.path(tmp_dir, "settings.yaml")
  yaml::write_yaml(
    list(
      project = "testrun",
      input_dir = input_dir,
      site_file = "site.csv",
      central_site = "s1",
      outputs = list(dir = output_dir)
    ),
    settings_path
  )

  run_cfg <- localmap::run_settings(
    settings_path = settings_path,
    targets = "cfg",
    base_profile = "jc"
  )

  testthat::expect_true(file.exists(run_cfg))
  testthat::expect_equal(Sys.getenv("LOCALMAP_CONFIG_PATH", unset = ""), old_env[[1]])
  testthat::expect_equal(Sys.getenv("R_CONFIG_ACTIVE", unset = ""), old_env[[2]])

  run_yaml <- yaml::read_yaml(run_cfg)
  testthat::expect_equal(run_yaml$run$data$outputs$output_dir, output_dir)
  testthat::expect_equal(run_yaml$run$data$camera_sites$central_site, "s1")
})
