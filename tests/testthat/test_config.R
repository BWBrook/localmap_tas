testthat::test_that("cfg_read returns a list with default profile", {
  cfg <- localmap::cfg_read()
  testthat::expect_type(cfg, "list")
  testthat::expect_true(!is.null(cfg$data_dir))
  testthat::expect_equal(cfg$schema_version, 2)
})

testthat::test_that("cfg_read fails when schema_version is missing", {
  tmp <- tempfile(fileext = ".yaml")
  writeLines(c("default:", "  data: {}"), tmp)
  testthat::expect_error(
    localmap::cfg_read(config_path = tmp),
    class = "cfg_schema_missing"
  )
})

testthat::test_that("cfg_read fails when required keys are missing", {
  tmp <- tempfile(fileext = ".yaml")
  writeLines(c(
    "default:",
    "  schema_version: 2",
    "  data:",
    "    aoi:",
    "      centroid:",
    "        lat: -41.0",
    "        lon: 145.0",
    "      size_km: 10",
    "    species_requests: \"metadata/species_requests.csv\""
  ), tmp)
  testthat::expect_error(
    localmap::cfg_read(config_path = tmp),
    class = "cfg_required_missing"
  )
})

testthat::test_that("cfg_read migrates schema v1 to v2", {
  tmp <- tempfile(fileext = ".yaml")
  writeLines(c(
    "default:",
    "  schema_version: 1",
    "  data:",
    "    manifest: \"metadata/data_manifest.csv\"",
    "    species_requests: \"metadata/species_requests.csv\"",
    "    occurrence:",
    "      fields: [decimalLatitude]",
    "      map:",
    "        bounding_box:",
    "          top_left:",
    "            lat: -40.0",
    "            lon: 145.0",
    "          length_km: 10",
    "    camera_sites:",
    "      path: \"data/raw/lyr_op.csv\"",
    "      central_site: \"centre\"",
    "      bbox_half_km: 10",
    "  ala:",
    "    email: \"test@example.com\"",
    "    download_reason_id: 4"
  ), tmp)
  cfg <- localmap::cfg_read(config_path = tmp)
  testthat::expect_equal(cfg$schema_version, 2)
  testthat::expect_true(!is.null(cfg$data$aoi))
  testthat::expect_equal(cfg$data$aoi$size_km, 10)
})

testthat::test_that("cfg_read accepts auto AOI without explicit size", {
  tmp <- tempfile(fileext = ".yaml")
  writeLines(c(
    "default:",
    "  schema_version: 2",
    "  data:",
    "    aoi:",
    "      mode: auto",
    "    manifest: \"metadata/data_manifest.csv\"",
    "    species_requests: \"metadata/species_requests.csv\"",
    "    occurrence:",
    "      fields: [decimalLatitude]",
    "      map: {}",
    "    camera_sites:",
    "      path: \"data/raw/lyr_op.csv\"",
    "      central_site: \"centre\"",
    "      bbox_half_km: 10",
    "  ala:",
    "    email: \"test@example.com\"",
    "    download_reason_id: 4"
  ), tmp)
  cfg <- localmap::cfg_read(config_path = tmp)
  testthat::expect_equal(tolower(cfg$data$aoi$mode), "auto")
})

testthat::test_that("cfg_read applies dem_variant overrides", {
  tmp <- tempfile(fileext = ".yaml")
  writeLines(c(
    "default:",
    "  schema_version: 2",
    "  data:",
    "    manifest: \"metadata/data_manifest.csv\"",
    "    species_requests: \"metadata/species_requests.csv\"",
    "    dem_variant: \"srtm_3s\"",
    "    aoi:",
    "      centroid:",
    "        lat: -41.0",
    "        lon: 145.0",
    "      size_km: 10",
    "    occurrence:",
    "      fields: [decimalLatitude]",
    "      map: {}",
    "    camera_sites:",
    "      path: \"data/raw/lyr_op.csv\"",
    "      central_site: \"centre\"",
    "      bbox_half_km: 10",
    "    analysis_layers:",
    "      - id: \"site_dem\"",
    "        type: \"raster_wcs\"",
    paste0(
      "        url: \"",
      "https://services.ga.gov.au/gis/services/",
      "DEM_SRTM_1Second_2024/MapServer/WCSServer",
      "\""
    ),
    "        coverage: \"1\"",
    "        output_path: \"outputs/jc/analysis/raster/jc_dem.tif\"",
    "        attribution:",
    "          source: \"stub\"",
    "  ala:",
    "    email: \"test@example.com\"",
    "    download_reason_id: 4"
  ), tmp)
  cfg <- localmap::cfg_read(config_path = tmp)
  dem_layer <- cfg$data$analysis_layers[[1]]
  testthat::expect_equal(dem_layer$type, "raster_geodata")
  testthat::expect_equal(dem_layer$resolution, "3s")
})

