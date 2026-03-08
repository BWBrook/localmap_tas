source("renv/activate.R")
options(repos = c(CRAN = "https://cloud.r-project.org"))
Sys.setenv(RENV_CONFIG_USE_CACHE = "TRUE")
if (!nzchar(Sys.getenv("RENV_CONFIG_PAK_ENABLED", unset = ""))) {
  Sys.setenv(RENV_CONFIG_PAK_ENABLED = "TRUE")
}
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
# Activate renv if present (no-op before init)
if (file.exists("renv/activate.R")) source("renv/activate.R")
