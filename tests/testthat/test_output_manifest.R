testthat::test_that("validate_output_manifest checks required fields", {
  bad_manifest <- tibble::tibble(output_id = "x")
  testthat::expect_error(
    localmap::validate_output_manifest(bad_manifest),
    "Names must include"
  )
})

testthat::test_that("validate_output_manifest errors on missing output id", {
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(
    data.frame(output_id = "species_map", type = "map", path = tmp),
    tmp,
    row.names = FALSE
  )
  manifest <- readr::read_csv(tmp, show_col_types = FALSE, num_threads = 1)
  testthat::expect_error(
    localmap::validate_output_manifest(
      manifest,
      expected_outputs = list(camera_sites_map = tmp)
    ),
    class = "output_manifest_missing_id"
  )
})

testthat::test_that("validate_output_manifest errors when declared path missing", {
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(
    data.frame(output_id = "species_map", type = "map", path = "outputs/jc/maps/nope.png"),
    tmp,
    row.names = FALSE
  )
  manifest <- readr::read_csv(tmp, show_col_types = FALSE, num_threads = 1)
  ok_path <- file.path(tempdir(), "ok.png")
  png::writePNG(array(1, dim = c(2, 2, 4)), ok_path)
  testthat::expect_error(
    localmap::validate_output_manifest(
      manifest,
      expected_outputs = list(species_map = ok_path)
    ),
    class = "output_manifest_missing_file"
  )
})

testthat::test_that("demo output manifest keeps demo-scoped paths and required ids", {
  manifest <- readr::read_csv(
    system.file("extdata", "output_manifest_demo.csv", package = "localmap"),
    show_col_types = FALSE,
    num_threads = 1
  )

  testthat::expect_identical(anyDuplicated(manifest$output_id), 0L)
  testthat::expect_true(all(startsWith(manifest$path, "outputs/demo/")))
  testthat::expect_true(all(manifest$profile == "demo"))
  testthat::expect_true(all(c(
    "species_map",
    "camera_sites_map",
    "overview_map",
    "panel_figure_png",
    "run_manifest"
  ) %in% manifest$output_id))
})

testthat::test_that("validate_output_manifest accepts matching expected outputs", {
  tmp_dir <- tempfile("manifest_ok")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  map_path <- file.path(tmp_dir, "species_occurrences.png")
  run_manifest_path <- file.path(tmp_dir, "run_manifest.yml")
  png::writePNG(array(1, dim = c(2, 2, 4)), map_path)
  writeLines("run: ok", run_manifest_path)

  manifest <- tibble::tibble(
    output_id = c("species_map", "run_manifest"),
    type = c("map", "provenance"),
    path = c(map_path, run_manifest_path)
  )

  out <- localmap::validate_output_manifest(
    manifest,
    expected_outputs = list(
      species_map = map_path,
      run_manifest = run_manifest_path
    )
  )

  testthat::expect_s3_class(out, "tbl_df")
  testthat::expect_equal(out$output_id, c("species_map", "run_manifest"))
})
