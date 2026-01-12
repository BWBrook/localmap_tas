# Site attribute extraction (raster + vector) and output products.

#' Build canonical long table of site attributes
#'
#' @param sites Data frame with `site`, `lat`, `lon`.
#' @param analysis_layers Tibble from `fetch_analysis_layers()`.
#' @return Tibble of site attributes in long form.
#' @export
build_site_attributes_long <- function(sites, analysis_layers) {
  if (is.null(sites) || !is.data.frame(sites) || nrow(sites) == 0L) {
    return(empty_site_attributes())
  }
  required <- c("site", "lat", "lon")
  if (!all(required %in% names(sites))) {
    rlang::abort(
      sprintf("Sites table missing required columns: %s", paste(required, collapse = ", ")),
      class = "site_attributes_missing_sites"
    )
  }

  if (is.null(analysis_layers) || !is.data.frame(analysis_layers) || nrow(analysis_layers) == 0L) {
    return(empty_site_attributes())
  }

  raster_types <- c("raster_file", "raster_arcgis", "derived_slope", "derived_ndvi", "derived_nbr")
  vector_types <- c("vector_file", "vector_arcgis")

  raster_layers <- analysis_layers[analysis_layers$type %in% raster_types, , drop = FALSE]
  vector_layers <- analysis_layers[analysis_layers$type %in% vector_types, , drop = FALSE]

  raster_long <- extract_raster_attributes(sites, raster_layers)
  vector_long <- extract_vector_attributes(sites, vector_layers)

  combined <- dplyr::bind_rows(raster_long, vector_long)
  if (nrow(combined) == 0L) {
    return(empty_site_attributes())
  }

  combined <- combined |>
    dplyr::mutate(
      site_id = as.character(.data$site_id),
      layer_id = as.character(.data$layer_id),
      attribute_name = as.character(.data$attribute_name),
      value = ifelse(is.na(.data$value), NA_character_, as.character(.data$value)),
      units = ifelse(is.na(.data$units), NA_character_, as.character(.data$units)),
      layer_type = as.character(.data$layer_type),
      source_id = ifelse(is.na(.data$source_id), NA_character_, as.character(.data$source_id)),
      provenance_path = as.character(.data$provenance_path)
    ) |>
    dplyr::arrange(.data$site_id, .data$layer_id, .data$attribute_name)

  combined
}

#' Write canonical long table as parquet
#'
#' @param attributes Long attributes tibble.
#' @param output_path Output parquet path.
#' @return Output path.
#' @export
write_site_attributes_long <- function(attributes, output_path = NULL) {
  if (is.null(output_path) || !nzchar(output_path)) {
    output_path <- here::here("outputs", "tables", "default", "site_attributes_long.parquet")
  }
  checkmate::assert_string(output_path, min.chars = 1L)
  if (!requireNamespace("arrow", quietly = TRUE)) {
    rlang::abort(
      c(
        "Package 'arrow' is required to write parquet outputs.",
        i = "Install arrow or choose a CSV output format."
      ),
      class = "site_attributes_missing_arrow"
    )
  }
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  arrow::write_parquet(attributes, output_path)
  output_path
}

#' Write convenience wide table as CSV
#'
#' @param attributes Long attributes tibble.
#' @param output_path Output CSV path.
#' @return Output path.
#' @export
write_site_attributes_wide <- function(attributes, output_path = NULL) {
  if (is.null(output_path) || !nzchar(output_path)) {
    output_path <- here::here("outputs", "tables", "default", "site_attributes_wide.csv")
  }
  checkmate::assert_string(output_path, min.chars = 1L)

  if (nrow(attributes) == 0L) {
    wide <- tibble::tibble(site_id = character())
  } else {
    wide <- attributes |>
      dplyr::mutate(
        column_id = paste0(.data$layer_id, "__", .data$attribute_name)
      ) |>
      dplyr::select(dplyr::all_of(c("site_id", "column_id", "value"))) |>
      tidyr::pivot_wider(
        names_from = "column_id",
        values_from = "value",
        values_fill = NA_character_
      ) |>
      dplyr::arrange(.data$site_id)
  }

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(wide, output_path, row.names = FALSE, na = "NA")
  output_path
}

