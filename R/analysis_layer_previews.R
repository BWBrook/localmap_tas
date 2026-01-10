# Render quick-look PNG previews for analysis layers.

render_analysis_layer_previews <- function(analysis_layers,
                                           aoi = NULL,
                                           sites = NULL,
                                           preview_cfg = NULL) {
  if (is.null(analysis_layers) || !is.data.frame(analysis_layers) || nrow(analysis_layers) == 0L) {
    return(tibble::tibble(id = character(), path = character(), type = character()))
  }

  defaults <- list(width = 900, height = 900, dpi = 120, overwrite = FALSE)
  preview_cfg <- utils::modifyList(defaults, preview_cfg %||% list())

  aoi_geom <- NULL
  if (!is.null(aoi)) {
    if (is.list(aoi) && !is.null(aoi$aoi)) {
      aoi_geom <- aoi$aoi
    } else if (inherits(aoi, c("sf", "sfc"))) {
      aoi_geom <- aoi
    }
  }

  results <- vector("list", length = nrow(analysis_layers))
  for (idx in seq_len(nrow(analysis_layers))) {
    layer_id <- as.character(analysis_layers$id[[idx]])
    layer_type <- as.character(analysis_layers$type[[idx]])
    source_path <- as.character(analysis_layers$path[[idx]])
    if (!file.exists(source_path)) {
      rlang::warn(sprintf("Analysis layer preview skipped; file missing: %s", source_path))
      next
    }
    preview_path <- analysis_preview_path(source_path)
    if (!isTRUE(preview_cfg$overwrite) &&
          file.exists(preview_path) &&
          file.mtime(preview_path) >= file.mtime(source_path)) {
      results[[idx]] <- tibble::tibble(id = layer_id, path = preview_path, type = layer_type)
      next
    }
    if (analysis_layer_is_vector(layer_type, source_path)) {
      render_vector_preview(
        path = source_path,
        output_path = preview_path,
        aoi_geom = aoi_geom,
        sites = sites,
        width = preview_cfg$width,
        height = preview_cfg$height,
        dpi = preview_cfg$dpi
      )
    } else {
      render_raster_preview(
        path = source_path,
        output_path = preview_path,
        aoi_geom = aoi_geom,
        sites = sites,
        width = preview_cfg$width,
        height = preview_cfg$height,
        dpi = preview_cfg$dpi
      )
    }
    results[[idx]] <- tibble::tibble(id = layer_id, path = preview_path, type = layer_type)
  }

  dplyr::bind_rows(results)
}

analysis_preview_path <- function(path) {
  if (is.null(path) || !nzchar(path)) {
    return(NA_character_)
  }
  if (grepl("\\.[A-Za-z0-9]+$", path)) {
    return(sub("\\.[A-Za-z0-9]+$", ".png", path))
  }
  paste0(path, ".png")
}

analysis_layer_is_vector <- function(layer_type, path) {
  if (!is.null(layer_type) && layer_type %in% c("vector_file", "vector_arcgis")) {
    return(TRUE)
  }
  grepl("\\.(gpkg|geojson|shp)$", path, ignore.case = TRUE)
}

