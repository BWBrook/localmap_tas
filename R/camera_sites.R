#' Derive camera site metrics from the Judbury camera study
#'
#' @param site_path Path to `site.csv` (lat/lon).
#' @param obs_path Optional path to `obs.csv` (site, datetime, count).
#' @param op_path Optional path to `op.csv` (operational days by site).
#' @param output_path Path for the derived camera sites CSV.
#' @return Path to the derived CSV.
#' @keywords internal
derive_camera_sites_from_jc <- function(site_path,
                                        obs_path = NULL,
                                        op_path = NULL,
                                        output_path = NULL) {
  site_path <- resolve_existing_path(site_path, "site.csv")

  if (is.null(output_path)) {
    output_path <- here::here("data", "interim", "jc_camera_sites.csv")
  }
  checkmate::assert_string(output_path, min.chars = 1L)

  sites <- readr::read_csv(site_path, show_col_types = FALSE, num_threads = 1)

  required_sites <- c("site", "lat", "lon")
  missing_sites <- setdiff(required_sites, names(sites))
  if (length(missing_sites) > 0L) {
    rlang::abort(
      sprintf("site.csv missing required columns: %s", paste(missing_sites, collapse = ", ")),
      class = "jc_site_missing_columns"
    )
  }

  sites$site <- as.character(sites$site)

  obs_values <- NULL
  if ("count" %in% names(sites)) {
    obs_values <- suppressWarnings(as.numeric(sites$count))
  } else if ("obs" %in% names(sites)) {
    obs_values <- suppressWarnings(as.numeric(sites$obs))
  }
  if (is.null(obs_values)) {
    obs_values <- rep(NA_real_, nrow(sites))
    obs_path_resolved <- resolve_optional_path(obs_path, "obs.csv")
    if (!is.null(obs_path_resolved)) {
      obs <- readr::read_csv(obs_path_resolved, show_col_types = FALSE, num_threads = 1)
      if (!"site" %in% names(obs)) {
        rlang::warn(
          c(
            "obs.csv missing required column; using NA for obs.",
            i = "Expected column: site"
          )
        )
      } else {
        obs$site <- as.character(obs$site)
        obs$count <- if ("count" %in% names(obs)) {
          suppressWarnings(as.numeric(obs$count))
        } else {
          NA_real_
        }
        obs_counts <- tapply(obs$count, obs$site, function(x) {
          if (all(is.na(x))) {
            return(length(x))
          }
          sum(x, na.rm = TRUE)
        })
        obs_values <- as.numeric(obs_counts[match(sites$site, names(obs_counts))])
      }
    }
  }

  rd_values <- NULL
  if ("rd" %in% names(sites)) {
    rd_values <- suppressWarnings(as.numeric(sites$rd))
  }
  if (is.null(rd_values)) {
    rd_values <- rep(NA_real_, nrow(sites))
    op_path_resolved <- resolve_optional_path(op_path, "op.csv")
    if (!is.null(op_path_resolved)) {
      op <- readr::read_csv(op_path_resolved, show_col_types = FALSE, num_threads = 1)
      site_cols <- intersect(names(op), sites$site)
      if (length(site_cols) == 0L) {
        rlang::warn(
          c(
            "op.csv missing site columns; using NA for rd.",
            i = "No site columns matched the site list."
          )
        )
      } else {
        rd_by_site <- vapply(site_cols, function(col) {
          suppressWarnings(sum(as.numeric(op[[col]]), na.rm = TRUE))
        }, numeric(1))
        rd_values <- as.numeric(rd_by_site[match(sites$site, names(rd_by_site))])
      }
    }
  }

  merged <- sites
  merged$obs <- obs_values
  merged$rd <- rd_values

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

resolve_optional_path <- function(path, label = NULL) {
  if (is.null(path) || !nzchar(path)) {
    return(NULL)
  }
  candidates <- unique(c(path, here::here(path)))
  existing <- candidates[file.exists(candidates)]
  if (length(existing) == 0L) {
    detail <- if (!is.null(label)) {
      sprintf("Expected %s at: %s", label, paste(candidates, collapse = ", "))
    } else {
      sprintf("Checked: %s", paste(candidates, collapse = ", "))
    }
    rlang::warn(
      c("Optional input file not found; using NA for derived values.", i = detail),
      class = "jc_optional_input_missing"
    )
    return(NULL)
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
    op_path <- jc_cfg$op_path
    output_path <- jc_cfg$output_path
    if (is.null(output_path)) {
      output_path <- here::here("data", "interim", "jc_camera_sites.csv")
    }

    if (file.exists(output_path)) {
      input_paths <- resolve_existing_path(site_path)
      optional_paths <- c(obs_path, op_path)
      for (candidate in optional_paths) {
        if (!is.null(candidate) && nzchar(candidate)) {
          candidate_paths <- unique(c(candidate, here::here(candidate)))
          existing <- candidate_paths[file.exists(candidate_paths)]
          if (length(existing) > 0L) {
            input_paths <- c(input_paths, existing[[1]])
          }
        }
      }
      input_times <- file.mtime(input_paths)
      if (all(input_times <= file.mtime(output_path))) {
        return(output_path)
      }
    }

    return(derive_camera_sites_from_jc(site_path, obs_path, op_path, output_path))
  }

  path <- camera_cfg$path
  if (is.null(path)) {
    rlang::abort("`data$camera_sites$path` must be set.", class = "camera_sites_path_missing")
  }
  resolve_existing_path(path)
}