extract_raster_attributes <- function(sites, raster_layers) {
  if (is.null(raster_layers) || nrow(raster_layers) == 0L) {
    return(empty_site_attributes())
  }
  sites_sf <- sf::st_as_sf(sites, coords = c("lon", "lat"), crs = 4326, remove = FALSE)

  output <- lapply(seq_len(nrow(raster_layers)), function(idx) {
    layer <- raster_layers[idx, , drop = FALSE]
    path <- as.character(layer$path[[1]])
    if (!file.exists(path)) {
      rlang::abort(
        sprintf("Raster layer missing for extraction: %s", path),
        class = "site_attributes_raster_missing"
      )
    }
    rast <- terra::rast(path)
    sites_proj <- sf::st_transform(sites_sf, terra::crs(rast))
    points <- terra::vect(sites_proj)
    vals <- terra::extract(rast, points)
    if (nrow(vals) == 0L) {
      return(NULL)
    }
    band_names_raw <- names(vals)[names(vals) != "ID"]
    values_mat <- vals[, band_names_raw, drop = FALSE]
    if (length(band_names_raw) == 0L) {
      band_names_raw <- paste0("band_", seq_len(terra::nlyr(rast)))
      names(values_mat) <- band_names_raw
    }
    band_names <- band_names_raw
    if (terra::nlyr(rast) == 1L &&
          length(band_names_raw) == 1L &&
          grepl("^lyr\\.", band_names_raw)) {
      band_names <- "value"
      names(values_mat) <- band_names
    }
    values_mat$site_id <- sites$site[vals$ID]
    values_long <- tidyr::pivot_longer(
      values_mat,
      cols = tidyselect::all_of(band_names),
      names_to = "attribute_name",
      values_to = "value"
    )
    values_long$layer_id <- layer$id[[1]]
    values_long$layer_type <- layer$type[[1]]
    values_long$units <- if ("units" %in% names(layer)) layer$units[[1]] else NA_character_
    values_long$source_id <- if ("source_id" %in% names(layer)) {
      layer$source_id[[1]]
    } else {
      NA_character_
    }
    values_long$provenance_path <- layer$provenance_path[[1]]
    values_long$value <- as.character(values_long$value)
    values_long
  })

  dplyr::bind_rows(output)
}

extract_vector_attributes <- function(sites, vector_layers) {
  if (is.null(vector_layers) || nrow(vector_layers) == 0L) {
    return(empty_site_attributes())
  }
  sites_sf <- sf::st_as_sf(sites, coords = c("lon", "lat"), crs = 4326, remove = FALSE)

  output <- lapply(seq_len(nrow(vector_layers)), function(idx) {
    layer <- vector_layers[idx, , drop = FALSE]
    path <- as.character(layer$path[[1]])
    if (!file.exists(path)) {
      rlang::abort(
        sprintf("Vector layer missing for extraction: %s", path),
        class = "site_attributes_vector_missing"
      )
    }
    vec <- sf::st_read(path, quiet = TRUE)
    geom_col <- attr(vec, "sf_column")
    if (is.null(geom_col) || !nzchar(geom_col)) {
      geom_col <- "geometry"
    }
    fields <- setdiff(names(vec), geom_col)
    if (length(fields) == 0L) {
      return(NULL)
    }
    sites_proj <- sf::st_transform(sites_sf, sf::st_crs(vec))
    matches <- sf::st_intersects(sites_proj, vec)
    values <- lapply(seq_along(matches), function(i) {
      idxs <- matches[[i]]
      if (length(idxs) == 0L) {
        return(rep(NA_character_, length(fields)))
      }
      row <- vec[idxs[1], fields, drop = TRUE]
      vapply(row, function(x) {
        if (length(x) == 0L) {
          return(NA_character_)
        }
        as.character(x[[1]])
      }, character(1))
    })
    values_mat <- do.call(rbind, values)
    if (!is.null(values_mat)) {
      colnames(values_mat) <- fields
    }
    values_tbl <- tibble::as_tibble(values_mat)
    names(values_tbl) <- fields
    values_tbl$site_id <- sites$site
    values_long <- tidyr::pivot_longer(
      values_tbl,
      cols = tidyselect::all_of(fields),
      names_to = "attribute_name",
      values_to = "value"
    )
    values_long$layer_id <- layer$id[[1]]
    values_long$layer_type <- layer$type[[1]]
    values_long$units <- NA_character_
    values_long$source_id <- if ("source_id" %in% names(layer)) {
      layer$source_id[[1]]
    } else {
      NA_character_
    }
    values_long$provenance_path <- layer$provenance_path[[1]]
    values_long
  })

  dplyr::bind_rows(output)
}

empty_site_attributes <- function() {
  tibble::tibble(
    site_id = character(),
    layer_id = character(),
    layer_type = character(),
    attribute_name = character(),
    value = character(),
    units = character(),
    source_id = character(),
    provenance_path = character()
  )
}
