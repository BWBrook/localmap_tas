#' Read simplified settings file
#'
#' @param settings_path Path to the settings YAML.
#' @param profile Profile name in the YAML (defaults to "settings").
#' @return List of settings.
#' @keywords internal
read_settings_file <- function(settings_path, profile = "settings") {
  checkmate::assert_file_exists(settings_path)
  checkmate::assert_string(profile, min.chars = 1L)
  settings <- yaml::read_yaml(settings_path)
  if (is.null(settings) || !is.list(settings)) {
    rlang::abort(
      "Settings file must be a YAML mapping.",
      class = "settings_read_failed"
    )
  }
  if (!is.null(settings[[profile]]) && is.list(settings[[profile]])) {
    return(settings[[profile]])
  }
  settings
}

resolve_settings_project <- function(settings, input_dir = NULL) {
  project <- settings$project
  if (is.null(project) || !nzchar(project)) {
    if (!is.null(input_dir) && nzchar(input_dir)) {
      project <- basename(normalizePath(input_dir, winslash = "/", mustWork = FALSE))
    } else {
      project <- "project"
    }
  }
  project
}

normalize_include_list <- function(value) {
  if (is.null(value)) {
    return(NULL)
  }
  if (is.character(value)) {
    return(as.character(value))
  }
  if (is.list(value) && !is.null(value$include)) {
    return(as.character(value$include))
  }
  NULL
}

filter_layers_by_ids <- function(layers, include_ids) {
  if (is.null(layers) || is.null(include_ids)) {
    return(layers)
  }
  keep <- vapply(layers, function(layer) {
    !is.null(layer$id) && layer$id %in% include_ids
  }, logical(1))
  layers[keep]
}

filter_analysis_layers <- function(layers, include_keys) {
  if (is.null(layers) || is.null(include_keys)) {
    return(layers)
  }
  include_keys <- tolower(as.character(include_keys))
  key_map <- list(
    dem = "dem",
    slope = "slope",
    canopy_height = "chm",
    chm = "chm",
    ndvi = "ndvi",
    nbr = "nbr",
    multiband = "multiband",
    tasveg = "tasveg",
    tasveg_class = "tasveg_class",
    fire = "fire_attributes",
    fire_attributes = "fire_attributes",
    geology = "geology",
    land_tenure = "land_tenure",
    reserve_estate = "reserve_estate",
    soil_ph = "soil_ph",
    climate = c("bio1", "bio12"),
    bio1 = "bio1",
    bio12 = "bio12"
  )
  include_suffixes <- unique(unlist(key_map[include_keys], use.names = FALSE))
  if (length(include_suffixes) == 0L) {
    return(list())
  }
  if (any(include_suffixes %in% c("ndvi", "nbr"))) {
    include_suffixes <- unique(c(include_suffixes, "multiband"))
  }
  if ("slope" %in% include_suffixes) {
    include_suffixes <- unique(c(include_suffixes, "dem"))
  }
  if ("tasveg" %in% include_suffixes) {
    include_suffixes <- unique(c(include_suffixes, "tasveg_class"))
  }

  keep <- vapply(layers, function(layer) {
    if (is.null(layer$id)) return(FALSE)
    suffix <- sub("^[^_]+_", "", layer$id)
    suffix %in% include_suffixes
  }, logical(1))
  layers[keep]
}

rewrite_output_paths <- function(value, output_dir) {
  if (is.list(value)) {
    return(lapply(value, rewrite_output_paths, output_dir = output_dir))
  }
  if (!is.character(value)) {
    return(value)
  }
  unname(vapply(value, function(path) {
    if (!nzchar(path)) {
      return(path)
    }
    if (startsWith(path, "outputs/")) {
      return(file.path(output_dir, sub("^outputs/", "", path)))
    }
    path
  }, character(1)))
}

resolve_first_site <- function(site_path) {
  if (is.null(site_path) || !nzchar(site_path) || !file.exists(site_path)) {
    return(NULL)
  }
  sites <- readr::read_csv(site_path, show_col_types = FALSE, n_max = 1, num_threads = 1)
  if (!"site" %in% names(sites) || nrow(sites) == 0L) {
    return(NULL)
  }
  as.character(sites$site[[1]])
}

