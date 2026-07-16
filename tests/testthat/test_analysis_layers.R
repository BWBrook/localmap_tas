testthat::test_that("analysis layers create clipped vector and raster outputs", {
  aoi_cfg <- list(
    centroid = list(lat = -43.0, lon = 146.944),
    size_km = 5,
    rotation_deg = 0,
    crs = "EPSG:28355"
  )
  aoi <- localmap::build_aoi_from_config(aoi_cfg)

  vector_out <- tempfile(fileext = ".gpkg")
  raster_out <- tempfile(fileext = ".tif")

  layers <- list(
    list(
      id = "habitats",
      type = "vector_file",
      path = "inst/extdata/jc_habitats.gpkg",
      layer = "habitats",
      output_path = vector_out,
      attribution = list(source = "fixture")
    ),
    list(
      id = "dem",
      type = "raster_file",
      path = "inst/extdata/jc_dem.tif",
      output_path = raster_out,
      categorical = FALSE,
      attribution = list(source = "fixture")
    )
  )

  res <- localmap::fetch_analysis_layers(layers, aoi = aoi)
  testthat::expect_true(file.exists(res$path[res$id == "habitats"]))
  testthat::expect_true(file.exists(res$path[res$id == "dem"]))

  vec <- sf::st_read(vector_out, quiet = TRUE)
  aoi_geom <- aoi$aoi
  vec <- sf::st_transform(vec, sf::st_crs(aoi_geom))
  intersects <- sf::st_intersects(vec, aoi_geom, sparse = FALSE)
  testthat::expect_true(all(intersects))

  rast <- terra::rast(raster_out)
  testthat::expect_true(terra::ncell(rast) > 0)
})

testthat::test_that("geodata raster layers use fixtures when offline", {
  aoi_cfg <- list(
    centroid = list(lat = -43.0, lon = 146.944),
    size_km = 5,
    rotation_deg = 0,
    crs = "EPSG:28355"
  )
  aoi <- localmap::build_aoi_from_config(aoi_cfg)

  raster_out <- tempfile(fileext = ".tif")
  layers <- list(
    list(
      id = "dem_geo",
      type = "raster_geodata",
      resolution = "3s",
      output_path = raster_out,
      offline = TRUE,
      fixture_path = "inst/extdata/jc_dem.tif",
      attribution = list(source = "fixture")
    )
  )

  res <- localmap::fetch_analysis_layers(layers, aoi = aoi)
  testthat::expect_true(file.exists(res$path[res$id == "dem_geo"]))
})

testthat::test_that("WCS raster layers use fixtures when offline", {
  aoi_cfg <- list(
    centroid = list(lat = -43.0, lon = 146.944),
    size_km = 5,
    rotation_deg = 0,
    crs = "EPSG:28355"
  )
  aoi <- localmap::build_aoi_from_config(aoi_cfg)

  raster_out <- tempfile(fileext = ".tif")
  layers <- list(
    list(
      id = "dem_wcs",
      type = "raster_wcs",
      url = "https://services.ga.gov.au/gis/services/DEM_SRTM_1Second_2024/MapServer/WCSServer",
      coverage = "1",
      output_path = raster_out,
      offline = TRUE,
      fixture_path = "inst/extdata/jc_dem.tif",
      attribution = list(source = "fixture")
    )
  )

  res <- localmap::fetch_analysis_layers(layers, aoi = aoi)
  testthat::expect_true(file.exists(res$path[res$id == "dem_wcs"]))
})

