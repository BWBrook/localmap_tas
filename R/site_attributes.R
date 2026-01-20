# Site attribute extraction (raster + vector) and output products.

#' Build canonical long table of site attributes
#'
#' @param sites Data frame with `site`, `lat`, `lon`.
#' @param analysis_layers Tibble from `fetch_analysis_layers()`.
#' @param aoi Optional AOI list from `build_aoi_from_config()`.
#' @param analysis_crs Optional CRS string for distance calculations.
#' @param distance_layers Optional list of distance-layer configs.
#' @return Tibble of site attributes in long form.
#' @export
build_site_attributes_long <- function(sites,
                                       analysis_layers,
                                       aoi = NULL,
                                       analysis_crs = NULL,
                                       distance_layers = NULL) {
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

  raster_types <- c(
    "raster_file",
    "raster_arcgis",
    "raster_wcs",
    "raster_remote",
    "raster_geodata",
    "derived_slope",
    "derived_ndvi",
    "derived_nbr"
  )
  vector_types <- c("vector_file", "vector_arcgis")

  raster_layers <- analysis_layers[analysis_layers$type %in% raster_types, , drop = FALSE]
  if ("skip_attributes" %in% names(raster_layers)) {
    skip_vals <- raster_layers$skip_attributes
    skip_vals[is.na(skip_vals)] <- FALSE
    raster_layers <- raster_layers[!skip_vals, , drop = FALSE]
  }
  vector_layers <- analysis_layers[analysis_layers$type %in% vector_types, , drop = FALSE]
  if ("skip_attributes" %in% names(vector_layers)) {
    skip_vals <- vector_layers$skip_attributes
    skip_vals[is.na(skip_vals)] <- FALSE
    vector_layers <- vector_layers[!skip_vals, , drop = FALSE]
  }

  raster_long <- extract_raster_attributes(sites, raster_layers)
  vector_long <- extract_vector_attributes(sites, vector_layers)
  distance_long <- extract_distance_attributes(
    sites = sites,
    distance_layers = distance_layers,
    aoi = aoi,
    analysis_crs = analysis_crs
  )

  combined <- dplyr::bind_rows(raster_long, vector_long, distance_long)
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
    output_path <- here::here("outputs", "tables", "jc", "site_attributes_long.parquet")
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
#' @param sites Optional sites data frame with `site`, `lat`, `lon`.
#' @param output_path Output CSV path.
#' @return Output path.
#' @export
write_site_attributes_wide <- function(attributes, sites = NULL, output_path = NULL) {
  if (is.null(output_path) || !nzchar(output_path)) {
    output_path <- here::here("outputs", "tables", "jc", "site_attributes_wide.csv")
  }
  checkmate::assert_string(output_path, min.chars = 1L)

  desired_cols <- c(
    "site_id",
    "lat",
    "lon",
    "dem",
    "slope",
    "ndvi",
    "nbr",
    "tasveg_category",
    "tasveg_class",
    "canopy_height_m",
    "soil_ph",
    "bio1_mean_temp_c",
    "bio12_annual_precip_mm",
    "fire_sensitivity",
    "fire_flammability",
    "geology_description",
    "land_tenure_class",
    "reserve_estate_class",
    "distance_to_road",
    "distance_to_locality"
  )

  if (!is.null(sites) &&
        is.data.frame(sites) &&
        all(c("site", "lat", "lon") %in% names(sites))) {
    site_tbl <- tibble::as_tibble(sites)
    site_tbl$site_id <- as.character(site_tbl$site)
    site_tbl$site <- NULL
    site_tbl$lat <- suppressWarnings(as.numeric(site_tbl$lat))
    site_tbl$lon <- suppressWarnings(as.numeric(site_tbl$lon))
    conflict_cols <- setdiff(
      intersect(names(site_tbl), desired_cols),
      c("site_id", "lat", "lon")
    )
    if (length(conflict_cols) > 0L) {
      site_tbl <- dplyr::rename_with(
        site_tbl,
        ~ paste0("site_", .x),
        tidyselect::all_of(conflict_cols)
      )
    }
  } else {
    site_tbl <- tibble::tibble(
      site_id = as.character(unique(attributes$site_id)),
      lat = NA_real_,
      lon = NA_real_
    )
  }

  if (nrow(attributes) == 0L) {
    wide <- site_tbl
  } else {
    attributes <- attributes |>
      dplyr::mutate(
        attribute_norm = gsub("[^a-z0-9]+", "_", tolower(.data$attribute_name)),
        target = dplyr::case_when(
          grepl("_dem$", .data$layer_id) & .data$attribute_name == "value" ~ "dem",
          grepl("_chm$", .data$layer_id) & .data$attribute_name == "value" ~ "canopy_height_m",
          grepl("_slope$", .data$layer_id) & .data$attribute_name == "slope" ~ "slope",
          grepl("_soil_ph$", .data$layer_id) &
            (.data$attribute_name == "value" | grepl("^phh2o", .data$attribute_norm)) ~ "soil_ph",
          grepl("_ndvi$", .data$layer_id) & .data$attribute_name == "ndvi" ~ "ndvi",
          grepl("_nbr$", .data$layer_id) & .data$attribute_name == "nbr" ~ "nbr",
          grepl("_bio1$", .data$layer_id) &
            (.data$attribute_name == "value" | .data$attribute_name %in% c("bio1", "bio_1")) ~
            "bio1_mean_temp_c",
          grepl("_bio12$", .data$layer_id) &
            (.data$attribute_name == "value" | .data$attribute_name %in% c("bio12", "bio_12")) ~
            "bio12_annual_precip_mm",
          grepl("tasveg", .data$layer_id) &
            grepl("veg", .data$attribute_norm) &
            grepl("group", .data$attribute_norm) ~ "tasveg_category",
          grepl("tasveg", .data$layer_id) &
            .data$attribute_name == "VEGCODE" ~ "tasveg_class",
          grepl("fire_attributes", .data$layer_id) &
            .data$attribute_name == "FIRESENS" ~ "fire_sensitivity",
          grepl("fire_attributes", .data$layer_id) &
            .data$attribute_name == "FLAMMAB" ~ "fire_flammability",
          grepl("geology", .data$layer_id) &
            tolower(.data$attribute_name) == "map_symb" ~ "geology_description",
          grepl("land_tenure", .data$layer_id) &
            .data$attribute_name == "TEN_CLASS" ~ "land_tenure_class",
          grepl("reserve_estate", .data$layer_id) &
            .data$attribute_name == "RES_CLASS" ~ "reserve_estate_class",
          .data$layer_id %in% c("distance_to_road", "distance_to_locality") &
            .data$attribute_name == "distance_m" ~ .data$layer_id,
          TRUE ~ NA_character_
        )
      ) |>
      dplyr::filter(!is.na(.data$target)) |>
      dplyr::group_by(.data$site_id, .data$target) |>
      dplyr::summarise(value = dplyr::first(.data$value), .groups = "drop")

    wide <- attributes |>
      dplyr::select(dplyr::all_of(c("site_id", "target", "value"))) |>
      tidyr::pivot_wider(
        names_from = "target",
        values_from = "value",
        values_fill = NA_character_
      ) |>
      dplyr::right_join(site_tbl, by = "site_id") |>
      dplyr::arrange(.data$site_id)

    code_cols <- intersect(
      c("tasveg_category", "land_tenure_class", "reserve_estate_class"),
      names(wide)
    )
    for (col in code_cols) {
      wide[[col]] <- attribute_code_from_label(wide[[col]])
    }
  }

  missing_cols <- setdiff(desired_cols, names(wide))
  if (length(missing_cols) > 0L) {
    for (col in missing_cols) {
      wide[[col]] <- NA_character_
    }
  }
  extra_cols <- setdiff(names(wide), desired_cols)
  wide <- wide[, c(desired_cols, extra_cols), drop = FALSE]
  numeric_cols <- c(
    "lat",
    "lon",
    "canopy_height_m",
    "dem",
    "slope",
    "soil_ph",
    "ndvi",
    "nbr",
    "bio1_mean_temp_c",
    "bio12_annual_precip_mm",
    "distance_to_road",
    "distance_to_locality"
  )
  for (col in intersect(numeric_cols, names(wide))) {
    wide[[col]] <- suppressWarnings(as.numeric(wide[[col]]))
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
    if (terra::nlyr(rast) == 1L && length(band_names_raw) == 1L) {
      raw_name <- band_names_raw[[1]]
      raw_name_lower <- tolower(raw_name)
      generic_name <- is.na(raw_name) || !nzchar(raw_name) ||
        grepl("^(lyr\\.|file)", raw_name_lower) || raw_name_lower == "band_1"
      if (isTRUE(generic_name)) {
        band_names <- "value"
        names(values_mat) <- band_names
      }
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
    requested <- NULL
    if ("attribute_fields" %in% names(layer)) {
      requested <- layer$attribute_fields[[1]]
      if (!is.null(requested)) {
        requested <- unlist(requested, use.names = FALSE)
        requested <- requested[!is.na(requested)]
      }
    }
    if (!is.null(requested) && length(requested) > 0L) {
      fields <- intersect(fields, requested)
    }
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

extract_distance_attributes <- function(sites,
                                        distance_layers = NULL,
                                        aoi = NULL,
                                        analysis_crs = NULL) {
  if (is.null(distance_layers)) {
    return(empty_site_attributes())
  }
  if (!is.list(distance_layers)) {
    rlang::abort("distance_layers must be a list.", class = "distance_layers_invalid")
  }
  if (!is.null(distance_layers$id)) {
    distance_layers <- list(distance_layers)
  }
  if (length(distance_layers) == 0L) {
    return(empty_site_attributes())
  }

  if (is.null(analysis_crs) || !nzchar(analysis_crs)) {
    analysis_crs <- if (!is.null(aoi) && is.list(aoi) && !is.null(aoi$crs)) {
      as.character(aoi$crs)
    } else {
      "EPSG:28355"
    }
  }

  sites_sf <- sf::st_as_sf(sites, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
  aoi_geom <- NULL
  if (!is.null(aoi) && is.list(aoi) && !is.null(aoi$aoi)) {
    aoi_geom <- aoi$aoi
  }
  if (is.null(aoi_geom)) {
    aoi_geom <- sf::st_as_sfc(sf::st_bbox(sites_sf))
  }

  output <- lapply(distance_layers, function(layer) {
    if (is.null(layer) || !is.list(layer)) {
      return(NULL)
    }
    distance_to <- layer$distance_to %||% layer$label
    if (is.null(distance_to) || !nzchar(distance_to)) {
      return(NULL)
    }
    layer_id <- paste0("distance_to_", distance_to)
    layer$id <- layer$id %||% distance_to
    layer$type <- layer$type %||% "vector_arcgis"
    if (is.null(layer$url) || !nzchar(layer$url)) {
      rlang::abort(
        sprintf("Distance layer '%s' requires a url.", layer$id),
        class = "distance_layer_missing_url"
      )
    }
    layer$crs <- layer$crs %||% "EPSG:4326"
    layer$out_fields <- layer$out_fields %||% "OBJECTID"
    layer$offline <- isTRUE(layer$offline)

    vec <- fetch_arcgis_vector(layer, aoi_geom)
    if (!is.null(vec) && nrow(vec) > 0L && !is.null(aoi_geom)) {
      aoi_proj <- aoi_geom
      if (!inherits(aoi_proj, "sfc")) {
        aoi_proj <- sf::st_as_sfc(aoi_proj)
      }
      aoi_proj <- sf::st_transform(aoi_proj, sf::st_crs(vec))
      hits <- sf::st_intersects(vec, aoi_proj, sparse = FALSE)
      keep <- apply(hits, 1, any)
      vec <- vec[keep, , drop = FALSE]
    }
    distances <- rep(NA_real_, nrow(sites))
    if (!is.null(vec) && nrow(vec) > 0L) {
      sites_proj <- sf::st_transform(sites_sf, sf::st_crs(analysis_crs))
      vec_proj <- sf::st_transform(vec, sf::st_crs(analysis_crs))
      idx <- sf::st_nearest_feature(sites_proj, vec_proj)
      if (length(idx) == nrow(sites_proj)) {
        nearest <- vec_proj[idx, , drop = FALSE]
        distances <- sf::st_distance(sites_proj, nearest, by_element = TRUE)
        distances <- as.numeric(distances)
      }
    }
    if (identical(distance_to, "locality") &&
          any(is.finite(distances)) &&
          all(distances[is.finite(distances)] == 0) &&
          !is.null(vec) &&
          nrow(vec) > 0L) {
      geom_types <- unique(as.character(sf::st_geometry_type(vec)))
      if (any(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
        distances <- rep(NA_real_, nrow(sites))
      }
    }

    tibble::tibble(
      site_id = as.character(sites$site),
      layer_id = layer_id,
      layer_type = "derived_distance",
      attribute_name = "distance_m",
      value = as.character(distances),
      units = "m",
      source_id = as.character(layer$id),
      provenance_path = as.character(layer$provenance_path %||% NA_character_)
    )
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
