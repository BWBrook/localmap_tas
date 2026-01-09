#' Build a coverage polygon from site points
#'
#' @param sites Data frame with `site`, `lat`, and `lon` columns.
#' @param coverage_cfg Optional list of coverage settings.
#' @param analysis_crs CRS string for area calculations (default EPSG:28355).
#' @return List with `polygon`, `area_m2`, `area_km2`, `n_sites`, and config.
#' @export
build_coverage_zone <- function(sites,
                                coverage_cfg = NULL,
                                analysis_crs = "EPSG:28355") {
  if (is.null(coverage_cfg) || !isTRUE(coverage_cfg$enabled)) {
    return(list(
      enabled = FALSE,
      polygon = NULL,
      area_m2 = NA_real_,
      area_km2 = NA_real_,
      n_sites = 0L,
      buffer_m = NA_real_,
      analysis_crs = analysis_crs
    ))
  }

  checkmate::assert_data_frame(sites, min.rows = 1L)
  required <- c("site", "lat", "lon")
  if (!all(required %in% names(sites))) {
    rlang::abort(
      sprintf("Sites table missing required columns: %s", paste(required, collapse = ", ")),
      class = "coverage_zone_missing_columns"
    )
  }
  checkmate::assert_string(analysis_crs, min.chars = 1L)

  selected <- sites
  site_ids <- coverage_cfg$site_ids
  if (!is.null(site_ids)) {
    site_ids <- as.character(unlist(site_ids, use.names = FALSE))
    site_ids <- trimws(site_ids)
    site_ids <- site_ids[nzchar(site_ids)]
    if (length(site_ids) > 0L) {
      selected <- selected[selected$site %in% site_ids, , drop = FALSE]
    }
  }

  if (nrow(selected) < 3L) {
    rlang::warn(
      "Coverage polygon requires at least 3 sites; skipping coverage zone."
    )
    return(list(
      enabled = TRUE,
      polygon = NULL,
      area_m2 = NA_real_,
      area_km2 = NA_real_,
      n_sites = nrow(selected),
      buffer_m = NA_real_,
      analysis_crs = analysis_crs
    ))
  }

  buffer_m <- as.numeric(coverage_cfg$buffer_m)
  if (!is.finite(buffer_m)) {
    buffer_m <- 0
  }
  if (buffer_m < 0) {
    rlang::abort("Coverage buffer_m must be >= 0.", class = "coverage_zone_invalid_buffer")
  }

  sites_sf <- sf::st_as_sf(selected, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
  sites_proj <- sf::st_transform(sites_sf, sf::st_crs(analysis_crs))
  hull <- sf::st_convex_hull(sf::st_union(sites_proj))
  if (buffer_m > 0) {
    hull <- sf::st_buffer(hull, dist = buffer_m)
  }
  hull <- sf::st_make_valid(hull)

  area_m2 <- as.numeric(sf::st_area(hull))
  area_km2 <- area_m2 / 1e6

  polygon_sf <- sf::st_as_sf(tibble::tibble(geometry = hull))
  list(
    enabled = TRUE,
    polygon = polygon_sf,
    area_m2 = area_m2,
    area_km2 = area_km2,
    n_sites = nrow(selected),
    buffer_m = buffer_m,
    analysis_crs = analysis_crs
  )
}

#' Write coverage summary table
#'
#' @param coverage Coverage list from `build_coverage_zone()`.
#' @param output_path Output CSV path.
#' @return Output path.
#' @export
write_coverage_summary <- function(coverage,
                                   output_path = NULL) {
  if (is.null(output_path)) {
    output_path <- here::here("outputs", "tables", "coverage_summary.csv")
  }
  checkmate::assert_string(output_path, min.chars = 1L)

  enabled <- FALSE
  area_m2 <- NA_real_
  area_km2 <- NA_real_
  n_sites <- 0L
  buffer_m <- NA_real_
  analysis_crs <- NA_character_

  if (!is.null(coverage) && is.list(coverage)) {
    enabled <- isTRUE(coverage$enabled)
    area_m2 <- coverage$area_m2
    area_km2 <- coverage$area_km2
    n_sites <- coverage$n_sites
    buffer_m <- coverage$buffer_m
    analysis_crs <- coverage$analysis_crs
  }

  summary_tbl <- tibble::tibble(
    enabled = enabled,
    area_m2 = area_m2,
    area_km2 = area_km2,
    n_sites = n_sites,
    buffer_m = buffer_m,
    analysis_crs = analysis_crs
  )

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(summary_tbl, output_path)
  output_path
}