testthat::test_that("derived slope and indices are computed", {
  aoi_cfg <- list(
    centroid = list(lat = -43.0, lon = 146.944),
    size_km = 5,
    rotation_deg = 0,
    crs = "EPSG:28355"
  )
  aoi <- localmap::build_aoi_from_config(aoi_cfg)

  dem_out <- tempfile(fileext = ".tif")
  mult_out <- tempfile(fileext = ".tif")
  slope_out <- tempfile(fileext = ".tif")
  ndvi_out <- tempfile(fileext = ".tif")
  nbr_out <- tempfile(fileext = ".tif")
  ndvi_named_out <- tempfile(fileext = ".tif")
  nbr_named_out <- tempfile(fileext = ".tif")

  layers <- list(
    list(
      id = "dem",
      type = "raster_file",
      path = "inst/extdata/jc_dem.tif",
      output_path = dem_out,
      categorical = FALSE,
      attribution = list(source = "fixture")
    ),
    list(
      id = "multi",
      type = "raster_file",
      path = "inst/extdata/jc_multiband.tif",
      output_path = mult_out,
      categorical = FALSE,
      attribution = list(source = "fixture")
    ),
    list(
      id = "slope",
      type = "derived_slope",
      source_id = "dem",
      output_path = slope_out,
      units = "degrees",
      attribution = list(source = "fixture")
    ),
    list(
      id = "ndvi",
      type = "derived_ndvi",
      source_id = "multi",
      bands = list(red = 1, nir = 2),
      output_path = ndvi_out,
      attribution = list(source = "fixture")
    ),
    list(
      id = "nbr",
      type = "derived_nbr",
      source_id = "multi",
      bands = list(nir = 2, swir2 = 3),
      output_path = nbr_out,
      attribution = list(source = "fixture")
    ),
    list(
      id = "ndvi_named",
      type = "derived_ndvi",
      source_id = "multi",
      bands = list(red = "red", nir = "nir"),
      output_path = ndvi_named_out,
      attribution = list(source = "fixture")
    ),
    list(
      id = "nbr_named",
      type = "derived_nbr",
      source_id = "multi",
      bands = list(nir = "nir", swir2 = "swir2"),
      output_path = nbr_named_out,
      attribution = list(source = "fixture")
    )
  )

  res <- localmap::fetch_analysis_layers(layers, aoi = aoi)
  testthat::expect_true(file.exists(res$path[res$id == "slope"]))
  testthat::expect_true(file.exists(res$path[res$id == "ndvi"]))
  testthat::expect_true(file.exists(res$path[res$id == "nbr"]))
  testthat::expect_true(file.exists(res$path[res$id == "ndvi_named"]))
  testthat::expect_true(file.exists(res$path[res$id == "nbr_named"]))

  ndvi <- terra::rast(ndvi_out)
  vals <- terra::values(ndvi, na.rm = TRUE)
  testthat::expect_true(all(vals >= -1 & vals <= 1))
})

testthat::test_that("categorical rasters use nearest-neighbor resampling", {
  aoi_cfg <- list(
    centroid = list(lat = -43.0, lon = 146.944),
    size_km = 5,
    rotation_deg = 0,
    crs = "EPSG:28355"
  )
  aoi <- localmap::build_aoi_from_config(aoi_cfg)

  input_path <- tempfile(fileext = ".tif")
  output_path <- tempfile(fileext = ".tif")

  cat_rast <- terra::rast(
    nrows = 10,
    ncols = 10,
    xmin = 146.94,
    xmax = 146.95,
    ymin = -43.01,
    ymax = -42.99,
    crs = "EPSG:4326"
  )
  cat_rast <- terra::setValues(
    cat_rast,
    rep(c(1L, 2L), length.out = terra::ncell(cat_rast))
  )
  terra::writeRaster(cat_rast, input_path, overwrite = TRUE)

  layers <- list(
    list(
      id = "categorical",
      type = "raster_file",
      path = input_path,
      output_path = output_path,
      categorical = TRUE,
      attribution = list(source = "fixture")
    )
  )

  localmap::fetch_analysis_layers(layers, aoi = aoi)
  out <- terra::rast(output_path)
  vals <- terra::values(out, na.rm = TRUE)
  testthat::expect_true(all(vals %in% c(1, 2)))
  testthat::expect_true(all(abs(vals - round(vals)) < 1e-6))
})

