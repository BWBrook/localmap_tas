#' Analysis-grade vector and raster layer acquisition
#'
#' Helpers for validating, fetching, and caching analysis-grade vector/raster
#' layers clipped to the AOI, including derived rasters.

# Analysis-grade vector and raster layer acquisition.

analysis_layer_types <- c(
  "vector_file",
  "vector_arcgis",
  "raster_arcgis",
  "raster_wcs",
  "raster_file",
  "raster_geodata",
  "derived_slope",
  "derived_ndvi",
  "derived_nbr"
)
analysis_cache_version <- "v5"

analysis_default <- function(value, fallback) {
  if (is.null(value)) fallback else value
}

analysis_normalize_path <- function(path, default_path) {
  if (is.null(path) || !nzchar(path)) {
    path <- default_path
  }
  candidates <- unique(c(path, here::here(path)))
  existing <- candidates[file.exists(candidates)]
  if (length(existing) > 0L) {
    return(existing[[1L]])
  }
  installed <- path
  if (startsWith(installed, "inst/")) {
    installed <- sub("^inst/", "", installed)
  }
  pkg_path <- system.file(installed, package = "localmap")
  if (nzchar(pkg_path) && file.exists(pkg_path)) {
    return(pkg_path)
  }
  candidates[[1L]]
}

#' Validate analysis layer configuration
#'
#' @param layers List of analysis layer definitions (from config).
#' @return Normalized list of layer definitions.
#' @export
validate_analysis_layers <- function(layers) {
  if (is.null(layers)) {
    return(list())
  }
  if (!is.list(layers)) {
    rlang::abort(
      "`data$analysis_layers` must be a list.",
      class = "analysis_layers_invalid"
    )
  }

  normalized <- lapply(layers, function(layer) {
    if (!is.list(layer)) {
      rlang::abort("Each analysis layer must be a list.", class = "analysis_layer_invalid")
    }
    layer
  })

  ids <- vapply(normalized, function(layer) {
    id <- layer$id
    if (is.null(id) || !nzchar(id)) {
      return(NA_character_)
    }
    as.character(id)
  }, character(1))
  if (anyNA(ids)) {
    rlang::abort(
      "Each analysis layer must define a non-empty `id`.",
      class = "analysis_layer_missing_id"
    )
  }
  if (any(duplicated(ids))) {
    rlang::abort("Analysis layer IDs must be unique.", class = "analysis_layer_duplicate_id")
  }

  id_index <- stats::setNames(seq_along(ids), ids)

  normalized <- Map(function(layer, id) {
    layer$id <- id
    type <- layer$type
    if (is.null(type) || !nzchar(type)) {
      rlang::abort(
        sprintf("Analysis layer '%s' missing `type`.", id),
        class = "analysis_layer_missing_type"
      )
    }
    type <- tolower(as.character(type))
    if (!type %in% analysis_layer_types) {
      rlang::abort(
        sprintf("Analysis layer '%s' has unsupported type '%s'.", id, type),
        class = "analysis_layer_invalid_type"
      )
    }
    layer$type <- type

    if (type %in% c("vector_file", "raster_file")) {
      if (is.null(layer$path) || !nzchar(layer$path)) {
        rlang::abort(
          sprintf("Analysis layer '%s' requires `path`.", id),
          class = "analysis_layer_missing_path"
        )
      }
    }

    if (type %in% c("vector_arcgis", "raster_arcgis")) {
      if (is.null(layer$url) || !nzchar(layer$url)) {
        rlang::abort(
          sprintf("Analysis layer '%s' requires an ArcGIS URL.", id),
          class = "analysis_layer_missing_url"
        )
      }
    }

    if (identical(type, "raster_wcs")) {
      if (is.null(layer$url) || !nzchar(layer$url)) {
        rlang::abort(
          sprintf("WCS raster layer '%s' requires `url`.", id),
          class = "analysis_layer_missing_url"
        )
      }
    }

    if (identical(type, "raster_wcs")) {
      coverage <- layer$coverage %||% layer$identifier
      if (is.null(coverage) || !nzchar(coverage)) {
        rlang::abort(
          sprintf("WCS raster layer '%s' requires `coverage`.", id),
          class = "analysis_layer_missing_coverage"
        )
      }
      layer$coverage <- as.character(coverage)
      resolution <- layer$resolution
      if (!is.null(resolution)) {
        res_value <- analysis_parse_wcs_resolution(resolution)
        if (!is.finite(res_value) || res_value <= 0) {
          rlang::abort(
            sprintf("WCS raster layer '%s' has invalid `resolution`.", id),
            class = "analysis_layer_invalid_resolution"
          )
        }
      }
    }

    if (type %in% c("derived_slope", "derived_ndvi", "derived_nbr")) {
      if (is.null(layer$source_id) || !nzchar(layer$source_id)) {
        rlang::abort(
          sprintf("Derived analysis layer '%s' requires `source_id`.", id),
          class = "analysis_layer_missing_source_id"
        )
      }
    }

    if (identical(type, "raster_geodata")) {
      resolution <- analysis_default(layer$resolution, "3s")
      resolution <- tolower(as.character(resolution))
      if (!resolution %in% c("3s", "30s")) {
        rlang::abort(
          sprintf(
            "Geodata raster layer '%s' requires resolution '3s' or '30s'.",
            id
          ),
          class = "analysis_layer_geodata_resolution_invalid"
        )
      }
      layer$resolution <- resolution
    }

    attrib <- layer$attribution
    if (is.null(attrib) || !is.list(attrib) || is.null(attrib$source)) {
      rlang::abort(
        sprintf("Analysis layer '%s' requires `attribution$source`.", id),
        class = "analysis_layer_missing_attribution"
      )
    }
    layer
  }, normalized, ids)

  for (layer in normalized) {
    if (layer$type %in% c("derived_slope", "derived_ndvi", "derived_nbr")) {
      source_id <- as.character(layer$source_id)
      if (!source_id %in% ids) {
        rlang::abort(
          sprintf(
            "Derived analysis layer '%s' references missing source_id '%s'.",
            layer$id,
            source_id
          ),
          class = "analysis_layer_source_not_found"
        )
      }
      if (id_index[[source_id]] >= id_index[[layer$id]]) {
        rlang::abort(
          sprintf(
            "Derived analysis layer '%s' must appear after its source layer '%s'.",
            layer$id,
            source_id
          ),
          class = "analysis_layer_source_order"
        )
      }
    }
  }

  normalized
}

