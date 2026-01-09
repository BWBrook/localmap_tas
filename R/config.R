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
  cfg_validate(cfg, config_path = path)
  cfg
}

cfg_validate <- function(cfg, config_path = NULL, expected_schema_version = 1L) {
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
  if (is.null(bbox) || !is.list(bbox)) {
    rlang::abort(
      c(
        "`data$occurrence$map$bounding_box` is required in the config.",
        i = "Provide top_left (lat/lon) and length_km."
      ),
      class = "cfg_occurrence_bbox_missing"
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

  camera_cfg <- data_cfg$camera_sites
  if (is.null(camera_cfg) || !is.list(camera_cfg)) {
    rlang::abort(
      "`data$camera_sites` must be a list in the config.",
      class = "cfg_camera_sites_missing"
    )
  }
  cfg_require_string(camera_cfg$path, "data$camera_sites$path")
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
