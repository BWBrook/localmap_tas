# Internal config loading and materialisation helpers.

cfg_resolve_path <- function(config_path = NULL) {
  if (!is.null(config_path)) {
    return(config_path)
  }

  local_path <- here::here("config", "config.yaml")
  if (file.exists(local_path)) {
    return(local_path)
  }

  installed <- system.file("config", "config.yaml", package = "localmap")
  if (nzchar(installed) && file.exists(installed)) {
    return(installed)
  }

  local_path
}

cfg_load_profile <- function(profile, config_path) {
  path <- cfg_resolve_path(config_path)
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

  structure(
    list(cfg = cfg, path = path),
    class = "localmap_config_load"
  )
}

cfg_resolve <- function(cfg) {
  cfg <- cfg_apply_dem_variant(cfg)
  cfg <- cfg_apply_output_dir(cfg)
  cfg <- cfg_resolve_attribute_mode(cfg)
  cfg <- cfg_resolve_buffered_attribute_aoi(cfg)
  cfg
}

cfg_resolve_attribute_mode <- function(cfg) {
  attributes_cfg <- cfg$data$attributes
  if (is.null(attributes_cfg) || !is.list(attributes_cfg)) {
    return(cfg)
  }
  radius_m <- attributes_cfg$radius_m %||% 0
  cfg$data$attributes$extraction_mode <- if (radius_m > 0) "buffered" else "exact_point"
  cfg
}

cfg_resolve_buffered_attribute_aoi <- function(cfg) {
  radius_m <- cfg$data$attributes$radius_m %||% 0
  if (radius_m == 0) {
    return(cfg)
  }

  aoi_cfg <- cfg$data$aoi
  mode <- resolve_aoi_mode(aoi_cfg)
  rotation_deg <- aoi_cfg$rotation_deg %||% 0
  if (!identical(mode, "auto") || rotation_deg != 0) {
    rlang::abort(
      c(
        "Buffered attributes require an unrotated auto AOI.",
        i = sprintf("Configured AOI mode is '%s' with rotation_deg %s.", mode, rotation_deg),
        i = "Set `data$aoi$mode: auto` and `rotation_deg: 0` so complete site buffers are acquired."
      ),
      class = "cfg_attributes_buffer_aoi_unsupported"
    )
  }

  margin_km <- radius_m / 1000
  aoi_cfg$mode <- "auto"
  if (!is.null(aoi_cfg$buffer_km)) {
    aoi_cfg$buffer_km <- max(aoi_cfg$buffer_km, margin_km)
  } else {
    aoi_cfg$min_buffer_km <- max(aoi_cfg$min_buffer_km %||% 0.25, margin_km)
    if (!is.null(aoi_cfg$max_buffer_km)) {
      aoi_cfg$max_buffer_km <- max(aoi_cfg$max_buffer_km, margin_km)
    }
  }
  cfg$data$aoi <- aoi_cfg
  cfg
}
