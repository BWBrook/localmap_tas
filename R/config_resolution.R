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
  cfg
}
