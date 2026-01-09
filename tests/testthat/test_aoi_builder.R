testthat::test_that("build_aoi_from_config uses centroid and size", {
  cfg <- list(
    centroid = list(lat = -41.0, lon = 145.0),
    size_km = 10,
    rotation_deg = 0
  )
  aoi <- localmap::build_aoi_from_config(cfg)

  testthat::expect_true(inherits(aoi$aoi, "sfc"))
  centroid <- sf::st_transform(sf::st_centroid(aoi$aoi), 4326)
  coords <- sf::st_coordinates(centroid)[1, ]
  testthat::expect_equal(coords[["Y"]], -41.0, tolerance = 1e-4)
  testthat::expect_equal(coords[["X"]], 145.0, tolerance = 1e-4)
})

testthat::test_that("build_aoi_from_config honours centroid_site", {
  cfg <- list(
    centroid_site = "site_a",
    width_km = 5,
    height_km = 4,
    rotation_deg = 0
  )
  sites <- data.frame(site = "site_a", lat = -42.0, lon = 146.0)
  aoi <- localmap::build_aoi_from_config(cfg, sites = sites)
  centroid <- sf::st_transform(sf::st_centroid(aoi$aoi), 4326)
  coords <- sf::st_coordinates(centroid)[1, ]
  testthat::expect_equal(coords[["Y"]], -42.0, tolerance = 1e-4)
  testthat::expect_equal(coords[["X"]], 146.0, tolerance = 1e-4)
})

testthat::test_that("build_aoi_from_config applies rotation", {
  cfg <- list(
    centroid = list(lat = -41.0, lon = 145.0),
    width_km = 8,
    height_km = 4,
    rotation_deg = 25
  )
  aoi <- localmap::build_aoi_from_config(cfg)
  coords <- sf::st_coordinates(aoi$aoi)
  unique_x <- length(unique(round(coords[, 1], 6)))
  unique_y <- length(unique(round(coords[, 2], 6)))
  testthat::expect_gt(unique_x, 2)
  testthat::expect_gt(unique_y, 2)
})
