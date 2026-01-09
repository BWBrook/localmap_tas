#' Validate layer registry configuration
#'
#' @param layers List of layer definitions (from config).
#' @return Normalized list of layer definitions.
#' @export
validate_layer_registry <- function(layers) {
  if (is.null(layers)) {
    return(list())
  }
  if (!is.list(layers)) {
    rlang::abort(
      "`data$layers` must be a list of layer definitions.",
      class = "layer_registry_invalid"
    )
  }

  normalized <- lapply(seq_along(layers), function(idx) {
    layer <- layers[[idx]]
    if (!is.list(layer)) {
      rlang::abort("Layer entries must be lists.", class = "layer_registry_invalid_entry")
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
    rlang::abort("Each layer must define a non-empty `id`.", class = "layer_registry_missing_id")
  }
  if (any(duplicated(ids))) {
    rlang::abort("Layer IDs must be unique.", class = "layer_registry_duplicate_id")
  }

  normalized <- Map(function(layer, id) {
    layer$id <- id
    type <- layer$type
    if (is.null(type) || !nzchar(type)) {
      rlang::abort(
        sprintf("Layer '%s' missing `type`.", id),
        class = "layer_registry_missing_type"
      )
    }
    type <- tolower(as.character(type))
    if (!type %in% c("wms", "arcgis_export", "file")) {
      rlang::abort(
        sprintf("Layer '%s' has unsupported type '%s'.", id, type),
        class = "layer_registry_invalid_type"
      )
    }
    layer$type <- type
    if (identical(type, "wms")) {
      if (is.null(layer$url) || !nzchar(layer$url)) {
        rlang::abort(
          sprintf("Layer '%s' requires a WMS url.", id),
          class = "layer_registry_wms_missing_url"
        )
      }
      if (is.null(layer$layers) || length(layer$layers) == 0L) {
        rlang::abort(
          sprintf("Layer '%s' requires WMS layers.", id),
          class = "layer_registry_wms_missing_layers"
        )
      }
    }
    if (identical(type, "arcgis_export")) {
      if (is.null(layer$url) || !nzchar(layer$url)) {
        rlang::abort(
          sprintf("Layer '%s' requires an ArcGIS export url.", id),
          class = "layer_registry_arcgis_missing_url"
        )
      }
    }
    if (identical(type, "file")) {
      if (is.null(layer$path) || !nzchar(layer$path)) {
        rlang::abort(
          sprintf("Layer '%s' requires a file path.", id),
          class = "layer_registry_file_missing_path"
        )
      }
    }
    attrib <- layer$attribution
    if (is.null(attrib) || !is.list(attrib) || is.null(attrib$source)) {
      rlang::abort(
        sprintf("Layer '%s' requires `attribution$source`.", id),
        class = "layer_registry_missing_attribution"
      )
    }
    layer
  }, normalized, ids)

  normalized
}

#' Fetch imagery layers from registry
#'
#' @param layers Validated layer registry list.
#' @param aoi AOI list from `build_aoi_from_config()`.
#' @return Tibble of layer metadata and output paths.
#' @export
fetch_layer_registry <- function(layers, aoi) {
  layers <- validate_layer_registry(layers)
  if (length(layers) == 0L) {
    return(tibble::tibble(
      id = character(),
      type = character(),
      path = character(),
      provenance_path = character(),
      cache_path = character(),
      opacity = numeric(),
      attribution_source = character(),
      attribution_license = character(),
      attribution_credit = character()
    ))
  }
  if (is.null(aoi) || !is.list(aoi) || is.null(aoi$aoi)) {
    rlang::abort("AOI is required to fetch layer imagery.", class = "layer_registry_missing_aoi")
  }

  bbox_geom <- aoi$aoi

  results <- lapply(layers, function(layer) {
    type <- layer$type
    output_path <- layer$output_path
    cache_dir <- layer$cache_dir
    offline <- isTRUE(layer$offline)
    res <- NULL
    if (identical(type, "wms")) {
      res <- fetch_wms_imagery(
        layer,
        bbox = bbox_geom,
        output_path = output_path,
        cache_dir = cache_dir,
        offline = offline
      )
    } else if (identical(type, "arcgis_export")) {
      res <- fetch_arcgis_imagery(
        layer,
        bbox = bbox_geom,
        output_path = output_path,
        cache_dir = cache_dir,
        offline = offline
      )
    } else if (identical(type, "file")) {
      target_path <- imagery_normalize_path(
        output_path,
        here::here("outputs", "tiles", paste0(layer$id, ".png"))
      )
      source_path <- imagery_normalize_path(layer$path, layer$path)
      dir.create(dirname(target_path), recursive = TRUE, showWarnings = FALSE)
      if (!file.exists(source_path)) {
        rlang::abort(
          sprintf("Layer file not found: %s", source_path),
          class = "layer_registry_file_missing"
        )
      }
      file.copy(source_path, target_path, overwrite = TRUE)
      prov <- imagery_write_provenance(
        paste0(target_path, ".yml"),
        list(type = "file", status = "copied", source = source_path, output_path = target_path)
      )
      res <- list(path = target_path, provenance_path = prov, cache_path = NA_character_)
    }

    tibble::tibble(
      id = layer$id,
      type = type,
      path = res$path,
      provenance_path = res$provenance_path,
      cache_path = res$cache_path,
      opacity = if (is.null(layer$opacity)) 1 else as.numeric(layer$opacity),
      attribution_source = as.character(layer$attribution$source),
      attribution_license = as.character(layer$attribution$license %||% ""),
      attribution_credit = as.character(layer$attribution$credit %||% "")
    )
  })

  dplyr::bind_rows(results)
}
