#' Render overview map (AOI, sites, optional coverage)
#'
#' @param aoi AOI list from `build_aoi_from_config()`.
#' @param sites Data frame of site locations.
#' @param coverage Coverage list from `build_coverage_zone()`.
#' @param layers Layer registry outputs (tibble).
#' @param map_cfg Overview map configuration list.
#' @return Output path.
#' @export
render_overview_map <- function(aoi,
                                sites,
                                coverage = NULL,
                                layers = NULL,
                                map_cfg = NULL) {
  if (is.null(aoi) || !is.list(aoi) || is.null(aoi$aoi)) {
    rlang::abort("AOI is required for overview map.", class = "overview_map_missing_aoi")
  }
  checkmate::assert_data_frame(sites, min.rows = 0L)

  defaults <- list(
    output_path = here::here("outputs", "maps", "overview_map.png"),
    width = 7,
    height = 7,
    dpi = 300,
    match_aspect = TRUE,
    base_layer_id = NULL,
    overlays = list(),
    show_labels = FALSE,
    label_field = "site",
    label_size = 3,
    label_colour = "#050505",
    label_nudge_x = 0,
    label_nudge_y = 0,
    point_colour = "#2171b5",
    point_size = 2,
    point_shape = 16,
    aoi_colour = "#d95f0e",
    aoi_linewidth = 0.6,
    coverage_colour = "#2ca25f",
    coverage_alpha = 0.15,
    coverage_linewidth = 0.5,
    scale_bar_location = "bl",
    north_arrow_location = "tr"
  )
  map_cfg <- utils::modifyList(defaults, if (is.null(map_cfg)) list() else map_cfg)

  output_path <- map_cfg$output_path
  checkmate::assert_string(output_path, min.chars = 1L)

  aoi_3857 <- sf::st_transform(aoi$aoi, 3857)
  bbox <- sf::st_bbox(aoi_3857)

  width_in <- map_cfg$width
  height_in <- map_cfg$height
  match_aspect <- map_cfg$match_aspect
  if (is.null(match_aspect)) {
    match_aspect <- TRUE
  }
  if (isTRUE(match_aspect)) {
    xspan <- as.numeric(bbox["xmax"] - bbox["xmin"])
    yspan <- as.numeric(bbox["ymax"] - bbox["ymin"])
    if (is.finite(xspan) && is.finite(yspan) && xspan > 0 && yspan > 0) {
      ratio <- xspan / yspan
      if (is.null(width_in) && is.null(height_in)) {
        width_in <- 7
      }
      if (!is.null(width_in)) {
        width_in <- as.numeric(width_in)
        height_in <- width_in / ratio
      } else {
        height_in <- as.numeric(height_in)
        width_in <- height_in * ratio
      }
    }
  }

  if (is.null(width_in) || !is.finite(width_in) || width_in <= 0) {
    width_in <- 7
  }
  if (is.null(height_in) || !is.finite(height_in) || height_in <= 0) {
    height_in <- 7
  }

  sites_sf <- NULL
  if (nrow(sites) > 0L && all(c("lat", "lon") %in% names(sites))) {
    sites_sf <- sf::st_as_sf(sites, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
    sites_sf <- sf::st_transform(sites_sf, 3857)
  }

  coverage_sf <- NULL
  if (!is.null(coverage) && is.list(coverage) && inherits(coverage$polygon, "sf")) {
    coverage_sf <- sf::st_transform(coverage$polygon, 3857)
  }

  read_layer_raster <- function(layer_path, opacity = 1) {
    if (is.null(layer_path) || !nzchar(layer_path) || !file.exists(layer_path)) {
      return(NULL)
    }
    img <- try(png::readPNG(layer_path), silent = TRUE)
    if (inherits(img, "try-error")) {
      return(NULL)
    }
    if (length(dim(img)) == 2L) {
      arr <- array(1, dim = c(dim(img)[1], dim(img)[2], 4))
      arr[, , 1] <- img
      arr[, , 2] <- img
      arr[, , 3] <- img
      arr[, , 4] <- 1
      img <- arr
    }
    if (dim(img)[3] == 3L) {
      arr <- array(1, dim = c(dim(img)[1], dim(img)[2], 4))
      arr[, , 1:3] <- img
      arr[, , 4] <- 1
      img <- arr
    }
    if (dim(img)[3] == 4L) {
      img[, , 4] <- img[, , 4] * opacity
    }
    img
  }

  find_layer_path <- function(layer_id) {
    if (is.null(layer_id) || is.null(layers) || nrow(layers) == 0L) {
      return(NULL)
    }
    match <- layers[layers$id == layer_id, , drop = FALSE]
    if (nrow(match) == 0L) {
      return(NULL)
    }
    match$path[[1]]
  }

  plot_obj <- ggplot2::ggplot()

  base_path <- find_layer_path(map_cfg$base_layer_id)
  base_img <- read_layer_raster(base_path, opacity = 1)
  if (!is.null(base_img)) {
    plot_obj <- plot_obj +
      ggplot2::annotation_raster(
        base_img,
        xmin = bbox["xmin"],
        xmax = bbox["xmax"],
        ymin = bbox["ymin"],
        ymax = bbox["ymax"]
      )
  }

  if (!is.null(map_cfg$overlays) && length(map_cfg$overlays) > 0L) {
    for (overlay in map_cfg$overlays) {
      if (!is.list(overlay) || is.null(overlay$id)) {
        next
      }
      overlay_path <- find_layer_path(overlay$id)
      overlay_opacity <- overlay$opacity
      if (is.null(overlay_opacity)) overlay_opacity <- 0.5
      overlay_img <- read_layer_raster(overlay_path, opacity = overlay_opacity)
      if (!is.null(overlay_img)) {
        plot_obj <- plot_obj +
          ggplot2::annotation_raster(
            overlay_img,
            xmin = bbox["xmin"],
            xmax = bbox["xmax"],
            ymin = bbox["ymin"],
            ymax = bbox["ymax"]
          )
      }
    }
  }

  if (!is.null(coverage_sf)) {
    plot_obj <- plot_obj +
      ggplot2::geom_sf(
        data = coverage_sf,
        fill = map_cfg$coverage_colour,
        alpha = map_cfg$coverage_alpha,
        colour = map_cfg$coverage_colour,
        linewidth = map_cfg$coverage_linewidth
      )
  }

  plot_obj <- plot_obj +
    ggplot2::geom_sf(
      data = aoi_3857,
      fill = NA,
      colour = map_cfg$aoi_colour,
      linewidth = map_cfg$aoi_linewidth
    )

  if (!is.null(sites_sf) && nrow(sites_sf) > 0L) {
    plot_obj <- plot_obj +
      ggplot2::geom_sf(
        data = sites_sf,
        colour = map_cfg$point_colour,
        size = map_cfg$point_size,
        shape = map_cfg$point_shape
      )
    if (isTRUE(map_cfg$show_labels)) {
      label_field <- map_cfg$label_field
      if (!is.null(label_field) && label_field %in% names(sites_sf)) {
        coords <- sf::st_coordinates(sites_sf)
        labels <- sites_sf[[label_field]]
        plot_obj <- plot_obj +
          ggplot2::geom_text(
            data = data.frame(
              x = coords[, 1],
              y = coords[, 2],
              label = labels
            ),
            ggplot2::aes(x = .data$x, y = .data$y, label = .data$label),
            size = map_cfg$label_size,
            colour = map_cfg$label_colour,
            nudge_x = map_cfg$label_nudge_x,
            nudge_y = map_cfg$label_nudge_y
          )
      }
    }
  }

  plot_obj <- plot_obj +
    ggplot2::coord_sf(
      crs = sf::st_crs(3857),
      xlim = c(bbox["xmin"], bbox["xmax"]),
      ylim = c(bbox["ymin"], bbox["ymax"]),
      expand = FALSE
    ) +
    ggplot2::theme_void() +
    ggspatial::annotation_scale(
      location = map_cfg$scale_bar_location,
      style = "ticks",
      text_cex = 0.7
    ) +
    ggspatial::annotation_north_arrow(
      location = map_cfg$north_arrow_location,
      which_north = "true",
      style = ggspatial::north_arrow_orienteering(text_size = 6)
    )

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(
    filename = output_path,
    plot = plot_obj,
    width = width_in,
    height = height_in,
    dpi = map_cfg$dpi
  )
  output_path
}
