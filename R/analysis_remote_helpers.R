# Internal remote-acquisition helpers for analysis layers.

analysis_remote_file_candidates <- function(layer, cache_root) {
  candidates <- character()
  if (!is.null(layer$extract_path) && nzchar(layer$extract_path)) {
    candidates <- c(candidates, layer$extract_path)
  }
  if (!is.null(layer$extract_file) && nzchar(layer$extract_file)) {
    candidates <- c(candidates, file.path(cache_root, layer$extract_file))
  }
  if (length(candidates) > 0L) {
    return(unique(candidates))
  }
  pattern <- layer$extract_pattern %||% "\\.tif$"
  list.files(cache_root, pattern = pattern, full.names = TRUE, recursive = TRUE)
}

analysis_placeholder_raster <- function(aoi_geom, analysis_crs, n = 10L) {
  if (is.null(aoi_geom)) {
    return(NULL)
  }
  target_crs <- if (!is.null(analysis_crs)) {
    sf::st_crs(analysis_crs)
  } else {
    sf::st_crs(aoi_geom)
  }
  if (is.na(target_crs)) {
    target_crs <- sf::st_crs(aoi_geom)
  }
  bbox <- sf::st_bbox(sf::st_transform(aoi_geom, target_crs))
  ext <- terra::ext(bbox$xmin, bbox$xmax, bbox$ymin, bbox$ymax)
  raster <- terra::rast(ext, ncols = n, nrows = n, crs = target_crs$wkt)
  terra::values(raster) <- NA_real_
  raster
}

analysis_download_file <- function(url, dest_path, expected_size_mb = NULL) {
  dir.create(dirname(dest_path), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(dest_path)) {
    if (!is.null(expected_size_mb) && is.finite(expected_size_mb)) {
      size_mb <- file.info(dest_path)$size / 1024^2
      if (!is.na(size_mb) && size_mb < (expected_size_mb * 0.95)) {
        rlang::warn(
          sprintf(
            "Download for %s appears incomplete (%.1f MB < %.1f MB); re-downloading.",
            basename(dest_path),
            size_mb,
            expected_size_mb
          )
        )
      } else {
        return(dest_path)
      }
    } else {
      return(dest_path)
    }
  }
  if (!localmap_network_allowed()) {
    rlang::warn(sprintf("Network access disabled; cannot download %s.", url))
    return(NA_character_)
  }
  cli::cli_inform(sprintf("Downloading large raster: %s", url))
  res <- try(utils::download.file(url, dest_path, mode = "wb", quiet = TRUE), silent = TRUE)
  if (inherits(res, "try-error")) {
    rlang::warn(sprintf("Download failed for %s.", url))
    return(NA_character_)
  }
  dest_path
}

analysis_unzip_archive <- function(archive_path, extract_dir) {
  dir.create(extract_dir, recursive = TRUE, showWarnings = FALSE)
  unzip_ok <- tryCatch(
    {
      utils::unzip(archive_path, exdir = extract_dir)
      TRUE
    },
    warning = function(w) FALSE,
    error = function(e) FALSE
  )
  if (!isTRUE(unzip_ok)) {
    seven_zip <- Sys.which("7z")
    if (!nzchar(seven_zip)) {
      rlang::abort(
        c(
          sprintf("Failed to unzip %s with base unzip.", basename(archive_path)),
          i = "Install '7z' (p7zip) or extract manually, then re-run."
        ),
        class = "analysis_unzip_missing_7z"
      )
    }
    res <- system2(
      seven_zip,
      c("x", archive_path, paste0("-o", extract_dir)),
      stdout = TRUE,
      stderr = TRUE
    )
    status <- attr(res, "status")
    if (!is.null(status) && status != 0) {
      rlang::abort(
        c(
          sprintf("7z extraction failed for %s.", basename(archive_path)),
          i = paste(res, collapse = "\n")
        ),
        class = "analysis_unzip_failed"
      )
    }
  }
  extract_dir
}