#' Fetch analysis layers (vector + raster)
#'
#' @param layers Validated analysis layer list.
#' @param aoi AOI list from `build_aoi_from_config()`.
#' @param cache_dir Optional cache directory.
#' @return Tibble of analysis layer outputs.
#' @export
fetch_analysis_layers <- function(layers, aoi, cache_dir = NULL) {
  layers <- validate_analysis_layers(layers)
  if (length(layers) == 0L) {
    return(tibble::tibble(
      id = character(),
      type = character(),
      path = character(),
      provenance_path = character(),
      cache_path = character(),
      source_id = character(),
      units = character(),
      attribution_source = character(),
      attribution_license = character(),
      attribution_credit = character()
    ))
  }
  if (is.null(aoi) || !is.list(aoi) || is.null(aoi$aoi)) {
    rlang::abort("AOI is required for analysis layers.", class = "analysis_layers_missing_aoi")
  }

  if (is.null(cache_dir)) {
    cache_dir <- here::here("data", "cache", "analysis")
  }
  cache_dir <- analysis_normalize_path(cache_dir, cache_dir)
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  aoi_geom <- aoi$aoi
  analysis_crs <- aoi$crs

  results <- list()
  raster_store <- list()
  layer_cache_keys <- list()

  for (layer in layers) {
    type <- layer$type
    source_descriptor <- layer$path %||% layer$url %||% layer$source_id %||% ""
    offline_flag <- isTRUE(layer$offline)
    if (type %in% c("vector_arcgis", "raster_arcgis")) {
      if (!localmap_network_allowed()) {
        offline_flag <- TRUE
      }
    }

    params <- list(
      layer = layer$layer,
      where = layer$where,
      out_fields = layer$out_fields,
      crs = layer$crs,
      categorical = layer$categorical,
      resample = layer$resample,
      bands = layer$bands,
      format = layer$format,
      width = layer$width,
      height = layer$height,
      dpi = layer$dpi,
      layers = layer$layers,
      layers_mode = layer$layers_mode,
      band = layer$band,
      transparent = layer$transparent,
      fixture_path = layer$fixture_path,
      offline = offline_flag,
      wcs_coverage = layer$coverage %||% layer$identifier,
      wcs_version = layer$version,
      wcs_format = layer$format,
      wcs_crs = layer$crs,
      wcs_resolution = layer$resolution,
      wcs_width = layer$width,
      wcs_height = layer$height,
      wcs_max_dim = layer$max_dim,
      wcs_fallback_type = layer$fallback$type,
      resolution = layer$resolution,
      geodata_path = layer$geodata_path,
      units = layer$units,
      source_id = layer$source_id
    )
    if (type %in% c("derived_slope", "derived_ndvi", "derived_nbr")) {
      source_key <- layer_cache_keys[[layer$source_id]]
      if (!is.null(source_key)) {
        params$source_cache_key <- source_key
      }
    }
    output_path <- analysis_normalize_path(
      layer$output_path,
      here::here("outputs", "analysis", paste0(layer$id, ".tif"))
    )
    provenance_path <- paste0(output_path, ".yml")
    cache_key <- imagery_cache_key(list(
      id = layer$id,
      type = type,
      source = source_descriptor,
      params = params,
      version = analysis_cache_version,
      bbox = as.numeric(sf::st_bbox(sf::st_transform(aoi_geom, 4326)))
    ))
    layer_cache_keys[[layer$id]] <- cache_key
    ext <- if (grepl("\\.gpkg$", output_path, ignore.case = TRUE)) ".gpkg" else ".tif"
    cache_path <- file.path(cache_dir, paste0(cache_key, ext))
    source_id <- layer$source_id %||% NA_character_

    if (file.exists(cache_path)) {
      dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
      if (!identical(
        normalizePath(cache_path, mustWork = FALSE),
        normalizePath(output_path, mustWork = FALSE)
      )) {
        file.copy(cache_path, output_path, overwrite = TRUE)
      }
      if (type %in% c("raster_file", "derived_slope", "derived_ndvi", "derived_nbr")) {
        raster_store[[layer$id]] <- terra::rast(output_path)
      }
      imagery_write_provenance(
        provenance_path,
        list(
          type = type,
          status = "cache_hit",
          cache_key = cache_key,
          cache_path = cache_path,
          output_path = output_path,
          source = source_descriptor,
          source_id = source_id,
          params = params
        )
      )
    } else {
      prov_params <- params
      prov_source <- source_descriptor
      prov_status <- "created"
      prov_meta <- NULL

      if (identical(type, "vector_file")) {
        vector <- read_vector_layer(layer$path, layer$layer)
        clipped <- clip_vector_to_aoi(vector, aoi_geom, analysis_crs)
        dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
        sf::st_write(
          clipped,
          output_path,
          layer = layer$layer %||% layer$id,
          quiet = TRUE,
          append = FALSE,
          delete_layer = TRUE
        )
      } else if (identical(type, "vector_arcgis")) {
        clipped <- fetch_arcgis_vector(layer, aoi_geom)
        dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
        sf::st_write(
          clipped,
          output_path,
          layer = layer$layer %||% layer$id,
          quiet = TRUE,
          append = FALSE,
          delete_layer = TRUE
        )
      } else if (identical(type, "raster_arcgis")) {
        raster <- fetch_arcgis_raster(layer, aoi_geom)
        clipped <- clip_raster_to_aoi(
          raster,
          aoi_geom,
          analysis_crs,
          categorical = isTRUE(layer$categorical),
          resample = layer$resample
        )
        dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
        terra::writeRaster(clipped, output_path, overwrite = TRUE)
        raster_store[[layer$id]] <- clipped
      } else if (identical(type, "raster_wcs")) {
        wcs_result <- fetch_wcs_raster(layer, aoi_geom, cache_dir = cache_dir)
        if (is.list(wcs_result) && !inherits(wcs_result, "SpatRaster")) {
          prov_meta <- wcs_result$meta
          raster <- wcs_result$raster
        } else {
          raster <- wcs_result
        }
        clipped <- clip_raster_to_aoi(
          raster,
          aoi_geom,
          analysis_crs,
          categorical = isTRUE(layer$categorical),
          resample = layer$resample
        )
        dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
        terra::writeRaster(clipped, output_path, overwrite = TRUE)
        raster_store[[layer$id]] <- clipped
      } else if (identical(type, "raster_geodata")) {
        raster <- fetch_geodata_raster(layer, aoi_geom, cache_dir = cache_dir)
        clipped <- clip_raster_to_aoi(
          raster,
          aoi_geom,
          analysis_crs,
          categorical = isTRUE(layer$categorical),
          resample = layer$resample
        )
        dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
        terra::writeRaster(clipped, output_path, overwrite = TRUE)
        raster_store[[layer$id]] <- clipped
      } else if (identical(type, "raster_file")) {
        raster <- read_raster_layer(layer$path)
        clipped <- clip_raster_to_aoi(
          raster,
          aoi_geom,
          analysis_crs,
          categorical = isTRUE(layer$categorical),
          resample = layer$resample
        )
        dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
        terra::writeRaster(clipped, output_path, overwrite = TRUE)
        raster_store[[layer$id]] <- clipped
      } else if (identical(type, "derived_slope")) {
        source <- raster_store[[layer$source_id]]
        if (is.null(source)) {
          rlang::abort(
            sprintf("Slope source raster '%s' not found.", layer$source_id),
            class = "analysis_layer_missing_source"
          )
        }
        units <- analysis_default(layer$units, "degrees")
        slope <- terra::terrain(source, v = "slope", unit = units)
        if (terra::nlyr(slope) == 1L) {
          names(slope) <- "slope"
        }
        dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
        terra::writeRaster(slope, output_path, overwrite = TRUE)
        raster_store[[layer$id]] <- slope
      } else if (type %in% c("derived_ndvi", "derived_nbr")) {
        source <- raster_store[[layer$source_id]]
        if (is.null(source)) {
          rlang::abort(
            sprintf("Index source raster '%s' not found.", layer$source_id),
            class = "analysis_layer_missing_source"
          )
        }
        bands <- layer$bands
        if (is.null(bands) || !is.list(bands)) {
          rlang::abort(
            sprintf("Derived layer '%s' requires `bands` mapping.", layer$id),
            class = "analysis_layer_missing_bands"
          )
        }
        if (identical(type, "derived_ndvi")) {
          red <- as.integer(bands$red)
          nir <- as.integer(bands$nir)
          idx <- compute_index(source, nir, red)
          names(idx) <- "ndvi"
        } else {
          nir <- as.integer(bands$nir)
          swir2 <- as.integer(bands$swir2)
          idx <- compute_index(source, nir, swir2)
          names(idx) <- "nbr"
        }
        dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
        terra::writeRaster(idx, output_path, overwrite = TRUE)
        raster_store[[layer$id]] <- idx
      }

      if (!is.null(prov_meta) && is.list(prov_meta)) {
        if (!is.null(prov_meta$params) && is.list(prov_meta$params)) {
          prov_params <- utils::modifyList(prov_params, prov_meta$params)
        }
        if (!is.null(prov_meta$source) && nzchar(prov_meta$source)) {
          prov_source <- prov_meta$source
        }
        if (!is.null(prov_meta$status) && nzchar(prov_meta$status)) {
          prov_status <- prov_meta$status
        }
      }

      if (!file.exists(output_path)) {
        rlang::abort(
          sprintf("Analysis layer output not created: %s", output_path),
          class = "analysis_layer_missing_output"
        )
      }
      dir.create(dirname(cache_path), recursive = TRUE, showWarnings = FALSE)
      if (!identical(
        normalizePath(cache_path, mustWork = FALSE),
        normalizePath(output_path, mustWork = FALSE)
      )) {
        file.copy(output_path, cache_path, overwrite = TRUE)
      }
      imagery_write_provenance(
        provenance_path,
        list(
          type = type,
          status = prov_status,
          cache_key = cache_key,
          cache_path = cache_path,
          output_path = output_path,
          source = prov_source,
          source_id = source_id,
          params = prov_params
        )
      )
    }

    results[[length(results) + 1L]] <- tibble::tibble(
      id = layer$id,
      type = type,
      path = output_path,
      provenance_path = provenance_path,
      cache_path = cache_path,
      source_id = source_id,
      units = as.character(layer$units %||% NA_character_),
      attribution_source = as.character(layer$attribution$source),
      attribution_license = as.character(layer$attribution$license %||% ""),
      attribution_credit = as.character(layer$attribution$credit %||% "")
    )
  }

  dplyr::bind_rows(results)
}

