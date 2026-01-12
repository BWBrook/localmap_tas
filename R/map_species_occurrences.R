#' Map species occurrence records
#'
#' Generates a static map depicting species occurrence points within a user
#' defined AOI or bounding box. The AOI is preferred when supplied, otherwise
#' the bounding box is derived from configuration settings (top-left coordinate
#' and side length in kilometres). The output is written to an image file to be
#' tracked by the `{targets}` pipeline.
#'
#' @param occurrences Tibble or data frame of occurrence records containing at
#'   least `longitude`, `latitude`, and `species_id` columns.
#' @param mapping_settings Optional list with entries such as `bounding_box`,
#'   `basemap`, `output_path`, appearance toggles (`show_title`, `show_legend`),
#'   point styling, and an optional `additional_points` list containing `path`,
#'   `colour`, and `size`. Typically sourced from `config/config.yaml`.
#' @param aoi Optional AOI list returned by `build_aoi_from_config()`; overrides
#'   `mapping_settings$bounding_box` when provided.
#' @param output_path Optional override for the output image path. When `NULL`,
#'   the value from `mapping_settings$output_path` is used; if that is also
#'   missing, defaults to `here::here("outputs", "maps",
#'   "species_occurrences.png")`.
#' @return The path (character scalar) to the generated map image.
#' @export
map_species_occurrences <- function(occurrences,
                                    mapping_settings = NULL,
                                    aoi = NULL,
                                    output_path = NULL) {
  checkmate::assert_data_frame(occurrences, min.rows = 0L)

  mapping_settings <- validate_mapping_settings(mapping_settings)
  defaults <- list(
    show_title = FALSE,
    show_legend = FALSE,
    point_colour = "#2171b5",
    point_size = 1.6,
    additional_points = list(
      path = NULL,
      colour = "#d73027",
      size = NULL
    )
  )
  mapping_settings <- utils::modifyList(defaults, mapping_settings)

  checkmate::assert_numeric(mapping_settings$point_size, len = 1L, lower = 0)
  checkmate::assert_string(mapping_settings$point_colour, min.chars = 1L)

  additional_cfg <- mapping_settings$additional_points
  if (!is.null(additional_cfg$colour)) {
    checkmate::assert_string(additional_cfg$colour, min.chars = 1L)
  }
  if (!is.null(additional_cfg$size)) {
    checkmate::assert_numeric(additional_cfg$size, len = 1L, lower = 0)
  }
  additional_points_sf <- load_additional_points(additional_cfg)

  bbox <- resolve_occurrence_bbox(mapping_settings, aoi = aoi)

  basemap <- mapping_settings$basemap
  if (is.null(basemap)) {
    basemap <- "rnaturalearth"
  }
  basemap <- match.arg(basemap, choices = c("rnaturalearth", "none"))

  if (is.null(output_path)) {
    output_path <- mapping_settings$output_path
  }
  if (is.null(output_path)) {
    output_path <- here::here("outputs", "maps", "species_occurrences.png")
  }
  checkmate::assert_string(output_path, min.chars = 1L)

  coord_cols <- c("longitude", "latitude")
  if (!all(coord_cols %in% names(occurrences))) {
    rlang::abort(
      c(
        "Occurrence data must contain `longitude` and `latitude` columns.",
        i = "Ensure ala_fetch_occurrences() retains these columns."
      ),
      class = "map_species_occurrences_missing_coords"
    )
  }
  has_coords <- !is.na(occurrences$longitude) & !is.na(occurrences$latitude)
  occurrences <- occurrences[has_coords, , drop = FALSE]

  bbox_bb <- sf::st_bbox(bbox)

  basemap_sf <- NULL
  if (identical(basemap, "rnaturalearth")) {
    basemap_sf <- get_basemap_tasmania(bbox)
  }

  occurrences_sf <- sf::st_as_sf(
    occurrences,
    coords = c("longitude", "latitude"),
    crs = 4326,
    remove = FALSE
  )

  if (nrow(occurrences_sf) > 0L) {
    occurrences_sf <- sf::st_filter(occurrences_sf, bbox, .predicate = sf::st_within)
  }

  if (!"species_id" %in% names(occurrences_sf)) {
    rlang::warn(
      "`species_id` column missing; colouring by species will fallback to \"occurrence\"."
    )
    occurrences_sf$species_id <- "occurrence"
  }

  label_fields <- c(
    "matched_common_name",
    "matched_scientific_name",
    "query_scientific_name",
    "query_common_name",
    "species_id"
  )
  available_labels <- intersect(label_fields, names(occurrences_sf))
  if (length(available_labels) == 0L) {
    occurrences_sf$species_label <- "occurrence"
  } else {
    occurrences_sf <- dplyr::mutate(
      occurrences_sf,
      species_label = dplyr::coalesce(!!!rlang::syms(available_labels))
    )
  }

  plot_obj <- ggplot2::ggplot()
  if (!is.null(basemap_sf)) {
    plot_obj <- plot_obj +
      ggplot2::geom_sf(data = basemap_sf, fill = "#f3f3f3", colour = "#b0b0b0", linewidth = 0.3)
  }
  if (nrow(occurrences_sf) > 0L) {
    plot_obj <- plot_obj +
      ggplot2::geom_sf(
        data = occurrences_sf,
        colour = mapping_settings$point_colour,
        alpha = 0.8,
        size = mapping_settings$point_size
      )
  }

  if (!is.null(additional_points_sf) && nrow(additional_points_sf) > 0L) {
    extra_size <- additional_cfg$size
    if (is.null(extra_size)) {
      extra_size <- mapping_settings$point_size
    }
    plot_obj <- plot_obj +
      ggplot2::geom_sf(
        data = additional_points_sf,
        colour = additional_cfg$colour,
        alpha = 0.9,
        size = extra_size
      )
  }

  plot_obj <- plot_obj +
    ggplot2::coord_sf(
      xlim = c(bbox_bb["xmin"], bbox_bb["xmax"]),
      ylim = c(bbox_bb["ymin"], bbox_bb["ymax"]),
      expand = FALSE
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = if (isTRUE(mapping_settings$show_legend)) "bottom" else "none")

  if (isTRUE(mapping_settings$show_title)) {
    subtitle <- sprintf(
      "Bounding box: (%.3f, %.3f)-(%.3f, %.3f)",
      bbox_bb["xmin"],
      bbox_bb["ymin"],
      bbox_bb["xmax"],
      bbox_bb["ymax"]
    )
    plot_obj <- plot_obj +
      ggplot2::labs(
        title = "Species occurrences",
        subtitle = subtitle,
        x = "Longitude",
        y = "Latitude"
      )
  } else {
    plot_obj <- plot_obj + ggplot2::labs(x = "Longitude", y = "Latitude")
  }

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(filename = output_path, plot = plot_obj, width = 7, height = 7, dpi = 300)

  output_path
}