fetch_remote_raster <- function(layer, cache_dir = NULL) {
  url <- layer$download_url %||% layer$url
  if (is.null(url) || !nzchar(url)) {
    rlang::abort(
      sprintf("Remote raster layer '%s' missing download_url.", layer$id),
      class = "analysis_remote_missing_url"
    )
  }
  if (!localmap_network_allowed()) {
    if (!isTRUE(layer$offline)) {
      rlang::warn(
        sprintf(
          paste0(
            "Network access disabled; remote raster '%s' requires a fixture ",
            "or LOCALMAP_ALLOW_NETWORK=1."
          ),
          layer$id
        )
      )
    }
    layer$offline <- TRUE
  }
  if (isTRUE(layer$offline)) {
    fixture <- layer$fixture_path
    if (!is.null(fixture) && nzchar(fixture) && file.exists(fixture)) {
      raster <- terra::rast(fixture)
      return(list(
        raster = raster,
        meta = list(status = "offline_fixture", source = fixture)
      ))
    }
    return(list(raster = NULL, meta = list(status = "offline_skipped")))
  }
  if (is.null(cache_dir) || !nzchar(cache_dir)) {
    cache_dir <- here::here("data", "cache", "remote")
  }
  cache_root <- analysis_normalize_path(layer$download_dir %||% cache_dir, cache_dir)
  dir.create(cache_root, recursive = TRUE, showWarnings = FALSE)

  archive_path <- layer$download_path %||% file.path(cache_root, basename(url))
  is_zip <- isTRUE(layer$download_zip) || grepl("\\.zip$", archive_path, ignore.case = TRUE)
  extract_dir <- analysis_normalize_path(layer$extract_dir %||% cache_root, cache_root)

  candidates <- analysis_remote_file_candidates(layer, extract_dir)
  existing <- candidates[file.exists(candidates)]
  if (length(existing) > 0L) {
    raster <- terra::rast(existing[[1]])
    return(list(
      raster = raster,
      meta = list(
        status = "local_cached",
        source = url,
        archive_path = archive_path,
        extract_path = existing[[1]]
      )
    ))
  }

  if (isTRUE(layer$large_download) && !localmap_large_downloads_allowed()) {
    rlang::warn(
      sprintf(
        paste0(
          "Large download disabled; skipping raster '%s'. ",
          "Set LOCALMAP_ALLOW_LARGE_DOWNLOADS=1 to enable."
        ),
        layer$id
      )
    )
    return(list(raster = NULL, meta = list(status = "skipped_large_download")))
  }

  archive_path <- analysis_download_file(url, archive_path, layer$download_size_mb)
  if (is.na(archive_path) || !nzchar(archive_path)) {
    return(list(raster = NULL, meta = list(status = "download_failed")))
  }

  extract_path <- NULL
  if (is_zip) {
    analysis_unzip_archive(archive_path, extract_dir)
    candidates <- analysis_remote_file_candidates(layer, extract_dir)
    existing <- candidates[file.exists(candidates)]
    if (length(existing) == 0L) {
      rlang::abort(
        sprintf("Remote raster '%s' extracted but no files matched.", layer$id),
        class = "analysis_remote_extract_missing"
      )
    }
    extract_path <- existing[[1]]
  } else {
    extract_path <- archive_path
  }

  raster <- terra::rast(extract_path)
  list(
    raster = raster,
    meta = list(
      status = "downloaded",
      source = url,
      archive_path = archive_path,
      extract_path = extract_path
    )
  )
}

analysis_parse_wcs_resolution <- function(resolution) {
  if (is.null(resolution)) {
    return(NA_real_)
  }
  if (is.numeric(resolution)) {
    return(as.numeric(resolution)[1])
  }
  resolution <- tolower(trimws(as.character(resolution)))
  if (!nzchar(resolution)) {
    return(NA_real_)
  }
  if (grepl("s$", resolution)) {
    val <- suppressWarnings(as.numeric(sub("s$", "", resolution)))
    if (is.finite(val)) {
      return(val / 3600)
    }
  }
  suppressWarnings(as.numeric(resolution))
}