read_vector_layer <- function(path, layer = NULL) {
  path <- analysis_normalize_path(path, path)
  if (!file.exists(path)) {
    rlang::abort(
      sprintf("Vector layer not found: %s", path),
      class = "analysis_vector_missing_file"
    )
  }
  sf::st_read(path, layer = layer, quiet = TRUE)
}

clip_vector_to_aoi <- function(vector, aoi_geom, analysis_crs) {
  if (sf::st_crs(vector) != sf::st_crs(aoi_geom)) {
    vector <- sf::st_transform(vector, sf::st_crs(analysis_crs))
  }
  clipped <- sf::st_intersection(vector, sf::st_make_valid(aoi_geom))
  sf::st_make_valid(clipped)
}

fetch_arcgis_vector <- function(layer, aoi_geom) {
  aoi_crs <- sf::st_crs(aoi_geom)
  if (!localmap_network_allowed()) {
    if (!isTRUE(layer$offline)) {
      rlang::warn(
        sprintf(
          paste0(
            "Network access disabled; ArcGIS vector layer '%s' requires a fixture ",
            "or LOCALMAP_ALLOW_NETWORK=1."
          ),
          layer$id
        )
      )
    }
    layer$offline <- TRUE
  }
  if (isTRUE(layer$offline)) {
    fixture <- layer$fixture_path
    if (is.null(fixture) || !nzchar(fixture)) {
      rlang::abort(
        sprintf("ArcGIS vector layer '%s' offline without fixture.", layer$id),
        class = "analysis_vector_offline_missing_fixture"
      )
    }
    vector <- read_vector_layer(fixture, layer$fixture_layer)
    return(clip_vector_to_aoi(vector, aoi_geom, aoi_crs))
  }

  base_url <- layer$url
  if (!grepl("/query$", base_url)) {
    base_url <- paste0(rtrim_slash(base_url), "/query")
  }
  query_crs <- analysis_default(layer$crs, "EPSG:4326")
  bbox <- sf::st_bbox(sf::st_transform(aoi_geom, sf::st_crs(query_crs)))
  bbox_param <- paste(c(bbox["xmin"], bbox["ymin"], bbox["xmax"], bbox["ymax"]), collapse = ",")
  query <- list(
    f = "geojson",
    where = analysis_default(layer$where, "1=1"),
    geometry = bbox_param,
    geometryType = "esriGeometryEnvelope",
    inSR = arcgis_wkid_from_crs(query_crs),
    outSR = arcgis_wkid_from_crs(query_crs),
    outFields = analysis_default(layer$out_fields, "*")
  )
  req <- httr2::request(base_url)
  resp <- try(httr2::req_url_query(req, !!!query) |> httr2::req_perform(), silent = TRUE)
  if (inherits(resp, "try-error")) {
    rlang::abort(
      sprintf("ArcGIS vector fetch failed for '%s'.", layer$id),
      class = "analysis_vector_fetch_failed"
    )
  }
  httr2::resp_check_status(resp)
  body <- httr2::resp_body_string(resp)
  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(body, tmp, useBytes = TRUE)
  vector <- sf::st_read(tmp, quiet = TRUE)
  clip_vector_to_aoi(vector, aoi_geom, aoi_crs)
}

