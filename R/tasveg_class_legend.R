#' Build a TASVEG class legend restricted to AOI classes
#'
#' @param vector_path Path to the TASVEG class GeoPackage.
#' @param legend_path Output PNG path for the legend.
#' @param lookup_path Output CSV path for code/label lookup.
#' @param layer_url ArcGIS layer URL (MapServer/85).
#' @param offline Logical; if TRUE, skip legend fetch and use fallback colors.
#' @return Named list with `legend_path` and `lookup_path`.
#' @keywords internal
render_tasveg_class_legend <- function(vector_path,
                                       legend_path,
                                       lookup_path = NULL,
                                       layer_url = NULL,
                                       offline = FALSE) {
  if (is.null(vector_path) || !nzchar(vector_path) || !file.exists(vector_path)) {
    rlang::warn("TASVEG class vector missing; legend will be placeholder.")
    dir.create(dirname(legend_path), recursive = TRUE, showWarnings = FALSE)
    imagery_write_placeholder(legend_path, width = 220, height = 120)
    if (!is.null(lookup_path)) {
      dir.create(dirname(lookup_path), recursive = TRUE, showWarnings = FALSE)
      utils::write.csv(
        tibble::tibble(code = character(), label = character()),
        lookup_path,
        row.names = FALSE
      )
    }
    return(list(legend_path = legend_path, lookup_path = lookup_path))
  }
  vec <- sf::st_read(vector_path, quiet = TRUE)
  if (!"VEGCODE" %in% names(vec)) {
    rlang::warn("TASVEG class vector missing VEGCODE; legend will be placeholder.")
    codes <- character()
    labels <- character()
  } else {
    codes <- as.character(stats::na.omit(unique(vec$VEGCODE)))
    codes <- sort(codes)
    labels <- character(length(codes))
    if ("VEGCODE_D" %in% names(vec)) {
      for (i in seq_along(codes)) {
        match_idx <- which(vec$VEGCODE == codes[[i]])
        labels[[i]] <- as.character(vec$VEGCODE_D[match_idx][[1]])
      }
    }
  }

  if (is.null(lookup_path) || !nzchar(lookup_path)) {
    lookup_path <- sub("\\.gpkg$", "_lookup.csv", vector_path)
  }
  if (length(codes) > 0L) {
    lookup_tbl <- tibble::tibble(
      code = codes,
      label = if (length(labels) == length(codes)) labels else NA_character_
    )
    dir.create(dirname(lookup_path), recursive = TRUE, showWarnings = FALSE)
    utils::write.csv(lookup_tbl, lookup_path, row.names = FALSE)
  } else {
    dir.create(dirname(lookup_path), recursive = TRUE, showWarnings = FALSE)
    utils::write.csv(
      tibble::tibble(code = character(), label = character()),
      lookup_path,
      row.names = FALSE
    )
  }

  colors <- rep("#bdbdbd", length(codes))
  allow_network <- localmap_network_allowed()
  if (!allow_network) {
    flag <- Sys.getenv("LOCALMAP_ALLOW_NETWORK", "")
    if (!nzchar(flag)) {
      allow_network <- TRUE
    }
  }
  if (!offline && allow_network && !is.null(layer_url) && nzchar(layer_url)) {
    legend_map <- fetch_tasveg_legend_colors(layer_url)
    if (!is.null(legend_map) && nrow(legend_map) > 0L) {
      color_lookup <- stats::setNames(legend_map$color, legend_map$code)
      colors <- vapply(codes, function(code) {
        if (!is.null(color_lookup[[code]]) && nzchar(color_lookup[[code]])) {
          color_lookup[[code]]
        } else {
          "#bdbdbd"
        }
      }, character(1))
    }
  }

  if (is.null(legend_path) || !nzchar(legend_path)) {
    return(list(legend_path = NA_character_, lookup_path = lookup_path))
  }

  dir.create(dirname(legend_path), recursive = TRUE, showWarnings = FALSE)
  n_items <- max(1L, length(codes))
  row_height <- 24
  width_px <- 220
  height_px <- n_items * row_height + 20

  grDevices::png(filename = legend_path, width = width_px, height = height_px, res = 96)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(1, 1, 1, 1))
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 1), ylim = c(0, n_items + 1))

  if (length(codes) == 0L) {
    graphics::text(0.5, 0.5, labels = "No TASVEG classes in AOI", cex = 0.8)
  } else {
    for (i in seq_along(codes)) {
      y <- n_items - i + 1
      graphics::rect(
        0.05,
        y - 0.35,
        0.2,
        y + 0.35,
        col = colors[[i]],
        border = "grey30"
      )
      graphics::text(0.25, y, labels = codes[[i]], adj = 0, cex = 0.8)
    }
  }

  list(legend_path = legend_path, lookup_path = lookup_path)
}

