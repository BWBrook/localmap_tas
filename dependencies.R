# Dependency helper for contributors who are not relying on renv::restore().

read_description_dependencies <- function(
  fields = c("Depends", "Imports", "Suggests")
) {
  desc <- read.dcf("DESCRIPTION", all = TRUE)
  available_fields <- intersect(fields, colnames(desc))

  if (!length(available_fields)) {
    return(character())
  }

  entries <- unlist(
    strsplit(paste(desc[1, available_fields], collapse = ","), ",", fixed = TRUE),
    use.names = FALSE
  )
  pkgs <- trimws(sub("\\s*\\(.*\\)$", "", entries))
  unique(pkgs[nzchar(pkgs) & pkgs != "R"])
}

# Returns the package names declared in DESCRIPTION.
project_dependencies <- function() {
  read_description_dependencies()
}

# Optional helper: install any DESCRIPTION packages that are still missing from
# the active library. Use this only when you are intentionally not restoring the
# project via renv.
install_project_dependencies <- function(pkgs = project_dependencies()) {
  pkgs <- unique(pkgs[nzchar(pkgs)])
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]

  if (!length(missing)) {
    message("All DESCRIPTION packages are already installed.")
    return(invisible(TRUE))
  }

  if (requireNamespace("pak", quietly = TRUE)) {
    pak::pkg_install(missing)
  } else {
    install.packages(missing, dependencies = TRUE)
  }

  invisible(TRUE)
}