fetch_arcgis_raster <- function(layer, aoi_geom) {
  if (!localmap_network_allowed()) {
    if (!isTRUE(layer$offline)) {
      rlang::warn(
        sprintf(
          paste0(
            "Network access disabled; ArcGIS raster layer '%s' requires a fixture ",
            "or LOCALMAP_ALLOW_NETWORK=1."
          ),
          layer$id
        )
      )
    }
    layer$offline <- TRUE
  }
  if (isTRUE(layer$offline)) {
    fixture <- layer$fixture_path
    if (is.null(fixture) || !nzchar(fixture)) {
      rlang::abort(
        sprintf("ArcGIS raster layer '%s' offline without fixture.", layer$id),
        class = "analysis_raster_offline_missing_fixture"
      )
    }
    return(read_raster_layer(fixture))
  }

  arc_cfg <- list(
    url = layer$url,
    crs = analysis_default(layer$crs, "EPSG:3857"),
    width = as.integer(layer$width %||% 2048L),
    height = as.integer(layer$height %||% 2048L),
    format = layer$format %||% "png",
    dpi = as.integer(layer$dpi %||% 96L),
    transparent = layer$transparent,
    layers = layer$layers,
    layers_mode = layer$layers_mode
  )
  arc_cfg <- arc_cfg[!vapply(arc_cfg, is.null, logical(1))]
  query_info <- try(arcgis_build_query(arc_cfg, aoi_geom), silent = TRUE)
  if (inherits(query_info, "try-error")) {
    rlang::abort(
      sprintf("ArcGIS raster query failed for '%s'.", layer$id),
      class = "analysis_raster_query_failed"
    )
  }

  req <- httr2::request(query_info$url)
  resp <- try(
    httr2::req_url_query(req, !!!query_info$query) |> httr2::req_perform(),
    silent = TRUE
  )
  if (inherits(resp, "try-error")) {
    if (!is.null(layer$fixture_path) && nzchar(layer$fixture_path)) {
      rlang::warn(
        sprintf("ArcGIS raster fetch failed for '%s'; using fixture.", layer$id)
      )
      return(read_raster_layer(layer$fixture_path))
    }
    rlang::abort(
      sprintf("ArcGIS raster fetch failed for '%s'.", layer$id),
      class = "analysis_raster_fetch_failed"
    )
  }
  httr2::resp_check_status(resp)
  body <- httr2::resp_body_raw(resp)
  if (length(body) == 0L) {
    if (!is.null(layer$fixture_path) && nzchar(layer$fixture_path)) {
      rlang::warn(
        sprintf("ArcGIS raster response empty for '%s'; using fixture.", layer$id)
      )
      return(read_raster_layer(layer$fixture_path))
    }
    rlang::abort(
      sprintf("ArcGIS raster response empty for '%s'.", layer$id),
      class = "analysis_raster_empty_response"
    )
  }

  fmt <- tolower(as.character(query_info$query$format %||% "png"))
  ext <- if (grepl("png", fmt)) ".png" else ".tif"
  tmp <- tempfile(fileext = ext)
  on.exit(unlink(tmp), add = TRUE)
  writeBin(body, tmp)
  raster <- try(suppressWarnings(terra::rast(tmp)), silent = TRUE)
  if (inherits(raster, "try-error")) {
    if (!is.null(layer$fixture_path) && nzchar(layer$fixture_path)) {
      rlang::warn(
        sprintf("ArcGIS raster unreadable for '%s'; using fixture.", layer$id)
      )
      return(read_raster_layer(layer$fixture_path))
    }
    rlang::abort(
      sprintf("ArcGIS raster unreadable for '%s'.", layer$id),
      class = "analysis_raster_unreadable"
    )
  }
  nlyr <- terra::nlyr(raster)
  raster_vals <- terra::values(raster, mat = nlyr > 1L)
  raster_mem <- terra::rast(
    nrows = terra::nrow(raster),
    ncols = terra::ncol(raster),
    nlyr = nlyr,
    xmin = terra::xmin(raster),
    xmax = terra::xmax(raster),
    ymin = terra::ymin(raster),
    ymax = terra::ymax(raster),
    crs = terra::crs(raster)
  )
  raster <- terra::setValues(raster_mem, raster_vals)

  bbox <- sf::st_bbox(sf::st_transform(aoi_geom, sf::st_crs(arc_cfg$crs)))
  terra::ext(raster) <- terra::ext(
    as.numeric(bbox["xmin"]),
    as.numeric(bbox["xmax"]),
    as.numeric(bbox["ymin"]),
    as.numeric(bbox["ymax"])
  )
  terra::crs(raster) <- arc_cfg$crs

  raster <- normalize_arcgis_raster(raster, layer)
  raster
}

