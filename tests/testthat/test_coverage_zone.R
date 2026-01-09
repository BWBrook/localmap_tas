testthat::test_that("build_coverage_zone computes hull area and buffer", {
  sites <- data.frame(
    site = c("a", "b", "c", "d"),
    lat = c(-42.0, -42.0, -42.01, -42.01),
    lon = c(146.0, 146.01, 146.0, 146.01)
  )

  cfg <- list(enabled = TRUE, buffer_m = 0)
  coverage <- localmap::build_coverage_zone(sites, cfg, analysis_crs = "EPSG:28355")
  testthat::expect_true(isTRUE(coverage$enabled))
  testthat::expect_true(inherits(coverage$polygon, "sf"))
  testthat::expect_gt(coverage$area_m2, 0)
  testthat::expect_equal(coverage$n_sites, 4)

  cfg_buffer <- list(enabled = TRUE, buffer_m = 100)
  buffered <- localmap::build_coverage_zone(sites, cfg_buffer, analysis_crs = "EPSG:28355")
  testthat::expect_gt(buffered$area_m2, coverage$area_m2)
})

testthat::test_that("build_coverage_zone handles disabled and undersized inputs", {
  sites <- data.frame(site = "a", lat = -42.0, lon = 146.0)

  disabled <- localmap::build_coverage_zone(sites, list(enabled = FALSE))
  testthat::expect_false(disabled$enabled)
  testthat::expect_true(is.null(disabled$polygon))

  testthat::expect_warning(
    localmap::build_coverage_zone(sites, list(enabled = TRUE, buffer_m = 0)),
    "Coverage polygon requires at least 3 sites"
  )
  enabled <- suppressWarnings(
    localmap::build_coverage_zone(sites, list(enabled = TRUE, buffer_m = 0))
  )
  testthat::expect_true(isTRUE(enabled$enabled))
  testthat::expect_true(is.null(enabled$polygon))
  testthat::expect_equal(enabled$n_sites, 1)
})
