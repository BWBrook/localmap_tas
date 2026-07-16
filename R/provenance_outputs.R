#' Build a combined layer provenance table
#'
#' @param layers Tibble from `fetch_layer_registry()`.
#' @param analysis_layers Tibble from `fetch_analysis_layers()`.
#' @param output_path Output CSV path.
#' @return Output path to the provenance CSV.
build_layer_provenance <- function(layers,
                                   analysis_layers,
                                   output_path = NULL) {
  if (is.null(output_path) || !nzchar(output_path)) {
    output_path <- here::here("outputs", "provenance", "analysis_layers.csv")
  }
  checkmate::assert_string(output_path, min.chars = 1L)

  normalize <- function(tbl, kind) {
    if (is.null(tbl) || !is.data.frame(tbl) || nrow(tbl) == 0L) {
      return(tibble::tibble())
    }
    src_id <- if ("source_id" %in% names(tbl)) tbl$source_id else NA_character_
    tibble::tibble(
      layer_kind = kind,
      layer_id = as.character(tbl$id),
      layer_type = as.character(tbl$type),
      path = as.character(tbl$path),
      provenance_path = as.character(tbl$provenance_path),
      cache_path = as.character(tbl$cache_path),
      source_id = as.character(src_id),
      attribution_source = as.character(tbl$attribution_source),
      attribution_license = as.character(tbl$attribution_license),
      attribution_credit = as.character(tbl$attribution_credit)
    )
  }

  combined <- dplyr::bind_rows(
    normalize(layers, "imagery"),
    normalize(analysis_layers, "analysis")
  )
  combined$generated_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(combined, output_path, row.names = FALSE)
  output_path
}

#' Write a human-readable attribution report
#'
#' @param layers Tibble from `fetch_layer_registry()`.
#' @param analysis_layers Tibble from `fetch_analysis_layers()`.
#' @param output_path Output Markdown path.
#' @return Output path to the attribution report.
write_attribution_report <- function(layers,
                                     analysis_layers,
                                     output_path = NULL) {
  if (is.null(output_path) || !nzchar(output_path)) {
    output_path <- here::here("outputs", "provenance", "attribution.md")
  }
  checkmate::assert_string(output_path, min.chars = 1L)

  format_entries <- function(tbl) {
    if (is.null(tbl) || !is.data.frame(tbl) || nrow(tbl) == 0L) {
      return("- (none)")
    }
    entries <- vector("character", length = nrow(tbl))
    for (i in seq_len(nrow(tbl))) {
      source <- tbl$attribution_source[[i]]
      license <- tbl$attribution_license[[i]]
      credit <- tbl$attribution_credit[[i]]
      extra <- character()
      if (!is.null(license) && nzchar(license)) extra <- c(extra, paste0("License: ", license))
      if (!is.null(credit) && nzchar(credit)) extra <- c(extra, paste0("Credit: ", credit))
      suffix <- if (length(extra) > 0L) paste0(" (", paste(extra, collapse = "; "), ")") else ""
      entries[[i]] <- sprintf("- `%s`: %s%s", tbl$id[[i]], source, suffix)
    }
    entries
  }

  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%SZ", tz = "UTC")
  lines <- c(
    "# Attribution",
    "",
    sprintf("Generated: %s", timestamp),
    "",
    "## Imagery layers",
    format_entries(layers),
    "",
    "## Analysis layers",
    format_entries(analysis_layers),
    ""
  )

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, output_path, useBytes = TRUE)
  output_path
}

#' Write a machine-readable run manifest
#'
#' @param cfg Configuration list from `cfg_read()`.
#' @param cfg_file Path to config file.
#' @param layer_registry Validated layer registry config.
#' @param layer_outputs Tibble from `fetch_layer_registry()`.
#' @param analysis_layers_cfg Config list for analysis layers.
#' @param analysis_layers Tibble from `fetch_analysis_layers()`.
#' @param output_manifest_file Output schema manifest path.
#' @param output_path Output manifest path.
#' @return Output path to the run manifest.
write_run_manifest <- function(cfg,
                               cfg_file,
                               layer_registry,
                               layer_outputs,
                               analysis_layers_cfg,
                               analysis_layers,
                               output_manifest_file,
                               output_path = NULL) {
  if (is.null(output_path) || !nzchar(output_path)) {
    output_path <- here::here("outputs", "provenance", "run_manifest.yml")
  }
  checkmate::assert_string(output_path, min.chars = 1L)

  cfg_hash <- NA_character_
  if (!is.null(cfg_file) && nzchar(cfg_file) && file.exists(cfg_file)) {
    cfg_hash <- unname(tools::md5sum(cfg_file))
  }
  manifest_hash <- NA_character_
  if (!is.null(output_manifest_file) &&
        nzchar(output_manifest_file) &&
        file.exists(output_manifest_file)) {
    manifest_hash <- unname(tools::md5sum(output_manifest_file))
  }

  build_entries <- function(cfg_layers, outputs, include_output = TRUE) {
    if (is.null(cfg_layers) || length(cfg_layers) == 0L) {
      return(list())
    }
    entries <- lapply(cfg_layers, function(layer) {
      output_row <- NULL
      if (include_output && !is.null(outputs) && nrow(outputs) > 0L) {
        output_row <- outputs[outputs$id == layer$id, , drop = FALSE]
      }
      out_path <- if (!is.null(output_row) && nrow(output_row) > 0L) {
        output_row$path[[1]]
      } else {
        NA_character_
      }
      out_prov <- if (!is.null(output_row) && nrow(output_row) > 0L) {
        output_row$provenance_path[[1]]
      } else {
        NA_character_
      }
      out_cache <- if (!is.null(output_row) && nrow(output_row) > 0L) {
        output_row$cache_path[[1]]
      } else {
        NA_character_
      }
      list(
        id = layer$id,
        type = layer$type,
        source = layer$path %||% layer$url %||% layer$source_id %||% "",
        params = list(
          layers = layer$layers,
          styles = layer$styles,
          crs = layer$crs,
          width = layer$width,
          height = layer$height,
          format = layer$format,
          layer = layer$layer,
          where = layer$where,
          out_fields = layer$out_fields,
          categorical = layer$categorical,
          resample = layer$resample,
          bands = layer$bands,
          units = layer$units,
          source_id = layer$source_id
        ),
        output_path = out_path,
        provenance_path = out_prov,
        cache_path = out_cache,
        attribution = layer$attribution
      )
    })
    names(entries) <- vapply(cfg_layers, function(layer) as.character(layer$id), character(1))
    entries
  }

  profile <- Sys.getenv("R_CONFIG_ACTIVE", "default")
  run_metadata <- list(
    run = list(profile = profile, timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
    config = list(
      schema_version = cfg$schema_version %||% NA_character_,
      path = cfg_file %||% NA_character_,
      hash = cfg_hash
    ),
    output_schema = list(
      version = "v1",
      manifest = output_manifest_file %||% NA_character_,
      hash = manifest_hash
    ),
    layers = list(
      imagery = build_entries(layer_registry, layer_outputs, include_output = TRUE),
      analysis = build_entries(analysis_layers_cfg, analysis_layers, include_output = TRUE)
    )
  )

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  imagery_write_provenance(output_path, run_metadata)
  output_path
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