render_vector_preview <- function(path,
                                  output_path,
                                  aoi_geom,
                                  sites,
                                  width,
                                  height,
                                  dpi) {
  vec <- sf::st_read(path, quiet = TRUE)
  aoi <- NULL
  if (!is.null(aoi_geom)) {
    aoi <- try(sf::st_transform(aoi_geom, sf::st_crs(vec)), silent = TRUE)
    if (inherits(aoi, "try-error")) {
      aoi <- NULL
    }
  }
  sites_sf <- prepare_preview_sites(sites, sf::st_crs(vec))
  geom_col <- attr(vec, "sf_column")
  if (is.null(geom_col) || !nzchar(geom_col)) {
    geom_col <- "geometry"
  }
  attr_cols <- setdiff(names(vec), geom_col)
  attr_name <- pick_preview_attribute(vec, attr_cols)
  fill_values <- NULL
  fill_palette <- NULL
  if (!is.null(attr_name)) {
    fill_values <- vec[[attr_name]]
    fill_values <- as.factor(fill_values)
    levels_used <- levels(fill_values)
    fill_palette <- grDevices::hcl.colors(length(levels_used), "Set2")
  }
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  grDevices::png(filename = output_path, width = width, height = height, res = dpi)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(2, 2, 2, 2))
  if (!is.null(fill_values) && !is.null(fill_palette)) {
    colors <- fill_palette[as.integer(fill_values)]
    graphics::plot(
      sf::st_geometry(vec),
      col = colors,
      border = "#2b8cbe",
      main = tools::file_path_sans_ext(basename(path))
    )
    graphics::legend(
      "topright",
      legend = levels(fill_values),
      fill = fill_palette,
      cex = 0.7,
      bty = "n",
      title = attr_name
    )
  } else {
    graphics::plot(
      sf::st_geometry(vec),
      col = "#74a9cf",
      border = "#2b8cbe",
      main = tools::file_path_sans_ext(basename(path))
    )
  }
  if (!is.null(aoi)) {
    graphics::plot(sf::st_geometry(aoi), add = TRUE, border = "#d95f0e", lwd = 2)
  }
  if (!is.null(sites_sf)) {
    graphics::points(sf::st_coordinates(sites_sf), pch = 3, col = "#b2182b", cex = 0.8)
  }
  invisible(output_path)
}

render_raster_preview <- function(path,
                                  output_path,
                                  aoi_geom,
                                  sites,
                                  width,
                                  height,
                                  dpi) {
  rast <- terra::rast(path)
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  grDevices::png(filename = output_path, width = width, height = height, res = dpi)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(2, 2, 2, 2))
  if (terra::nlyr(rast) >= 3) {
    terra::plotRGB(
      rast,
      r = 1,
      g = 2,
      b = 3,
      stretch = "lin",
      main = tools::file_path_sans_ext(basename(path)),
      axes = FALSE
    )
  } else {
    terra::plot(
      rast,
      main = tools::file_path_sans_ext(basename(path)),
      axes = FALSE
    )
  }
  if (!is.null(aoi_geom)) {
    aoi_vec <- try(terra::vect(sf::st_transform(aoi_geom, terra::crs(rast))), silent = TRUE)
    if (!inherits(aoi_vec, "try-error")) {
      terra::plot(aoi_vec, add = TRUE, border = "#d95f0e", lwd = 1.5)
    }
  }
  sites_sf <- prepare_preview_sites(sites, terra::crs(rast))
  if (!is.null(sites_sf)) {
    graphics::points(sf::st_coordinates(sites_sf), pch = 3, col = "#b2182b", cex = 0.8)
  }
  graphics::box()
  invisible(output_path)
}

prepare_preview_sites <- function(sites, target_crs) {
  if (is.null(sites)) {
    return(NULL)
  }
  sites_sf <- NULL
  if (inherits(sites, c("sf", "sfc"))) {
    sites_sf <- sites
  } else if (is.data.frame(sites) && all(c("lon", "lat") %in% names(sites))) {
    sites_sf <- sf::st_as_sf(sites, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
  }
  if (is.null(sites_sf)) {
    return(NULL)
  }
  transformed <- try(sf::st_transform(sites_sf, target_crs), silent = TRUE)
  if (inherits(transformed, "try-error")) {
    return(NULL)
  }
  transformed
}

pick_preview_attribute <- function(vec, attr_cols) {
  if (length(attr_cols) == 0L) {
    return(NULL)
  }
  preferred <- c("habitat", "class", "type", "zone")
  for (candidate in preferred) {
    if (candidate %in% attr_cols) {
      return(candidate)
    }
  }
  unique_counts <- vapply(attr_cols, function(col) {
    length(unique(vec[[col]]))
  }, integer(1))
  attr_cols[[which.min(unique_counts)]]
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
