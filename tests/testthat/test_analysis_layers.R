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
    )
  )

  res <- localmap::fetch_analysis_layers(layers, aoi = aoi)
  testthat::expect_true(file.exists(res$path[res$id == "slope"]))
  testthat::expect_true(file.exists(res$path[res$id == "ndvi"]))
  testthat::expect_true(file.exists(res$path[res$id == "nbr"]))

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
