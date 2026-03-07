camera_sites_pick_step <- function(range_deg) {
  steps <- c(0.01, 0.02, 0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10)
  if (!is.finite(range_deg) || range_deg <= 0) {
    return(steps[[1]])
  }
  for (step in steps) {
    if ((range_deg / step) <= 8) {
      return(step)
    }
  }
  utils::tail(steps, 1)
}

camera_sites_create_graticule <- function(bbox_4326) {
  if (is.null(bbox_4326)) {
    return(list(lines = NULL, labels = NULL))
  }
  bb <- sf::st_bbox(bbox_4326)
  lon_range <- bb["xmax"] - bb["xmin"]
  lat_range <- bb["ymax"] - bb["ymin"]
  lon_step <- camera_sites_pick_step(lon_range)
  lat_step <- camera_sites_pick_step(lat_range)
  lon_seq <- seq(
    floor(bb["xmin"] / lon_step) * lon_step,
    ceiling(bb["xmax"] / lon_step) * lon_step,
    by = lon_step
  )
  lat_seq <- seq(
    floor(bb["ymin"] / lat_step) * lat_step,
    ceiling(bb["ymax"] / lat_step) * lat_step,
    by = lat_step
  )
  lon_seq <- unique(lon_seq)
  lat_seq <- unique(lat_seq)
  if (length(lon_seq) < 2 || length(lat_seq) < 2) {
    return(list(lines = NULL, labels = NULL))
  }

  grid <- sf::st_graticule(
    lon = lon_seq,
    lat = lat_seq,
    xlim = c(bb["xmin"], bb["xmax"]),
    ylim = c(bb["ymin"], bb["ymax"])
  )

  has_lwgeom <- requireNamespace("lwgeom", quietly = TRUE)
  if (isTRUE(has_lwgeom)) {
    grid <- sf::st_segmentize(grid, dfMaxLength = 25 * 1000)
    grid <- sf::st_make_valid(grid)
  } else {
    rlang::warn(
      paste(
        "Package 'lwgeom' is not installed; skipping graticule densification.",
        "Install lwgeom for smoother graticules in geographic coordinates."
      ),
      class = "localmap_missing_lwgeom"
    )
  }

  xmin <- as.numeric(bb[["xmin"]])
  xmax <- as.numeric(bb[["xmax"]])
  ymin <- as.numeric(bb[["ymin"]])
  ymax <- as.numeric(bb[["ymax"]])
  bbox_sfc <- sf::st_as_sfc(bb)
  bbox_3857 <- sf::st_transform(bbox_sfc, 3857)
  grid_3857 <- sf::st_transform(grid, 3857)
  grid_geom <- sf::st_geometry(grid_3857)
  grid_clipped <- sf::st_intersection(grid_geom, bbox_3857)
  grid_sf <- sf::st_as_sf(grid_clipped)
  grid_sf$id <- seq_len(nrow(grid_sf))
  grid_sf <- sf::st_set_agr(grid_sf, "constant")
  row.names(grid_sf) <- NULL

  format_lon <- function(x) {
    dir <- ifelse(x >= 0, "E", "W")
    sprintf("%.2f\u00b0%s", abs(x), dir)
  }
  format_lat <- function(y) {
    dir <- ifelse(y >= 0, "N", "S")
    sprintf("%.2f\u00b0%s", abs(y), dir)
  }

  lon_offset <- lon_range * 0.02
  lat_offset <- lat_range * 0.02
  if (!is.finite(lon_offset) || lon_offset <= 0) lon_offset <- 0.02
  if (!is.finite(lat_offset) || lat_offset <= 0) lat_offset <- 0.02

  lon_labels <- sf::st_as_sf(
    data.frame(
      lon = lon_seq,
      lat = rep(ymin + lat_offset, length(lon_seq)),
      label = format_lon(lon_seq)
    ),
    coords = c("lon", "lat"),
    crs = 4326,
    remove = FALSE
  )

  lat_labels <- sf::st_as_sf(
    data.frame(
      lon = rep(xmax - lon_offset, length(lat_seq)),
      lat = lat_seq,
      label = format_lat(lat_seq)
    ),
    coords = c("lon", "lat"),
    crs = 4326,
    remove = FALSE
  )

  labels <- rbind(lon_labels, lat_labels)
  inside <- sf::st_intersects(labels, bbox_sfc, sparse = FALSE)
  if (!is.null(dim(inside))) {
    inside <- inside[, 1]
  }
  labels <- labels[inside, , drop = FALSE]
  labels_3857 <- sf::st_transform(labels, 3857)
  labels_3857 <- sf::st_as_sf(labels_3857)
  labels_3857$id <- seq_len(nrow(labels_3857))
  labels_3857 <- sf::st_set_agr(labels_3857, "constant")
  row.names(labels_3857) <- NULL

  list(lines = grid_sf, labels = labels_3857)
}
