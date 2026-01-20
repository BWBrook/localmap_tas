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