validate_mapping_settings <- function(mapping_settings) {
  if (is.null(mapping_settings)) {
    return(list())
  }
  checkmate::assert_list(mapping_settings, any.missing = FALSE)
  mapping_settings
}

resolve_occurrence_bbox <- function(mapping_settings, aoi = NULL) {
  if (!is.null(aoi)) {
    aoi_geom <- aoi
    if (is.list(aoi) && !is.null(aoi$bbox_4326)) {
      return(aoi$bbox_4326)
    }
    if (is.list(aoi) && !is.null(aoi$aoi)) {
      aoi_geom <- aoi$aoi
    }
    if (!inherits(aoi_geom, c("sfc", "sf"))) {
      rlang::abort("AOI must be an sf polygon.", class = "map_species_occurrences_invalid_aoi")
    }
    aoi_4326 <- sf::st_transform(aoi_geom, 4326)
    return(sf::st_as_sfc(sf::st_bbox(aoi_4326)))
  }

  bbox_cfg <- mapping_settings$bounding_box
  if (is.null(bbox_cfg)) {
    rlang::abort(
      c(
        "A bounding box configuration is required for mapping.",
        i = "Set cfg$data$occurrence$map$bounding_box in config/config.yaml"
      ),
      class = "map_species_occurrences_no_bbox"
    )
  }

  top_left <- bbox_cfg$top_left
  if (is.null(top_left)) {
    rlang::abort(
      "Bounding box must include a `top_left` coordinate.",
      class = "map_species_occurrences_missing_top_left"
    )
  }
  top_left_vec <- coerce_top_left(top_left)

  length_km <- bbox_cfg$length_km
  checkmate::assert_numeric(length_km, len = 1L, lower = 1e-6)
  side_length <- as.numeric(length_km)

  build_square_bbox(top_left_vec, side_length)
}

coerce_top_left <- function(value) {
  if (is.list(value) && all(c("lat", "lon") %in% names(value))) {
    lat <- as.numeric(value$lat)
    lon <- as.numeric(value$lon)
    coords <- c(lat, lon)
  } else {
    coords <- as.numeric(unlist(value, use.names = FALSE))
  }
  checkmate::assert_numeric(coords, len = 2L, any.missing = FALSE)
  c(lat = coords[[1]], lon = coords[[2]])
}

