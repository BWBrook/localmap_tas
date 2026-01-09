#' Combine CSV files from a manifest when columns align
#'
#' Reads all existing `.csv` files referenced in a manifest and returns a
#' single tibble consisting of the intersection of common columns across files.
#' Non-CSV or missing files are skipped with a warning.
#'
#' @param manifest A tibble/data.frame containing `path` and `abs_path`.
#' @return A tibble with the common columns across all readable CSV files.
#' @export
combine_manifest_csvs <- function(manifest) {
  if (!all(c("path", "abs_path") %in% names(manifest))) {
    rlang::abort(
      "`manifest` must contain path and abs_path columns.",
      class = "combine_manifest_bad_cols"
    )
  }

  idx <- grepl("\\.csv$", tolower(manifest$path)) & file.exists(manifest$abs_path)
  paths <- manifest$abs_path[idx]
  if (length(paths) == 0L) {
    return(tibble::tibble())
  }

  dfs <- purrr::map(paths, function(p) {
    dat <- try(
      readr::read_csv(p, show_col_types = FALSE, progress = FALSE, num_threads = 1),
      silent = TRUE
    )
    if (inherits(dat, "try-error")) {
      cli::cli_warn(sprintf("Failed to read CSV: %s", basename(p)))
      return(NULL)
    }
    dat
  }) |> purrr::compact()

  if (length(dfs) == 0L) {
    return(tibble::tibble())
  }

  # Determine intersection of column names
  common <- Reduce(base::intersect, lapply(dfs, names))
  if (length(common) == 0L) {
    cli::cli_warn("No common columns across CSV inputs; returning empty tibble.")
    return(tibble::tibble())
  }

  dplyr::bind_rows(lapply(dfs, function(x) dplyr::select(x, dplyr::all_of(common))))
}

#' Validate output schema manifest
#'
#' Ensures the output manifest contains required fields and verifies that
#' declared output files exist on disk when expected outputs are supplied.
#'
#' @param manifest A tibble/data.frame with output metadata.
#' @param expected_outputs Optional named list mapping output_id to file path.
#' @return The manifest as a tibble (invisibly) after validation.
#' @export

validate_output_manifest <- function(manifest,
                                     expected_outputs = NULL) {
  checkmate::assert_data_frame(manifest, min.rows = 1L)
  required <- c("output_id", "type", "path")
  checkmate::assert_names(names(manifest), must.include = required)

  if (!is.null(expected_outputs)) {
    checkmate::assert_list(expected_outputs, any.missing = FALSE)
    for (id in names(expected_outputs)) {
      path <- expected_outputs[[id]]
      if (!is.null(path) && nzchar(path) && file.exists(path)) {
        manifest_rows <- manifest[manifest$output_id == id, , drop = FALSE]
        if (nrow(manifest_rows) == 0L) {
          rlang::abort(
            sprintf("Output manifest missing output_id '%s'.", id),
            class = "output_manifest_missing_id"
          )
        }
        for (declared in manifest_rows$path) {
          if (!file.exists(declared)) {
            rlang::abort(
              sprintf("Declared output missing on disk: %s", declared),
              class = "output_manifest_missing_file"
            )
          }
        }
      }
    }
  }

  tibble::as_tibble(manifest)
}
