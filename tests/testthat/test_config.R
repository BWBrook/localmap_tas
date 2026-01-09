testthat::test_that("cfg_read returns a list with default profile", {
  cfg <- localmap::cfg_read()
  testthat::expect_type(cfg, "list")
  testthat::expect_true(!is.null(cfg$data_dir))
  testthat::expect_equal(cfg$schema_version, 1)
})

testthat::test_that("cfg_read fails when schema_version is missing", {
  tmp <- tempfile(fileext = ".yaml")
  writeLines(c("default:", "  data: {}"), tmp)
  testthat::expect_error(
    localmap::cfg_read(config_path = tmp),
    class = "cfg_schema_missing"
  )
})

testthat::test_that("cfg_read fails when required keys are missing", {
  tmp <- tempfile(fileext = ".yaml")
  writeLines(c(
    "default:",
    "  schema_version: 1",
    "  data:",
    "    species_requests: \"metadata/species_requests.csv\""
  ), tmp)
  testthat::expect_error(
    localmap::cfg_read(config_path = tmp),
    class = "cfg_required_missing"
  )
})

testthat::test_that("cfg_read fails on unsupported schema_version", {
  tmp <- tempfile(fileext = ".yaml")
  writeLines(c(
    "default:",
    "  schema_version: 2",
    "  data:",
    "    manifest: \"metadata/data_manifest.csv\"",
    "    species_requests: \"metadata/species_requests.csv\"",
    "    occurrence:",
    "      fields: [decimalLatitude]",
    "      map:",
    "        bounding_box:",
    "          top_left:",
    "            lat: -40.0",
    "            lon: 145.0",
    "          length_km: 10",
    "    camera_sites:",
    "      path: \"data/raw/lyr_op.csv\"",
    "      central_site: \"centre\"",
    "      bbox_half_km: 10",
    "  ala:",
    "    email: \"test@example.com\"",
    "    download_reason_id: 4"
  ), tmp)
  testthat::expect_error(
    localmap::cfg_read(config_path = tmp),
    class = "cfg_schema_unsupported"
  )
})
