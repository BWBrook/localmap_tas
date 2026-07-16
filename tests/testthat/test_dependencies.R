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

testthat::test_that("plain R startup keeps sandbox paths valid after cwd changes", {
  project_root <- normalizePath(
    testthat::test_path("..", ".."),
    winslash = "/",
    mustWork = TRUE
  )
  probe <- tempfile(fileext = ".R")
  writeLines(
    c(
      "is_absolute <- function(path) {",
      "  slash <- intToUtf8(92L)",
      paste0(
        "  startsWith(path, '/') || grepl('^[A-Za-z]:', path) || ",
        "startsWith(path, paste0(slash, slash))"
      ),
      "}",
      "sandbox <- Sys.getenv('RENV_PATHS_SANDBOX')",
      paste0(
        "expected_sandbox <- normalizePath(file.path(getwd(), 'renv', 'sandbox'), ",
        "winslash = '/', mustWork = TRUE)"
      ),
      "sandbox <- normalizePath(sandbox, winslash = '/', mustWork = TRUE)",
      "grid_before <- find.package('grid')",
      "setwd('man')",
      "grid_after <- find.package('grid')",
      "checks <- c(",
      "  sandbox_exact = identical(sandbox, expected_sandbox),",
      "  sandbox_absolute = is_absolute(sandbox),",
      "  base_library_absolute = is_absolute(.Library),",
      "  library_paths_absolute = all(vapply(.libPaths(), is_absolute, logical(1))),",
      "  grid_before_absolute = is_absolute(grid_before),",
      "  grid_after_absolute = is_absolute(grid_after),",
      "  grid_path_stable = identical(grid_before, grid_after),",
      "  grid_namespace_exists = file.exists(file.path(grid_after, 'NAMESPACE'))",
      ")",
      "cat(paste(names(checks), checks, sep = '='), sep = '\\n')",
      "if (!all(checks)) quit(status = 1L)"
    ),
    probe
  )

  withr::local_envvar(c(
    R_LIBS = NA,
    R_CMD = NA,
    R_LIBS_USER = NA,
    RENV_PATHS_SANDBOX = NA
  ))
  output <- withr::with_dir(
    project_root,
    suppressWarnings(system2(file.path(R.home("bin"), "Rscript"), probe,
      stdout = TRUE, stderr = TRUE
    ))
  )
  status <- attr(output, "status", exact = TRUE)
  if (is.null(status)) status <- 0L

  testthat::expect_identical(status, 0L, info = paste(output, collapse = "\n"))
})

testthat::test_that("sandbox startup test clears inherited state and checks exact path", {
  path <- testthat::test_path("test_dependencies.R")
  lines <- readLines(path, warn = FALSE)
  start <- grep(
    'testthat::test_that\\("plain R startup keeps sandbox paths valid',
    lines
  )
  later_tests <- grep("^testthat::test_that", lines)
  end <- later_tests[later_tests > start][[1L]] - 1L
  target_test <- lines[start:end]

  testthat::expect_true(any(grepl(
    "RENV_PATHS_SANDBOX = NA",
    target_test,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl("sandbox_exact", target_test, fixed = TRUE)))
})
