#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L) {
  stop("Usage: Rscript scripts/run_project.R settings.yaml", call. = FALSE)
}

settings_path <- args[[1]]

if (!requireNamespace("localmap", quietly = TRUE)) {
  if (requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(".")
  } else {
    stop("Package 'localmap' is not installed. Install it or add pkgload.", call. = FALSE)
  }
}

localmap::run_settings(settings_path)
