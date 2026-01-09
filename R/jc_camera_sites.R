#' Derive camera site metrics from the Judbury camera study
#'
#' @param site_path Path to `jc_site.csv` (lat/lon).
#' @param obs_path Path to `jc_obs.csv` (datetime, site, count).
#' @param output_path Path for the derived camera sites CSV.
#' @return Path to the derived CSV.
#' @keywords internal
derive_camera_sites_from_jc <- function(site_path,
                                        obs_path,
                                        output_path = NULL) {
  site_path <- resolve_existing_path(site_path, "jc_site.csv")
  obs_path <- resolve_existing_path(obs_path, "jc_obs.csv")

  if (is.null(output_path)) {
    output_path <- here::here("data", "interim", "jc_camera_sites.csv")
  }
  checkmate::assert_string(output_path, min.chars = 1L)

  sites <- readr::read_csv(site_path, show_col_types = FALSE, num_threads = 1)
  obs <- readr::read_csv(obs_path, show_col_types = FALSE, num_threads = 1)

  required_sites <- c("site", "lat", "lon")
  missing_sites <- setdiff(required_sites, names(sites))
  if (length(missing_sites) > 0L) {
    rlang::abort(
      sprintf("jc_site.csv missing required columns: %s", paste(missing_sites, collapse = ", ")),
      class = "jc_site_missing_columns"
    )
  }
  required_obs <- c("site", "datetime")
  missing_obs <- setdiff(required_obs, names(obs))
  if (length(missing_obs) > 0L) {
    rlang::abort(
      sprintf("jc_obs.csv missing required columns: %s", paste(missing_obs, collapse = ", ")),
      class = "jc_obs_missing_columns"
    )
  }

  obs$site <- as.character(obs$site)
  sites$site <- as.character(sites$site)
  obs_date <- sub(" .*", "", obs$datetime)
  parsed_date <- as.Date(obs_date, tryFormats = c("%d/%m/%Y", "%Y-%m-%d"))

  obs$count <- if ("count" %in% names(obs)) as.numeric(obs$count) else NA_real_
  obs_counts <- tapply(obs$count, obs$site, function(x) {
    if (all(is.na(x))) {
      return(length(x))
    }
    sum(x, na.rm = TRUE)
  })

  obs_days <- tapply(parsed_date, obs$site, function(x) {
    length(unique(stats::na.omit(x)))
  })

  summary_df <- tibble::tibble(
    site = names(obs_counts),
    obs = as.numeric(obs_counts),
    rd = as.numeric(obs_days[match(names(obs_counts), names(obs_days))])
  )

  merged <- dplyr::left_join(sites, summary_df, by = "site")
  merged$obs[is.na(merged$obs)] <- 0
  merged$rd[is.na(merged$rd)] <- 0

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(merged, output_path, row.names = FALSE)

  output_path
}

resolve_existing_path <- function(path, label = NULL) {
  checkmate::assert_character(path, len = 1L, any.missing = FALSE)
  candidates <- unique(c(path, here::here(path)))
  existing <- candidates[file.exists(candidates)]
  if (length(existing) == 0L) {
    detail <- if (!is.null(label)) {
      sprintf("Expected %s at: %s", label, paste(candidates, collapse = ", "))
    } else {
      sprintf("Checked: %s", paste(candidates, collapse = ", "))
    }
    rlang::abort(
      c("Required file not found.", i = detail),
      class = "jc_input_missing_file"
    )
  }
  existing[[1]]
}

resolve_camera_sites_file <- function(camera_cfg) {
  checkmate::assert_list(camera_cfg, any.missing = FALSE)
  source_type <- camera_cfg$source
  if (is.null(source_type)) {
    source_type <- "file"
  }
  checkmate::assert_string(source_type, min.chars = 1L)
  if (!source_type %in% c("file", "jc")) {
    rlang::abort(
      sprintf("Unsupported camera_sites source '%s'.", source_type),
      class = "camera_sites_source_invalid"
    )
  }

  if (identical(source_type, "jc")) {
    jc_cfg <- camera_cfg$jc
    if (is.null(jc_cfg) || !is.list(jc_cfg)) {
      rlang::abort(
        "`data$camera_sites$jc` must be provided for source=jc.",
        class = "camera_sites_jc_missing"
      )
    }
    site_path <- jc_cfg$site_path
    obs_path <- jc_cfg$obs_path
    output_path <- jc_cfg$output_path
    if (is.null(output_path)) {
      output_path <- here::here("data", "interim", "jc_camera_sites.csv")
    }

    if (file.exists(output_path)) {
      input_times <- file.mtime(c(
        resolve_existing_path(site_path),
        resolve_existing_path(obs_path)
      ))
      if (all(input_times <= file.mtime(output_path))) {
        return(output_path)
      }
    }

    return(derive_camera_sites_from_jc(site_path, obs_path, output_path))
  }

  path <- camera_cfg$path
  if (is.null(path)) {
    rlang::abort("`data$camera_sites$path` must be set.", class = "camera_sites_path_missing")
  }
  resolve_existing_path(path)
}
