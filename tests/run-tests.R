# Run tests for the localmap package (triggered by `R CMD check`).

if (requireNamespace("testthat", quietly = TRUE)) {
  library(localmap)
  testthat::test_dir("testthat", reporter = "summary")
}