fetch_wcs_raster <- function(layer, aoi_geom, cache_dir = NULL) {
  if (!localmap_network_allowed()) {
    if (!isTRUE(layer$offline)) {
      rlang::warn(
        sprintf(
          paste0(
            "Network access disabled; WCS raster layer '%s' requires a fixture ",
            "or LOCALMAP_ALLOW_NETWORK=1."
          ),
          layer$id
        )
      )
    }
    layer$offline <- TRUE
  }
  if (isTRUE(layer$offline)) {
    fixture <- layer$fixture_path
    if (is.null(fixture) || !nzchar(fixture)) {
      rlang::abort(
        sprintf("WCS raster layer '%s' offline without fixture.", layer$id),
        class = "analysis_wcs_offline_missing_fixture"
      )
    }
    return(read_raster_layer(fixture))
  }

  coverage <- layer$coverage %||% layer$identifier
  version <- analysis_default(layer$version, "1.0.0")
  format <- analysis_default(layer$format, "GeoTIFF")
  crs <- analysis_default(layer$crs, "EPSG:4326")
  aoi_crs <- sf::st_crs(crs)
  bbox <- sf::st_bbox(sf::st_transform(aoi_geom, aoi_crs))
  bbox_param <- paste(
    c(
      as.numeric(bbox["xmin"]),
      as.numeric(bbox["ymin"]),
      as.numeric(bbox["xmax"]),
      as.numeric(bbox["ymax"])
    ),
    collapse = ","
  )
  resolution <- analysis_parse_wcs_resolution(layer$resolution)
  dims <- analysis_wcs_dimensions(
    bbox = bbox,
    resolution = resolution,
    width = layer$width,
    height = layer$height,
    max_dim = layer$max_dim
  )

  query <- list(
    service = "WCS",
    request = "GetCoverage",
    version = version,
    coverage = coverage,
    crs = crs,
    bbox = bbox_param,
    format = format,
    width = dims$width,
    height = dims$height
  )

  tmp <- tempfile(fileext = ".tif")
  req <- httr2::request(layer$url)
  req <- httr2::req_url_query(req, !!!query)
  resp <- try(httr2::req_perform(req, path = tmp), silent = TRUE)
  if (inherits(resp, "try-error")) {
    downloaded <- analysis_wcs_download_file(layer$url, query, tmp)
    if (!downloaded) {
      return(analysis_wcs_fallback(layer, aoi_geom, cache_dir, "request_failed"))
    }
  } else if (httr2::resp_status(resp) >= 400) {
    return(analysis_wcs_fallback(layer, aoi_geom, cache_dir, "http_error"))
  }

  raster <- try(terra::rast(tmp), silent = TRUE)
  if (inherits(raster, "try-error")) {
    return(analysis_wcs_fallback(layer, aoi_geom, cache_dir, "read_failed"))
  }
  raster
}

