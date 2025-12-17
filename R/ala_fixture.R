# Helpers for running the ALA workflow without network access (demo/CI fixtures).

ala_fixture_taxa <- function(species_requests) {
  fn_env <- environment()
  import::from("checkmate", assert_data_frame, assert_names, .into = fn_env)
  import::from("tibble", tibble, .into = fn_env)

  assert_data_frame(species_requests, min.rows = 1L)
  assert_names(
    colnames(species_requests),
    must.include = c("species_id", "common_name", "scientific_name")
  )

  tibble(
    species_id = species_requests$species_id,
    query_common_name = species_requests$common_name,
    query_scientific_name = species_requests$scientific_name,
    matched_scientific_name = species_requests$scientific_name,
    matched_common_name = species_requests$common_name,
    taxon_concept_id = NA_character_,
    search_term = species_requests$scientific_name,
    match_type = "fixture"
  )
}

ala_fixture_occurrences <- function(
  taxa,
  fixture_path,
  min_year = NULL,
  min_lat = NULL,
  state_province = NULL
) {
  fn_env <- environment()
  import::from("checkmate", assert_data_frame, assert_string, test_string, .into = fn_env)
  import::from("here", here, .into = fn_env)
  import::from("readr", read_csv, .into = fn_env)
  import::from("rlang", abort, .into = fn_env)

  assert_data_frame(taxa, min.rows = 0L)
  if (nrow(taxa) == 0L) {
    return(data.frame())
  }

  if (!test_string(fixture_path, min.chars = 1L)) {
    abort(
      c(
        "Fixture occurrences path is required when `cfg$ala$use_fixture` is TRUE.",
        i = "Set `cfg$ala$fixture_occurrences` in config/config.yaml (demo profile)."
      ),
      class = "ala_fixture_missing_path"
    )
  }

  candidate_paths <- unique(c(fixture_path, here(fixture_path)))
  resolved <- candidate_paths[file.exists(candidate_paths)][1]

  if (is.na(resolved)) {
    installed <- fixture_path
    if (startsWith(installed, "inst/")) {
      installed <- sub("^inst/", "", installed)
    }
    installed_path <- system.file(installed, package = "localmap")
    if (nzchar(installed_path) && file.exists(installed_path)) {
      resolved <- installed_path
    }
  }

  if (is.na(resolved)) {
    abort(
      c(
        "Fixture occurrences file not found.",
        i = sprintf("fixture_path = %s", fixture_path)
      ),
      class = "ala_fixture_missing_file"
    )
  }

  assert_string(resolved, min.chars = 1L)
  data <- read_csv(resolved, show_col_types = FALSE, progress = FALSE)

  required_cols <- c(
    "species_id",
    "longitude",
    "latitude",
    "matched_common_name",
    "matched_scientific_name",
    "query_common_name",
    "query_scientific_name"
  )
  missing <- setdiff(required_cols, names(data))
  if (length(missing) > 0L) {
    abort(
      c(
        "Fixture occurrences file missing required columns.",
        i = sprintf("Missing columns: %s", paste(missing, collapse = ", "))
      ),
      class = "ala_fixture_missing_columns"
    )
  }

  data <- data[data$species_id %in% taxa$species_id, , drop = FALSE]

  if (!is.null(min_year) && "eventDate" %in% names(data)) {
    year_val <- suppressWarnings(as.integer(substr(data$eventDate, 1L, 4L)))
    data <- data[is.na(year_val) | year_val >= as.integer(min_year), , drop = FALSE]
  }

  if (!is.null(state_province) && "stateProvince" %in% names(data)) {
    data <- data[data$stateProvince == state_province, , drop = FALSE]
  }

  if (!is.null(min_lat) && !is.na(min_lat) && min_lat != 0) {
    cutoff <- as.numeric(min_lat)
    if (cutoff < 0) {
      data <- data[data$latitude <= cutoff, , drop = FALSE]
    } else {
      data <- data[data$latitude >= cutoff, , drop = FALSE]
    }
  }

  data$match_type <- "fixture"
  data
}
