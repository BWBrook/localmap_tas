#' Coalesce optional config values
#'
#' @param value Any value (possibly `NULL`).
#' @param default Value returned when `value` is `NULL`.
#' @return `value` if non-`NULL`, otherwise `default`.
#' @keywords internal
camera_sites_default <- function(value, default) {
  if (is.null(value)) default else value
}

camera_sites_write_placeholder_tile <- function(path) {
  placeholder <- array(1, dim = c(1, 1, 4))
  placeholder[, , 4] <- 0
  png::writePNG(placeholder, path)
  path
}
