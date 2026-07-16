testthat::test_that("network imagery fetch is gated behind LOCALMAP_ALLOW_NETWORK", {
  if (!localmap:::localmap_network_allowed()) {
    testthat::skip("Network fetch disabled (set LOCALMAP_ALLOW_NETWORK=1 to enable).")
  }

  bbox <- sf::st_sfc(sf::st_polygon(list(rbind(
    c(146.94, -43.01),
    c(146.95, -43.01),
    c(146.95, -43.00),
    c(146.94, -43.00),
    c(146.94, -43.01)
  ))), crs = 4326)

  cfg <- list(
    url = paste0(
      "https://services.thelist.tas.gov.au/arcgis/services/Public/NaturalEnvironment/",
      "MapServer/WMSServer"
    ),
    layers = c("TASVEG_4.0_Groups55513"),
    styles = "",
    crs = "EPSG:3857",
    format = "image/png",
    width = 128,
    height = 128,
    dpi = 96,
    output_path = tempfile(fileext = ".png")
  )

  res <- localmap:::fetch_wms_imagery(cfg, bbox, offline = FALSE, cache_dir = tempfile())
  testthat::expect_true(file.exists(res$path))
})
