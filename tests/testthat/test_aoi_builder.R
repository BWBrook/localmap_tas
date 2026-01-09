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

testthat::test_that("build_aoi_from_config auto sizes from sites", {
  cfg <- list(
    mode = "auto",
    buffer_km = 0.3,
    rotation_deg = 0,
    crs = "EPSG:28355"
  )
  sites <- data.frame(
    site = c("a", "b"),
    lat = c(-42.0, -42.001),
    lon = c(146.0, 146.002)
  )
  aoi <- localmap::build_aoi_from_config(cfg, sites = sites)

  sites_sf <- sf::st_as_sf(sites, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
  sites_proj <- sf::st_transform(sites_sf, 28355)
  site_bbox <- sf::st_bbox(sites_proj)

  expected_width <- as.numeric((site_bbox["xmax"] - site_bbox["xmin"]) / 1000) + 2 * cfg$buffer_km
  expected_height <- as.numeric((site_bbox["ymax"] - site_bbox["ymin"]) / 1000) + 2 * cfg$buffer_km

  bbox <- sf::st_bbox(aoi$aoi)
  width_km <- as.numeric((bbox["xmax"] - bbox["xmin"]) / 1000)
  height_km <- as.numeric((bbox["ymax"] - bbox["ymin"]) / 1000)

  testthat::expect_equal(width_km, expected_width, tolerance = 1e-3)
  testthat::expect_equal(height_km, expected_height, tolerance = 1e-3)
})

testthat::test_that("build_aoi_from_config auto requires sites", {
  cfg <- list(mode = "auto", buffer_km = 0.2)
  testthat::expect_error(
    localmap::build_aoi_from_config(cfg),
    class = "aoi_auto_missing_sites"
  )
})
