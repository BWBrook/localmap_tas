testthat::local_edition(3)
set.seed(1)
base_lib <- file.path(R.home("library"))
if (!base_lib %in% .libPaths()) {
  .libPaths(c(base_lib, .libPaths()))
}
invisible(requireNamespace("parallel", quietly = TRUE))
Sys.setenv(VROOM_THREADS = "1")