load_additional_points <- function(cfg) {
  if (is.null(cfg) || (!is.list(cfg))) {
    return(NULL)
  }

  path <- cfg$path
  if (is.null(path) || !is.character(path) || length(path) != 1L) {
    return(NULL)
  }

  candidate_paths <- unique(c(path, here::here(path)))
  resolved <- candidate_paths[file.exists(candidate_paths)][1]
  if (is.na(resolved)) {
    rlang::warn(sprintf("Additional points file not found: %s", path))
    return(NULL)
  }

  data <- try(
    readr::read_csv(resolved, show_col_types = FALSE, progress = FALSE, num_threads = 1),
    silent = TRUE
  )
  if (inherits(data, "try-error")) {
    rlang::warn(sprintf("Failed to read additional points file: %s", resolved))
    return(NULL)
  }

  required <- c("lat", "lon")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    rlang::warn(sprintf(
      "Additional points file missing columns: %s",
      paste(missing, collapse = ", ")
    ))
    return(NULL)
  }

  data <- data[!is.na(data$lat) & !is.na(data$lon), , drop = FALSE]
  if (nrow(data) == 0L) {
    rlang::warn("Additional points file contains no valid lat/lon rows.")
    return(NULL)
  }

  sf::st_as_sf(data, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
}

create_graticule <- function(bbox) {
  bb <- sf::st_bbox(bbox)
  lon_seq <- seq(floor(bb["xmin"]), ceiling(bb["xmax"]), by = 1)
  lat_seq <- seq(floor(bb["ymin"]), ceiling(bb["ymax"]), by = 1)

  if (length(lon_seq) < 2 && length(lat_seq) < 2) {
    return(NULL)
  }

  grid <- sf::st_graticule(
    lon = lon_seq,
    lat = lat_seq,
    xlim = c(bb["xmin"], bb["xmax"]),
    ylim = c(bb["ymin"], bb["ymax"])
  )
  grid <- sf::st_segmentize(grid, dfMaxLength = 25 * 1000)
  grid <- sf::st_make_valid(grid)
  bbox_sfc <- sf::st_as_sfc(bb)
  bbox_3857 <- sf::st_transform(bbox_sfc, 3857)
  grid_3857 <- sf::st_intersection(sf::st_transform(grid, 3857), bbox_3857)

  lon_offset <- (bb["xmax"] - bb["xmin"]) * 0.02
  lat_offset <- (bb["ymax"] - bb["ymin"]) * 0.02
  if (lon_offset == 0) lon_offset <- 0.01
  if (lat_offset == 0) lat_offset <- 0.01
  lat_label_offset <- (bb["xmax"] - bb["xmin"]) * 0.05
  if (lat_label_offset == 0) lat_label_offset <- 0.05

  format_lon <- function(x) {
    dir <- ifelse(x >= 0, "E", "W")
    sprintf("%.1f\u00b0%s", abs(x), dir)
  }
  format_lat <- function(y) {
    dir <- ifelse(y >= 0, "N", "S")
    sprintf("%.1f\u00b0%s", abs(y), dir)
  }

  lon_labels <- sf::st_as_sf(
    data.frame(
      lon = lon_seq,
      lat = bb["ymin"] + lat_offset,
      label = format_lon(lon_seq)
    ),
    coords = c("lon", "lat"),
    crs = 4326,
    remove = FALSE
  )

  lat_labels <- sf::st_as_sf(
    data.frame(
      lon = bb["xmin"] + lat_label_offset,
      lat = lat_seq,
      label = format_lat(lat_seq)
    ),
    coords = c("lon", "lat"),
    crs = 4326,
    remove = FALSE
  )

  labels <- rbind(lon_labels, lat_labels)
  labels <- sf::st_intersection(labels, bbox_sfc)
  labels_3857 <- sf::st_transform(labels, 3857)

  list(lines = grid_3857, labels = labels_3857)
}

