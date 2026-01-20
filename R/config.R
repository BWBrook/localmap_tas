#' Read project configuration
#'
#' Reads `config/config.yaml` using the active config profile (defaults to
#' `Sys.getenv("R_CONFIG_ACTIVE", "default")`). Returns a named list.
#'
#' @param profile Character scalar. Config profile name.
#' @param config_path Optional path to the YAML file. Defaults to
#'   `here::here("config", "config.yaml")`.
#' @return A named list with configuration values.
#' @export
cfg_read <- function(profile = Sys.getenv("R_CONFIG_ACTIVE", "default"),
                     config_path = NULL) {
  if (is.null(config_path)) {
    installed <- system.file("config", "config.yaml", package = "localmap")
    if (nzchar(installed) && file.exists(installed)) {
      config_path <- installed
    } else {
      config_path <- here::here("config", "config.yaml")
    }
  }
  path <- config_path
  if (!file.exists(path)) {
    rlang::abort(
      c(
        "Configuration file not found.",
        i = sprintf("Expected at: %s", path)
      ),
      class = "cfg_read_missing_config"
    )
  }

  cfg <- config::get(file = path, config = profile)
  if (!is.list(cfg)) {
    rlang::abort("Config must resolve to a list.", class = "cfg_read_invalid_config")
  }
  cfg <- cfg_migrate(cfg, config_path = path)
  cfg_validate(cfg, config_path = path)
  cfg <- cfg_apply_dem_variant(cfg)
  cfg
}

cfg_migrate <- function(cfg, config_path = NULL) {
  checkmate::assert_list(cfg, any.missing = FALSE)
  schema_version <- cfg$schema_version
  if (is.null(schema_version)) {
    config_note <- NULL
    if (!is.null(config_path)) {
      config_note <- sprintf("Config file: %s", config_path)
    }
    rlang::abort(
      c(
        "`schema_version` is required in the config profile.",
        i = "Add `schema_version: 2` under the profile root.",
        if (!is.null(config_note)) config_note else NULL
      ),
      class = "cfg_schema_missing"
    )
  }

  schema_version <- as.integer(schema_version)
  if (identical(schema_version, 1L)) {
    cfg <- cfg_migrate_v1_to_v2(cfg)
    schema_version <- as.integer(cfg$schema_version)
  }

  if (!identical(schema_version, 2L)) {
    rlang::abort(
      c(
        "Unsupported config schema_version.",
        i = sprintf("Expected schema_version 2, got %s.", cfg$schema_version)
      ),
      class = "cfg_schema_unsupported"
    )
  }

  cfg
}

cfg_migrate_v1_to_v2 <- function(cfg) {
  if (is.null(cfg$data)) {
    rlang::abort(
      "`data` must be present for schema migration.",
      class = "cfg_schema_migrate_missing"
    )
  }
  if (is.null(cfg$data$aoi)) {
    bbox <- cfg$data$occurrence$map$bounding_box
    if (is.null(bbox) || is.null(bbox$top_left) || is.null(bbox$length_km)) {
      rlang::abort(
        "Cannot migrate config without a bounding box to derive AOI.",
        class = "cfg_schema_migrate_missing_bbox"
      )
    }
    top_left <- coerce_top_left(bbox$top_left)
    side_length <- as.numeric(bbox$length_km)
    half_m <- side_length * 1000 / 2
    mid_east <- geosphere::destPoint(c(top_left[["lon"]], top_left[["lat"]]), b = 90, d = half_m)
    centre <- geosphere::destPoint(mid_east, b = 180, d = half_m)
    cfg$data$aoi <- list(
      centroid = list(lat = as.numeric(centre[1, 2]), lon = as.numeric(centre[1, 1])),
      size_km = side_length,
      rotation_deg = 0,
      crs = "EPSG:28355"
    )
  }
  cfg$schema_version <- 2L
  cfg
}

