#' Build an AOI polygon from configuration
#'
#' @param aoi_cfg List describing the AOI definition (centroid, size, rotation).
#'   Set `mode = "auto"` to derive the AOI from site bounds plus a buffer.
#' @param sites Optional data.frame with `site`, `lat`, `lon` columns for
#'   resolving `centroid_site`.
#' @return List containing the AOI polygon and derived bounding boxes.
#' @export
build_aoi_from_config <- function(aoi_cfg, sites = NULL) {
  checkmate::assert_list(aoi_cfg, any.missing = FALSE)

  analysis_crs <- aoi_cfg$crs
  if (is.null(analysis_crs)) {
    analysis_crs <- "EPSG:28355"
  }
  checkmate::assert_string(analysis_crs, min.chars = 1L)

  mode <- resolve_aoi_mode(aoi_cfg)
  rotation <- aoi_cfg$rotation_deg
  if (is.null(rotation)) {
    rotation <- 0
  }
  checkmate::assert_numeric(rotation, len = 1L, any.missing = FALSE)

  if (identical(mode, "auto")) {
    auto <- resolve_aoi_from_sites(aoi_cfg, sites = sites, analysis_crs = analysis_crs)
    size <- list(width_km = auto$width_km, height_km = auto$height_km)
    centroid_sf <- auto$centroid_4326
    centroid_xy <- auto$centroid_xy
  } else {
    centroid <- resolve_aoi_centroid(aoi_cfg, sites = sites)
    size <- resolve_aoi_size(aoi_cfg)
    centroid_sf <- sf::st_sfc(sf::st_point(c(centroid$lon, centroid$lat)), crs = 4326)
    centroid_proj <- sf::st_transform(centroid_sf, sf::st_crs(analysis_crs))
    centroid_xy <- sf::st_coordinates(centroid_proj)[1, ]
  }

  half_width <- size$width_km * 1000 / 2
  half_height <- size$height_km * 1000 / 2

  coords <- matrix(
    c(
      -half_width, half_height,
      half_width, half_height,
      half_width, -half_height,
      -half_width, -half_height,
      -half_width, half_height
    ),
    ncol = 2,
    byrow = TRUE
  )

  theta <- -rotation * pi / 180
  rotation_mat <- matrix(
    c(cos(theta), -sin(theta), sin(theta), cos(theta)),
    nrow = 2,
    byrow = TRUE
  )
  rotated <- t(rotation_mat %*% t(coords))
  rotated[, 1] <- rotated[, 1] + centroid_xy[1]
  rotated[, 2] <- rotated[, 2] + centroid_xy[2]

  aoi <- sf::st_sfc(sf::st_polygon(list(rotated)), crs = sf::st_crs(analysis_crs))
  aoi_4326 <- sf::st_transform(aoi, 4326)
  bbox_4326 <- sf::st_as_sfc(sf::st_bbox(aoi_4326))
  bbox_3857 <- sf::st_transform(bbox_4326, 3857)

  list(
    aoi = aoi,
    centroid_4326 = centroid_sf,
    bbox_4326 = bbox_4326,
    bbox_3857 = bbox_3857,
    crs = analysis_crs
  )
}

resolve_aoi_mode <- function(aoi_cfg) {
  mode <- aoi_cfg$mode
  if (is.null(mode)) {
    if (is.null(aoi_cfg$size_km) &&
      (is.null(aoi_cfg$width_km) || is.null(aoi_cfg$height_km))) {
      return("auto")
    }
    return("fixed")
  }
  checkmate::assert_string(mode, min.chars = 1L)
  mode <- tolower(mode)
  if (!mode %in% c("fixed", "auto")) {
    rlang::abort(
      sprintf("Unsupported AOI mode '%s'.", mode),
      class = "aoi_mode_invalid"
    )
  }
  mode
}

resolve_aoi_centroid <- function(aoi_cfg, sites = NULL) {
  if (!is.null(aoi_cfg$centroid_site)) {
    checkmate::assert_string(aoi_cfg$centroid_site, min.chars = 1L)
    if (is.null(sites)) {
      rlang::abort(
        "`centroid_site` requires a sites table with lat/lon.",
        class = "aoi_centroid_missing_sites"
      )
    }
    checkmate::assert_data_frame(sites, min.rows = 1L)
    if (!all(c("site", "lat", "lon") %in% names(sites))) {
      rlang::abort(
        "Sites table missing required columns (site, lat, lon).",
        class = "aoi_centroid_site_missing_columns"
      )
    }
    match <- sites[sites$site == aoi_cfg$centroid_site, , drop = FALSE]
    if (nrow(match) == 0L) {
      rlang::abort(
        sprintf("centroid_site '%s' not found in sites table.", aoi_cfg$centroid_site),
        class = "aoi_centroid_site_not_found"
      )
    }
    return(list(lat = as.numeric(match$lat[1]), lon = as.numeric(match$lon[1])))
  }

  centroid <- aoi_cfg$centroid
  if (is.null(centroid)) {
    rlang::abort("AOI centroid is required.", class = "aoi_centroid_missing")
  }
  checkmate::assert_list(centroid, any.missing = FALSE)
  if (!all(c("lat", "lon") %in% names(centroid))) {
    rlang::abort("AOI centroid must include lat/lon.", class = "aoi_centroid_missing")
  }
  lat <- as.numeric(centroid$lat)
  lon <- as.numeric(centroid$lon)
  checkmate::assert_numeric(lat, len = 1L, any.missing = FALSE)
  checkmate::assert_numeric(lon, len = 1L, any.missing = FALSE)
  list(lat = lat, lon = lon)
}