#' Render a tile-based occurrence map using slippy map tiles
#'
#' Fetches map tiles for the configured bounding box (defaulting to
#' OpenTopoMap) and overlays species occurrences plus any additional points.
#'
#' @inheritParams map_species_occurrences
#' @return Path to the rendered PNG file.
#' @export
generate_topo_tile_map <- function(occurrences,
                                   mapping_settings = NULL,
                                   aoi = NULL,
                                   output_path = NULL) {
  checkmate::assert_data_frame(occurrences, min.rows = 0L)

  mapping_settings <- validate_mapping_settings(mapping_settings)
  defaults <- list(
    show_title = FALSE,
    show_legend = FALSE,
    enable_topo_tiles = TRUE,
    point_colour = "#2ca25f",
    point_size = 1.6,
    additional_points = list(
      path = NULL,
      colour = "#d73027",
      size = NULL
    ),
    tile_provider = "Esri.WorldImagery",
    tile_zoom = 8,
    tile_outline_colour = "#ffffff",
    topo_output_path = NULL,
  tile_graticule = TRUE
  )
  mapping_settings <- utils::modifyList(defaults, mapping_settings)

  enable_tiles <- mapping_settings$enable_topo_tiles
  if (is.null(enable_tiles)) {
    enable_tiles <- TRUE
  }
  checkmate::assert_logical(enable_tiles, len = 1L, any.missing = FALSE)
  if (is.null(output_path)) {
    output_path <- mapping_settings$topo_output_path
  }
  if (!isTRUE(enable_tiles)) {
    return(map_species_occurrences(occurrences, mapping_settings, aoi = aoi, output_path))
  }

  checkmate::assert_numeric(mapping_settings$point_size, len = 1L, lower = 0)
  checkmate::assert_string(mapping_settings$point_colour, min.chars = 1L)
  checkmate::assert_string(mapping_settings$tile_provider, min.chars = 1L)
  checkmate::assert_numeric(mapping_settings$tile_zoom, len = 1L, lower = 0)
  checkmate::assert_string(mapping_settings$tile_outline_colour, min.chars = 1L)
  checkmate::assert_logical(mapping_settings$tile_graticule, len = 1L, any.missing = FALSE)

  additional_cfg <- mapping_settings$additional_points
  if (!is.null(additional_cfg$colour)) {
    checkmate::assert_string(additional_cfg$colour, min.chars = 1L)
  }
  if (!is.null(additional_cfg$size)) {
    checkmate::assert_numeric(additional_cfg$size, len = 1L, lower = 0)
  }

  additional_points_sf <- load_additional_points(additional_cfg)

  bbox <- try(resolve_occurrence_bbox(mapping_settings, aoi = aoi), silent = TRUE)
  if (inherits(bbox, "try-error")) {
    rlang::warn("Bounding box configuration missing; falling back to default species map.")
    return(map_species_occurrences(occurrences, mapping_settings, aoi = aoi, output_path))
  }

  if (is.null(output_path)) {
    output_path <- here::here("outputs", "maps", "species_topo.png")
  }
  checkmate::assert_string(output_path, min.chars = 1L)

  coord_cols <- c("longitude", "latitude")
  if (!all(coord_cols %in% names(occurrences))) {
    rlang::warn(
      "Occurrence data missing longitude/latitude columns; falling back to default species map."
    )
    return(map_species_occurrences(occurrences, mapping_settings, aoi = aoi, output_path))
  }

  has_coords <- !is.na(occurrences$longitude) & !is.na(occurrences$latitude)
  occurrences <- occurrences[has_coords, , drop = FALSE]

  bbox_3857 <- sf::st_transform(bbox, 3857)

  occurrences_sf <- sf::st_as_sf(
    occurrences,
    coords = c("longitude", "latitude"),
    crs = 4326,
    remove = FALSE
  )
  if (nrow(occurrences_sf) > 0L) {
    occurrences_sf <- sf::st_filter(occurrences_sf, bbox, .predicate = sf::st_within)
  }
  occurrences_sf <- sf::st_transform(occurrences_sf, 3857)

  if (!is.null(additional_points_sf) && nrow(additional_points_sf) > 0L) {
    additional_points_sf <- sf::st_filter(additional_points_sf, bbox, .predicate = sf::st_within)
    if (nrow(additional_points_sf) > 0L) {
      additional_points_sf <- sf::st_transform(additional_points_sf, 3857)
    } else {
      additional_points_sf <- NULL
    }
  } else {
    additional_points_sf <- NULL
  }

  outline_sf <- get_basemap_tasmania(bbox)
  if (!is.null(outline_sf) && nrow(outline_sf) > 0L) {
    outline_sf <- sf::st_transform(outline_sf, 3857)
  }

  tiles <- try(
    maptiles::get_tiles(
      x = bbox_3857,
      provider = mapping_settings$tile_provider,
      zoom = as.integer(mapping_settings$tile_zoom),
      crop = TRUE
    ),
    silent = TRUE
  )
  if (inherits(tiles, "try-error")) {
    rlang::warn(sprintf(
      "Failed to retrieve tiles from provider '%s'; falling back to default species map.",
      mapping_settings$tile_provider
    ))
    return(map_species_occurrences(occurrences, mapping_settings, aoi = aoi, output_path))
  }

  plot_obj <- ggplot2::ggplot() +
    tidyterra::geom_spatraster_rgb(data = tiles)

  if (!is.null(outline_sf) && nrow(outline_sf) > 0L) {
    plot_obj <- plot_obj +
      ggplot2::geom_sf(
        data = outline_sf,
        fill = NA,
        colour = mapping_settings$tile_outline_colour,
        linewidth = 0.4
      )
  }

  if (nrow(occurrences_sf) > 0L) {
    plot_obj <- plot_obj +
      ggplot2::geom_sf(
        data = occurrences_sf,
        colour = mapping_settings$point_colour,
        alpha = 0.8,
        size = mapping_settings$point_size
      )
  }

  if (!is.null(additional_points_sf) && nrow(additional_points_sf) > 0L) {
    extra_size <- additional_cfg$size
    if (is.null(extra_size)) {
      extra_size <- mapping_settings$point_size
    }
    plot_obj <- plot_obj +
      ggplot2::geom_sf(
        data = additional_points_sf,
        colour = additional_cfg$colour,
        alpha = 0.9,
        size = extra_size
      )
  }

  plot_obj <- plot_obj +
    ggplot2::coord_sf(crs = sf::st_crs(3857), expand = FALSE)

  if (isTRUE(mapping_settings$tile_graticule)) {
    grid <- create_graticule(bbox)
    if (!is.null(grid)) {
      plot_obj <- plot_obj +
        ggplot2::geom_sf(
          data = grid$lines,
          colour = mapping_settings$tile_outline_colour,
          linewidth = 0.1,
          alpha = 0.6
        )
      if (!is.null(grid$labels) && nrow(grid$labels) > 0L) {
        plot_obj <- plot_obj +
          ggplot2::geom_sf_text(
            data = grid$labels,
            ggplot2::aes(label = .data$label),
            colour = mapping_settings$tile_outline_colour,
            size = 2.8,
            check_overlap = TRUE
          )
      }
    }
  }

  plot_obj <- plot_obj + ggplot2::theme_void()

  if (isTRUE(mapping_settings$show_title)) {
    bbox_bb <- sf::st_bbox(bbox)
    subtitle <- sprintf(
      "Bounding box: (%.3f, %.3f)-(%.3f, %.3f)",
      bbox_bb["xmin"],
      bbox_bb["ymin"],
      bbox_bb["xmax"],
      bbox_bb["ymax"]
    )
    plot_obj <- plot_obj +
      ggplot2::labs(
        title = "Species occurrences",
        subtitle = subtitle
      )
  }

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(filename = output_path, plot = plot_obj, width = 8, height = 8, dpi = 300)

  output_path
}

