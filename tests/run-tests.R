# Run tests for the localmap package from the repository root.

if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::test(reporter = "summary")
} else if (requireNamespace("testthat", quietly = TRUE)) {
  testthat::test_local(".", reporter = "summary")
}
