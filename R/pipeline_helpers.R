# Internal helpers that keep `_targets.R` declarative.

localmap_active_profile <- function(cfg = NULL,
                                    default = Sys.getenv("R_CONFIG_ACTIVE", "default")) {
  profile <- NULL
  if (!is.null(cfg)) {
    profile <- attr(cfg, "config")
  }
  if (is.null(profile) || !nzchar(profile)) {
    profile <- default
  }
  profile
}

named_path_lookup <- function(values, key) {
  if (is.null(values) || is.null(key) || !nzchar(key)) {
    return("")
  }
  if (!key %in% names(values)) {
    return("")
  }
  values[[key]]
}

find_layer_cfg <- function(layers_cfg, id) {
  if (is.null(layers_cfg)) {
    return(NULL)
  }
  for (layer in layers_cfg) {
    if (!is.null(layer$id) && identical(layer$id, id)) {
      return(layer)
    }
  }
  NULL
}

resolve_tasveg_class_id <- function(profile, analysis_layer_paths) {
  class_id <- NULL
  layer_ids <- names(analysis_layer_paths)
  if (!is.null(layer_ids)) {
    matches <- layer_ids[grepl("tasveg_class", layer_ids)]
    if (length(matches) > 0L) {
      class_id <- matches[[1]]
    }
  }

  if (!is.null(class_id) && nzchar(class_id)) {
    return(class_id)
  }

  if (profile %in% c("tas_canonical", "tas_canonical_ci")) {
    return("tasveg_class_vector")
  }
  if (identical(profile, "demo")) {
    return("demo_tasveg_class")
  }
  "jc_tasveg_class"
}

tasveg_class_lookup_path <- function(output_dir, class_id, vector_path = NULL) {
  if (!is.null(vector_path) && nzchar(vector_path)) {
    return(sub("\\.gpkg$", "_lookup.csv", vector_path))
  }

  prefix <- if (grepl("^demo", class_id)) {
    "demo"
  } else if (grepl("^jc", class_id)) {
    "jc"
  } else if (grepl("^tas", class_id)) {
    "tas"
  } else {
    "site"
  }

  file.path(
    output_dir,
    "analysis",
    "vector",
    paste0(prefix, "_tasveg_class_lookup.csv")
  )
}

render_tasveg_class_outputs <- function(cfg,
                                        analysis_layer_paths,
                                        layer_legend_paths,
                                        output_dir) {
  profile <- localmap_active_profile(cfg)
  class_id <- resolve_tasveg_class_id(profile, analysis_layer_paths)
  layer_cfg <- find_layer_cfg(cfg$data$analysis_layers, class_id)
  vector_path <- named_path_lookup(analysis_layer_paths, class_id)
  legend_path <- named_path_lookup(layer_legend_paths, "tasveg_class_wms")
  if (is.null(legend_path) || !nzchar(legend_path)) {
    legend_path <- file.path(output_dir, "layers", "tasveg_class_wms_legend.png")
  }
  lookup_path <- tasveg_class_lookup_path(output_dir, class_id, vector_path)

  render_tasveg_class_legend(
    vector_path = vector_path,
    legend_path = legend_path,
    lookup_path = lookup_path,
    layer_url = layer_cfg$url %||% "",
    offline = isTRUE(layer_cfg$offline)
  )
}

flatten_lookup_paths <- function(lookup_paths) {
  if (is.null(lookup_paths)) {
    lookup_paths <- character()
  } else {
    lookup_paths <- unname(unlist(lookup_paths, use.names = FALSE))
  }
  lookup_paths[!is.na(lookup_paths) & nzchar(lookup_paths)]
}
