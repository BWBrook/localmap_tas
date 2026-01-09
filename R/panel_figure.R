#' Assemble a multi-panel figure with optional PDF export
#'
#' @param panel_cfg Panel configuration list (paths, layout, labels, output).
#' @param prerequisites Optional list to force dependencies.
#' @return List with `png` and `pdf` paths.
#' @export
assemble_panel_figure <- function(panel_cfg, prerequisites = NULL) {
  force(prerequisites)
  if (is.null(panel_cfg) || !is.list(panel_cfg)) {
    rlang::abort("Panel figure configuration is required.", class = "panel_figure_missing_config")
  }

  png_path <- camera_sites_stack_maps(panel_cfg, prerequisites = prerequisites)

  export_pdf <- panel_cfg$export_pdf
  if (is.null(export_pdf)) {
    export_pdf <- TRUE
  }

  pdf_path <- panel_cfg$output_pdf
  if (is.null(pdf_path) || !nzchar(pdf_path)) {
    pdf_path <- sub("\\.png$", ".pdf", png_path)
    if (!nzchar(pdf_path) || identical(pdf_path, png_path)) {
      pdf_path <- paste0(png_path, ".pdf")
    }
  }

  if (isTRUE(export_pdf)) {
    img <- png::readPNG(png_path)
    width_px <- dim(img)[2]
    height_px <- dim(img)[1]
    width_in <- panel_cfg$pdf_width
    height_in <- panel_cfg$pdf_height
    if (is.null(width_in) || !is.finite(width_in)) {
      width_in <- width_px / 300
    }
    if (is.null(height_in) || !is.finite(height_in)) {
      height_in <- height_px / 300
    }
    dir.create(dirname(pdf_path), recursive = TRUE, showWarnings = FALSE)
    grDevices::pdf(pdf_path, width = width_in, height = height_in)
    grid::grid.newpage()
    grid::grid.raster(
      img,
      width = grid::unit(1, "npc"),
      height = grid::unit(1, "npc"),
      interpolate = TRUE
    )
    grDevices::dev.off()
  } else {
    pdf_path <- NA_character_
  }

  list(png = png_path, pdf = pdf_path)
}
