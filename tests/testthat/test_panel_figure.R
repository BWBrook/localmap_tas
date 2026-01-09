testthat::test_that("assemble_panel_figure creates PNG and PDF", {
  tmp_dir <- tempfile(pattern = "panel_fig")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  cols <- list(
    c(0.9, 0.4, 0.4),
    c(0.4, 0.9, 0.4),
    c(0.4, 0.4, 0.9),
    c(0.9, 0.9, 0.4)
  )
  paths <- file.path(tmp_dir, sprintf("panel_%02d.png", seq_along(cols)))
  for (i in seq_along(cols)) {
    img <- array(1, dim = c(30, 30, 4))
    img[, , 1] <- cols[[i]][[1]]
    img[, , 2] <- cols[[i]][[2]]
    img[, , 3] <- cols[[i]][[3]]
    img[, , 4] <- 1
    png::writePNG(img, target = paths[[i]])
  }

  output_png <- file.path(tmp_dir, "panel_figure.png")
  output_pdf <- file.path(tmp_dir, "panel_figure.pdf")

  res <- localmap::assemble_panel_figure(
    panel_cfg = list(
      paths = paths,
      output_path = output_png,
      output_pdf = output_pdf,
      columns = 2,
      rows = 2,
      labels = list(values = c("a)", "b)", "c)", "d)"))
    )
  )

  testthat::expect_true(file.exists(res$png))
  testthat::expect_true(file.exists(res$pdf))
})
