testthat::test_that("raster extraction returns sites × bands rows", {
  sites <- tibble::tibble(
    site = c("site_a", "site_b", "site_c"),
    lon = c(146.94, 146.945, 146.948),
    lat = c(-43.000, -42.998, -43.001)
  )
  n_sites <- nrow(sites)

  layers <- tibble::tibble(
    id = c("dem", "multi"),
    type = c("raster_file", "raster_file"),
    path = c(
      system.file("extdata", "jc_dem.tif", package = "localmap"),
      system.file("extdata", "jc_multiband.tif", package = "localmap")
    ),
    provenance_path = c(
      "outputs/analysis/jc/raster/jc_dem.tif.yml",
      "outputs/analysis/jc/raster/jc_multiband.tif.yml"
    ),
    units = c("m", "index")
  )

  out <- localmap::build_site_attributes_long(sites = sites, analysis_layers = layers)
  expected_rows <- n_sites * 4L
  testthat::expect_equal(nrow(out), expected_rows)
  testthat::expect_true(all(c("red", "nir", "swir2") %in% out$attribute_name))
})

testthat::test_that("vector extraction returns attributes with NA for no-hit", {
  sites <- tibble::tibble(
    site = c("site_a", "site_b", "site_c"),
    lon = c(146.94, 146.945, 146.948),
    lat = c(-43.000, -42.998, -43.001)
  )

  # Create a tiny polygon far from JC sites to force NA extraction.
  poly <- sf::st_polygon(list(rbind(
    c(150, -40),
    c(150.01, -40),
    c(150.01, -40.01),
    c(150, -40.01),
    c(150, -40)
  )))
  vec <- sf::st_sf(class = "test", geometry = sf::st_sfc(poly, crs = 4326))
  vec_path <- tempfile(fileext = ".gpkg")
  sf::st_write(vec, vec_path, quiet = TRUE)

  layers <- tibble::tibble(
    id = "habitats",
    type = "vector_file",
    path = vec_path,
    provenance_path = "outputs/analysis/jc/vector/jc_tasveg.gpkg.yml"
  )

  out <- localmap::build_site_attributes_long(sites = sites, analysis_layers = layers)
  testthat::expect_true(all(is.na(out$value)))
  testthat::expect_true(all(out$attribute_name == "class"))
})

testthat::test_that("site attributes outputs write long + wide products", {
  sites <- tibble::tibble(
    site = c("site_a", "site_b", "site_c"),
    lon = c(146.94, 146.945, 146.948),
    lat = c(-43.000, -42.998, -43.001)
  )
  layers <- tibble::tibble(
    id = "habitats",
    type = "vector_file",
    path = system.file("extdata", "jc_habitats.gpkg", package = "localmap"),
    provenance_path = "outputs/analysis/jc/vector/jc_tasveg.gpkg.yml"
  )

  long_tbl <- localmap::build_site_attributes_long(sites = sites, analysis_layers = layers)
  long_path <- tempfile(fileext = ".parquet")
  wide_path <- tempfile(fileext = ".csv")

  long_out <- localmap::write_site_attributes_long(long_tbl, output_path = long_path)
  wide_out <- localmap::write_site_attributes_wide(long_tbl, output_path = wide_path)

  testthat::expect_true(file.exists(long_out))
  testthat::expect_true(file.exists(wide_out))
})