fetch_geodata_raster <- function(layer, aoi_geom, cache_dir = NULL) {
  if (!localmap_network_allowed()) {
    if (!isTRUE(layer$offline)) {
      rlang::warn(
        sprintf(
          paste0(
            "Network access disabled; geodata raster layer '%s' requires a fixture ",
            "or LOCALMAP_ALLOW_NETWORK=1."
          ),
          layer$id
        )
      )
    }
    layer$offline <- TRUE
  }
  if (isTRUE(layer$offline)) {
    fixture <- layer$fixture_path
    if (is.null(fixture) || !nzchar(fixture)) {
      rlang::abort(
        sprintf("Geodata raster layer '%s' offline without fixture.", layer$id),
        class = "analysis_geodata_offline_missing_fixture"
      )
    }
    return(read_raster_layer(fixture))
  }

  if (!requireNamespace("geodata", quietly = TRUE)) {
    rlang::abort(
      "Package 'geodata' is required for raster_geodata layers.",
      class = "analysis_geodata_missing_package"
    )
  }

  resolution <- analysis_default(layer$resolution, "3s")
  resolution <- tolower(as.character(resolution))
  if (!resolution %in% c("3s", "30s")) {
    rlang::abort(
      sprintf(
        "Geodata raster layer '%s' requires resolution '3s' or '30s'.",
        layer$id
      ),
      class = "analysis_geodata_resolution_invalid"
    )
  }

  if (is.null(cache_dir) || !nzchar(cache_dir)) {
    cache_dir <- here::here("data", "cache", "geodata")
  }
  cache_dir <- analysis_normalize_path(layer$geodata_path %||% cache_dir, cache_dir)
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  aoi_4326 <- sf::st_transform(aoi_geom, 4326)
  centroid <- sf::st_coordinates(sf::st_centroid(aoi_4326))[1, ]
  lon <- centroid[1]
  lat <- centroid[2]

  if (identical(resolution, "3s")) {
    geodata::elevation_3s(lon, lat, path = cache_dir)
  } else {
    geodata::elevation_30s(lon, lat, path = cache_dir)
  }
}

