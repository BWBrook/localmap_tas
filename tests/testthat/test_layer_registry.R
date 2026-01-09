testthat::test_that("validate_layer_registry enforces required fields", {
  valid <- list(
    list(
      id = "tasveg",
      type = "wms",
      url = "https://example.com/wms",
      layers = "layer_a",
      attribution = list(source = "Example")
    ),
    list(
      id = "topo",
      type = "arcgis_export",
      url = "https://example.com/arcgis/export",
      attribution = list(source = "Example")
    )
  )
  out <- localmap::validate_layer_registry(valid)
  testthat::expect_equal(length(out), 2L)
  testthat::expect_equal(out[[1]]$id, "tasveg")
})

testthat::test_that("validate_layer_registry errors on missing id", {
  bad <- list(list(
    type = "wms",
    url = "https://example.com",
    layers = "x",
    attribution = list(source = "x")
  ))
  testthat::expect_error(
    localmap::validate_layer_registry(bad),
    class = "layer_registry_missing_id"
  )
})

testthat::test_that("validate_layer_registry errors on missing attribution", {
  bad <- list(list(id = "x", type = "wms", url = "https://example.com", layers = "x"))
  testthat::expect_error(
    localmap::validate_layer_registry(bad),
    class = "layer_registry_missing_attribution"
  )
})