apply_settings_to_config <- function(cfg, settings, settings_path = NULL) {
  checkmate::assert_list(cfg, any.missing = FALSE)
  checkmate::assert_list(settings, any.missing = FALSE)

  input_dir <- settings$input_dir
  if (is.null(input_dir) || !nzchar(input_dir)) {
    input_dir <- file.path("data", "raw", resolve_settings_project(settings))
  }

  project <- resolve_settings_project(settings, input_dir = input_dir)
  output_dir <- settings$outputs$dir
  if (is.null(output_dir) || !nzchar(output_dir)) {
    output_dir <- file.path("outputs", project)
  }

  site_file <- settings$site_file
  if (is.null(site_file) || !nzchar(site_file)) {
    site_file <- "site.csv"
  }
  obs_file <- settings$obs_file
  if (is.null(obs_file)) {
    obs_file <- "obs.csv"
  }
  op_file <- settings$op_file
  if (is.null(op_file)) {
    op_file <- "op.csv"
  }

  camera_cfg <- cfg$data$camera_sites
  if (is.null(camera_cfg) || !is.list(camera_cfg)) {
    camera_cfg <- list()
  }
  camera_cfg$source <- "jc"
  if (is.null(camera_cfg$jc)) camera_cfg$jc <- list()
  camera_cfg$jc$site_path <- file.path(input_dir, site_file)
  camera_cfg$jc$obs_path <- if (!is.null(obs_file) && nzchar(obs_file)) {
    file.path(input_dir, obs_file)
  } else {
    NULL
  }
  camera_cfg$jc$op_path <- if (!is.null(op_file) && nzchar(op_file)) {
    file.path(input_dir, op_file)
  } else {
    NULL
  }

  central_site <- settings$central_site
  if (is.null(central_site) || !nzchar(central_site)) {
    central_site <- resolve_first_site(camera_cfg$jc$site_path)
  }
  if (!is.null(central_site) && nzchar(central_site)) {
    camera_cfg$central_site <- central_site
  }

  if (!is.null(settings$camera_sites$bbox_half_km)) {
    camera_cfg$bbox_half_km <- as.numeric(settings$camera_sites$bbox_half_km)
  }

  cfg$data$camera_sites <- camera_cfg

  if (!is.null(settings$aoi)) {
    aoi_cfg <- cfg$data$aoi
    aoi_cfg$mode <- rlang::`%||%`(settings$aoi$mode, aoi_cfg$mode)
    if (!is.null(settings$aoi$buffer_km)) {
      aoi_cfg$buffer_km <- as.numeric(settings$aoi$buffer_km)
    }
    if (!is.null(settings$aoi$size_km)) {
      aoi_cfg$size_km <- as.numeric(settings$aoi$size_km)
    }
    if (!is.null(settings$aoi$rotation_deg)) {
      aoi_cfg$rotation_deg <- as.numeric(settings$aoi$rotation_deg)
    }
    cfg$data$aoi <- aoi_cfg
  }

  if (!is.null(settings$large_downloads$allow)) {
    cfg$data$large_downloads$allow <- isTRUE(settings$large_downloads$allow)
  }

  layer_include <- normalize_include_list(settings$layers)
  if (!is.null(layer_include)) {
    layer_map <- list(
      orthophoto = "orthophoto_arcgis",
      tasveg = "tasveg_wms",
      topography = "topography_arcgis",
      roads = "roads_wms",
      localities = "localities_wms"
    )
    include_ids <- unique(unlist(layer_map[tolower(layer_include)], use.names = FALSE))
    cfg$data$layers <- filter_layers_by_ids(cfg$data$layers, include_ids)
  }

  analysis_include <- normalize_include_list(settings$analysis_layers)
  if (!is.null(analysis_include)) {
    cfg$data$analysis_layers <- filter_analysis_layers(cfg$data$analysis_layers, analysis_include)
  }

  cfg <- rewrite_output_paths(cfg, output_dir = output_dir)
  cfg$data$outputs <- list(
    project = project,
    output_dir = output_dir,
    settings_path = settings_path
  )

  cfg
}

#' Run the pipeline using simplified settings
#'
#' @param settings_path Path to the settings YAML file.
#' @param targets Optional vector of target names to run.
#' @param base_profile Base config profile to start from (defaults to "jc").
#' @param config_path Optional base config path (defaults to `config/config.yaml`).
#' @return Path to the generated run config file.
#' @export
run_settings <- function(settings_path,
                         targets = NULL,
                         base_profile = NULL,
                         config_path = NULL) {
  settings <- read_settings_file(settings_path)
  if (is.null(base_profile) || !nzchar(base_profile)) {
    base_profile <- settings$base_profile
  }
  if (is.null(base_profile) || !nzchar(base_profile)) {
    base_profile <- "jc"
  }
  base_cfg <- cfg_read(profile = base_profile, config_path = config_path)
  run_cfg <- apply_settings_to_config(base_cfg, settings, settings_path = settings_path)

  project <- run_cfg$data$outputs$project
  output_dir <- run_cfg$data$outputs$output_dir
  run_config_path <- file.path(output_dir, "run_config.yaml")
  dir.create(dirname(run_config_path), recursive = TRUE, showWarnings = FALSE)
  yaml::write_yaml(list(default = run_cfg, run = run_cfg), run_config_path)

  old_env <- Sys.getenv(c("LOCALMAP_CONFIG_PATH", "R_CONFIG_ACTIVE"), unset = "")
  on.exit({
    Sys.setenv(LOCALMAP_CONFIG_PATH = old_env[[1]])
    Sys.setenv(R_CONFIG_ACTIVE = old_env[[2]])
  }, add = TRUE)
  Sys.setenv(LOCALMAP_CONFIG_PATH = run_config_path, R_CONFIG_ACTIVE = "run")

  if (!requireNamespace("targets", quietly = TRUE)) {
    rlang::abort(
      c(
        "Package 'targets' is required to run the pipeline.",
        i = "Install targets or run within the project renv."
      ),
      class = "settings_missing_targets"
    )
  }

  if (is.null(targets) || length(targets) == 0L) {
    targets::tar_make()
  } else {
    targets::tar_make(names = targets)
  }

  run_config_path
}
