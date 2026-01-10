#' Build WMS GetMap query parameters
#'
#' @param wms_cfg List with WMS settings.
#' @param bbox Polygon (`sf`) defining extent.
#' @return List with `url`, `query`, and `bbox_param`.
#' @keywords internal
wms_build_query <- function(wms_cfg, bbox) {
  checkmate::assert_list(wms_cfg, any.missing = FALSE)
  if (is.null(bbox) || !inherits(bbox, c("sfc", "sf"))) {
    rlang::abort("WMS bbox must be an sf/sfc polygon.", class = "wms_bbox_invalid")
  }

  url <- wms_cfg$url
  if (is.null(url) || !nzchar(url)) {
    rlang::abort("WMS URL is required.", class = "wms_url_missing")
  }
  checkmate::assert_string(url, min.chars = 1L)

  version <- wms_cfg$version
  if (is.null(version)) version <- "1.3.0"
  layers <- wms_cfg$layers
  if (is.null(layers)) {
    rlang::abort("WMS layers are required.", class = "wms_layers_missing")
  }
  if (is.character(layers)) {
    layers <- trimws(layers)
    layers <- layers[nzchar(layers)]
  }
  if (length(layers) == 0L) {
    rlang::abort("WMS layers are empty.", class = "wms_layers_missing")
  }
  styles <- wms_cfg$styles
  if (is.null(styles)) styles <- ""
  fmt <- wms_cfg$format
  if (is.null(fmt)) fmt <- "image/png"
  crs <- wms_cfg$crs
  if (is.null(crs)) crs <- "EPSG:3857"
  width <- as.integer(wms_cfg$width %||% 2048L)
  height <- as.integer(wms_cfg$height %||% 2048L)
  transparent <- wms_cfg$transparent
  if (is.null(transparent)) transparent <- TRUE
  dpi <- wms_cfg$dpi
  if (is.null(dpi)) dpi <- 96

  bbox_target <- sf::st_bbox(sf::st_transform(bbox, sf::st_crs(crs)))
  bbox_values <- as.numeric(bbox_target[c("xmin", "ymin", "xmax", "ymax")])
  if (utils::compareVersion(version, "1.3.0") >= 0 && startsWith(crs, "EPSG:4326")) {
    bbox_values <- bbox_values[c(2, 1, 4, 3)]
  }
  bbox_param <- paste(bbox_values, collapse = ",")

  crs_param <- if (utils::compareVersion(version, "1.3.0") >= 0) "CRS" else "SRS"
  query <- list(
    service = "WMS",
    request = "GetMap",
    version = version,
    layers = paste(layers, collapse = ","),
    styles = styles,
    format = fmt,
    width = width,
    height = height,
    transparent = if (isTRUE(transparent)) "TRUE" else "FALSE"
  )
  query[[crs_param]] <- crs
  query$BBOX <- bbox_param
  if (is.finite(dpi) && dpi > 0) {
    query$dpi <- dpi
  }

  list(url = url, query = query, bbox_param = bbox_param)
}

#' Fetch a WMS image with caching and provenance
#'
#' @param wms_cfg List describing the WMS layer.
#' @param bbox `sf` polygon defining the extent.
#' @param output_path Output PNG path.
#' @param cache_dir Cache directory.
#' @param offline Logical; if TRUE, skip network fetch.
#' @return List with `path`, `provenance_path`, and `cache_path`.
#' @export
fetch_wms_imagery <- function(wms_cfg,
                              bbox,
                              output_path = NULL,
                              cache_dir = NULL,
                              offline = FALSE) {
  default_output <- here::here("outputs", "tiles", "wms_layer.png")
  if (is.null(wms_cfg) || !is.list(wms_cfg)) {
    rlang::warn("WMS config missing; creating placeholder.")
    path <- imagery_normalize_path(output_path, default_output)
    imagery_write_placeholder(path, width = 512, height = 512)
    prov <- imagery_write_provenance(paste0(path, ".yml"), list(status = "placeholder"))
    return(list(path = path, provenance_path = prov, cache_path = NA_character_))
  }

  output_path <- imagery_normalize_path(output_path %||% wms_cfg$output_path, default_output)
  cache_dir <- imagery_normalize_path(
    cache_dir %||% wms_cfg$cache_dir,
    here::here("data", "cache", "wms")
  )
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  offline <- isTRUE(offline) || isTRUE(wms_cfg$offline)
  if (!localmap_network_allowed()) {
    if (!offline) {
      rlang::warn("Network access disabled; using offline placeholder for WMS imagery.")
    }
    offline <- TRUE
  }

  query_info <- try(wms_build_query(wms_cfg, bbox), silent = TRUE)
  if (inherits(query_info, "try-error")) {
    rlang::warn("Failed to build WMS query; creating placeholder.")
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
        type = "wms",
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
      width = query_info$query$width,
      height = query_info$query$height
    )
    imagery_write_provenance(
      provenance_path,
      list(
        type = "wms",
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
    rlang::warn("Failed to fetch WMS imagery; creating placeholder.")
    imagery_write_placeholder(
      output_path,
      width = query_info$query$width,
      height = query_info$query$height
    )
    imagery_write_provenance(
      provenance_path,
      list(
        type = "wms",
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
  png_signature <- as.raw(c(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A))
  is_png <- length(body) >= length(png_signature) &&
    identical(body[seq_along(png_signature)], png_signature)
  if (!is_png || length(body) == 0L) {
    rlang::warn("WMS response was not a PNG; creating placeholder.")
    imagery_write_placeholder(
      output_path,
      width = query_info$query$width,
      height = query_info$query$height
    )
    imagery_write_provenance(
      provenance_path,
      list(
        type = "wms",
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

  dir.create(dirname(cache_path), recursive = TRUE, showWarnings = FALSE)
  writeBin(body, cache_path)
  if (!identical(normalizePath(cache_path), normalizePath(output_path, mustWork = FALSE))) {
    dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
    file.copy(cache_path, output_path, overwrite = TRUE)
  }

  imagery_write_provenance(
    provenance_path,
    list(
      type = "wms",
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

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