cfg_validate <- function(cfg, config_path = NULL, expected_schema_version = 2L) {
  checkmate::assert_list(cfg, any.missing = FALSE)
  schema_version <- cfg$schema_version
  if (is.null(schema_version)) {
    config_note <- NULL
    if (!is.null(config_path)) {
      config_note <- sprintf("Config file: %s", config_path)
    }
    rlang::abort(
      c(
        "`schema_version` is required in the config profile.",
        i = sprintf("Add `schema_version: %d` under the profile root.", expected_schema_version),
        if (!is.null(config_note)) config_note else NULL
      ),
      class = "cfg_schema_missing"
    )
  }
  checkmate::assert_integerish(schema_version, len = 1L, any.missing = FALSE)
  if (!identical(as.integer(schema_version), as.integer(expected_schema_version))) {
    rlang::abort(
      c(
        "Unsupported config schema_version.",
        i = sprintf("Expected schema_version %d, got %s.", expected_schema_version, schema_version)
      ),
      class = "cfg_schema_unsupported"
    )
  }

  data_cfg <- cfg$data
  if (is.null(data_cfg) || !is.list(data_cfg)) {
    rlang::abort("`data` must be a list in the config.", class = "cfg_data_missing")
  }

  aoi_cfg <- data_cfg$aoi
  if (is.null(aoi_cfg) || !is.list(aoi_cfg)) {
    rlang::abort("`data$aoi` must be a list in the config.", class = "cfg_aoi_missing")
  }
  mode <- aoi_cfg$mode
  if (is.null(mode)) {
    if (is.null(aoi_cfg$size_km) &&
          (is.null(aoi_cfg$width_km) || is.null(aoi_cfg$height_km))) {
      mode <- "auto"
    } else {
      mode <- "fixed"
    }
  }
  checkmate::assert_string(mode, min.chars = 1L)
  mode <- tolower(mode)
  if (!mode %in% c("fixed", "auto")) {
    rlang::abort(
      sprintf("Unsupported AOI mode '%s'.", mode),
      class = "cfg_aoi_mode_invalid"
    )
  }

  if (identical(mode, "fixed")) {
    if (!is.null(aoi_cfg$centroid_site)) {
      checkmate::assert_string(aoi_cfg$centroid_site, min.chars = 1L)
    } else {
      centroid <- aoi_cfg$centroid
      if (is.null(centroid) || !is.list(centroid) || !all(c("lat", "lon") %in% names(centroid))) {
        rlang::abort(
          "`data$aoi$centroid` must include lat/lon when centroid_site is not set.",
          class = "cfg_aoi_centroid_missing"
        )
      }
      checkmate::assert_numeric(as.numeric(centroid$lat), len = 1L, any.missing = FALSE)
      checkmate::assert_numeric(as.numeric(centroid$lon), len = 1L, any.missing = FALSE)
    }
    if (!is.null(aoi_cfg$size_km)) {
      checkmate::assert_numeric(aoi_cfg$size_km, len = 1L, lower = 1e-6, any.missing = FALSE)
    } else {
      checkmate::assert_numeric(aoi_cfg$width_km, len = 1L, lower = 1e-6, any.missing = FALSE)
      checkmate::assert_numeric(aoi_cfg$height_km, len = 1L, lower = 1e-6, any.missing = FALSE)
    }
  } else {
    if (!is.null(aoi_cfg$buffer_km)) {
      checkmate::assert_numeric(aoi_cfg$buffer_km, len = 1L, lower = 0, any.missing = FALSE)
    }
    if (!is.null(aoi_cfg$buffer_multiplier)) {
      checkmate::assert_numeric(aoi_cfg$buffer_multiplier, len = 1L, lower = 0, any.missing = FALSE)
    }
    if (!is.null(aoi_cfg$min_buffer_km)) {
      checkmate::assert_numeric(aoi_cfg$min_buffer_km, len = 1L, lower = 0, any.missing = FALSE)
    }
    if (!is.null(aoi_cfg$max_buffer_km)) {
      checkmate::assert_numeric(aoi_cfg$max_buffer_km, len = 1L, lower = 0, any.missing = FALSE)
    }
  }
  if (!is.null(aoi_cfg$rotation_deg)) {
    checkmate::assert_numeric(aoi_cfg$rotation_deg, len = 1L, any.missing = FALSE)
  }
  if (!is.null(aoi_cfg$crs)) {
    checkmate::assert_string(aoi_cfg$crs, min.chars = 1L)
  }

  dem_variant <- data_cfg$dem_variant
  if (!is.null(dem_variant) && nzchar(dem_variant)) {
    dem_variant <- tolower(as.character(dem_variant))
    allowed <- c("ga_1s", "ga_1s_hydro", "srtm_3s", "srtm_30s", "elvis_2m")
    if (!dem_variant %in% allowed) {
      rlang::abort(
        sprintf("Unsupported `data$dem_variant` '%s'.", dem_variant),
        class = "cfg_dem_variant_invalid"
      )
    }
    if (dem_variant %in% c("elvis_2m")) {
      if (is.null(data_cfg$dem_variant_path) || !nzchar(data_cfg$dem_variant_path)) {
        rlang::abort(
          "`data$dem_variant_path` is required when dem_variant is elvis_2m.",
          class = "cfg_dem_variant_path_missing"
        )
      }
    }
  }

  cfg_require_string <- function(value, label, hint = NULL) {
    if (!checkmate::test_string(value, min.chars = 1L)) {
      rlang::abort(
        c(
          sprintf("`%s` is required in the config.", label),
          if (!is.null(hint)) hint else NULL
        ),
        class = "cfg_required_missing"
      )
    }
  }

  cfg_require_string(
    data_cfg$manifest,
    "data$manifest",
    "Point to a CSV manifest (e.g., metadata/data_manifest.csv)."
  )
  cfg_require_string(
    data_cfg$species_requests,
    "data$species_requests",
    "Point to a species request CSV (e.g., metadata/species_requests.csv)."
  )

  occ_cfg <- data_cfg$occurrence
  if (is.null(occ_cfg) || !is.list(occ_cfg)) {
    rlang::abort(
      "`data$occurrence` must be a list in the config.",
      class = "cfg_occurrence_missing"
    )
  }

  if (!is.null(occ_cfg$min_year)) {
    checkmate::assert_numeric(occ_cfg$min_year, len = 1L, any.missing = FALSE)
  }
  if (!is.null(occ_cfg$min_lat)) {
    checkmate::assert_numeric(occ_cfg$min_lat, len = 1L, any.missing = FALSE)
  }
  if (!is.null(occ_cfg$state_province)) {
    checkmate::assert_string(occ_cfg$state_province, min.chars = 1L)
  }
  if (!is.null(occ_cfg$fields)) {
    checkmate::assert_character(occ_cfg$fields, min.len = 1L, any.missing = FALSE)
  } else {
    rlang::abort(
      c(
        "`data$occurrence$fields` is required in the config.",
        i = "Provide a character vector of ALA occurrence fields."
      ),
      class = "cfg_occurrence_fields_missing"
    )
  }

  occ_map <- occ_cfg$map
  if (is.null(occ_map) || !is.list(occ_map)) {
    rlang::abort(
      "`data$occurrence$map` must be a list in the config.",
      class = "cfg_occurrence_map_missing"
    )
  }
  bbox <- occ_map$bounding_box
  if (!is.null(bbox)) {
    if (!is.list(bbox)) {
      rlang::abort(
        "`data$occurrence$map$bounding_box` must be a list if provided.",
        class = "cfg_occurrence_bbox_invalid"
      )
    }
    top_left <- bbox$top_left
    if (is.null(top_left) || !is.list(top_left) || !all(c("lat", "lon") %in% names(top_left))) {
      rlang::abort(
        "`data$occurrence$map$bounding_box$top_left` must be a list with lat/lon.",
        class = "cfg_occurrence_bbox_top_left_missing"
      )
    }
    checkmate::assert_numeric(as.numeric(top_left$lat), len = 1L, any.missing = FALSE)
    checkmate::assert_numeric(as.numeric(top_left$lon), len = 1L, any.missing = FALSE)
    checkmate::assert_numeric(bbox$length_km, len = 1L, lower = 0, any.missing = FALSE)
  }

  camera_cfg <- data_cfg$camera_sites
  if (is.null(camera_cfg) || !is.list(camera_cfg)) {
    rlang::abort(
      "`data$camera_sites` must be a list in the config.",
      class = "cfg_camera_sites_missing"
    )
  }
  source_type <- camera_cfg$source
  if (is.null(source_type)) {
    source_type <- "file"
  }
  checkmate::assert_string(source_type, min.chars = 1L)
  if (!source_type %in% c("file", "jc")) {
    rlang::abort(
      sprintf("Unsupported camera_sites source '%s'.", source_type),
      class = "cfg_camera_sites_source_invalid"
    )
  }
  if (identical(source_type, "jc")) {
    jc_cfg <- camera_cfg$jc
    if (is.null(jc_cfg) || !is.list(jc_cfg)) {
      rlang::abort(
        "`data$camera_sites$jc` must be provided for source=jc.",
        class = "cfg_camera_sites_jc_missing"
      )
    }
    cfg_require_string(jc_cfg$site_path, "data$camera_sites$jc$site_path")
    if (!is.null(jc_cfg$obs_path)) {
      cfg_require_string(jc_cfg$obs_path, "data$camera_sites$jc$obs_path")
    }
    if (!is.null(jc_cfg$op_path)) {
      cfg_require_string(jc_cfg$op_path, "data$camera_sites$jc$op_path")
    }
  } else {
    cfg_require_string(camera_cfg$path, "data$camera_sites$path")
  }

  coverage_cfg <- data_cfg$coverage
  if (!is.null(coverage_cfg)) {
    if (!is.list(coverage_cfg)) {
      rlang::abort(
        "`data$coverage` must be a list if provided.",
        class = "cfg_coverage_invalid"
      )
    }
    if (!is.null(coverage_cfg$enabled)) {
      checkmate::assert_logical(coverage_cfg$enabled, len = 1L, any.missing = FALSE)
    }
    if (!is.null(coverage_cfg$buffer_m)) {
      checkmate::assert_numeric(coverage_cfg$buffer_m, len = 1L, lower = 0, any.missing = FALSE)
    }
    if (!is.null(coverage_cfg$site_ids)) {
      checkmate::assert_character(
        as.character(unlist(coverage_cfg$site_ids, use.names = FALSE)),
        min.len = 1L,
        any.missing = FALSE
      )
    }
    if (!is.null(coverage_cfg$summary_path)) {
      checkmate::assert_string(coverage_cfg$summary_path, min.chars = 1L)
    }
  }

  layers_cfg <- data_cfg$layers
  if (!is.null(layers_cfg)) {
    validate_layer_registry(layers_cfg)
  }

  analysis_layers_cfg <- data_cfg$analysis_layers
  if (!is.null(analysis_layers_cfg)) {
    if (!is.list(analysis_layers_cfg)) {
      rlang::abort(
        "`data$analysis_layers` must be a list if provided.",
        class = "cfg_analysis_layers_invalid"
      )
    }
    validate_analysis_layers(analysis_layers_cfg)
  }

  attributes_cfg <- data_cfg$attributes
  if (!is.null(attributes_cfg)) {
    if (!is.list(attributes_cfg)) {
      rlang::abort(
        "`data$attributes` must be a list if provided.",
        class = "cfg_attributes_invalid"
      )
    }
    if (!is.null(attributes_cfg$enabled)) {
      checkmate::assert_logical(attributes_cfg$enabled, len = 1L, any.missing = FALSE)
    }
    if (!is.null(attributes_cfg$output_long)) {
      checkmate::assert_string(attributes_cfg$output_long, min.chars = 1L)
    }
    if (!is.null(attributes_cfg$output_wide)) {
      checkmate::assert_string(attributes_cfg$output_wide, min.chars = 1L)
    }
  }

  overview_cfg <- data_cfg$overview_map
  if (!is.null(overview_cfg)) {
    if (!is.list(overview_cfg)) {
      rlang::abort(
        "`data$overview_map` must be a list if provided.",
        class = "cfg_overview_map_invalid"
      )
    }
    if (!is.null(overview_cfg$output_path)) {
      checkmate::assert_string(overview_cfg$output_path, min.chars = 1L)
    }
    if (!is.null(overview_cfg$base_layer_id)) {
      checkmate::assert_string(overview_cfg$base_layer_id, min.chars = 1L)
    }
    if (!is.null(overview_cfg$overlays)) {
      checkmate::assert_list(overview_cfg$overlays, any.missing = FALSE)
    }
  }

  panel_cfg <- data_cfg$panel_figure
  if (!is.null(panel_cfg)) {
    if (!is.list(panel_cfg)) {
      rlang::abort(
        "`data$panel_figure` must be a list if provided.",
        class = "cfg_panel_figure_invalid"
      )
    }
    if (!is.null(panel_cfg$paths)) {
      checkmate::assert_character(
        as.character(unlist(panel_cfg$paths, use.names = FALSE)),
        min.len = 1L,
        any.missing = FALSE
      )
    }
    if (!is.null(panel_cfg$output_path)) {
      checkmate::assert_string(panel_cfg$output_path, min.chars = 1L)
    }
  }
  cfg_require_string(camera_cfg$central_site, "data$camera_sites$central_site")
  checkmate::assert_numeric(camera_cfg$bbox_half_km, len = 1L, lower = 0, any.missing = FALSE)

  if (!is.null(camera_cfg$basemap)) {
    checkmate::assert_list(camera_cfg$basemap, any.missing = FALSE)
  }
  if (!is.null(camera_cfg$map)) {
    checkmate::assert_list(camera_cfg$map, any.missing = FALSE)
    if (!is.null(camera_cfg$map$output_path)) {
      checkmate::assert_string(camera_cfg$map$output_path, min.chars = 1L)
    }
  }
  if (!is.null(camera_cfg$stack)) {
    checkmate::assert_list(camera_cfg$stack, any.missing = FALSE)
    if (!is.null(camera_cfg$stack$output_path)) {
      checkmate::assert_string(camera_cfg$stack$output_path, min.chars = 1L)
    }
  }

  ala_cfg <- cfg$ala
  if (is.null(ala_cfg) || !is.list(ala_cfg)) {
    rlang::abort("`ala` must be a list in the config.", class = "cfg_ala_missing")
  }
  use_fixture <- isTRUE(ala_cfg$use_fixture)
  if (use_fixture) {
    checkmate::assert_string(ala_cfg$fixture_occurrences, min.chars = 1L)
  } else {
    email <- ala_cfg$email
    if (!checkmate::test_string(email, min.chars = 1L)) {
      email <- Sys.getenv("ALA_EMAIL", unset = "")
    }
    if (!checkmate::test_string(email, min.chars = 1L)) {
      rlang::abort(
        c(
          "ALA email is required when not using fixtures.",
          i = "Set `ala$email` in config or `ALA_EMAIL` in the environment."
        ),
        class = "cfg_ala_email_missing"
      )
    }
  }
  if (!is.null(ala_cfg$download_reason_id)) {
    checkmate::assert_integerish(ala_cfg$download_reason_id, lower = 1L, len = 1L)
  }

  cfg
}