analysis_wcs_dimensions <- function(bbox, resolution, width, height, max_dim) {
  if (!is.null(width) && !is.null(height)) {
    return(list(width = as.integer(width), height = as.integer(height)))
  }
  if (!is.finite(resolution) || resolution <= 0) {
    return(list(width = as.integer(width %||% 256L), height = as.integer(height %||% 256L)))
  }
  span_x <- as.numeric(bbox["xmax"]) - as.numeric(bbox["xmin"])
  span_y <- as.numeric(bbox["ymax"]) - as.numeric(bbox["ymin"])
  width_calc <- max(1L, as.integer(ceiling(span_x / resolution)))
  height_calc <- max(1L, as.integer(ceiling(span_y / resolution)))
  max_dim <- as.integer(max_dim %||% 4096L)
  if (is.finite(max_dim) && max_dim > 0) {
    width_calc <- min(width_calc, max_dim)
    height_calc <- min(height_calc, max_dim)
  }
  list(width = width_calc, height = height_calc)
}

analysis_wcs_download_file <- function(base_url, query, dest_path) {
  if (is.null(base_url) || !nzchar(base_url)) {
    return(FALSE)
  }
  url <- try(httr2::url_parse(base_url), silent = TRUE)
  if (inherits(url, "try-error")) {
    return(FALSE)
  }
  url$query <- query
  full_url <- try(httr2::url_build(url), silent = TRUE)
  if (inherits(full_url, "try-error")) {
    return(FALSE)
  }
  res <- try(utils::download.file(full_url, dest_path, mode = "wb", quiet = TRUE), silent = TRUE)
  if (inherits(res, "try-error")) {
    return(FALSE)
  }
  file.exists(dest_path) && file.info(dest_path)$size > 0
}

analysis_wcs_fallback <- function(layer, aoi_geom, cache_dir, reason = NULL) {
  fallback <- layer$fallback
  if (is.null(fallback) || !is.list(fallback)) {
    rlang::abort(
      sprintf("WCS raster layer '%s' failed without fallback.", layer$id),
      class = "analysis_wcs_missing_fallback"
    )
  }
  fb_type <- tolower(as.character(fallback$type %||% "raster_geodata"))
  fb_layer <- list(
    id = layer$id,
    type = fb_type,
    resolution = analysis_default(fallback$resolution, "3s"),
    geodata_path = fallback$geodata_path,
    path = fallback$path,
    url = fallback$url,
    crs = fallback$crs,
    categorical = layer$categorical,
    resample = layer$resample,
    offline = analysis_default(fallback$offline, FALSE),
    fixture_path = fallback$fixture_path %||% layer$fixture_path,
    attribution = layer$attribution
  )

  if (identical(fb_type, "raster_geodata")) {
    raster <- fetch_geodata_raster(fb_layer, aoi_geom, cache_dir = cache_dir)
    fb_source <- sprintf("geodata (SRTM %s)", analysis_default(fb_layer$resolution, "3s"))
  } else if (identical(fb_type, "raster_file")) {
    if (is.null(fb_layer$path) || !nzchar(fb_layer$path)) {
      rlang::abort(
        sprintf("WCS fallback for '%s' missing `fallback$path`.", layer$id),
        class = "analysis_wcs_fallback_missing_path"
      )
    }
    raster <- read_raster_layer(fb_layer$path)
    fb_source <- "raster_file"
  } else if (identical(fb_type, "raster_arcgis")) {
    raster <- fetch_arcgis_raster(fb_layer, aoi_geom)
    fb_source <- "ArcGIS raster"
  } else {
    rlang::abort(
      sprintf("Unsupported WCS fallback type '%s' for '%s'.", fb_type, layer$id),
      class = "analysis_wcs_fallback_invalid_type"
    )
  }

  list(
    raster = raster,
    meta = list(
      status = "fallback",
      source = fb_source,
      params = list(
        fallback_type = fb_type,
        fallback_reason = reason %||% ""
      )
    )
  )
}

rtrim_slash <- function(path) {
  sub("/+$", "", path)
}
