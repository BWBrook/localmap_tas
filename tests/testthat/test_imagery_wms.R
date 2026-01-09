testthat::test_that("wms_build_query is deterministic", {
  bbox <- sf::st_sfc(sf::st_polygon(list(rbind(
    c(145, -42),
    c(145.1, -42),
    c(145.1, -42.1),
    c(145, -42.1),
    c(145, -42)
  ))), crs = 4326)

  cfg <- list(
    url = "https://example.com/wms",
    layers = c("layer_a"),
    styles = "",
    format = "image/png",
    crs = "EPSG:3857",
    width = 256,
    height = 256,
    version = "1.3.0",
    dpi = 96
  )

  q1 <- localmap:::wms_build_query(cfg, bbox)
  q2 <- localmap:::wms_build_query(cfg, bbox)
  testthat::expect_identical(q1$query, q2$query)
  testthat::expect_identical(q1$bbox_param, q2$bbox_param)
})

testthat::test_that("fetch_wms_imagery writes placeholder and provenance offline", {
  bbox <- sf::st_sfc(sf::st_polygon(list(rbind(
    c(145, -42),
    c(145.1, -42),
    c(145.1, -42.1),
    c(145, -42.1),
    c(145, -42)
  ))), crs = 4326)

  cfg <- list(
    url = "https://example.com/wms",
    layers = c("layer_a"),
    crs = "EPSG:3857",
    width = 128,
    height = 128,
    output_path = tempfile(fileext = ".png")
  )

  res <- localmap::fetch_wms_imagery(cfg, bbox, offline = TRUE, cache_dir = tempfile())
  testthat::expect_true(file.exists(res$path))
  testthat::expect_true(file.exists(res$provenance_path))
  testthat::expect_gt(file.info(res$provenance_path)$size, 0)
})

testthat::test_that("imagery_cache_key changes with bbox", {
  params_a <- list(url = "https://example.com/wms", BBOX = "1,2,3,4", width = 256)
  params_b <- list(url = "https://example.com/wms", BBOX = "5,6,7,8", width = 256)
  key_a <- localmap:::imagery_cache_key(params_a)
  key_b <- localmap:::imagery_cache_key(params_b)
  testthat::expect_false(identical(key_a, key_b))
})
