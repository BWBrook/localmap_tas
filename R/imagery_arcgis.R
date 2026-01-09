#' Build ArcGIS export query parameters
#'
#' @param arc_cfg List with ArcGIS export settings.
#' @param bbox `sf` polygon defining extent.
#' @return List with `url`, `query`, and `bbox_param`.
#' @keywords internal
arcgis_build_query <- function(arc_cfg, bbox) {
  checkmate::assert_list(arc_cfg, any.missing = FALSE)
  if (is.null(bbox) || !inherits(bbox, c("sfc", "sf"))) {
    rlang::abort("ArcGIS bbox must be an sf/sfc polygon.", class = "arcgis_bbox_invalid")
  }

  url <- arc_cfg$url
  if (is.null(url) || !nzchar(url)) {
    rlang::abort("ArcGIS export URL is required.", class = "arcgis_url_missing")
  }
  checkmate::assert_string(url, min.chars = 1L)

  crs <- arc_cfg$crs
  if (is.null(crs)) crs <- "EPSG:3857"
  width <- as.integer(arc_cfg$width %||% 2048L)
  height <- as.integer(arc_cfg$height %||% 2048L)
  fmt <- arc_cfg$format
  if (is.null(fmt)) fmt <- "png"
  dpi <- arc_cfg$dpi
  if (is.null(dpi)) dpi <- 96
  transparent <- arc_cfg$transparent
  if (is.null(transparent)) transparent <- TRUE

  bbox_target <- sf::st_bbox(sf::st_transform(bbox, sf::st_crs(crs)))
  bbox_values <- as.numeric(bbox_target[c("xmin", "ymin", "xmax", "ymax")])
  bbox_param <- paste(bbox_values, collapse = ",")

  wkid <- arcgis_wkid_from_crs(crs)
  query <- list(
    f = "image",
    bbox = bbox_param,
    bboxSR = wkid,
    imageSR = wkid,
    size = sprintf("%d,%d", width, height),
    format = fmt,
    transparent = if (isTRUE(transparent)) "true" else "false",
    dpi = dpi
  )

  list(url = url, query = query, bbox_param = bbox_param)
}

arcgis_wkid_from_crs <- function(crs) {
  if (is.null(crs)) {
    return(3857)
  }
  crs <- as.character(crs)
  match <- regmatches(crs, regexpr("[0-9]+$", crs))
  if (length(match) == 0L || !nzchar(match)) {
    return(3857)
  }
  as.integer(match)
}

