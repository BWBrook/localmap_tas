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

restore_project_library <- function(
  activation_path = "renv/activate.R",
  restore = function() renv::restore(prompt = FALSE)
) {
  if (!file.exists(activation_path)) {
    return(restore())
  }

  original <- readBin(
    activation_path,
    what = "raw",
    n = file.info(activation_path)$size
  )
  on.exit(writeBin(original, activation_path), add = TRUE)
  restore()
}

command_exists <- function(command) {
  nzchar(Sys.which(command))
}

pkg_config_has <- function(module) {
  if (!command_exists("pkg-config")) {
    return(FALSE)
  }
  identical(
    suppressWarnings(system2("pkg-config", c("--exists", module), stdout = NULL, stderr = NULL)),
    0L
  )
}

brew_prefix <- function(formula) {
  if (!command_exists("brew")) {
    return("")
  }
  out <- tryCatch(
    suppressWarnings(system2("brew", c("--prefix", formula), stdout = TRUE, stderr = TRUE)),
    error = function(e) character()
  )
  if (!length(out)) {
    return("")
  }
  prefix <- out[[1]]
  if (dir.exists(prefix)) prefix else ""
}

missing_system_requirements <- function() {
  sysname <- Sys.info()[["sysname"]]
  if (!identical(sysname, "Darwin")) {
    return(character())
  }

  missing <- character()
  if (!command_exists("gdal-config")) missing <- c(missing, "gdal")
  if (!command_exists("geos-config")) missing <- c(missing, "geos")
  if (!command_exists("proj")) missing <- c(missing, "proj")
  udunits_prefix <- brew_prefix("udunits")
  has_udunits <- pkg_config_has("udunits2") ||
    command_exists("udunits2") ||
    (nzchar(udunits_prefix) && file.exists(file.path(udunits_prefix, "lib", "libudunits2.dylib")))
  if (!has_udunits) missing <- c(missing, "udunits")
  if (!pkg_config_has("arrow")) missing <- c(missing, "apache-arrow")

  unique(missing)
}

check_system_requirements <- function() {
  missing <- missing_system_requirements()
  if (!length(missing)) {
    return(invisible(TRUE))
  }

  if (identical(Sys.info()[["sysname"]], "Darwin")) {
    stop(
      paste(
        "Missing required macOS system libraries for localmap_tas.",
        paste("Install them with Homebrew: brew install", paste(missing, collapse = " ")),
        "Then rerun the bootstrap or restore command.",
        sep = "\n"
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}
