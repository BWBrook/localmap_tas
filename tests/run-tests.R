# Run package tests in a way that is compatible with `R CMD check`.

if (requireNamespace("testthat", quietly = TRUE)) {
  testthat::test_check("localmap")
}