#' Fetch an ArcGIS export image with caching and provenance
#'
#' @param arc_cfg List describing the ArcGIS export layer.
#' @param bbox `sf` polygon defining extent.
#' @param output_path Output PNG path.
#' @param cache_dir Cache directory.
#' @param offline Logical; if TRUE, skip network fetch.
#' @return List with `path`, `provenance_path`, and `cache_path`.
#' @export
fetch_arcgis_imagery <- function(arc_cfg,
                                 bbox,
                                 output_path = NULL,
                                 cache_dir = NULL,
                                 offline = FALSE) {
  default_output <- here::here("outputs", "tiles", "arcgis_layer.png")
  if (is.null(arc_cfg) || !is.list(arc_cfg)) {
    rlang::warn("ArcGIS config missing; creating placeholder.")
    path <- imagery_normalize_path(output_path, default_output)
    imagery_write_placeholder(path, width = 512, height = 512)
    prov <- imagery_write_provenance(paste0(path, ".yml"), list(status = "placeholder"))
    return(list(path = path, provenance_path = prov, cache_path = NA_character_))
  }

  output_path <- imagery_normalize_path(output_path %||% arc_cfg$output_path, default_output)
  cache_dir <- imagery_normalize_path(
    cache_dir %||% arc_cfg$cache_dir,
    here::here("data", "cache", "arcgis")
  )
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  offline <- isTRUE(offline) || isTRUE(arc_cfg$offline)

  query_info <- try(arcgis_build_query(arc_cfg, bbox), silent = TRUE)
  if (inherits(query_info, "try-error")) {
    rlang::warn("Failed to build ArcGIS export query; creating placeholder.")
    imagery_write_placeholder(output_path, width = 512, height = 512)
    prov <- imagery_write_provenance(paste0(output_path, ".yml"), list(status = "placeholder"))
    return(list(path = output_path, provenance_path = prov, cache_path = NA_character_))
  }

  cache_key <- imagery_cache_key(c(list(url = query_info$url), query_info$query))
  cache_path <- file.path(cache_dir, paste0(cache_key, ".png"))
  provenance_path <- paste0(output_path, ".yml")

  if (file.exists(cache_path)) {
    if (!identical(normalizePath(cache_path), normalizePath(output_path, mustWork = FALSE))) {
      dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
      file.copy(cache_path, output_path, overwrite = TRUE)
    }
    imagery_write_provenance(
      provenance_path,
      list(
        type = "arcgis_export",
        status = "cache_hit",
        url = query_info$url,
        cache_key = cache_key,
        cache_path = cache_path,
        output_path = output_path,
        bbox = query_info$bbox_param
      )
    )
    return(list(path = output_path, provenance_path = provenance_path, cache_path = cache_path))
  }

  if (offline) {
    imagery_write_placeholder(
      output_path,
      width = arc_cfg$width %||% 512,
      height = arc_cfg$height %||% 512
    )
    imagery_write_provenance(
      provenance_path,
      list(
        type = "arcgis_export",
        status = "offline_placeholder",
        url = query_info$url,
        cache_key = cache_key,
        cache_path = cache_path,
        output_path = output_path,
        bbox = query_info$bbox_param
      )
    )
    return(list(path = output_path, provenance_path = provenance_path, cache_path = cache_path))
  }

  req <- httr2::request(query_info$url)
  resp <- try(httr2::req_url_query(req, !!!query_info$query) |> httr2::req_perform(), silent = TRUE)
  if (inherits(resp, "try-error")) {
    rlang::warn("Failed to fetch ArcGIS imagery; creating placeholder.")
    imagery_write_placeholder(
      output_path,
      width = arc_cfg$width %||% 512,
      height = arc_cfg$height %||% 512
    )
    imagery_write_provenance(
      provenance_path,
      list(
        type = "arcgis_export",
        status = "fetch_failed",
        url = query_info$url,
        cache_key = cache_key,
        cache_path = cache_path,
        output_path = output_path,
        bbox = query_info$bbox_param
      )
    )
    return(list(path = output_path, provenance_path = provenance_path, cache_path = cache_path))
  }
  httr2::resp_check_status(resp)
  body <- httr2::resp_body_raw(resp)
  if (length(body) == 0L) {
    rlang::warn("ArcGIS response empty; creating placeholder.")
    imagery_write_placeholder(
      output_path,
      width = arc_cfg$width %||% 512,
      height = arc_cfg$height %||% 512
    )
    imagery_write_provenance(
      provenance_path,
      list(
        type = "arcgis_export",
        status = "empty_response",
        url = query_info$url,
        cache_key = cache_key,
        cache_path = cache_path,
        output_path = output_path,
        bbox = query_info$bbox_param
      )
    )
    return(list(path = output_path, provenance_path = provenance_path, cache_path = cache_path))
  }
  if (grepl("png", query_info$query$format, ignore.case = TRUE)) {
    png_signature <- as.raw(c(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A))
    is_png <- length(body) >= length(png_signature) &&
      identical(body[seq_along(png_signature)], png_signature)
    if (!is_png) {
      rlang::warn("ArcGIS response was not a PNG; creating placeholder.")
      imagery_write_placeholder(
        output_path,
        width = arc_cfg$width %||% 512,
        height = arc_cfg$height %||% 512
      )
      imagery_write_provenance(
        provenance_path,
        list(
          type = "arcgis_export",
          status = "non_png",
          url = query_info$url,
          cache_key = cache_key,
          cache_path = cache_path,
          output_path = output_path,
          bbox = query_info$bbox_param
        )
      )
      return(list(path = output_path, provenance_path = provenance_path, cache_path = cache_path))
    }
  }
  dir.create(dirname(cache_path), recursive = TRUE, showWarnings = FALSE)
  writeBin(body, cache_path)
  if (!identical(normalizePath(cache_path), normalizePath(output_path, mustWork = FALSE))) {
    dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
    file.copy(cache_path, output_path, overwrite = TRUE)
  }

  imagery_write_provenance(
    provenance_path,
    list(
      type = "arcgis_export",
      status = "downloaded",
      url = query_info$url,
      cache_key = cache_key,
      cache_path = cache_path,
      output_path = output_path,
      bbox = query_info$bbox_param
    )
  )
  list(path = output_path, provenance_path = provenance_path, cache_path = cache_path)
}
