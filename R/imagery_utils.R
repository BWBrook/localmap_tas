# Utility helpers for imagery acquisition.

imagery_normalize_path <- function(path, default_path) {
  if (is.null(path) || !nzchar(path)) {
    path <- default_path
  }
  candidates <- unique(c(path, here::here(path)))
  candidates[[1L]]
}

imagery_cache_key <- function(params) {
  if (is.null(params) || length(params) == 0L) {
    params <- list()
  }
  flat <- unlist(params, recursive = TRUE, use.names = TRUE)
  name_vec <- names(flat)
  if (length(flat) == 0L) {
    flat <- character()
  }
  flat <- as.character(flat)
  if (!is.null(name_vec)) {
    names(flat) <- name_vec
  }
  name_vec <- names(flat)
  if (is.null(name_vec)) {
    name_vec <- rep("", length(flat))
  }
  flat <- flat[order(name_vec)]
  name_vec <- names(flat)
  if (is.null(name_vec)) {
    name_vec <- rep("", length(flat))
  }
  key_text <- paste(sprintf("%s=%s", name_vec, flat), collapse = "&")
  tmp <- tempfile(fileext = ".txt")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(key_text, tmp, useBytes = TRUE)
  unname(tools::md5sum(tmp))
}

localmap_network_allowed <- function() {
  flag <- Sys.getenv("LOCALMAP_ALLOW_NETWORK", "")
  flag <- tolower(trimws(flag))
  flag %in% c("1", "true", "yes", "y")
}

localmap_large_downloads_allowed <- function() {
  flag <- Sys.getenv("LOCALMAP_ALLOW_LARGE_DOWNLOADS", "")
  flag <- tolower(trimws(flag))
  if (!nzchar(flag)) {
    return(TRUE)
  }
  flag %in% c("1", "true", "yes", "y")
}

imagery_write_placeholder <- function(path, width, height, colour = "#f0f0f0") {
  width <- as.integer(width)
  height <- as.integer(height)
  if (!is.finite(width) || width <= 0) width <- 512L
  if (!is.finite(height) || height <= 0) height <- 512L

  rgb <- try(grDevices::col2rgb(colour) / 255, silent = TRUE)
  if (inherits(rgb, "try-error")) {
    rgb <- matrix(c(0.94, 0.94, 0.94), nrow = 3)
  }
  rgb <- as.numeric(rgb)
  img <- array(1, dim = c(height, width, 4))
  img[, , 1] <- rgb[1]
  img[, , 2] <- rgb[2]
  img[, , 3] <- rgb[3]
  img[, , 4] <- 1
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  png::writePNG(img, target = path)
  path
}

imagery_write_provenance <- function(path, metadata) {
  if (is.null(metadata) || length(metadata) == 0L) {
    metadata <- list()
  }
  if (is.null(metadata$timestamp)) {
    metadata$timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  }
  flat <- unlist(metadata, recursive = TRUE, use.names = TRUE)
  name_vec <- names(flat)
  flat <- as.character(flat)
  if (!is.null(name_vec)) {
    names(flat) <- name_vec
  }
  lines <- sprintf("%s: %s", names(flat), flat)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path, useBytes = TRUE)
  path
}
