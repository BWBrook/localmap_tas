testthat::test_that("render_overview_map writes output", {
  aoi_cfg <- list(centroid = list(lat = -42.0, lon = 146.0), size_km = 10, rotation_deg = 0)
  aoi <- localmap::build_aoi_from_config(aoi_cfg)
  sites <- data.frame(
    site = c("a", "b", "c"),
    lat = c(-42.0, -42.01, -42.02),
    lon = c(146.0, 146.01, 146.02)
  )
  coverage <- localmap::build_coverage_zone(sites, list(enabled = TRUE, buffer_m = 0))
  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp), add = TRUE)

  out <- localmap::render_overview_map(
    aoi = aoi,
    sites = sites,
    coverage = coverage,
    layers = tibble::tibble(),
    map_cfg = list(output_path = tmp, show_labels = FALSE)
  )

  testthat::expect_true(file.exists(out))
})

testthat::test_that("render_overview_map matches AOI aspect ratio by default", {
  aoi_cfg <- list(
    centroid = list(lat = -42.0, lon = 146.0),
    width_km = 20,
    height_km = 10,
    rotation_deg = 0
  )
  aoi <- localmap::build_aoi_from_config(aoi_cfg)
  sites <- data.frame(site = "a", lat = -42.0, lon = 146.0)
  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp), add = TRUE)

  out <- localmap::render_overview_map(
    aoi = aoi,
    sites = sites,
    layers = tibble::tibble(),
    map_cfg = list(output_path = tmp, width = 6, dpi = 100, show_labels = FALSE)
  )

  img <- png::readPNG(out)
  pixel_ratio <- dim(img)[2] / dim(img)[1]
  testthat::expect_equal(pixel_ratio, 2, tolerance = 0.2)
})
