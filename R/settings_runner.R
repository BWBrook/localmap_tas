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

normalize_settings_products <- function(products = NULL) {
  allowed <- c("attributes", "atlas", "figure", "all")
  if (is.null(products) || length(products) == 0L) {
    return("all")
  }

  if (is.list(products)) {
    products <- unlist(products, recursive = TRUE, use.names = FALSE)
  }
  products <- as.character(products)
  if (length(products) == 0L || anyNA(products)) {
    rlang::abort(
      c(
        "Settings `products` must name one or more products.",
        i = sprintf("Allowed values: %s.", paste(allowed, collapse = ", "))
      ),
      class = "settings_products_invalid"
    )
  }

  products <- tolower(trimws(products))
  if (any(!nzchar(products))) {
    rlang::abort(
      c(
        "Settings `products` cannot contain empty names.",
        i = sprintf("Allowed values: %s.", paste(allowed, collapse = ", "))
      ),
      class = "settings_products_invalid"
    )
  }
  unknown <- setdiff(unique(products), allowed)
  if (length(unknown) > 0L) {
    rlang::abort(
      c(
        sprintf("Unknown settings product(s): %s.", paste(unknown, collapse = ", ")),
        i = sprintf("Choose from: %s.", paste(allowed, collapse = ", "))
      ),
      class = "settings_products_invalid"
    )
  }

  if ("all" %in% products) {
    return("all")
  }
  unique(products)
}

settings_product_target_sets <- function() {
  list(
    attributes = c(
      "site_attributes_long_file",
      "site_attributes_wide_file",
      "analysis_provenance",
      "attribution_report",
      "run_manifest"
    ),
    atlas = c(
      "overview_map",
      "camera_sites_map",
      "analysis_provenance",
      "attribution_report",
      "run_manifest"
    ),
    figure = c(
      "panel_figure_png",
      "panel_figure_pdf",
      "analysis_provenance",
      "attribution_report",
      "run_manifest"
    )
  )
}

settings_targets_for_products <- function(products = NULL) {
  products <- normalize_settings_products(products)
  if (identical(products, "all")) {
    products <- names(settings_product_target_sets())
  }
  targets <- settings_product_target_sets()[products]
  unique(unlist(targets, use.names = FALSE))
}

resolve_settings_targets <- function(targets = NULL, products = NULL) {
  if (is.null(targets) || length(targets) == 0L) {
    return(settings_targets_for_products(products))
  }
  targets
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

rewrite_output_paths <- function(value, output_dir, strip_prefixes = NULL) {
  if (is.list(value)) {
    return(lapply(
      value,
      rewrite_output_paths,
      output_dir = output_dir,
      strip_prefixes = strip_prefixes
    ))
  }
  if (!is.character(value)) {
    return(value)
  }
  if (!is.null(strip_prefixes)) {
    strip_prefixes <- strip_prefixes[nzchar(strip_prefixes)]
    strip_prefixes <- sub("/+$", "", strip_prefixes)
    strip_prefixes <- unique(strip_prefixes)
  }
  unname(vapply(value, function(path) {
    if (!nzchar(path)) {
      return(path)
    }
    if (startsWith(path, "outputs/")) {
      if (!is.null(strip_prefixes) && length(strip_prefixes) > 0L) {
        for (prefix in strip_prefixes) {
          if (identical(path, prefix)) {
            return(output_dir)
          }
          if (startsWith(path, paste0(prefix, "/"))) {
            return(file.path(output_dir, sub(paste0("^", prefix, "/"), "", path)))
          }
        }
      }
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

apply_settings_to_config <- function(cfg,
                                     settings,
                                     settings_path = NULL,
                                     base_profile = NULL) {
  checkmate::assert_list(cfg, any.missing = FALSE)
  checkmate::assert_list(settings, any.missing = FALSE)
  products <- normalize_settings_products(settings$products)

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

  base_output_dir <- cfg$data$outputs$output_dir
  if ((is.null(base_output_dir) || !nzchar(base_output_dir)) &&
        !is.null(base_profile) && nzchar(base_profile)) {
    base_output_dir <- file.path("outputs", base_profile)
  }
  strip_prefixes <- c()
  if (!is.null(base_output_dir) && nzchar(base_output_dir)) {
    strip_prefixes <- c(strip_prefixes, base_output_dir)
  }
  strip_prefixes <- unique(c(strip_prefixes, "outputs/default"))

  cfg <- rewrite_output_paths(cfg, output_dir = output_dir, strip_prefixes = strip_prefixes)
  cfg$data$outputs <- list(
    project = project,
    output_dir = output_dir,
    settings_path = settings_path,
    products = products
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
  run_cfg <- apply_settings_to_config(
    base_cfg,
    settings,
    settings_path = settings_path,
    base_profile = base_profile
  )

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

  script_path <- here::here("_targets.R")
  if (!file.exists(script_path)) {
    script_path <- "_targets.R"
  }
  script_dir <- dirname(script_path)
  script_file <- basename(script_path)
  callr_args <- list(wd = script_dir)
  old_wd <- setwd(script_dir)
  on.exit(setwd(old_wd), add = TRUE)

  targets <- resolve_settings_targets(targets, run_cfg$data$outputs$products)

  if (is.null(targets) || length(targets) == 0L) {
    targets::tar_make(
      script = script_file,
      callr_arguments = callr_args
    )
  } else {
    targets::tar_make(
      names = tidyselect::any_of(targets),
      script = script_file,
      callr_arguments = callr_args
    )
  }

  run_config_path
}
