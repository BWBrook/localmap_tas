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
  cfg
}
