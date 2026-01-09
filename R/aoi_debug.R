#' Render a debug plot for the current AOI
#'
#' @param aoi List returned by `build_aoi_from_config()` or an `sf` polygon.
#' @param sites Optional data.frame with `lat` and `lon` columns to overlay.
#' @param output_path Output PNG path.
#' @return Path to the rendered PNG file.
render_aoi_debug_plot <- function(aoi,
                                  sites = NULL,
                                  output_path = NULL) {
  if (is.null(aoi)) {
    rlang::abort("`aoi` is required.", class = "aoi_debug_invalid_aoi")
  }

  aoi_geom <- aoi
  if (is.list(aoi) && !is.null(aoi$aoi)) {
    aoi_geom <- aoi$aoi
  }
  if (!inherits(aoi_geom, c("sfc", "sf"))) {
    rlang::abort("`aoi` must be an sf/sfc polygon.", class = "aoi_debug_invalid_aoi")
  }

  aoi_4326 <- sf::st_transform(aoi_geom, 4326)
  bbox_4326 <- sf::st_as_sfc(sf::st_bbox(aoi_4326))

  if (is.null(output_path)) {
    output_path <- here::here("outputs", "maps", "aoi_debug.png")
  }
  checkmate::assert_string(output_path, min.chars = 1L)
  outline_sf <- get_basemap_tasmania(bbox_4326)

  sites_sf <- NULL
  if (!is.null(sites)) {
    checkmate::assert_data_frame(sites, min.rows = 0L)
    if (all(c("lat", "lon") %in% names(sites))) {
      valid <- !is.na(sites$lat) & !is.na(sites$lon)
      sites <- sites[valid, , drop = FALSE]
      if (nrow(sites) > 0L) {
        sites_sf <- sf::st_as_sf(sites, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
      }
    }
  }

  centroid <- sf::st_centroid(aoi_4326)
  plot_obj <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = outline_sf, fill = "grey95", colour = "grey70", linewidth = 0.4) +
    ggplot2::geom_sf(data = aoi_4326, fill = NA, colour = "#d95f0e", linewidth = 0.7) +
    ggplot2::geom_sf(data = centroid, colour = "#d95f0e", size = 2)

  if (!is.null(sites_sf) && nrow(sites_sf) > 0L) {
    plot_obj <- plot_obj +
      ggplot2::geom_sf(data = sites_sf, colour = "#2c7fb8", size = 2, alpha = 0.8)
  }

  plot_obj <- plot_obj +
    ggplot2::coord_sf(expand = FALSE) +
    ggplot2::labs(x = "Longitude", y = "Latitude", title = "AOI Debug (bounding box)")

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(filename = output_path, plot = plot_obj, width = 7, height = 7, dpi = 300)

  output_path
}