analysis_parse_wcs_resolution <- function(resolution) {
  if (is.null(resolution)) {
    return(NA_real_)
  }
  if (is.numeric(resolution)) {
    return(as.numeric(resolution)[1])
  }
  resolution <- tolower(trimws(as.character(resolution)))
  if (!nzchar(resolution)) {
    return(NA_real_)
  }
  if (grepl("s$", resolution)) {
    val <- suppressWarnings(as.numeric(sub("s$", "", resolution)))
    if (is.finite(val)) {
      return(val / 3600)
    }
  }
  suppressWarnings(as.numeric(resolution))
}

analysis_wcs_dimensions <- function(bbox, resolution, width, height, max_dim) {
  if (!is.null(width) && !is.null(height)) {
    return(list(width = as.integer(width), height = as.integer(height)))
  }
  if (!is.finite(resolution) || resolution <= 0) {
    return(list(width = as.integer(width %||% 256L), height = as.integer(height %||% 256L)))
  }
  span_x <- as.numeric(bbox["xmax"]) - as.numeric(bbox["xmin"])
  span_y <- as.numeric(bbox["ymax"]) - as.numeric(bbox["ymin"])
  width_calc <- max(1L, as.integer(ceiling(span_x / resolution)))
  height_calc <- max(1L, as.integer(ceiling(span_y / resolution)))
  max_dim <- as.integer(max_dim %||% 4096L)
  if (is.finite(max_dim) && max_dim > 0) {
    width_calc <- min(width_calc, max_dim)
    height_calc <- min(height_calc, max_dim)
  }
  list(width = width_calc, height = height_calc)
}

analysis_wcs_download_file <- function(base_url, query, dest_path) {
  if (is.null(base_url) || !nzchar(base_url)) {
    return(FALSE)
  }
  url <- try(httr2::url_parse(base_url), silent = TRUE)
  if (inherits(url, "try-error")) {
    return(FALSE)
  }
  url$query <- query
  full_url <- try(httr2::url_build(url), silent = TRUE)
  if (inherits(full_url, "try-error")) {
    return(FALSE)
  }
  res <- try(utils::download.file(full_url, dest_path, mode = "wb", quiet = TRUE), silent = TRUE)
  if (inherits(res, "try-error")) {
    return(FALSE)
  }
  file.exists(dest_path) && file.info(dest_path)$size > 0
}

