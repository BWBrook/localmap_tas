#' Build an AOI polygon from configuration
#'
#' @param aoi_cfg List describing the AOI definition (centroid, size, rotation).
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

  centroid <- resolve_aoi_centroid(aoi_cfg, sites = sites)
  size <- resolve_aoi_size(aoi_cfg)
  rotation <- aoi_cfg$rotation_deg
  if (is.null(rotation)) {
    rotation <- 0
  }
  checkmate::assert_numeric(rotation, len = 1L, any.missing = FALSE)

  centroid_sf <- sf::st_sfc(sf::st_point(c(centroid$lon, centroid$lat)), crs = 4326)
  centroid_proj <- sf::st_transform(centroid_sf, sf::st_crs(analysis_crs))
  centroid_xy <- sf::st_coordinates(centroid_proj)[1, ]

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
