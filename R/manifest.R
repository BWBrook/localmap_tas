#' Read a CSV manifest of input files
#'
#' Expects a CSV with columns `id` and `path`. Returns a tibble with an
#' additional `abs_path` column resolved relative to the project root.
#'
#' @param manifest_path Character path to the CSV manifest.
#' @return A tibble with columns `id`, `path`, and `abs_path`.
#' @export
read_manifest <- function(manifest_path) {
  if (!is.character(manifest_path) || length(manifest_path) != 1L) {
    rlang::abort(
      "`manifest_path` must be a single character string.",
      class = "read_manifest_bad_path"
    )
  }

  # Allow relative paths
  csv_path <- manifest_path
  root_dir <- NULL
  if (!file.exists(csv_path)) {
    # Try resolving under repo root
    csv_path_here <- here::here(manifest_path)
    if (file.exists(csv_path_here)) {
      csv_path <- csv_path_here
      root_dir <- here::here()
    }
  } else {
    root_dir <- tryCatch(here::here(), error = function(e) NULL)
  }
  if (!file.exists(csv_path)) {
    csv_path_pkg <- system.file(manifest_path, package = "localmap")
    if (nzchar(csv_path_pkg) && file.exists(csv_path_pkg)) {
      csv_path <- csv_path_pkg
      root_dir <- system.file(package = "localmap")
    }
  }
  if (!file.exists(csv_path)) {
    rlang::abort(
      c(
        "Manifest file not found.",
        i = sprintf("Tried: %s and %s", manifest_path, csv_path)
      ),
      class = "read_manifest_missing"
    )
  }
  if (is.null(root_dir) || !nzchar(root_dir)) {
    root_dir <- dirname(csv_path)
  }

  dat <- readr::read_csv(
    csv_path,
    show_col_types = FALSE,
    progress = FALSE,
    num_threads = 1
  )
  # Validate minimal schema
  needed <- c("id", "path")
  checkmate::assert_names(colnames(dat), must.include = needed)
  dat$id <- stringr::str_trim(dat$id)
  dat$path <- stringr::str_trim(dat$path)

  resolve_path <- function(p) {
    candidate <- file.path(root_dir, p)
    if (!file.exists(candidate) && startsWith(p, "inst/")) {
      candidate_inst <- file.path(root_dir, substring(p, nchar("inst/") + 1L))
      if (file.exists(candidate_inst)) {
        return(candidate_inst)
      }
    }
    candidate
  }

  out <- dplyr::mutate(dat, abs_path = vapply(.data$path, resolve_path, character(1)))
  # Warn for missing files but do not abort; downstream targets may generate them
  missing <- out[!file.exists(out$abs_path), , drop = FALSE]
  if (nrow(missing) > 0L) {
    cli::cli_warn(sprintf("%d manifest file(s) do not exist yet.", nrow(missing)))
  } else {
    cli::cli_inform("All manifest files exist.")
  }
  out
}
