#' Download occurrence records for resolved species
#'
#' Fetches occurrence records from the Atlas of Living Australia for the
#' species produced by [ala_resolve_species()].
#'
#' @param taxa Tibble with resolved species metadata.
#' @param min_year Optional numeric year; if supplied, filters records to events
#'   on or after this year.
#' @param boundary Optional spatial boundary (path to a vector file or `sf`
#'   object) used to restrict the query. When provided, the resulting polygon is
#'   passed via `galah::galah_polygon()`.
#' @param boundary_simplify Optional numeric tolerance (in boundary CRS units)
#'   applied when simplifying the boundary geometry.
#' @param columns Character vector of occurrence fields to request.
#' @param min_lat Optional numeric latitude threshold. Negative values retain
#'   southerly records at or below the threshold; positive values retain
#'   northerly records at or above the threshold.
#' @param state_province Optional string used to filter records by the
#'   `stateProvince` field (e.g., "Tasmania").
#' @param fetch_fun Optional function overriding the download implementation.
#'   Defaults to an internal wrapper around `galah` and exists mostly for
#'   testing.
#' @param config Optional list of galah configuration values (e.g., email).
#'   Passed through to `galah::galah_config()` when using the default
#'   implementation.
#' @return A tibble of occurrence records with species metadata attached.
#' @export
ala_fetch_occurrences <- function(taxa,
                                  min_year = NULL,
                                  boundary = NULL,
                                  boundary_simplify = NULL,
                                  columns = ala_default_occurrence_fields(),
                                  min_lat = NULL,
                                  state_province = NULL,
                                  fetch_fun = NULL,
                                  config = NULL) {
  checkmate::assert_data_frame(taxa, min.rows = 0L)
  required <- c(
    "species_id", "matched_scientific_name", "matched_common_name",
    "query_scientific_name", "query_common_name", "match_type"
  )
  checkmate::assert_names(colnames(taxa), must.include = required)

  if (!is.null(min_year)) {
    checkmate::assert_numeric(min_year, lower = 0, upper = Inf, len = 1L, any.missing = FALSE)
  }

  if (!is.null(state_province)) {
    checkmate::assert_string(state_province, min.chars = 1L)
  }

  if (is.null(fetch_fun)) {
    fetch_fun <- ala_fetch_occurrences_galah
  } else if (!rlang::is_function(fetch_fun)) {
    rlang::abort(
      "`fetch_fun` must be a function when supplied.",
      class = "ala_fetch_occurrences_bad_fetch"
    )
  }

  boundary_wkt <- prepare_boundary(boundary, boundary_simplify)

  if (nrow(taxa) == 0L) {
    return(tibble::tibble())
  }

  purrr::map_dfr(seq_len(nrow(taxa)), function(idx) {
    row <- taxa[idx, , drop = FALSE]
    if (identical(row$match_type[[1]], "not_found")) {
      return(tibble::tibble())
    }
    identifier <- row$matched_scientific_name[[1]]
    if (!is.na(identifier) && nzchar(identifier) && grepl("\\(", identifier, fixed = FALSE)) {
      # Some resolved names include subgenus parentheses that the API rejects.
      identifier <- row$query_scientific_name[[1]]
    }
    if (is.na(identifier) || !nzchar(identifier)) {
      identifier <- row$query_scientific_name[[1]]
    }
    if (is.na(identifier) || !nzchar(identifier)) {
      identifier <- row$query_common_name[[1]]
    }
    if (is.na(identifier) || !nzchar(identifier)) {
      return(tibble::tibble())
    }
    records <- fetch_fun(
      identifier = identifier,
      species_row = row,
      min_year = min_year,
      boundary_wkt = boundary_wkt,
      columns = columns,
      min_lat = min_lat,
      state_province = state_province,
      config = config
    )
    if (is.null(records)) {
      return(tibble::tibble())
    }

    if (is.list(records) && "data" %in% names(records)) {
      records <- records$data
    }

    if (!inherits(records, "data.frame")) {
      records <- try(tibble::as_tibble(records), silent = TRUE)
      if (inherits(records, "try-error")) {
        return(tibble::tibble())
      }
    }

    records <- tibble::as_tibble(records)

    if (NROW(records) == 0L) {
      return(tibble::tibble())
    }
    records
  })
}