cfg_apply_dem_variant <- function(cfg) {
  data_cfg <- cfg$data
  if (is.null(data_cfg) || !is.list(data_cfg)) {
    return(cfg)
  }
  variant <- data_cfg$dem_variant
  if (is.null(variant) || !nzchar(variant)) {
    return(cfg)
  }
  variant <- tolower(as.character(variant))
  if (is.null(data_cfg$analysis_layers) || !is.list(data_cfg$analysis_layers)) {
    return(cfg)
  }

  dem_path <- data_cfg$dem_variant_path
  dem_attr_override <- data_cfg$dem_variant_attribution

  updated_layers <- lapply(data_cfg$analysis_layers, function(layer) {
    if (is.null(layer$id) || !grepl("_dem$", layer$id)) {
      return(layer)
    }

    base <- list(
      id = layer$id,
      output_path = layer$output_path,
      categorical = layer$categorical %||% FALSE,
      units = layer$units %||% "m",
      offline = layer$offline,
      fixture_path = layer$fixture_path,
      resample = layer$resample
    )

    variant_cfg <- resolve_dem_variant_config(variant, dem_path, dem_attr_override)
    utils::modifyList(base, variant_cfg, keep.null = TRUE)
  })

  cfg$data$analysis_layers <- updated_layers
  cfg
}

