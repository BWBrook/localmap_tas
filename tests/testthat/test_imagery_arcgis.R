testthat::test_that("arcgis_build_query is deterministic", {
  bbox <- sf::st_sfc(sf::st_polygon(list(rbind(
    c(145, -42),
    c(145.1, -42),
    c(145.1, -42.1),
    c(145, -42.1),
    c(145, -42)
  ))), crs = 4326)

  cfg <- list(
    url = "https://example.com/arcgis/export",
    crs = "EPSG:3857",
    width = 256,
    height = 256,
    format = "png",
    dpi = 96
  )

  q1 <- localmap:::arcgis_build_query(cfg, bbox)
  q2 <- localmap:::arcgis_build_query(cfg, bbox)
  testthat::expect_identical(q1$query, q2$query)
  testthat::expect_identical(q1$bbox_param, q2$bbox_param)
})

testthat::test_that("fetch_arcgis_imagery writes placeholder and provenance offline", {
  bbox <- sf::st_sfc(sf::st_polygon(list(rbind(
    c(145, -42),
    c(145.1, -42),
    c(145.1, -42.1),
    c(145, -42.1),
    c(145, -42)
  ))), crs = 4326)

  cfg <- list(
    url = "https://example.com/arcgis/export",
    crs = "EPSG:3857",
    width = 128,
    height = 128,
    output_path = tempfile(fileext = ".png")
  )

  res <- localmap::fetch_arcgis_imagery(cfg, bbox, offline = TRUE, cache_dir = tempfile())
  testthat::expect_true(file.exists(res$path))
  testthat::expect_true(file.exists(res$provenance_path))
  testthat::expect_gt(file.info(res$provenance_path)$size, 0)
})
