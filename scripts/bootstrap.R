# Bootstrap script for local setup (run in RStudio Console)

message("Restoring renv and preparing the project library...")
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
renv::restore(prompt = FALSE)
if (requireNamespace("devtools", quietly = TRUE)) devtools::document()
message(
  paste(
    "Done. The renv library is ready.",
    "If you are intentionally working outside renv, run",
    "source('dependencies.R'); install_project_dependencies()."
  )
)