resolve_dem_variant_config <- function(variant, dem_path, dem_attr_override) {
  variant <- tolower(as.character(variant))
  if (identical(variant, "ga_1s")) {
    return(list(
      type = "raster_wcs",
      url = "https://services.ga.gov.au/gis/services/DEM_SRTM_1Second_2024/MapServer/WCSServer",
      coverage = "1",
      version = "1.0.0",
      crs = "EPSG:4326",
      format = "GeoTIFF",
      resolution = "1s",
      fallback = list(type = "raster_geodata", resolution = "3s"),
      attribution = list(
        source = "Geoscience Australia",
        license = "CC BY 4.0",
        credit = "DEM SRTM 1 Second 2024"
      )
    ))
  }

  if (identical(variant, "ga_1s_hydro")) {
    return(list(
      type = "raster_wcs",
      url = paste0(
        "https://services.ga.gov.au/gis/services/",
        "DEM_SRTM_1Second_Hydro_Enforced_2024/MapServer/WCSServer"
      ),
      coverage = "1",
      version = "1.0.0",
      crs = "EPSG:4326",
      format = "GeoTIFF",
      resolution = "1s",
      fallback = list(type = "raster_geodata", resolution = "3s"),
      attribution = list(
        source = "Geoscience Australia",
        license = "CC BY 4.0",
        credit = "DEM SRTM 1 Second Hydro Enforced 2024"
      )
    ))
  }

  if (identical(variant, "srtm_3s")) {
    return(list(
      type = "raster_geodata",
      resolution = "3s",
      attribution = list(
        source = "geodata (SRTM)",
        license = "CC0 1.0",
        credit = "SRTM 3 arc-second elevation"
      )
    ))
  }

  if (identical(variant, "srtm_30s")) {
    return(list(
      type = "raster_geodata",
      resolution = "30s",
      attribution = list(
        source = "geodata (SRTM)",
        license = "CC0 1.0",
        credit = "SRTM 30 arc-second elevation"
      )
    ))
  }

  if (identical(variant, "elvis_2m")) {
    attr <- dem_attr_override
    if (is.null(attr) || !is.list(attr)) {
      attr <- list(source = "ELVIS (user supplied)", license = "", credit = "2m DEM")
    }
    return(list(
      type = "raster_file",
      path = dem_path,
      attribution = attr
    ))
  }

  list()
}
