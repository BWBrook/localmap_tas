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
      "outputs/jc/analysis/raster/jc_dem.tif.yml",
      "outputs/jc/analysis/raster/jc_multiband.tif.yml"
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
    provenance_path = "outputs/jc/analysis/vector/jc_tasveg.gpkg.yml"
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
    provenance_path = "outputs/jc/analysis/vector/jc_tasveg.gpkg.yml"
  )

  long_tbl <- localmap::build_site_attributes_long(sites = sites, analysis_layers = layers)
  long_path <- tempfile(fileext = ".parquet")
  wide_path <- tempfile(fileext = ".csv")

  long_out <- localmap::write_site_attributes_long(long_tbl, output_path = long_path)
  wide_out <- localmap::write_site_attributes_wide(
    long_tbl,
    sites = sites,
    output_path = wide_path
  )

  testthat::expect_true(file.exists(long_out))
  testthat::expect_true(file.exists(wide_out))
  wide_tbl <- utils::read.csv(wide_out, stringsAsFactors = FALSE)
  expected_cols <- c(
    "canopy_height_m",
    "soil_ph",
    "bio1_mean_temp_c",
    "bio12_annual_precip_mm",
    "fire_sensitivity",
    "fire_flammability",
    "geology_description",
    "land_tenure_class",
    "reserve_estate_class"
  )
  testthat::expect_true(all(expected_cols %in% names(wide_tbl)))
})

testthat::test_that("attribute lookups stay empty-but-named without analysis layers", {
  lookups <- localmap:::render_attribute_lookups(NULL)

  testthat::expect_named(
    lookups,
    c(
      "tasveg_group_lookup",
      "geology_lookup",
      "land_tenure_lookup",
      "reserve_estate_lookup"
    )
  )
  testthat::expect_true(all(vapply(lookups, function(x) identical(x, ""), logical(1))))
})

testthat::test_that("site attributes wide maps representative fields into stable columns", {
  attributes <- tibble::tibble(
    site_id = rep("site_a", 8),
    layer_id = c(
      "jc_dem",
      "jc_slope",
      "jc_ndvi",
      "jc_tasveg",
      "jc_fire_attributes",
      "jc_geology",
      "jc_land_tenure",
      "distance_to_road"
    ),
    attribute_name = c(
      "value",
      "slope",
      "ndvi",
      "VEG_GROUP",
      "FIRESENS",
      "map_symb",
      "TEN_CLASS",
      "distance_m"
    ),
    value = c(
      "101.5",
      "12.1",
      "0.34",
      "Dry eucalypt forest and woodland",
      "Moderate",
      "Qm",
      "Public Reserve",
      "42"
    ),
    units = c("m", "degrees", NA, NA, NA, NA, NA, "m"),
    layer_type = c(
      "raster_file",
      "derived_slope",
      "derived_ndvi",
      "vector_file",
      "vector_arcgis",
      "vector_arcgis",
      "vector_arcgis",
      "vector_arcgis"
    ),
    source_id = NA_character_,
    provenance_path = rep("outputs/jc/provenance/example.yml", 8)
  )
  sites <- tibble::tibble(site = "site_a", lat = -42, lon = 146)
  out_path <- tempfile(fileext = ".csv")

  wide_out <- localmap::write_site_attributes_wide(
    attributes,
    sites = sites,
    output_path = out_path
  )
  wide_tbl <- utils::read.csv(wide_out, stringsAsFactors = FALSE)

  testthat::expect_equal(wide_tbl$dem[[1]], 101.5)
  testthat::expect_equal(wide_tbl$slope[[1]], 12.1)
  testthat::expect_equal(wide_tbl$ndvi[[1]], 0.34)
  testthat::expect_equal(wide_tbl$fire_sensitivity[[1]], "Moderate")
  testthat::expect_equal(wide_tbl$geology_description[[1]], "Qm")
  testthat::expect_equal(wide_tbl$distance_to_road[[1]], 42)
  testthat::expect_equal(
    wide_tbl$tasveg_category[[1]],
    unname(localmap:::attribute_code_from_label("Dry eucalypt forest and woodland"))
  )
  testthat::expect_equal(
    wide_tbl$land_tenure_class[[1]],
    unname(localmap:::attribute_code_from_label("Public Reserve"))
  )
})