analysis_wcs_fallback <- function(layer, aoi_geom, cache_dir, reason = NULL) {
  fallback <- layer$fallback
  if (is.null(fallback) || !is.list(fallback)) {
    rlang::abort(
      sprintf("WCS raster layer '%s' failed without fallback.", layer$id),
      class = "analysis_wcs_missing_fallback"
    )
  }
  fb_type <- tolower(as.character(fallback$type %||% "raster_geodata"))
  fb_layer <- list(
    id = layer$id,
    type = fb_type,
    resolution = analysis_default(fallback$resolution, "3s"),
    geodata_path = fallback$geodata_path,
    path = fallback$path,
    url = fallback$url,
    crs = fallback$crs,
    categorical = layer$categorical,
    resample = layer$resample,
    offline = analysis_default(fallback$offline, FALSE),
    fixture_path = fallback$fixture_path %||% layer$fixture_path,
    attribution = layer$attribution
  )

  if (identical(fb_type, "raster_geodata")) {
    raster <- fetch_geodata_raster(fb_layer, aoi_geom, cache_dir = cache_dir)
    fb_source <- sprintf("geodata (SRTM %s)", analysis_default(fb_layer$resolution, "3s"))
  } else if (identical(fb_type, "raster_file")) {
    if (is.null(fb_layer$path) || !nzchar(fb_layer$path)) {
      rlang::abort(
        sprintf("WCS fallback for '%s' missing `fallback$path`.", layer$id),
        class = "analysis_wcs_fallback_missing_path"
      )
    }
    raster <- read_raster_layer(fb_layer$path)
    fb_source <- "raster_file"
  } else if (identical(fb_type, "raster_arcgis")) {
    raster <- fetch_arcgis_raster(fb_layer, aoi_geom)
    fb_source <- "ArcGIS raster"
  } else {
    rlang::abort(
      sprintf("Unsupported WCS fallback type '%s' for '%s'.", fb_type, layer$id),
      class = "analysis_wcs_fallback_invalid_type"
    )
  }

  list(
    raster = raster,
    meta = list(
      status = "fallback",
      source = fb_source,
      params = list(
        fallback_type = fb_type,
        fallback_reason = reason %||% ""
      )
    )
  )
}

normalize_arcgis_raster <- function(raster, layer) {
  nlyr <- terra::nlyr(raster)
  if (nlyr <= 1L) {
    names(raster) <- layer$id
    return(raster)
  }

  band <- layer$band
  if (!is.null(band)) {
    band <- as.integer(band)
    if (!is.finite(band) || band < 1 || band > nlyr) {
      rlang::abort(
        sprintf("ArcGIS raster layer '%s' band %s is out of range.", layer$id, band),
        class = "analysis_raster_band_invalid"
      )
    }
    raster <- raster[[band]]
    names(raster) <- layer$id
    return(raster)
  }

  if (nlyr >= 3L) {
    rlang::warn(
      sprintf(
        "ArcGIS raster layer '%s' returned multiple bands; averaging RGB channels.",
        layer$id
      )
    )
    raster <- terra::app(raster[[1:3]], mean, na.rm = TRUE)
  } else {
    rlang::warn(
      sprintf(
        "ArcGIS raster layer '%s' returned multiple bands; using the first band.",
        layer$id
      )
    )
    raster <- raster[[1]]
  }
  names(raster) <- layer$id
  raster
}

read_raster_layer <- function(path) {
  path <- analysis_normalize_path(path, path)
  if (!file.exists(path)) {
    rlang::abort(
      sprintf("Raster layer not found: %s", path),
      class = "analysis_raster_missing_file"
    )
  }
  terra::rast(path)
}

clip_raster_to_aoi <- function(raster,
                               aoi_geom,
                               analysis_crs,
                               categorical = FALSE,
                               resample = NULL) {
  if (is.null(resample) || !nzchar(resample)) {
    resample <- if (isTRUE(categorical)) "near" else "bilinear"
  }
  resample <- tolower(as.character(resample))
  if (!resample %in% c("near", "bilinear", "cubic")) {
    rlang::abort(
      "Raster resample must be near/bilinear/cubic.",
      class = "analysis_raster_resample_invalid"
    )
  }

  target_crs <- analysis_crs
  if (!is.null(terra::crs(raster)) && !identical(terra::crs(raster), target_crs)) {
    raster <- terra::project(raster, target_crs, method = resample)
  }
  aoi_vect <- terra::vect(sf::st_transform(aoi_geom, sf::st_crs(target_crs)))
  cropped <- terra::crop(raster, aoi_vect, snap = "out")
  terra::mask(cropped, aoi_vect)
}

compute_index <- function(raster, band_a, band_b) {
  if (!is.finite(band_a) || !is.finite(band_b)) {
    rlang::abort("Index bands must be numeric.", class = "analysis_index_invalid_bands")
  }
  band_a <- as.integer(band_a)
  band_b <- as.integer(band_b)
  if (terra::nlyr(raster) < max(band_a, band_b)) {
    rlang::abort(
      "Index bands exceed available raster layers.",
      class = "analysis_index_missing_band"
    )
  }
  a <- raster[[band_a]]
  b <- raster[[band_b]]
  denom <- a + b
  idx <- (a - b) / denom
  idx[denom == 0] <- NA
  idx
}

rtrim_slash <- function(path) {
  sub("/+$", "", path)
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
