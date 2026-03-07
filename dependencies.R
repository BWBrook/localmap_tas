# Dependency helpers for contributors and QA workflows.

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

# Returns package names declared in DESCRIPTION.
project_dependencies <- function(fields = c("Depends", "Imports", "Suggests")) {
  read_description_dependencies(fields)
}

project_runtime_dependencies <- function() {
  project_dependencies(fields = c("Depends", "Imports", "LinkingTo"))
}

project_qa_dependencies <- function() {
  project_dependencies(fields = "Suggests")
}

qa_library_path <- function() {
  minor <- strsplit(R.version$minor, ".", fixed = TRUE)[[1]][1]
  file.path(
    tools::R_user_dir("localmap", which = "cache"),
    "qa-library",
    paste0("R-", R.version$major, ".", minor)
  )
}

with_qa_library <- function(expr, lib = qa_library_path()) {
  dir.create(lib, recursive = TRUE, showWarnings = FALSE)
  old_paths <- .libPaths()
  on.exit(.libPaths(old_paths), add = TRUE)
  .libPaths(c(normalizePath(lib, winslash = "/", mustWork = FALSE), old_paths))
  eval.parent(substitute(expr))
}

install_missing_packages <- function(pkgs, lib = NULL) {
  pkgs <- unique(pkgs[nzchar(pkgs)])

  installer <- function() {
    missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]

    if (!length(missing)) {
      message("All requested packages are already installed.")
      return(invisible(TRUE))
    }

    if (requireNamespace("pak", quietly = TRUE)) {
      pak::pkg_install(missing)
    } else {
      install.packages(missing, dependencies = TRUE)
    }

    invisible(TRUE)
  }

  if (is.null(lib)) {
    return(installer())
  }

  with_qa_library(installer(), lib = lib)
}

# Optional helper: install any DESCRIPTION packages still missing from the
# active library. Use this only when you are intentionally not restoring the
# project via renv.
install_project_dependencies <- function(pkgs = project_dependencies()) {
  install_missing_packages(pkgs)
}

# Optional helper: install Suggests-based QA packages into a separate cache
# library so runtime `renv` state stays focused on execution dependencies.
install_project_qa_dependencies <- function(pkgs = project_qa_dependencies(),
                                            lib = qa_library_path()) {
  install_missing_packages(pkgs, lib = lib)
}
