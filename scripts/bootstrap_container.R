# Minimal bootstrap for container builds (renv restore only).

message("[container bootstrap] Restoring renv and installing project dependencies...")
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}

# Avoid pak auto-install (can fail in slim images or slow builds)
Sys.setenv(RENV_CONFIG_PAK_ENABLED = "FALSE")
options(repos = c(CRAN = "https://cloud.r-project.org"))

if (file.exists("renv.lock")) {
  renv::restore(prompt = FALSE)
} else {
  renv::init(bare = TRUE)
  renv::snapshot(prompt = FALSE)
}

message("[container bootstrap] Done.")
