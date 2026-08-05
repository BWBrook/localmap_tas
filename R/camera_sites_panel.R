camera_sites_stack_maps <- function(stack_cfg,
                                    prerequisites = NULL) {
  force(prerequisites)

  if (is.null(stack_cfg)) {
    rlang::abort(
      "Stack configuration is required to assemble camera site panels.",
      class = "camera_sites_stack_missing_config"
    )
  }
  if (!is.list(stack_cfg)) {
    rlang::abort(
      "Camera site stack configuration must be a list or mapping from config.yaml.",
      class = "camera_sites_stack_invalid_config"
    )
  }

  normalise_output_path <- function(path) {
    checkmate::assert_string(path, min.chars = 1L)
    candidates <- unique(c(path, here::here(path)))
    candidates[[1L]]
  }

  collect_from_paths <- function(paths) {
    resolved <- character()
    if (length(paths) == 0L) {
      return(resolved)
    }
    for (p in paths) {
      if (is.null(p) || !nzchar(p)) {
        next
      }
      candidates <- unique(c(p, here::here(p)))
      existing <- candidates[file.exists(candidates)]
      if (length(existing) == 0L) {
        rlang::warn(sprintf("Camera site panel path not found: %s", p))
      } else {
        resolved <- c(resolved, existing)
      }
    }
    resolved
  }

  collect_from_glob <- function(patterns) {
    resolved <- character()
    if (length(patterns) == 0L) {
      return(resolved)
    }
    for (pat in patterns) {
      if (is.null(pat) || !nzchar(pat)) {
        next
      }
      candidates <- unique(c(pat, here::here(pat)))
      matches <- unlist(lapply(candidates, Sys.glob), use.names = FALSE)
      matches <- matches[file.exists(matches)]
      if (length(matches) == 0L) {
        rlang::warn(sprintf("Camera site panel glob matched no files: %s", pat))
      } else {
        resolved <- c(resolved, matches)
      }
    }
    resolved
  }

  collect_from_directory <- function(dir_paths, pattern) {
    resolved <- character()
    if (length(dir_paths) == 0L) {
      return(resolved)
    }
    for (dir_candidate in dir_paths) {
      if (is.null(dir_candidate) || !nzchar(dir_candidate)) {
        next
      }
      candidates <- unique(c(dir_candidate, here::here(dir_candidate)))
      for (cand in candidates) {
        if (!dir.exists(cand)) {
          next
        }
        matches <- list.files(cand, pattern = pattern, full.names = TRUE)
        matches <- matches[file.exists(matches)]
        if (length(matches) == 0L) {
          rlang::warn(sprintf("Camera site panel directory yielded no matches: %s", cand))
        } else {
          resolved <- c(resolved, matches)
        }
      }
    }
    resolved
  }

  resolve_panel_entries <- function(panels, path_lookup = NULL) {
    if (is.null(panels)) {
      return(list())
    }
    lookup <- if (is.list(path_lookup)) path_lookup else list()
    entries <- list()
    if (is.character(panels)) {
      panels <- as.list(panels)
    }
    for (item in panels) {
      entry <- list()
      if (is.list(item)) {
        entry$path <- as.character(item$path %||% item$file %||% "")
        entry$label <- as.character(item$label %||% "")
        entry$legend_path <- as.character(item$legend_path %||% "")
        entry$alpha <- item$legend_alpha %||% item$alpha
        entry$position <- item$legend_position %||% item$position
        entry$width_fraction <- item$legend_width_fraction %||% item$width_fraction
        entry$margin_fraction <- item$legend_margin_fraction %||% item$margin_fraction
        if (!nzchar(entry$path)) {
          entry$id <- as.character(item$id %||% "")
          if (nzchar(entry$id) && !is.null(lookup[[entry$id]])) {
            entry$path <- as.character(lookup[[entry$id]])
          } else if (nzchar(entry$id)) {
            rlang::warn(sprintf("Panel entry id not found in path_lookup: %s", entry$id))
          }
        }
      } else if (is.character(item) && length(item) > 0L) {
        entry$path <- as.character(item[[1L]])
      } else {
        next
      }
      if (is.null(entry$path) || !nzchar(entry$path)) {
        next
      }
      entries[[length(entries) + 1L]] <- entry
    }
    entries
  }

  panel_entries <- resolve_panel_entries(stack_cfg$panels, stack_cfg$path_lookup)
  panel_paths <- vapply(panel_entries, function(entry) entry$path %||% "", character(1))
  panel_paths <- panel_paths[nzchar(panel_paths)]

  direct_paths <- stack_cfg$paths
  if (is.null(direct_paths)) {
    direct_paths <- character()
  }
  direct_paths <- as.character(unlist(direct_paths, use.names = FALSE))
  direct_paths <- trimws(direct_paths)
  direct_paths <- direct_paths[nzchar(direct_paths)]

  glob_patterns <- stack_cfg$glob
  if (is.null(glob_patterns)) {
    glob_patterns <- stack_cfg$input_glob
  }
  glob_patterns <- as.character(unlist(glob_patterns, use.names = FALSE))
  glob_patterns <- trimws(glob_patterns)
  glob_patterns <- glob_patterns[nzchar(glob_patterns)]

  input_dirs <- stack_cfg$input_dir
  input_dirs <- as.character(unlist(input_dirs, use.names = FALSE))
  input_dirs <- trimws(input_dirs)
  input_dirs <- input_dirs[nzchar(input_dirs)]
  dir_pattern <- camera_sites_default(stack_cfg$pattern, "\\.png$")

  if (length(panel_paths) > 0L) {
    collected_paths <- panel_paths
  } else {
    collected_paths <- c(
      collect_from_paths(direct_paths),
      collect_from_glob(glob_patterns),
      collect_from_directory(input_dirs, dir_pattern)
    )
    collected_paths <- collected_paths[nzchar(collected_paths)]
    collected_paths <- unique(collected_paths)
  }

  if (length(collected_paths) == 0L) {
    rlang::abort(
      "No camera site map images found for stacking.",
      class = "camera_sites_stack_missing_inputs"
    )
  }

  collected_paths <- normalizePath(collected_paths, winslash = "/", mustWork = TRUE)
  if (length(panel_paths) == 0L) {
    collected_paths <- sort(unique(collected_paths))
  }

  preferred_order <- stack_cfg$order
  if (!is.null(preferred_order) && length(panel_paths) == 0L) {
    preferred_order <- as.character(unlist(preferred_order, use.names = FALSE))
    preferred_order <- trimws(preferred_order)
    preferred_order <- preferred_order[nzchar(preferred_order)]
    if (length(preferred_order) > 0L) {
      ordered <- character()
      remaining <- collected_paths
      base_names <- basename(remaining)
      for (pattern in preferred_order) {
        matches <- grepl(pattern, base_names)
        if (any(matches)) {
          ordered <- c(ordered, remaining[matches])
          keep <- !matches
          remaining <- remaining[keep]
          base_names <- base_names[keep]
        }
      }
      collected_paths <- c(unique(ordered), remaining)
    }
  }

  max_panels <- camera_sites_default(stack_cfg$max_panels, 9L)
  checkmate::assert_numeric(max_panels, len = 1L, lower = 1, upper = 9)
  max_panels <- as.integer(round(max_panels))
  if (length(collected_paths) > max_panels) {
    rlang::warn(sprintf(
      "Camera site stack limited to first %d panels (of %d found).",
      max_panels,
      length(collected_paths)
    ))
    collected_paths <- collected_paths[seq_len(max_panels)]
  }

  output_path <- camera_sites_default(
    stack_cfg$output_path,
    here::here("outputs", "maps", "panel_figure.png")
  )
  output_path <- normalise_output_path(output_path)
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)

  gap_px <- camera_sites_default(stack_cfg$gap_px, 6)
  checkmate::assert_numeric(gap_px, len = 1L, lower = 0)
  gap_px <- as.integer(round(gap_px))

  background <- camera_sites_default(stack_cfg$background, "#ffffff")
  checkmate::assert_character(background, len = 1L, pattern = "^#|^[A-Za-z]", any.missing = FALSE)
  bg_rgb <- try(grDevices::col2rgb(background) / 255, silent = TRUE)
  if (inherits(bg_rgb, "try-error")) {
    rlang::abort(
      sprintf("Invalid background colour for camera site panel: %s", background),
      class = "camera_sites_stack_invalid_colour"
    )
  }
  bg_rgb <- as.numeric(bg_rgb)

  label_cfg_raw <- stack_cfg$labels
  if (is.null(label_cfg_raw)) {
    label_cfg <- list(values = character())
  } else if (is.list(label_cfg_raw)) {
    label_cfg <- label_cfg_raw
  } else if (is.character(label_cfg_raw)) {
    label_cfg <- list(values = label_cfg_raw)
  } else {
    rlang::abort(
      "labels configuration must be NULL, a character vector, or a list with `values`.",
      class = "camera_sites_stack_invalid_labels"
    )
  }

  label_values <- camera_sites_default(label_cfg$values, character())
  label_values <- as.character(unlist(label_values, use.names = FALSE))
  label_values <- trimws(label_values)
  label_values <- label_values[nzchar(label_values)]
  panel_label_values <- vapply(panel_entries, function(entry) entry$label %||% "", character(1))
  use_panel_labels <- length(panel_label_values) > 0L && any(nzchar(panel_label_values))
  if (isTRUE(use_panel_labels)) {
    label_values <- panel_label_values
  }
  if (length(label_values) > 0L) {
    label_values <- rep(label_values, length.out = length(collected_paths))
  }
  label_padding <- as.numeric(camera_sites_default(label_cfg$padding_px, 16))
  label_colour <- camera_sites_default(label_cfg$colour, "#050505")
  label_font_size <- as.numeric(camera_sites_default(label_cfg$font_size, 28))
  label_font_family <- camera_sites_default(label_cfg$font_family, "")
  label_font_face <- camera_sites_default(label_cfg$font_face, "bold")

  normalize_rgba <- function(img, path = NULL) {
    dims <- dim(img)
    if (length(dims) == 2L) {
      arr <- array(1, dim = c(dims[1], dims[2], 4))
      arr[, , 1] <- img
      arr[, , 2] <- img
      arr[, , 3] <- img
      arr[, , 4] <- 1
      return(arr)
    }
    channels <- dims[3]
    if (channels == 4L) {
      return(img)
    }
    if (channels == 3L) {
      arr <- array(1, dim = c(dims[1], dims[2], 4))
      arr[, , 1:3] <- img
      arr[, , 4] <- 1
      return(arr)
    }
    if (channels == 2L) {
      arr <- array(1, dim = c(dims[1], dims[2], 4))
      arr[, , 1] <- img[, , 1]
      arr[, , 2] <- img[, , 1]
      arr[, , 3] <- img[, , 1]
      arr[, , 4] <- img[, , 2]
      return(arr)
    }
    rlang::abort(
      sprintf("Unsupported channel count (%d) for camera site panel: %s", channels, path),
      class = "camera_sites_stack_invalid_channels"
    )
  }

  read_rgba <- function(path) {
    img <- try(png::readPNG(path), silent = TRUE)
    if (inherits(img, "try-error")) {
      rlang::abort(
        sprintf("Failed to read PNG for camera site panel: %s", path),
        class = "camera_sites_stack_read_failed"
      )
    }
    normalize_rgba(img, path = path)
  }

  resize_rgba <- function(img, width_px, height_px) {
    if (is.null(width_px) || is.null(height_px)) {
      return(img)
    }
    width_px <- as.integer(round(width_px))
    height_px <- as.integer(round(height_px))
    if (width_px <= 0 || height_px <= 0) {
      return(img)
    }
    if (dim(img)[2] == width_px && dim(img)[1] == height_px) {
      return(img)
    }
    tmp <- tempfile(fileext = ".png")
    grDevices::png(filename = tmp, width = width_px, height = height_px, bg = "transparent")
    grid::grid.newpage()
    grid::grid.raster(
      img,
      width = grid::unit(1, "npc"),
      height = grid::unit(1, "npc"),
      interpolate = TRUE
    )
    grDevices::dev.off()
    on.exit(unlink(tmp), add = TRUE)
    normalize_rgba(png::readPNG(tmp), path = tmp)
  }

  annotate_label <- function(img, label_text) {
    if (is.null(label_text) || !nzchar(label_text)) {
      return(img)
    }
    height <- dim(img)[1]
    width <- dim(img)[2]
    tmp <- tempfile(fileext = ".png")
    grDevices::png(filename = tmp, width = width, height = height, bg = "transparent")
    grid::grid.newpage()
    grid::grid.raster(
      img,
      width = grid::unit(1, "npc"),
      height = grid::unit(1, "npc"),
      interpolate = TRUE
    )
    padding_x <- max(0, min(label_padding, width))
    padding_y <- max(0, min(label_padding, height))
    x_pos <- grid::unit(1 - (padding_x / width), "npc")
    y_pos <- grid::unit(padding_y / height, "npc")
    grid::grid.text(
      label_text,
      x = x_pos,
      y = y_pos,
      just = c("right", "bottom"),
      gp = grid::gpar(
        col = label_colour,
        fontsize = label_font_size,
        fontface = label_font_face,
        fontfamily = label_font_family
      )
    )
    grDevices::dev.off()
    on.exit(unlink(tmp), add = TRUE)
    normalize_rgba(png::readPNG(tmp), path = tmp)
  }

  overlay_panel_legend <- function(img, legend_path, legend_cfg = list()) {
    if (is.null(legend_path) || !nzchar(legend_path) || !file.exists(legend_path)) {
      return(img)
    }
    legend_img <- try(png::readPNG(legend_path), silent = TRUE)
    if (inherits(legend_img, "try-error")) {
      rlang::warn(sprintf("Failed to read panel legend image: %s", legend_path))
      return(img)
    }
    legend_img <- normalize_rgba(legend_img, path = legend_path)
    alpha <- as.numeric(legend_cfg$alpha %||% 0.75)
    if (is.finite(alpha) && alpha < 1) {
      legend_img[, , 4] <- legend_img[, , 4] * max(0, min(alpha, 1))
    }
    width_frac <- as.numeric(legend_cfg$width_fraction %||% 0.2)
    margin_frac <- as.numeric(legend_cfg$margin_fraction %||% 0.04)
    if (!is.finite(width_frac) || width_frac <= 0) width_frac <- 0.2
    if (!is.finite(margin_frac) || margin_frac < 0) margin_frac <- 0.04
    position <- as.character(legend_cfg$position %||% "tr")
    panel_width <- dim(img)[2]
    panel_height <- dim(img)[1]
    legend_width_px <- max(1, round(panel_width * width_frac))
    aspect <- dim(legend_img)[1] / dim(legend_img)[2]
    legend_height_px <- max(1, round(legend_width_px * aspect))
    legend_width_npc <- legend_width_px / panel_width
    legend_height_npc <- legend_height_px / panel_height
    margin_x <- margin_frac
    margin_y <- margin_frac
    x_pos <- 1 - margin_x
    y_pos <- 1 - margin_y
    just <- c("right", "top")
    if (identical(position, "br")) {
      y_pos <- margin_y
      just <- c("right", "bottom")
    } else if (identical(position, "bl")) {
      x_pos <- margin_x
      y_pos <- margin_y
      just <- c("left", "bottom")
    } else if (identical(position, "tl")) {
      x_pos <- margin_x
      just <- c("left", "top")
    }
    tmp <- tempfile(fileext = ".png")
    grDevices::png(filename = tmp, width = panel_width, height = panel_height, bg = "transparent")
    grid::grid.newpage()
    grid::grid.raster(
      img,
      width = grid::unit(1, "npc"),
      height = grid::unit(1, "npc"),
      interpolate = TRUE
    )
    grid::grid.raster(
      legend_img,
      x = grid::unit(x_pos, "npc"),
      y = grid::unit(y_pos, "npc"),
      width = grid::unit(legend_width_npc, "npc"),
      height = grid::unit(legend_height_npc, "npc"),
      just = just,
      interpolate = TRUE
    )
    grDevices::dev.off()
    on.exit(unlink(tmp), add = TRUE)
    normalize_rgba(png::readPNG(tmp), path = tmp)
  }

  raw_images <- lapply(seq_along(collected_paths), function(idx) {
    read_rgba(collected_paths[[idx]])
  })

  widths <- vapply(raw_images, function(img) dim(img)[2], numeric(1))
  heights <- vapply(raw_images, function(img) dim(img)[1], numeric(1))

  target_width <- stack_cfg$target_width_px
  target_height <- stack_cfg$target_height_px
  normalize_sizes <- isTRUE(stack_cfg$normalize_sizes) ||
    !is.null(target_width) ||
    !is.null(target_height)
  size_mode <- as.character(stack_cfg$size_mode %||% "min")
  if (normalize_sizes) {
    if (is.null(target_width) && is.null(target_height)) {
      if (identical(size_mode, "max")) {
        target_width <- max(widths)
        target_height <- max(heights)
      } else {
        target_width <- min(widths)
        target_height <- min(heights)
      }
    } else {
      if (is.null(target_width) && is.finite(target_height)) {
        target_width <- round(target_height * (widths[[1]] / heights[[1]]))
      }
      if (is.null(target_height) && is.finite(target_width)) {
        target_height <- round(target_width * (heights[[1]] / widths[[1]]))
      }
    }
    raw_images <- lapply(
      raw_images,
      resize_rgba,
      width_px = target_width,
      height_px = target_height
    )
    widths <- vapply(raw_images, function(img) dim(img)[2], numeric(1))
    heights <- vapply(raw_images, function(img) dim(img)[1], numeric(1))
  } else if (length(unique(widths)) > 1L || length(unique(heights)) > 1L) {
    rlang::warn(
      "Panel images differ in size; bounding boxes may not match. Consider normalize_sizes = TRUE."
    )
  }

  if (length(panel_entries) == 0L) {
    panel_entries <- rep(list(list()), length(raw_images))
  } else if (length(panel_entries) < length(raw_images)) {
    panel_entries <- c(panel_entries, rep(list(list()), length(raw_images) - length(panel_entries)))
  }

  legend_defaults <- stack_cfg$legend_defaults %||% list()

  images <- lapply(seq_along(raw_images), function(idx) {
    img <- raw_images[[idx]]
    entry <- panel_entries[[idx]]
    legend_cfg <- utils::modifyList(legend_defaults, entry)
    if (!is.null(legend_cfg$legend_path) && nzchar(legend_cfg$legend_path)) {
      img <- overlay_panel_legend(img, legend_cfg$legend_path, legend_cfg)
    }
    if (length(label_values) >= idx && nzchar(label_values[[idx]])) {
      img <- annotate_label(img, label_values[[idx]])
    }
    img
  })

  heights <- vapply(images, function(img) dim(img)[1], numeric(1))
  widths <- vapply(images, function(img) dim(img)[2], numeric(1))

  channel_counts <- vapply(images, function(img) dim(img)[3], integer(1))
  if (length(unique(channel_counts)) != 1L) {
    rlang::abort("Camera site panel image channels are inconsistent after conversion.")
  }
  channels <- channel_counts[[1]]

  columns_cfg <- stack_cfg$columns
  rows_cfg <- stack_cfg$rows
  total_panels <- length(images)
  determine_layout <- function(columns, rows) {
    list(columns = columns, rows = rows)
  }

  layout <- NULL
  if (!is.null(columns_cfg) && !is.null(rows_cfg)) {
    columns <- max(1L, as.integer(round(columns_cfg)))
    rows <- max(1L, as.integer(round(rows_cfg)))
    if (columns * rows < total_panels) {
      rows <- ceiling(total_panels / columns)
      rlang::warn(
        "Specified columns/rows insufficient for panels; rows increased to fit all panels."
      )
    }
    layout <- determine_layout(columns, rows)
  } else if (!is.null(columns_cfg)) {
    columns <- max(1L, as.integer(round(columns_cfg)))
    columns <- min(columns, total_panels)
    rows <- ceiling(total_panels / columns)
    layout <- determine_layout(columns, rows)
  } else if (!is.null(rows_cfg)) {
    rows <- max(1L, as.integer(round(rows_cfg)))
    rows <- min(rows, total_panels)
    columns <- ceiling(total_panels / rows)
    layout <- determine_layout(columns, rows)
  } else {
    if (total_panels <= 3L) {
      layout <- determine_layout(1L, total_panels)
    } else {
      layout <- determine_layout(
        min(3L, total_panels),
        ceiling(total_panels / min(3L, total_panels))
      )
    }
  }

  columns <- layout$columns
  rows <- layout$rows

  cell_width <- max(widths)
  cell_height <- max(heights)
  panel_width <- columns * cell_width + gap_px * (columns - 1L)
  panel_height <- rows * cell_height + gap_px * (rows - 1L)

  panel <- array(1, dim = c(panel_height, panel_width, channels))
  for (idx in seq_len(min(3, channels))) {
    panel[, , idx] <- bg_rgb[min(idx, length(bg_rgb))]
  }
  if (channels >= 4L) {
    panel[, , 4] <- 1
  }

  for (i in seq_along(images)) {
    img <- images[[i]]
    h <- dim(img)[1]
    w <- dim(img)[2]
    row_idx <- ceiling(i / columns)
    col_idx <- ((i - 1L) %% columns) + 1L
    row_start <- (row_idx - 1L) * (cell_height + gap_px) + 1L
    col_start <- (col_idx - 1L) * (cell_width + gap_px) + 1L
    row_offset <- floor((cell_height - h) / 2)
    col_offset <- floor((cell_width - w) / 2)
    row_range <- (row_start + row_offset):(row_start + row_offset + h - 1L)
    col_range <- (col_start + col_offset):(col_start + col_offset + w - 1L)
    panel[row_range, col_range, ] <- img
  }

  png::writePNG(panel, target = output_path)
  structure(
    output_path,
    panel_paths = collected_paths,
    layout = list(columns = columns, rows = rows)
  )
}