testthat::test_that("cfg_read errors when elvis_2m path is missing", {
  tmp <- tempfile(fileext = ".yaml")
  writeLines(c(
    "default:",
    "  schema_version: 2",
    "  data:",
    "    manifest: \"metadata/data_manifest.csv\"",
    "    species_requests: \"metadata/species_requests.csv\"",
    "    dem_variant: \"elvis_2m\"",
    "    aoi:",
    "      centroid:",
    "        lat: -41.0",
    "        lon: 145.0",
    "      size_km: 10",
    "    occurrence:",
    "      fields: [decimalLatitude]",
    "      map: {}",
    "    camera_sites:",
    "      path: \"data/raw/lyr_op.csv\"",
    "      central_site: \"centre\"",
    "      bbox_half_km: 10"
  ), tmp)
  testthat::expect_error(
    localmap::cfg_read(config_path = tmp),
    class = "cfg_dem_variant_path_missing"
  )
})

testthat::test_that("cfg_read fails on unsupported schema_version", {
  tmp <- tempfile(fileext = ".yaml")
  writeLines(c(
    "default:",
    "  schema_version: 3",
    "  data:",
    "    manifest: \"metadata/data_manifest.csv\"",
    "    species_requests: \"metadata/species_requests.csv\"",
    "    aoi:",
    "      centroid:",
    "        lat: -41.0",
    "        lon: 145.0",
    "      size_km: 10",
    "    occurrence:",
    "      fields: [decimalLatitude]",
    "      map: {}",
    "    camera_sites:",
    "      path: \"data/raw/lyr_op.csv\"",
    "      central_site: \"centre\"",
    "      bbox_half_km: 10",
    "  ala:",
    "    email: \"test@example.com\"",
    "    download_reason_id: 4"
  ), tmp)
  testthat::expect_error(
    localmap::cfg_read(config_path = tmp),
    class = "cfg_schema_unsupported"
  )
})

testthat::test_that("cfg_read resolves demo outputs under outputs/demo", {
  cfg <- localmap::cfg_read(profile = "demo")

  testthat::expect_equal(cfg$data$outputs$output_dir, "outputs/demo")
  testthat::expect_true(startsWith(cfg$data$overview_map$output_path, "outputs/demo/"))
  testthat::expect_true(startsWith(cfg$data$panel_figure$output_path, "outputs/demo/"))
})

testthat::test_that("cfg_read resolves jc outputs under outputs/jc", {
  cfg <- localmap::cfg_read(profile = "jc")

  testthat::expect_equal(cfg$data$outputs$output_dir, "outputs/jc")
  testthat::expect_true(startsWith(cfg$data$overview_map$output_path, "outputs/jc/"))
  testthat::expect_true(startsWith(cfg$data$panel_figure$output_path, "outputs/jc/"))
})

testthat::test_that("cfg_read resolves tas canonical outputs and DEM override", {
  cfg <- localmap::cfg_read(profile = "tas_canonical")
  dem_layer <- purrr::detect(cfg$data$analysis_layers, ~ grepl("_dem$", .x$id))

  testthat::expect_equal(cfg$data$outputs$output_dir, "outputs/tas")
  testthat::expect_true(startsWith(cfg$data$overview_map$output_path, "outputs/tas/"))
  testthat::expect_true(startsWith(cfg$data$panel_figure$output_path, "outputs/tas/"))
  testthat::expect_false(is.null(dem_layer))
  testthat::expect_true(dem_layer$type %in% c("raster_wcs", "raster_geodata", "raster_file"))
})

testthat::test_that("offline CI analysis vectors have local fixtures", {
  profiles <- c("jc_ci", "tas_canonical_ci")

  missing <- purrr::map_dfr(profiles, function(profile) {
    cfg <- localmap::cfg_read(profile = profile)
    layers <- cfg$data$analysis_layers
    if (is.null(layers) || length(layers) == 0L) {
      return(tibble::tibble())
    }
    purrr::map_dfr(layers, function(layer) {
      if (!identical(layer$type, "vector_arcgis")) {
        return(tibble::tibble())
      }
      fixture <- if (is.null(layer$fixture_path)) "" else layer$fixture_path
      resolved_fixture <- if (nzchar(fixture)) {
        localmap:::analysis_normalize_path(fixture, fixture)
      } else {
        ""
      }
      tibble::tibble(
        profile = profile,
        layer_id = layer$id,
        fixture_path = fixture,
        exists = nzchar(resolved_fixture) && file.exists(resolved_fixture)
      )
    })
  }) |>
    dplyr::filter(!.data$exists)

  testthat::expect_equal(missing, tibble::tibble(
    profile = character(),
    layer_id = character(),
    fixture_path = character(),
    exists = logical()
  ))
})

testthat::test_that("offline CI camera sites use packaged files", {
  profiles <- c("jc_ci", "tas_canonical_ci")

  missing <- purrr::map_dfr(profiles, function(profile) {
    cfg <- localmap::cfg_read(profile = profile)
    camera <- cfg$data$camera_sites
    source_type <- if (is.null(camera$source)) "file" else camera$source
    path <- if (identical(source_type, "file") && !is.null(camera$path)) {
      camera$path
    } else {
      ""
    }
    resolved_path <- if (nzchar(path)) {
      localmap:::analysis_normalize_path(path, path)
    } else {
      ""
    }
    tibble::tibble(
      profile = profile,
      source = source_type,
      path = path,
      exists = identical(source_type, "file") &&
        nzchar(resolved_path) &&
        file.exists(resolved_path)
    )
  }) |>
    dplyr::filter(!.data$exists)

  testthat::expect_equal(missing, tibble::tibble(
    profile = character(),
    source = character(),
    path = character(),
    exists = logical()
  ))
})
