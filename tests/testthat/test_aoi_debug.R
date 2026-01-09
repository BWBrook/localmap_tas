testthat::test_that("render_aoi_debug_plot writes a PNG", {
  aoi_cfg <- list(
    centroid = list(lat = -41.0, lon = 145.0),
    size_km = 40,
    rotation_deg = 0
  )
  aoi <- localmap::build_aoi_from_config(aoi_cfg)
  sites <- data.frame(site = "a", lat = -41.1, lon = 145.1)
  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp), add = TRUE)

  path <- localmap:::render_aoi_debug_plot(
    aoi = aoi,
    sites = sites,
    output_path = tmp
  )

  testthat::expect_true(file.exists(path))
})