ala_fetch_occurrences_galah <- function(
  identifier,
  species_row,
  min_year,
  boundary_wkt,
  columns,
  min_lat,
  state_province,
  config
) {
  if (!is.null(config)) {
    galah::galah_config(
      atlas = if (is.null(config$atlas)) "ALA" else config$atlas,
      email = config$email,
      verbose = if (is.null(config$verbose)) FALSE else config$verbose,
      caching = if (is.null(config$caching)) TRUE else config$caching
    )
  }

  pipeline_steps <- c(
    "galah::galah_call()",
    sprintf("galah::galah_identify(%s)", shQuote(identifier))
  )
  if (!is.null(min_year)) {
    pipeline_steps <- c(
      pipeline_steps,
      sprintf("galah::galah_filter(year >= %s)", as.numeric(min_year))
    )
  }
  if (!is.null(state_province) && nzchar(state_province)) {
    pipeline_steps <- c(
      pipeline_steps,
      sprintf(
        "galah::galah_filter(stateProvince == %s)",
        shQuote(state_province)
      )
    )
  }
  if (!is.null(min_lat) && !is.na(min_lat) && min_lat != 0) {
    lat_cutoff <- as.numeric(min_lat)
    op <- if (lat_cutoff < 0) "<=" else ">="
    pipeline_steps <- c(
      pipeline_steps,
      sprintf(
        "galah::galah_filter(decimalLatitude %s %s)",
        op,
        lat_cutoff
      )
    )
  }
  if (!is.null(columns) && length(columns) > 0L) {
    pipeline_steps <- c(
      pipeline_steps,
      sprintf(
        "galah::galah_select(%s)",
        paste(columns, collapse = ", ")
      )
    )
  }
  pipeline_expr <- parse(text = paste(pipeline_steps, collapse = " |>\n    "))
  call <- eval(pipeline_expr)
  if (!is.null(boundary_wkt)) {
    call <- galah::galah_polygon(call, boundary_wkt)
  }

  occ <- tryCatch(
    galah::atlas_occurrences(call),
    error = function(err) {
      details <- conditionMessage(err)
      body <- NULL
      if (!is.null(err$resp)) {
        body <- tryCatch(httr2::resp_body_string(err$resp), error = function(e) NULL)
      }
      rlang::abort(
        c(
          "galah download failed.",
          i = paste0("Pipeline: ", paste(pipeline_steps, collapse = " |> ")),
          x = details,
          if (!is.null(body)) paste0("body: ", body) else NULL
        ),
        class = "ala_fetch_galah_error"
      )
    }
  )
  if (is.list(occ) && "data" %in% names(occ)) {
    occ <- occ$data
  }
  if (is.null(occ)) {
    return(NULL)
  }
  records <- tibble::as_tibble(occ)
  if (nrow(records) == 0L) {
    return(records)
  }
  records <- dplyr::mutate(
    records,
    species_id = species_row$species_id[[1]],
    matched_scientific_name = species_row$matched_scientific_name[[1]],
    matched_common_name = species_row$matched_common_name[[1]],
    query_scientific_name = species_row$query_scientific_name[[1]],
    query_common_name = species_row$query_common_name[[1]]
  )
  if ("decimalLongitude" %in% colnames(records) && "decimalLatitude" %in% colnames(records)) {
    records <- dplyr::rename(
      records,
      longitude = dplyr::any_of("decimalLongitude"),
      latitude = dplyr::any_of("decimalLatitude")
    )
  }
  records
}

prepare_boundary <- function(boundary, simplify) {
  if (is.null(boundary)) {
    return(NULL)
  }

  geom <- boundary
  if (!inherits(boundary, "sf")) {
    geom <- sf::read_sf(boundary)
  }

  geom <- sf::st_make_valid(geom)
  geom <- sf::st_union(geom)
  crs <- sf::st_crs(geom)
  if (is.na(crs)) {
    geom <- sf::st_transform(geom, 4326)
  } else if (!is.null(crs$epsg) && crs$epsg != 4326) {
    geom <- sf::st_transform(geom, 4326)
  }
  if (!is.null(simplify)) {
    geom <- sf::st_simplify(geom, dTolerance = simplify)
  }
  sf::st_as_text(sf::st_geometry(geom))[[1]]
}
