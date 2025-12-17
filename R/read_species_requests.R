#' Read species request definitions
#'
#' Reads a CSV file describing the species to query from the Atlas of Living
#' Australia. Each row should supply at least one of `common_name` or
#' `scientific_name`. A `species_id` column is optional; if missing, unique ids
#' are generated from the row numbers.
#'
#' @param path Character scalar. Path to the CSV file, relative to the project
#'   root or absolute.
#' @return A tibble with columns `species_id`, `common_name`, and
#'   `scientific_name`.
#' @export
read_species_requests <- function(path) {
  checkmate::assert_character(path, any.missing = FALSE, len = 1L)

  candidate_paths <- unique(c(
    path,
    here::here(path),
    system.file(path, package = "localmap")
  ))
  candidate_paths <- candidate_paths[nzchar(candidate_paths)]
  path_resolved <- candidate_paths[file.exists(candidate_paths)][1]
  if (is.na(path_resolved)) {
    rlang::abort(
      c(
        "Species request file not found.",
        i = sprintf("Tried: %s", paste(candidate_paths, collapse = ", "))
      ),
      class = "read_species_requests_missing"
    )
  }

  raw <- readr::read_csv(path_resolved, show_col_types = FALSE, progress = FALSE)
  required <- c("common_name", "scientific_name")
  missing_cols <- setdiff(required, colnames(raw))
  if (length(missing_cols) > 0L) {
    rlang::abort(
      c(
        "Species request file is missing required columns.",
        i = sprintf("Missing: %s", paste(missing_cols, collapse = ", "))
      ),
      class = "read_species_requests_schema"
    )
  }

  has_id <- "species_id" %in% colnames(raw)

  out <- dplyr::mutate(
    raw,
    species_id = if (has_id) {
      .data$species_id
    } else {
      sprintf("species_%02d", dplyr::row_number())
    }
  )

  if (any(is.na(out$species_id) | out$species_id == "")) {
    rlang::abort(
      "`species_id` values must be non-missing.",
      class = "read_species_requests_id_missing"
    )
  }
  if (any(duplicated(out$species_id))) {
    rlang::abort(
      "`species_id` values must be unique.",
      class = "read_species_requests_id_duplicate"
    )
  }

  cleaned <- dplyr::mutate(
    out,
    common_name = stringr::str_trim(.data$common_name),
    scientific_name = stringr::str_trim(.data$scientific_name),
    common_name = dplyr::if_else(
      .data$common_name == "",
      NA_character_,
      .data$common_name
    ),
    scientific_name = dplyr::if_else(
      .data$scientific_name == "",
      NA_character_,
      .data$scientific_name
    )
  )

  invalid_rows <- which(is.na(cleaned$common_name) & is.na(cleaned$scientific_name))
  if (length(invalid_rows) > 0L) {
    rlang::abort(
      c(
        "Each species request must include a common or scientific name.",
        i = sprintf("Invalid rows: %s", paste(invalid_rows, collapse = ", "))
      ),
      class = "read_species_requests_no_query"
    )
  }

  dplyr::select(cleaned, dplyr::all_of(c("species_id", "common_name", "scientific_name"))) |>
    tibble::as_tibble()
}
