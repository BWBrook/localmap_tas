#' Validate analysis layer configuration
#'
#' @param layers List of analysis layer definitions (from config).
#' @return Normalized list of layer definitions.
validate_analysis_layers <- function(layers) {
  if (is.null(layers)) {
    return(list())
  }
  if (!is.list(layers)) {
    rlang::abort(
      "`data$analysis_layers` must be a list.",
      class = "analysis_layers_invalid"
    )
  }

  normalized <- lapply(layers, function(layer) {
    if (!is.list(layer)) {
      rlang::abort("Each analysis layer must be a list.", class = "analysis_layer_invalid")
    }
    layer
  })

  ids <- vapply(normalized, function(layer) {
    id <- layer$id
    if (is.null(id) || !nzchar(id)) {
      return(NA_character_)
    }
    as.character(id)
  }, character(1))
  if (anyNA(ids)) {
    rlang::abort(
      "Each analysis layer must define a non-empty `id`.",
      class = "analysis_layer_missing_id"
    )
  }
  if (any(duplicated(ids))) {
    rlang::abort("Analysis layer IDs must be unique.", class = "analysis_layer_duplicate_id")
  }

  id_index <- stats::setNames(seq_along(ids), ids)

  normalized <- Map(function(layer, id) {
    layer$id <- id
    type <- layer$type
    if (is.null(type) || !nzchar(type)) {
      rlang::abort(
        sprintf("Analysis layer '%s' missing `type`.", id),
        class = "analysis_layer_missing_type"
      )
    }
    type <- tolower(as.character(type))
    if (!type %in% analysis_layer_types) {
      rlang::abort(
        sprintf("Analysis layer '%s' has unsupported type '%s'.", id, type),
        class = "analysis_layer_invalid_type"
      )
    }
    layer$type <- type

    if (type %in% c("vector_file", "raster_file")) {
      if (is.null(layer$path) || !nzchar(layer$path)) {
        rlang::abort(
          sprintf("Analysis layer '%s' requires `path`.", id),
          class = "analysis_layer_missing_path"
        )
      }
    }

    if (identical(type, "raster_remote")) {
      if (is.null(layer$download_url) || !nzchar(layer$download_url)) {
        rlang::abort(
          sprintf("Analysis layer '%s' requires `download_url`.", id),
          class = "analysis_layer_missing_url"
        )
      }
    }

    if (type %in% c("vector_arcgis", "raster_arcgis")) {
      if (is.null(layer$url) || !nzchar(layer$url)) {
        rlang::abort(
          sprintf("Analysis layer '%s' requires an ArcGIS URL.", id),
          class = "analysis_layer_missing_url"
        )
      }
    }

    if (identical(type, "raster_wcs")) {
      if (is.null(layer$url) || !nzchar(layer$url)) {
        rlang::abort(
          sprintf("WCS raster layer '%s' requires `url`.", id),
          class = "analysis_layer_missing_url"
        )
      }
    }

    if (identical(type, "raster_wcs")) {
      coverage <- layer$coverage %||% layer$identifier
      if (is.null(coverage) || !nzchar(coverage)) {
        rlang::abort(
          sprintf("WCS raster layer '%s' requires `coverage`.", id),
          class = "analysis_layer_missing_coverage"
        )
      }
      layer$coverage <- as.character(coverage)
      resolution <- layer$resolution
      if (!is.null(resolution)) {
        res_value <- analysis_parse_wcs_resolution(resolution)
        if (!is.finite(res_value) || res_value <= 0) {
          rlang::abort(
            sprintf("WCS raster layer '%s' has invalid `resolution`.", id),
            class = "analysis_layer_invalid_resolution"
          )
        }
      }
    }

    if (type %in% c("derived_slope", "derived_ndvi", "derived_nbr")) {
      if (is.null(layer$source_id) || !nzchar(layer$source_id)) {
        rlang::abort(
          sprintf("Derived analysis layer '%s' requires `source_id`.", id),
          class = "analysis_layer_missing_source_id"
        )
      }
    }

    if (identical(type, "raster_geodata")) {
      resolution <- analysis_default(layer$resolution, "3s")
      resolution <- tolower(as.character(resolution))
      if (!resolution %in% c("3s", "30s")) {
        rlang::abort(
          sprintf(
            "Geodata raster layer '%s' requires resolution '3s' or '30s'.",
            id
          ),
          class = "analysis_layer_geodata_resolution_invalid"
        )
      }
      layer$resolution <- resolution
    }

    attrib <- layer$attribution
    if (is.null(attrib) || !is.list(attrib) || is.null(attrib$source)) {
      rlang::abort(
        sprintf("Analysis layer '%s' requires `attribution$source`.", id),
        class = "analysis_layer_missing_attribution"
      )
    }
    layer
  }, normalized, ids)

  for (layer in normalized) {
    if (layer$type %in% c("derived_slope", "derived_ndvi", "derived_nbr")) {
      source_id <- as.character(layer$source_id)
      if (!source_id %in% ids) {
        rlang::abort(
          sprintf(
            "Derived analysis layer '%s' references missing source_id '%s'.",
            layer$id,
            source_id
          ),
          class = "analysis_layer_source_not_found"
        )
      }
      if (id_index[[source_id]] >= id_index[[layer$id]]) {
        rlang::abort(
          sprintf(
            "Derived analysis layer '%s' must appear after its source layer '%s'.",
            layer$id,
            source_id
          ),
          class = "analysis_layer_source_order"
        )
      }
    }
  }

  normalized
}