testthat::test_that("analysis layer cache keys are deterministic and hit cache", {
  aoi_cfg <- list(
    centroid = list(lat = -43.0, lon = 146.944),
    size_km = 2,
    rotation_deg = 0,
    crs = "EPSG:28355"
  )
  aoi <- localmap::build_aoi_from_config(aoi_cfg)
  cache_dir <- tempfile()
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  layer <- list(
    id = "dem",
    type = "raster_file",
    path = system.file("extdata", "jc_dem.tif", package = "localmap"),
    output_path = tempfile(fileext = ".tif"),
    attribution = list(source = "fixture")
  )

  res1 <- localmap::fetch_analysis_layers(list(layer), aoi = aoi, cache_dir = cache_dir)
  prov1 <- readLines(res1$provenance_path[[1]], warn = FALSE)
  testthat::expect_true(any(grepl("status: created", prov1)))

  file.remove(res1$path[[1]])
  res2 <- localmap::fetch_analysis_layers(list(layer), aoi = aoi, cache_dir = cache_dir)
  prov2 <- readLines(res2$provenance_path[[1]], warn = FALSE)
  testthat::expect_true(any(grepl("status: cache_hit", prov2)))
  testthat::expect_identical(res1$cache_path[[1]], res2$cache_path[[1]])
})

testthat::test_that("arcgis vector fetch is gated without network or fixture", {
  aoi_cfg <- list(
    centroid = list(lat = -43.0, lon = 146.944),
    size_km = 2,
    rotation_deg = 0,
    crs = "EPSG:28355"
  )
  aoi <- localmap::build_aoi_from_config(aoi_cfg)

  layer <- list(
    id = "arcgis_vec",
    type = "vector_arcgis",
    url = "https://example.com/arcgis/service",
    output_path = tempfile(fileext = ".gpkg"),
    attribution = list(source = "fixture")
  )

  old <- Sys.getenv("LOCALMAP_ALLOW_NETWORK", unset = NA_character_)
  on.exit({
    if (is.na(old)) {
      Sys.unsetenv("LOCALMAP_ALLOW_NETWORK")
    } else {
      Sys.setenv(LOCALMAP_ALLOW_NETWORK = old)
    }
  }, add = TRUE)
  Sys.unsetenv("LOCALMAP_ALLOW_NETWORK")

  testthat::expect_error(
    localmap::fetch_analysis_layers(list(layer), aoi = aoi, cache_dir = tempfile()),
    class = "analysis_vector_offline_missing_fixture"
  )
})

testthat::test_that("arcgis raster fetch falls back to fixture when offline", {
  aoi_cfg <- list(
    centroid = list(lat = -43.0, lon = 146.944),
    size_km = 2,
    rotation_deg = 0,
    crs = "EPSG:28355"
  )
  aoi <- localmap::build_aoi_from_config(aoi_cfg)

  layer <- list(
    id = "arcgis_raster",
    type = "raster_arcgis",
    url = "https://example.com/arcgis/export",
    output_path = tempfile(fileext = ".tif"),
    fixture_path = "inst/extdata/jc_dem.tif",
    attribution = list(source = "fixture")
  )

  old <- Sys.getenv("LOCALMAP_ALLOW_NETWORK", unset = NA_character_)
  on.exit({
    if (is.na(old)) {
      Sys.unsetenv("LOCALMAP_ALLOW_NETWORK")
    } else {
      Sys.setenv(LOCALMAP_ALLOW_NETWORK = old)
    }
  }, add = TRUE)
  Sys.unsetenv("LOCALMAP_ALLOW_NETWORK")

  res <- localmap::fetch_analysis_layers(list(layer), aoi = aoi, cache_dir = tempfile())
  testthat::expect_true(file.exists(res$path[res$id == "arcgis_raster"]))
})

testthat::test_that("arcgis raster fetch errors when offline without fixture", {
  aoi_cfg <- list(
    centroid = list(lat = -43.0, lon = 146.944),
    size_km = 2,
    rotation_deg = 0,
    crs = "EPSG:28355"
  )
  aoi <- localmap::build_aoi_from_config(aoi_cfg)

  layer <- list(
    id = "arcgis_raster",
    type = "raster_arcgis",
    url = "https://example.com/arcgis/export",
    output_path = tempfile(fileext = ".tif"),
    attribution = list(source = "fixture")
  )

  old <- Sys.getenv("LOCALMAP_ALLOW_NETWORK", unset = NA_character_)
  on.exit({
    if (is.na(old)) {
      Sys.unsetenv("LOCALMAP_ALLOW_NETWORK")
    } else {
      Sys.setenv(LOCALMAP_ALLOW_NETWORK = old)
    }
  }, add = TRUE)
  Sys.unsetenv("LOCALMAP_ALLOW_NETWORK")

  testthat::expect_error(
    localmap::fetch_analysis_layers(list(layer), aoi = aoi, cache_dir = tempfile()),
    class = "analysis_raster_offline_missing_fixture"
  )
})

