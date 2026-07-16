testthat::test_that("project restore preserves renv activation bytes", {
  helpers <- new.env(parent = baseenv())
  sys.source(
    testthat::test_path("..", "..", "dependencies.R"),
    envir = helpers
  )

  activation_path <- tempfile(fileext = ".R")
  original <- charToRaw("local({\n  value <- TRUE\n})\n")
  writeBin(original, activation_path)

  helpers$restore_project_library(
    activation_path = activation_path,
    restore = function() writeBin(charToRaw("local({  \n})\n"), activation_path)
  )

  actual <- readBin(
    activation_path,
    what = "raw",
    n = file.info(activation_path)$size
  )
  testthat::expect_identical(actual, original)
})

testthat::test_that("project restore preserves bytes and errors on failure", {
  helpers <- new.env(parent = baseenv())
  sys.source(
    testthat::test_path("..", "..", "dependencies.R"),
    envir = helpers
  )

  activation_path <- tempfile(fileext = ".R")
  original <- charToRaw("local({\n  value <- TRUE\n})\n")
  writeBin(original, activation_path)
  restore_error <- structure(
    list(message = "restore callback failed", call = NULL),
    class = c("localmap_restore_failure", "error", "condition")
  )

  caught <- tryCatch(
    helpers$restore_project_library(
      activation_path = activation_path,
      restore = function() {
        writeBin(charToRaw("local({  \n})\n"), activation_path)
        stop(restore_error)
      }
    ),
    error = identity
  )

  actual <- readBin(
    activation_path,
    what = "raw",
    n = file.info(activation_path)$size
  )
  testthat::expect_identical(actual, original)
  testthat::expect_s3_class(caught, "localmap_restore_failure")
  testthat::expect_identical(conditionMessage(caught), "restore callback failed")
})

testthat::test_that("bootstrap uses the byte-preserving project restore", {
  bootstrap_path <- testthat::test_path("..", "..", "scripts", "bootstrap.R")
  expressions <- parse(file = bootstrap_path)
  code <- paste(
    vapply(expressions, deparse1, character(1), width.cutoff = 500L),
    collapse = "\n"
  )

  testthat::expect_match(code, "restore_project_library\\(\\)")
  testthat::expect_false(grepl("renv::restore\\s*\\(", code, perl = TRUE))
})