resolve_aoi_from_sites <- function(aoi_cfg, sites, analysis_crs) {
  if (is.null(sites)) {
    rlang::abort(
      "AOI auto mode requires a sites table with lat/lon.",
      class = "aoi_auto_missing_sites"
    )
  }
  checkmate::assert_data_frame(sites, min.rows = 1L)
  if (!all(c("lat", "lon") %in% names(sites))) {
    rlang::abort(
      "Sites table missing required columns (lat, lon) for AOI auto mode.",
      class = "aoi_auto_sites_missing_columns"
    )
  }

  sites_sf <- sf::st_as_sf(sites, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
  sites_proj <- sf::st_transform(sites_sf, sf::st_crs(analysis_crs))
  bbox <- sf::st_bbox(sites_proj)

  buffer_km <- resolve_aoi_buffer_km(aoi_cfg, sites_proj = sites_proj)
  width_km <- as.numeric((bbox["xmax"] - bbox["xmin"]) / 1000) + 2 * buffer_km
  height_km <- as.numeric((bbox["ymax"] - bbox["ymin"]) / 1000) + 2 * buffer_km

  if (!is.finite(width_km) || !is.finite(height_km)) {
    rlang::abort(
      "AOI auto mode could not derive a finite size from sites.",
      class = "aoi_auto_size_invalid"
    )
  }

  centroid_proj <- sf::st_centroid(sf::st_as_sfc(bbox))
  centroid_xy <- sf::st_coordinates(centroid_proj)[1, ]
  centroid_4326 <- sf::st_transform(centroid_proj, 4326)

  list(
    width_km = width_km,
    height_km = height_km,
    centroid_xy = centroid_xy,
    centroid_4326 = centroid_4326
  )
}

resolve_aoi_buffer_km <- function(aoi_cfg, sites_proj) {
  if (!is.null(aoi_cfg$buffer_km)) {
    buffer_km <- as.numeric(aoi_cfg$buffer_km)
    checkmate::assert_numeric(buffer_km, len = 1L, lower = 0)
    return(buffer_km)
  }

  multiplier <- aoi_cfg$buffer_multiplier
  if (is.null(multiplier)) {
    multiplier <- 1
  }
  checkmate::assert_numeric(multiplier, len = 1L, lower = 0)

  min_buffer_km <- aoi_cfg$min_buffer_km
  if (is.null(min_buffer_km)) {
    min_buffer_km <- 0.25
  }
  checkmate::assert_numeric(min_buffer_km, len = 1L, lower = 0)

  max_buffer_km <- aoi_cfg$max_buffer_km
  if (!is.null(max_buffer_km)) {
    checkmate::assert_numeric(max_buffer_km, len = 1L, lower = 0)
  }

  n_sites <- nrow(sites_proj)
  if (n_sites < 2L) {
    buffer_km <- min_buffer_km
  } else {
    dist_mat <- sf::st_distance(sites_proj)
    dist_mat <- matrix(as.numeric(dist_mat), nrow = n_sites)
    diag(dist_mat) <- NA_real_
    nearest <- apply(dist_mat, 1, min, na.rm = TRUE)
    buffer_km <- stats::median(nearest, na.rm = TRUE) / 1000
    if (!is.finite(buffer_km)) {
      buffer_km <- min_buffer_km
    }
    buffer_km <- buffer_km * multiplier
  }

  buffer_km <- max(buffer_km, min_buffer_km)
  if (!is.null(max_buffer_km)) {
    buffer_km <- min(buffer_km, max_buffer_km)
  }
  buffer_km
}

resolve_aoi_size <- function(aoi_cfg) {
  if (!is.null(aoi_cfg$size_km)) {
    size_km <- as.numeric(aoi_cfg$size_km)
    checkmate::assert_numeric(size_km, len = 1L, lower = 1e-6)
    return(list(width_km = size_km, height_km = size_km))
  }

  width_km <- as.numeric(aoi_cfg$width_km)
  height_km <- as.numeric(aoi_cfg$height_km)
  if (!is.finite(width_km) || !is.finite(height_km)) {
    rlang::abort(
      "AOI size requires `size_km` or both `width_km` and `height_km`.",
      class = "aoi_size_missing"
    )
  }
  checkmate::assert_numeric(width_km, len = 1L, lower = 1e-6)
  checkmate::assert_numeric(height_km, len = 1L, lower = 1e-6)
  list(width_km = width_km, height_km = height_km)
}