testthat::test_that("arcgis vector fixtures are clipped in AOI CRS", {
  aoi_cfg <- list(
    centroid = list(lat = -43.0, lon = 146.944),
    size_km = 2,
    rotation_deg = 0,
    crs = "EPSG:28355"
  )
  aoi <- localmap::build_aoi_from_config(aoi_cfg)
  cache_dir <- tempfile()
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  layer <- list(
    id = "arcgis_vec_fixture",
    type = "vector_arcgis",
    url = "https://example.com/arcgis/service",
    output_path = tempfile(fileext = ".gpkg"),
    offline = TRUE,
    fixture_path = "inst/extdata/jc_habitats.gpkg",
    fixture_layer = "habitats",
    attribution = list(source = "fixture")
  )

  res <- localmap::fetch_analysis_layers(list(layer), aoi = aoi, cache_dir = cache_dir)
  vec <- sf::st_read(res$path[[1]], quiet = TRUE)
  provenance <- yaml::read_yaml(res$provenance_path[[1]])
  testthat::expect_equal(sf::st_crs(vec)$epsg, sf::st_crs(aoi$aoi)$epsg)
  testthat::expect_identical(provenance$status, "offline_fixture")
  testthat::expect_true(provenance[["params.offline"]])
  testthat::expect_identical(
    provenance[["params.fixture_path"]],
    "inst/extdata/jc_habitats.gpkg"
  )

  file.remove(res$path[[1]])
  cached <- localmap::fetch_analysis_layers(list(layer), aoi = aoi, cache_dir = cache_dir)
  cached_provenance <- yaml::read_yaml(cached$provenance_path[[1]])
  testthat::expect_identical(cached_provenance$status, "offline_fixture")
})

testthat::test_that("analysis layer previews render PNGs", {
  aoi_cfg <- list(
    centroid = list(lat = -43.0, lon = 146.944),
    size_km = 5,
    rotation_deg = 0,
    crs = "EPSG:28355"
  )
  aoi <- localmap::build_aoi_from_config(aoi_cfg)

  vec_path <- tempfile(fileext = ".gpkg")
  rast_path <- tempfile(fileext = ".tif")

  vec <- sf::st_sf(
    id = c("a", "b"),
    geometry = sf::st_sfc(
      sf::st_point(c(146.94, -43.0)),
      sf::st_point(c(146.945, -43.002)),
      crs = 4326
    )
  )
  sf::st_write(vec, vec_path, quiet = TRUE)

  rast <- terra::rast(
    nrows = 5,
    ncols = 5,
    xmin = 146.94,
    xmax = 146.95,
    ymin = -43.01,
    ymax = -42.99,
    crs = "EPSG:4326"
  )
  rast <- terra::setValues(rast, seq_len(terra::ncell(rast)))
  terra::writeRaster(rast, rast_path, overwrite = TRUE)

  layers <- tibble::tibble(
    id = c("vec", "rast"),
    type = c("vector_file", "raster_file"),
    path = c(vec_path, rast_path)
  )

  previews <- localmap:::render_analysis_layer_previews(layers, aoi = aoi)
  testthat::expect_true(all(file.exists(previews$path)))
})

testthat::test_that("derived layers require sources to appear earlier", {
  layers <- list(
    list(
      id = "slope",
      type = "derived_slope",
      source_id = "dem",
      output_path = tempfile(fileext = ".tif"),
      attribution = list(source = "fixture")
    ),
    list(
      id = "dem",
      type = "raster_file",
      path = "inst/extdata/jc_dem.tif",
      output_path = tempfile(fileext = ".tif"),
      attribution = list(source = "fixture")
    )
  )

  testthat::expect_error(
    localmap:::validate_analysis_layers(layers),
    class = "analysis_layer_source_order"
  )
})