fetch_tasveg_legend_colors <- function(layer_url) {
  service_url <- sub("/\\d+/?$", "", rtrim_slash(layer_url))
  legend_url <- paste0(service_url, "/legend?f=pjson")
  resp <- try(httr2::req_perform(httr2::request(legend_url)), silent = TRUE)
  if (inherits(resp, "try-error")) {
    rlang::warn("Failed to fetch TASVEG legend JSON.")
    return(NULL)
  }
  httr2::resp_check_status(resp)
  legend_json <- httr2::resp_body_json(resp, simplifyVector = TRUE, check_type = FALSE)
  layers <- legend_json$layers
  if (is.null(layers) || length(layers) == 0L) {
    return(NULL)
  }

  layer_id <- NA_integer_
  id_match <- regmatches(layer_url, regexpr("/\\d+/?$", layer_url))
  if (length(id_match) == 1 && nzchar(id_match)) {
    layer_id <- suppressWarnings(as.integer(gsub("[^0-9]", "", id_match)))
  }

  layer_tbl <- if (!is.na(layer_id)) {
    layers[layers$layerId == layer_id, , drop = FALSE]
  } else {
    layers
  }
  if (nrow(layer_tbl) == 0L) {
    layer_tbl <- layers
  }
  legend_items <- layer_tbl$legend[[1]]
  if (is.data.frame(legend_items)) {
    legend_items <- split(legend_items, seq_len(nrow(legend_items)))
  }
  if (is.null(legend_items) || length(legend_items) == 0L) {
    return(NULL)
  }

  build_item <- function(item) {
    label <- item$label %||% ""
    code <- sub("^\\(([^)]+)\\).*", "\\1", label)
    if (!nzchar(code) || identical(code, label)) {
      return(NULL)
    }
    color <- decode_legend_color(item$imageData)
    tibble::tibble(code = code, color = color)
  }
  legend_tbl <- purrr::map(legend_items, build_item) |> purrr::compact() |> dplyr::bind_rows()
  legend_tbl
}

decode_legend_color <- function(image_data) {
  if (is.null(image_data) || !nzchar(image_data)) {
    return("#bdbdbd")
  }
  raw <- try(base64enc::base64decode(image_data), silent = TRUE)
  if (inherits(raw, "try-error")) {
    return("#bdbdbd")
  }
  img <- try(png::readPNG(raw), silent = TRUE)
  if (inherits(img, "try-error")) {
    return("#bdbdbd")
  }
  if (length(dim(img)) == 2L) {
    arr <- array(1, dim = c(dim(img)[1], dim(img)[2], 4))
    arr[, , 1] <- img
    arr[, , 2] <- img
    arr[, , 3] <- img
    arr[, , 4] <- 1
    img <- arr
  }
  if (dim(img)[3] == 3L) {
    arr <- array(1, dim = c(dim(img)[1], dim(img)[2], 4))
    arr[, , 1:3] <- img
    arr[, , 4] <- 1
    img <- arr
  }
  alpha <- img[, , 4]
  mask <- alpha > 0
  if (!any(mask)) {
    return("#bdbdbd")
  }
  r <- img[, , 1][mask]
  g <- img[, , 2][mask]
  b <- img[, , 3][mask]
  a <- alpha[mask]
  if (length(a) == 0L || sum(a) == 0) {
    return("#bdbdbd")
  }
  r_mean <- sum(r * a) / sum(a)
  g_mean <- sum(g * a) / sum(a)
  b_mean <- sum(b * a) / sum(a)
  grDevices::rgb(r_mean, g_mean, b_mean)
}