build_square_bbox <- function(top_left, side_length_km) {
  start <- c(lon = top_left[["lon"]], lat = top_left[["lat"]])
  metres <- side_length_km * 1000

  normalize_lonlat <- function(coord) {
    vals <- as.numeric(coord)
    if (length(vals) != 2L || any(is.na(vals))) {
      rlang::abort(
        "destPoint returned invalid coordinates when constructing bounding box.",
        class = "map_species_occurrences_invalid_bbox"
      )
    }
    structure(vals, names = c("lon", "lat"))
  }

  top_right <- normalize_lonlat(geosphere::destPoint(start, b = 90, d = metres))
  bottom_left <- normalize_lonlat(geosphere::destPoint(start, b = 180, d = metres))
  bottom_right <- normalize_lonlat(geosphere::destPoint(bottom_left, b = 90, d = metres))

  coords <- rbind(
    c(start[["lon"]], start[["lat"]]),
    c(top_right[["lon"]], top_right[["lat"]]),
    c(bottom_right[["lon"]], bottom_right[["lat"]]),
    c(bottom_left[["lon"]], bottom_left[["lat"]]),
    c(start[["lon"]], start[["lat"]])
  )

  sf::st_sfc(sf::st_polygon(list(coords)), crs = 4326)
}

get_basemap_tasmania <- function(bbox) {
  australia <- rnaturalearthdata::countries50
  australia <- australia[australia$admin == "Australia", , drop = FALSE]
  australia <- sf::st_make_valid(australia)
  bbox_sfc <- sf::st_as_sfc(sf::st_bbox(bbox))
  clipped <- sf::st_intersection(sf::st_geometry(australia), bbox_sfc)
  sf::st_as_sf(clipped)
}
