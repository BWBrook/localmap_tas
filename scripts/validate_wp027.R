.wp027_script_file <- local({
  frames <- sys.frames()
  candidates <- vapply(
    frames,
    function(frame) {
      if (is.null(frame$ofile)) NA_character_ else as.character(frame$ofile)
    },
    character(1)
  )
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]
  if (length(candidates) > 0L) {
    path <- candidates[[length(candidates)]]
  } else {
    file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
    path <- if (length(file_arg) == 1L) sub("^--file=", "", file_arg) else NA_character_
  }
  if (is.na(path)) NA_character_ else normalizePath(path, winslash = "/", mustWork = FALSE)
})

.wp027_root <- if (is.na(.wp027_script_file)) {
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
} else {
  normalizePath(dirname(dirname(.wp027_script_file)), winslash = "/", mustWork = TRUE)
}

.wp027_stable_exports <- c(
  "cfg_read",
  "run_settings",
  "ala_fetch_occurrences",
  "ala_resolve_species",
  "assemble_panel_figure",
  "build_aoi_from_config",
  "build_coverage_zone",
  "build_site_attributes_long",
  "fetch_analysis_layers",
  "map_species_occurrences",
  "read_species_requests",
  "render_overview_map",
  "validate_output_manifest"
)

.wp027_stable_formals <- list(
  cfg_read = c(
    profile = "Sys.getenv(\"R_CONFIG_ACTIVE\", \"default\")",
    config_path = "NULL"
  ),
  run_settings = c(
    settings_path = "<missing>",
    targets = "NULL",
    base_profile = "NULL",
    config_path = "NULL"
  ),
  ala_fetch_occurrences = c(
    taxa = "<missing>",
    min_year = "NULL",
    boundary = "NULL",
    boundary_simplify = "NULL",
    columns = "ala_default_occurrence_fields()",
    min_lat = "NULL",
    state_province = "NULL",
    fetch_fun = "NULL",
    config = "NULL"
  ),
  ala_resolve_species = c(
    species_requests = "<missing>",
    search_fun = "galah::search_taxa"
  ),
  assemble_panel_figure = c(
    panel_cfg = "<missing>",
    prerequisites = "NULL"
  ),
  build_aoi_from_config = c(
    aoi_cfg = "<missing>",
    sites = "NULL"
  ),
  build_coverage_zone = c(
    sites = "<missing>",
    coverage_cfg = "NULL",
    analysis_crs = "\"EPSG:28355\""
  ),
  build_site_attributes_long = c(
    sites = "<missing>",
    analysis_layers = "<missing>",
    aoi = "NULL",
    analysis_crs = "NULL",
    distance_layers = "NULL"
  ),
  fetch_analysis_layers = c(
    layers = "<missing>",
    aoi = "<missing>",
    cache_dir = "NULL"
  ),
  map_species_occurrences = c(
    occurrences = "<missing>",
    mapping_settings = "NULL",
    aoi = "NULL",
    output_path = "NULL"
  ),
  read_species_requests = c(path = "<missing>"),
  render_overview_map = c(
    aoi = "<missing>",
    sites = "<missing>",
    coverage = "NULL",
    layers = "NULL",
    map_cfg = "NULL"
  ),
  validate_output_manifest = c(
    manifest = "<missing>",
    expected_outputs = "NULL"
  )
)

.wp027_internal_names <- c(
  "ala_default_occurrence_fields",
  "build_layer_provenance",
  "combine_manifest_csvs",
  "fetch_arcgis_imagery",
  "fetch_wms_imagery",
  "preview_manifest",
  "validate_analysis_layers",
  "validate_layer_registry",
  "write_attribution_report",
  "write_coverage_summary",
  "write_run_manifest",
  "write_site_attributes_long",
  "write_site_attributes_wide"
)

.wp027_allowed_internal_paths <- c(
  "tests/testthat/test_provenance_outputs.R",
  "tests/testthat/test_combine.R",
  "tests/testthat/test_imagery_arcgis.R",
  "tests/testthat/test_imagery_wms.R",
  "tests/testthat/test_network_optional.R",
  "tests/testthat/test_preview.R",
  "tests/testthat/test_analysis_layers.R",
  "tests/testthat/test_layer_registry.R",
  "tests/testthat/test_site_attributes.R"
)

.wp027_migrated_test_counts <- setNames(
  c(2L, 1L, 3L, 4L, 1L, 1L, 12L, 3L, 5L),
  .wp027_allowed_internal_paths
)

.wp027_migrated_expectation_counts <- setNames(
  c(13L, 3L, 6L, 7L, 1L, 2L, 27L, 4L, 17L),
  .wp027_allowed_internal_paths
)

.wp027_suite_minima <- c(test_that = 92L, expectations = 243L)
.wp027_warning_baselines <- c(focused = 6L, full = 7L)
.wp027_skip_baselines <- c(focused = 1L, full = 1L)
.wp027_network_skip <-
  "Network fetch disabled (set LOCALMAP_ALLOW_NETWORK=1 to enable)."

.wp027_network_skip_test <- paste0(
  "network imagery fetch is gated behind LOCALMAP_ALLOW_NETWORK ",
  "('test_network_optional.R:3:5')"
)

.wp027_accepted_warnings <- data.frame(
  test = c(
    paste0(
      "arcgis vector fetch is gated without network or fixture ",
      "('test_analysis_layers.R:289:3')"
    ),
    paste0(
      "arcgis raster fetch falls back to fixture when offline ",
      "('test_analysis_layers.R:323:3')"
    ),
    paste0(
      "arcgis raster fetch errors when offline without fixture ",
      "('test_analysis_layers.R:354:3')"
    ),
    paste0(
      "arcgis vector fixtures are clipped in AOI CRS ",
      "('test_analysis_layers.R:382:3')"
    ),
    paste0(
      "fetch_arcgis_imagery respects network gating ",
      "('test_imagery_arcgis.R:75:3')"
    ),
    paste0(
      "fetch_wms_imagery respects network gating ",
      "('test_imagery_wms.R:80:3')"
    ),
    paste0(
      "camera_sites_stack_maps stacks PNGs vertically ",
      "('test-camera-sites-map.R:156:3')"
    )
  ),
  text = c(
    paste0(
      "Network access disabled; ArcGIS vector layer 'arcgis_vec' requires a ",
      "fixture or LOCALMAP_ALLOW_NETWORK=1."
    ),
    paste0(
      "Network access disabled; ArcGIS raster layer 'arcgis_raster' requires a ",
      "fixture or LOCALMAP_ALLOW_NETWORK=1."
    ),
    paste0(
      "Network access disabled; ArcGIS raster layer 'arcgis_raster' requires a ",
      "fixture or LOCALMAP_ALLOW_NETWORK=1."
    ),
    "attribute variables are assumed to be spatially constant throughout all geometries",
    "Network access disabled; using offline placeholder for ArcGIS imagery.",
    "Network access disabled; using offline placeholder for WMS imagery.",
    paste0(
      "Panel images differ in size; bounding boxes may not match. Consider ",
      "normalize_sizes = TRUE."
    )
  ),
  stringsAsFactors = FALSE
)

.wp027_command_columns <- c(
  "sequence",
  "gate",
  "kind",
  "started_utc",
  "ended_utc",
  "command",
  "arguments",
  "environment",
  "exit_status",
  "stdout_path",
  "stderr_path"
)

.wp027_gate_order <- c(
  "Bootstrap",
  "QA bootstrap",
  "Package metadata",
  "Tests",
  "Test contracts",
  "Harness fixture",
  "Lint",
  "JC demonstration",
  "Quarto",
  "pkgdown",
  "Report",
  "Artifact assertions",
  "Relative links",
  "Package check",
  "Diff hygiene",
  "Evidence collection"
)

.wp027_jc_environment <- c(
  "LOCALMAP_ALLOW_NETWORK=0",
  "LOCALMAP_ALLOW_LARGE_DOWNLOADS=0",
  "R_CONFIG_ACTIVE=jc_ci",
  "TARGETS_PROFILE=ci"
)

.wp027_report_environment <- c(
  "R_CONFIG_ACTIVE=jc_ci",
  "TARGETS_PROFILE=ci"
)

.wp027_required_jc_paths <- c(
  "outputs/jc/maps/species_occurrences.png",
  "outputs/jc/maps/overview_map.png",
  "outputs/jc/maps/panel_figure.png",
  "outputs/jc/maps/panel_figure.pdf",
  "outputs/jc/maps/camera_sites.png",
  "outputs/jc/maps/camera_sites_panel.png",
  "outputs/jc/tables/coverage_summary.csv",
  "outputs/jc/tables/site_attributes_long.parquet",
  "outputs/jc/tables/site_attributes_wide.csv",
  "outputs/jc/layers/tasveg_wms.png",
  "outputs/jc/layers/topography_arcgis.png"
)

.wp027_required_docs_paths <- c(
  "outputs/quarto/index.html",
  "outputs/pkgdown/index.html",
  file.path("outputs/pkgdown/reference", paste0(.wp027_stable_exports, ".html")),
  file.path(
    "outputs/pkgdown/reference",
    paste0(
      c(
        "ala_configure",
        "fetch_layer_registry",
        "generate_topo_tile_map",
        "read_manifest"
      ),
      ".html"
    )
  )
)

.wp027_required_report_paths <- "outputs/reports/paper.html"

.wp027_approved_design_commit <- "a55733d860f78e48753749977ce69d6a2e0d2b41"
.wp027_post_task2_commit <- "9938ba84a80e10773cf5dab19bca54cf0e60f1be"

wp027_normalize_formals <- function(fn) {
  values <- formals(fn)
  normalized <- vapply(
    seq_along(values),
    function(index) {
      if (identical(values[[index]], quote(expr = ))) {
        "<missing>"
      } else {
        deparse1(values[[index]], width.cutoff = 500L)
      }
    },
    character(1)
  )
  names(normalized) <- names(values)
  normalized
}

wp027_count_matches <- function(text, pattern) {
  matches <- gregexpr(pattern, text, perl = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) 0L else as.integer(length(matches))
}

wp027_inventory_tests <- function(root = .wp027_root) {
  test_root <- file.path(root, "tests", "testthat")
  paths <- sort(list.files(test_root, "[.]R$", full.names = TRUE))
  records <- lapply(paths, function(path) {
    text <- paste(readLines(path, warn = FALSE), collapse = "\n")
    data.frame(
      path = substring(
        normalizePath(path, winslash = "/", mustWork = TRUE),
        nchar(normalizePath(root, winslash = "/", mustWork = TRUE)) + 2L
      ),
      test_that = wp027_count_matches(text, "\\btest_that\\s*\\("),
      expectations = wp027_count_matches(text, "\\bexpect_[[:alnum:]_]+\\s*\\("),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, records)
}

wp027_scan_internal_references <- function(root = .wp027_root) {
  test_root <- file.path(root, "tests")
  paths <- sort(list.files(test_root, "[.]R$", recursive = TRUE, full.names = TRUE))
  names_pattern <- paste(.wp027_internal_names, collapse = "|")
  pattern <- paste0("localmap(:::|::)(", names_pattern, ")\\b")
  records <- list()
  record_index <- 0L
  normalized_root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  for (path in paths) {
    lines <- readLines(path, warn = FALSE)
    for (line_number in seq_along(lines)) {
      locations <- gregexpr(pattern, lines[[line_number]], perl = TRUE)
      matches <- regmatches(lines[[line_number]], locations)[[1L]]
      if (length(matches) == 1L && identical(matches, character(0))) next
      for (match in matches) {
        if (!nzchar(match)) next
        record_index <- record_index + 1L
        operator <- if (grepl("localmap:::", match, fixed = TRUE)) ":::" else "::"
        records[[record_index]] <- data.frame(
          path = substring(
            normalizePath(path, winslash = "/", mustWork = TRUE),
            nchar(normalized_root) + 2L
          ),
          line = as.integer(line_number),
          operator = operator,
          name = sub("^localmap:{2,3}", "", match),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  if (length(records) == 0L) {
    return(data.frame(
      path = character(),
      line = integer(),
      operator = character(),
      name = character(),
      stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, records)
}

wp027_assert_nonempty <- function(paths) {
  info <- file.info(paths)
  valid <- !is.na(info$isdir) & !info$isdir & !is.na(info$size) & info$size > 0
  if (!all(valid)) {
    stop(
      paste("Missing or empty artifact:", paste(paths[!valid], collapse = ", ")),
      call. = FALSE
    )
  }
  invisible(normalizePath(paths, winslash = "/", mustWork = TRUE))
}

wp027_extract_relative_links <- function(path) {
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  pattern <- "(?i)\\bhref\\s*=\\s*(['\"])(.*?)\\1"
  matches <- regmatches(text, gregexpr(pattern, text, perl = TRUE))[[1L]]
  if (length(matches) == 1L && identical(matches, character(0))) return(character())

  hrefs <- sub(pattern, "\\2", matches, perl = TRUE)
  hrefs <- gsub("&amp;", "&", hrefs, fixed = TRUE)
  relative <- !grepl("^[[:alpha:]][[:alnum:]+.-]*:", hrefs) &
    !grepl("^(//|/|#)", hrefs)
  hrefs <- hrefs[relative]
  hrefs <- sub("[?#].*$", "", hrefs)
  hrefs <- utils::URLdecode(hrefs)
  unique(hrefs[nzchar(hrefs)])
}

wp027_path_relative <- function(path, root) {
  normalized_root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  normalized_path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(normalized_root, "/")
  if (startsWith(normalized_path, prefix)) {
    substring(normalized_path, nchar(prefix) + 1L)
  } else if (identical(normalized_path, normalized_root)) {
    "."
  } else {
    normalized_path
  }
}

wp027_scan_relative_links <- function(root) {
  html_paths <- sort(list.files(
    root,
    "[.]html?$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  ))
  records <- list()
  record_index <- 0L

  for (source in html_paths) {
    hrefs <- wp027_extract_relative_links(source)
    for (href in hrefs) {
      record_index <- record_index + 1L
      target <- file.path(dirname(source), href)
      records[[record_index]] <- data.frame(
        source = wp027_path_relative(source, root),
        href = href,
        target = wp027_path_relative(target, root),
        exists = file.exists(target),
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(records) == 0L) {
    return(data.frame(
      source = character(),
      href = character(),
      target = character(),
      exists = logical(),
      stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, records)
}

wp027_regular_files <- function(run_dir) {
  entries <- list.files(
    run_dir,
    recursive = TRUE,
    all.files = TRUE,
    full.names = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  )
  info <- file.info(entries)
  files <- entries[!is.na(info$isdir) & !info$isdir]
  relative <- vapply(files, wp027_path_relative, character(1), root = run_dir)
  sort(setdiff(relative, "SHA256SUMS"))
}

wp027_hash_manifest <- function(run_dir) {
  run_dir <- normalizePath(run_dir, winslash = "/", mustWork = TRUE)
  relative <- wp027_regular_files(run_dir)
  if (any(grepl("[\r\n]", relative))) {
    stop("Hash manifest paths must not contain newlines.", call. = FALSE)
  }
  absolute <- file.path(run_dir, relative)
  hashes <- unname(tools::sha256sum(absolute))
  if (any(is.na(hashes))) stop("Unable to hash every evidence file.", call. = FALSE)
  lines <- sprintf("%s  %s", hashes, relative)
  writeLines(lines, file.path(run_dir, "SHA256SUMS"), useBytes = TRUE)
  invisible(file.path(run_dir, "SHA256SUMS"))
}

wp027_fail_hash_verification <- function() {
  stop("SHA256 verification failed", call. = FALSE)
}

wp027_verify_hash_manifest <- function(run_dir) {
  run_dir <- normalizePath(run_dir, winslash = "/", mustWork = TRUE)
  manifest <- file.path(run_dir, "SHA256SUMS")
  if (!file.exists(manifest)) wp027_fail_hash_verification()
  lines <- readLines(manifest, warn = FALSE)
  if (length(lines) == 0L || any(!grepl("^[0-9a-fA-F]{64}  .+$", lines))) {
    wp027_fail_hash_verification()
  }
  expected_hashes <- tolower(sub("  .*$", "", lines))
  expected_paths <- sub("^[0-9a-fA-F]{64}  ", "", lines)
  actual_paths <- wp027_regular_files(run_dir)
  if (!identical(expected_paths, actual_paths)) wp027_fail_hash_verification()
  actual_hashes <- tolower(unname(tools::sha256sum(file.path(run_dir, actual_paths))))
  if (any(is.na(actual_hashes)) || !identical(expected_hashes, actual_hashes)) {
    wp027_fail_hash_verification()
  }
  invisible(TRUE)
}

wp027_verify_hash_manifest_system2 <- function(run_dir) {
  wp027_verify_hash_manifest(run_dir)
  old <- setwd(run_dir)
  on.exit(setwd(old), add = TRUE)
  output <- suppressWarnings(system2(
    command = "shasum",
    args = c("-a", "256", "-c", "SHA256SUMS"),
    env = character(),
    stdout = TRUE,
    stderr = TRUE
  ))
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  if (!identical(as.integer(status), 0L)) wp027_fail_hash_verification()
  invisible(TRUE)
}

wp027_promote_verified <- function(temp_run, final_run) {
  temp_run <- normalizePath(temp_run, winslash = "/", mustWork = TRUE)
  temp_parent <- normalizePath(dirname(temp_run), winslash = "/", mustWork = TRUE)
  final_parent <- normalizePath(dirname(final_run), winslash = "/", mustWork = TRUE)
  if (!identical(temp_parent, final_parent)) {
    stop("Atomic promotion requires source and destination siblings.", call. = FALSE)
  }
  if (file.exists(final_run)) {
    stop("Canonical destination already exists.", call. = FALSE)
  }
  wp027_verify_hash_manifest(temp_run)
  if (!file.rename(temp_run, final_run)) {
    stop("Atomic file.rename() promotion failed; temporary evidence retained.", call. = FALSE)
  }
  normalizePath(final_run, winslash = "/", mustWork = TRUE)
}

wp027_utc <- function(time = Sys.time()) {
  format(time, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

wp027_slug <- function(value) {
  slug <- tolower(gsub("[^[:alnum:]]+", "-", value))
  gsub("(^-|-$)", "", slug)
}

wp027_encode_vector <- function(values) {
  if (length(values) == 0L) return("[]")
  encoded <- vapply(values, encodeString, character(1), quote = "\"")
  paste0("[", paste(encoded, collapse = ","), "]")
}

wp027_system2_executor <- function(command, arguments, environment, stdout, stderr) {
  quoted_arguments <- vapply(arguments, shQuote, character(1))
  status <- system2(
    command = command,
    args = quoted_arguments,
    env = environment,
    stdout = stdout,
    stderr = stderr
  )
  if (is.null(status)) 0L else as.integer(status)
}

wp027_run_gate <- function(spec, sequence, run_dir, executor = wp027_system2_executor) {
  steps_dir <- file.path(run_dir, "steps")
  dir.create(steps_dir, recursive = TRUE, showWarnings = FALSE)
  stem <- sprintf("%02d-%s", as.integer(sequence), wp027_slug(spec$gate))
  stdout_relative <- file.path("steps", paste0(stem, ".stdout.log"))
  stderr_relative <- file.path("steps", paste0(stem, ".stderr.log"))
  stdout_path <- file.path(run_dir, stdout_relative)
  stderr_path <- file.path(run_dir, stderr_relative)
  file.create(stdout_path, stderr_path)
  started <- wp027_utc()
  detail <- ""

  status <- tryCatch({
    if (identical(spec$kind, "internal")) {
      value <- spec$action(run_dir)
      if (length(value) > 0L) writeLines(as.character(value), stdout_path)
      0L
    } else {
      as.integer(executor(
        command = spec$command,
        arguments = spec$arguments,
        environment = spec$environment,
        stdout = stdout_path,
        stderr = stderr_path
      ))
    }
  }, error = function(error) {
    detail <<- conditionMessage(error)
    writeLines(detail, stderr_path)
    1L
  })
  ended <- wp027_utc()
  if (status != 0L && !nzchar(detail)) {
    stderr_lines <- readLines(stderr_path, warn = FALSE)
    detail <- if (length(stderr_lines) > 0L) {
      stderr_lines[[length(stderr_lines)]]
    } else {
      paste("exit status", status)
    }
  }

  row <- data.frame(
    sequence = as.integer(sequence),
    gate = spec$gate,
    kind = spec$kind,
    started_utc = started,
    ended_utc = ended,
    command = spec$command,
    arguments = wp027_encode_vector(spec$arguments),
    environment = wp027_encode_vector(spec$environment),
    exit_status = as.integer(status),
    stdout_path = stdout_relative,
    stderr_path = stderr_relative,
    stringsAsFactors = FALSE
  )
  row <- row[, .wp027_command_columns, drop = FALSE]
  list(row = row, status = as.integer(status), detail = detail)
}

wp027_write_tsv <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(
    data,
    path,
    sep = "\t",
    quote = TRUE,
    row.names = FALSE,
    col.names = TRUE,
    qmethod = "double",
    na = ""
  )
  invisible(path)
}

wp027_append_command <- function(row, path) {
  utils::write.table(
    row,
    path,
    sep = "\t",
    quote = TRUE,
    row.names = FALSE,
    col.names = !file.exists(path),
    append = file.exists(path),
    qmethod = "double",
    na = ""
  )
}

wp027_execute_specs <- function(specs, run_dir, executor = wp027_system2_executor) {
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)
  commands_path <- file.path(run_dir, "commands.tsv")
  validation_path <- file.path(run_dir, "validation.log")
  if (file.exists(commands_path) || file.exists(validation_path)) {
    stop("Execution ledgers already exist in the run directory.", call. = FALSE)
  }

  rows <- vector("list", length(specs))
  for (index in seq_along(specs)) {
    result <- wp027_run_gate(specs[[index]], index, run_dir, executor)
    rows[[index]] <- result$row
    wp027_append_command(result$row, commands_path)
    outcome <- if (result$status == 0L) "PASS" else "FAIL"
    cat(
      sprintf(
        "%s\t%02d\t%s\t%s\tstatus=%d\n",
        wp027_utc(),
        index,
        specs[[index]]$gate,
        outcome,
        result$status
      ),
      file = validation_path,
      append = TRUE
    )
    if (result$status != 0L) {
      writeLines(
        c(
          paste0("gate=", specs[[index]]$gate),
          paste0("status=", result$status),
          paste0("detail=", result$detail)
        ),
        file.path(run_dir, "FAILED")
      )
      message("Retained WP-027 evidence: ", normalizePath(run_dir, winslash = "/"))
      stop(
        sprintf("Gate failed: %s (status %d)", specs[[index]]$gate, result$status),
        call. = FALSE
      )
    }
  }
  invisible(do.call(rbind, rows))
}

wp027_dry_run_specs <- function() {
  make_spec <- function(command, fixture) {
    list(
      gate = command,
      kind = "fixture",
      command = command,
      arguments = paste0("arg-", command),
      environment = paste0("FIXTURE=", fixture),
      fixture = fixture
    )
  }
  c(
    lapply(c("fixture-pass", "fixture-fail", "fixture-after"), make_spec,
      fixture = "failure"
    ),
    lapply(c("fixture-one", "fixture-two"), make_spec, fixture = "success")
  )
}

wp027_run_dry_run <- function() {
  parent <- tempfile("wp027-dry-")
  dir.create(parent)
  on.exit(unlink(parent, recursive = TRUE, force = TRUE), add = TRUE)
  specs <- wp027_dry_run_specs()

  calls <- new.env(parent = emptyenv())
  calls$commands <- character()
  fake_executor <- function(command, arguments, environment, stdout, stderr) {
    calls$commands <- c(calls$commands, command)
    writeLines(paste("stdout", command), stdout)
    writeLines(paste("stderr", command), stderr)
    if (identical(command, "fixture-fail")) 9L else 0L
  }

  failure_run <- file.path(parent, ".WP-027_FAILURE.tmp")
  failure_final <- file.path(parent, "WP-027_FAILURE")
  failure_specs <- Filter(function(spec) identical(spec$fixture, "failure"), specs)
  failed <- FALSE
  suppressMessages(tryCatch(
    wp027_execute_specs(failure_specs, failure_run, fake_executor),
    error = function(error) failed <<- TRUE
  ))
  failure_fixture_ok <- failed &&
    identical(calls$commands, c("fixture-pass", "fixture-fail")) &&
    file.exists(file.path(failure_run, "FAILED")) &&
    dir.exists(failure_run) &&
    !dir.exists(failure_final)
  if (!failure_fixture_ok) {
    stop("WP-027 dry-run failure fixture did not retain first-failure evidence.",
      call. = FALSE
    )
  }

  calls$commands <- character()
  success_run <- file.path(parent, ".WP-027_SUCCESS.tmp")
  success_final <- file.path(parent, "WP-027_SUCCESS")
  success_specs <- Filter(function(spec) identical(spec$fixture, "success"), specs)
  wp027_execute_specs(success_specs, success_run, fake_executor)
  writeLines("status=PASS", file.path(success_run, "metadata.txt"))
  writeLines("payload", file.path(success_run, "payload.txt"))
  wp027_hash_manifest(success_run)
  wp027_verify_hash_manifest(success_run)
  promoted <- wp027_promote_verified(success_run, success_final)
  success_fixture_ok <- identical(calls$commands, c("fixture-one", "fixture-two")) &&
    dir.exists(promoted) &&
    !dir.exists(success_run)
  if (!success_fixture_ok) {
    stop("WP-027 dry-run success fixture did not promote atomically.", call. = FALSE)
  }

  cat("WP-027 dry run PASS\n")
  invisible(promoted)
}

wp027_parse_summary_counts <- function(lines) {
  summary <- grep(
    "\\[ FAIL [0-9]+ \\| WARN [0-9]+ \\| SKIP [0-9]+ \\| PASS [0-9]+ \\]",
    lines,
    value = TRUE
  )
  if (length(summary) > 1L) stop("Found multiple test summaries.", call. = FALSE)
  if (length(summary) == 1L) {
    values <- sub(
      paste0(
        ".*\\[ FAIL ([0-9]+) \\| WARN ([0-9]+) \\| ",
        "SKIP ([0-9]+) \\| PASS ([0-9]+) \\].*"
      ),
      "\\1 \\2 \\3 \\4",
      summary
    )
    values <- as.integer(strsplit(values, " ", fixed = TRUE)[[1L]])
    return(setNames(values, c("fail", "warning", "skip", "pass")))
  }
  if (!any(grepl("^══ DONE", lines))) {
    stop("Test summary did not reach DONE.", call. = FALSE)
  }
  failed <- wp027_summary_section(lines, "Failed")
  c(
    fail = as.integer(sum(grepl("^── [0-9]+[.]", failed))),
    warning = as.integer(nrow(wp027_warning_entries(lines))),
    skip = as.integer(nrow(wp027_skip_entries(lines))),
    pass = NA_integer_
  )
}

wp027_summary_section <- function(lines, heading) {
  starts <- grep(paste0("^══ ", heading), lines)
  if (length(starts) == 0L) return(character())
  start <- starts[[1L]] + 1L
  later <- grep("^══ ", lines)
  later <- later[later >= start]
  end <- if (length(later) == 0L) length(lines) else later[[1L]] - 1L
  lines[start:end]
}

wp027_warning_entries <- function(lines) {
  section <- wp027_summary_section(lines, "Warnings")
  starts <- grep("^[0-9]+[.] ", section)
  if (length(starts) == 0L) {
    return(data.frame(test = character(), text = character(), stringsAsFactors = FALSE))
  }
  ends <- c(starts[-1L] - 1L, length(section))
  records <- Map(function(start, end) {
    block <- trimws(section[start:end])
    block <- block[nzchar(block)]
    entry <- paste(block, collapse = " ")
    entry <- sub("^[0-9]+[.] ", "", entry)
    separator <- regexpr(" - ", entry, fixed = TRUE)[[1L]]
    if (separator == -1L) stop("Malformed warning inventory entry.", call. = FALSE)
    test <- substr(entry, 1L, separator - 1L)
    text <- substring(entry, separator + 3L)
    data.frame(test = test, text = text, stringsAsFactors = FALSE)
  }, starts, ends)
  do.call(rbind, records)
}

wp027_skip_entries <- function(lines) {
  section <- wp027_summary_section(lines, "Skipped")
  entries <- grep("^([0-9]+[.]|•) ", trimws(section), value = TRUE)
  if (length(entries) == 0L) {
    return(data.frame(test = character(), text = character(), stringsAsFactors = FALSE))
  }
  records <- lapply(entries, function(entry) {
    entry <- sub("^([0-9]+[.]|•) ", "", trimws(entry))
    separator <- regexpr(" - ", entry, fixed = TRUE)[[1L]]
    if (separator == -1L) stop("Malformed skip inventory entry.", call. = FALSE)
    test <- substr(entry, 1L, separator - 1L)
    text <- sub("^Reason: ", "", substring(entry, separator + 3L))
    data.frame(test = test, text = text, stringsAsFactors = FALSE)
  })
  do.call(rbind, records)
}

wp027_test_warning_inventory <- function(stdout_path, stderr_path, scope = "full") {
  lines <- c(readLines(stdout_path, warn = FALSE), readLines(stderr_path, warn = FALSE))
  counts <- wp027_parse_summary_counts(lines)
  warnings <- wp027_warning_entries(lines)
  skips <- wp027_skip_entries(lines)
  inventory <- rbind(
    data.frame(kind = "warning", warnings, stringsAsFactors = FALSE),
    data.frame(kind = "skip", skips, stringsAsFactors = FALSE)
  )
  inventory$scope <- scope
  inventory$ordinal <- ave(
    seq_len(nrow(inventory)),
    inventory$kind,
    FUN = seq_along
  )
  warning_keys <- paste(.wp027_accepted_warnings$test, .wp027_accepted_warnings$text,
    sep = "\r"
  )
  inventory_keys <- paste(inventory$test, inventory$text, sep = "\r")
  accepted_warning <- inventory$kind == "warning" &
    inventory_keys %in% warning_keys
  accepted_skip <- inventory$kind == "skip" &
    inventory$test == .wp027_network_skip_test &
    inventory$text == .wp027_network_skip
  inventory$accepted <- accepted_warning | accepted_skip
  inventory <- inventory[, c("scope", "kind", "ordinal", "test", "text", "accepted")]

  expected_warning <- unname(.wp027_warning_baselines[[scope]])
  expected_skip <- unname(.wp027_skip_baselines[[scope]])
  valid <- identical(unname(counts[["fail"]]), 0L) &&
    identical(unname(counts[["warning"]]), expected_warning) &&
    identical(unname(counts[["skip"]]), expected_skip) &&
    identical(nrow(warnings), expected_warning) &&
    identical(nrow(skips), expected_skip) &&
    identical(warnings, .wp027_accepted_warnings) &&
    all(inventory$accepted)
  if (!valid) stop("Unexpected full-suite warning, skip, or failure inventory.", call. = FALSE)
  inventory
}

wp027_validate_test_contracts <- function(root, run_dir) {
  inventory <- wp027_inventory_tests(root)
  expected <- data.frame(
    path = .wp027_allowed_internal_paths,
    test_that = unname(.wp027_migrated_test_counts),
    expectations = unname(.wp027_migrated_expectation_counts),
    stringsAsFactors = FALSE
  )
  observed <- inventory[match(expected$path, inventory$path), names(expected), drop = FALSE]
  rownames(observed) <- NULL
  file_ok <- identical(observed, expected)
  total_ok <- sum(inventory$test_that) >= .wp027_suite_minima[["test_that"]] &&
    sum(inventory$expectations) >= .wp027_suite_minima[["expectations"]]
  expected_test_counts <- unname(.wp027_migrated_test_counts[inventory$path])
  expected_expectation_counts <- unname(
    .wp027_migrated_expectation_counts[inventory$path]
  )
  governed <- !is.na(expected_test_counts) & !is.na(expected_expectation_counts)
  file_accepted <- inventory$test_that == expected_test_counts &
    inventory$expectations == expected_expectation_counts
  file_accepted[!governed] <- TRUE
  ledger <- rbind(
    data.frame(
      scope = "file",
      path = inventory$path,
      test_that = inventory$test_that,
      expectations = inventory$expectations,
      accepted = file_accepted,
      stringsAsFactors = FALSE
    ),
    data.frame(
      scope = "suite",
      path = "TOTAL",
      test_that = sum(inventory$test_that),
      expectations = sum(inventory$expectations),
      accepted = total_ok,
      stringsAsFactors = FALSE
    )
  )
  wp027_write_tsv(ledger, file.path(run_dir, "test-contract-counts.tsv"))
  if (!file_ok || !total_ok) stop("Test count contract changed.", call. = FALSE)

  references <- wp027_scan_internal_references(root)
  observed_reference_counts <- table(factor(
    references$path,
    levels = .wp027_allowed_internal_paths
  ))
  expected_reference_counts <- c(3L, 1L, 2L, 2L, 1L, 1L, 1L, 3L, 3L)
  references_ok <- !any(references$operator == "::") &&
    identical(nrow(references), 17L) &&
    identical(as.integer(observed_reference_counts), expected_reference_counts) &&
    all(references$path %in% .wp027_allowed_internal_paths)
  if (!references_ok) stop("Internal-reference contract changed.", call. = FALSE)

  test_stdout <- file.path(run_dir, "steps", "04-tests.stdout.log")
  test_stderr <- file.path(run_dir, "steps", "04-tests.stderr.log")
  warning_inventory <- wp027_test_warning_inventory(test_stdout, test_stderr, "full")
  wp027_write_tsv(
    warning_inventory,
    file.path(run_dir, "test-warning-inventory.tsv")
  )
  "test counts, internal references, warnings, and skip match"
}

wp027_artifact_assertions <- function(root) {
  required <- c(
    .wp027_required_jc_paths,
    .wp027_required_docs_paths,
    .wp027_required_report_paths
  )
  wp027_assert_nonempty(file.path(root, required))
  sprintf("verified %d non-empty products", length(required))
}

wp027_write_link_scan <- function(root, run_dir) {
  sources <- c(
    quarto = file.path(root, "outputs", "quarto"),
    pkgdown = file.path(root, "outputs", "pkgdown"),
    report = file.path(root, "outputs", "reports")
  )
  records <- lapply(names(sources), function(scope) {
    links <- wp027_scan_relative_links(sources[[scope]])
    links$scope <- rep(scope, nrow(links))
    links[, c("scope", "source", "href", "target", "exists"), drop = FALSE]
  })
  ledger <- do.call(rbind, records)
  wp027_write_tsv(ledger, file.path(run_dir, "docs", "link-scan.tsv"))
  if (any(!ledger$exists)) {
    stop("Generated documentation has missing relative links.", call. = FALSE)
  }
  sprintf("verified %d generated relative links", nrow(ledger))
}

wp027_copy_tree <- function(source, destination) {
  if (!dir.exists(source)) stop("Evidence source directory is missing: ", source, call. = FALSE)
  if (file.exists(destination)) stop("Evidence destination already exists: ", destination,
    call. = FALSE
  )
  dir.create(destination, recursive = TRUE)
  entries <- list.files(
    source,
    recursive = TRUE,
    all.files = TRUE,
    full.names = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  )
  if (length(entries) == 0L) return(invisible(destination))
  info <- file.info(entries)
  relative <- vapply(entries, wp027_path_relative, character(1), root = source)
  directories <- entries[!is.na(info$isdir) & info$isdir]
  directory_relative <- relative[!is.na(info$isdir) & info$isdir]
  for (path in file.path(destination, directory_relative)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  files <- entries[!is.na(info$isdir) & !info$isdir]
  file_relative <- relative[!is.na(info$isdir) & !info$isdir]
  for (index in seq_along(files)) {
    target <- file.path(destination, file_relative[[index]])
    dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
    if (!file.copy(files[[index]], target, overwrite = FALSE, copy.mode = TRUE)) {
      stop("Unable to copy evidence file: ", files[[index]], call. = FALSE)
    }
  }
  invisible(destination)
}

wp027_git <- function(root, arguments, allow_failure = FALSE) {
  output <- suppressWarnings(system2(
    command = "git",
    args = vapply(c("-C", root, arguments), shQuote, character(1)),
    env = character(),
    stdout = TRUE,
    stderr = TRUE
  ))
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  if (!allow_failure && status != 0L) {
    stop(paste(output, collapse = "\n"), call. = FALSE)
  }
  structure(output, status = as.integer(status))
}

wp027_assert_protected_metadata <- function(root) {
  description_diff <- wp027_git(
    root,
    c("diff", "--exit-code", paste0(.wp027_post_task2_commit, "..HEAD"), "--", "DESCRIPTION"),
    allow_failure = TRUE
  )
  if (attr(description_diff, "status") != 0L) {
    stop("DESCRIPTION changed after the accepted Task 2 baseline.", call. = FALSE)
  }

  baseline_lines <- wp027_git(
    root,
    c("show", paste0(.wp027_approved_design_commit, ":DESCRIPTION"))
  )
  baseline <- read.dcf(textConnection(paste(baseline_lines, collapse = "\n")))
  current <- read.dcf(file.path(root, "DESCRIPTION"))
  if (!setequal(colnames(current), colnames(baseline))) {
    stop("DESCRIPTION field inventory changed.", call. = FALSE)
  }
  protected <- setdiff(colnames(baseline), c("Title", "Description"))
  protected_fields_match <- identical(
    current[1L, protected],
    baseline[1L, protected]
  )
  version_matches <- identical(unname(current[1L, "Version"]), "0.0.0.9000")
  if (!protected_fields_match || !version_matches) {
    stop("Protected DESCRIPTION release metadata changed.", call. = FALSE)
  }
  invisible(TRUE)
}

wp027_collect_evidence <- function(root, run_dir) {
  wp027_assert_protected_metadata(root)
  wp027_copy_tree(file.path(root, "outputs", "jc"), file.path(run_dir, "jc"))
  wp027_copy_tree(
    file.path(root, "outputs", "quarto"),
    file.path(run_dir, "docs", "quarto")
  )
  wp027_copy_tree(
    file.path(root, "outputs", "pkgdown"),
    file.path(run_dir, "docs", "pkgdown")
  )
  report_source <- file.path(root, "outputs", "reports", "paper.html")
  report_destination <- file.path(run_dir, "reports", "paper.html")
  dir.create(dirname(report_destination), recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(report_source, report_destination, overwrite = FALSE, copy.mode = TRUE)) {
    stop("Unable to copy rendered report evidence.", call. = FALSE)
  }
  required <- c(
    "metadata.txt",
    "commands.tsv",
    "validation.log",
    "test-contract-counts.tsv",
    "test-warning-inventory.tsv",
    "docs/link-scan.tsv",
    "reports/paper.html"
  )
  wp027_assert_nonempty(file.path(run_dir, required))
  "accepted JC, documentation, report, and ledgers copied"
}

wp027_internal_spec <- function(gate, action, label) {
  list(
    gate = gate,
    kind = "internal",
    command = "<internal>",
    arguments = label,
    environment = character(),
    action = action
  )
}

wp027_external_spec <- function(gate, command, arguments, environment = character()) {
  list(
    gate = gate,
    kind = "external",
    command = command,
    arguments = arguments,
    environment = environment
  )
}

wp027_canonical_specs <- function(root) {
  specs <- list(
    wp027_external_spec("Bootstrap", "make", "bootstrap"),
    wp027_external_spec("QA bootstrap", "make", "bootstrap-qa"),
    wp027_external_spec("Package metadata", "Rscript", c("-e", "devtools::document()")),
    wp027_external_spec("Tests", "make", "test"),
    wp027_internal_spec(
      "Test contracts",
      function(run_dir) wp027_validate_test_contracts(root, run_dir),
      "test-and-warning-contracts"
    ),
    wp027_external_spec(
      "Harness fixture",
      "Rscript",
      c("scripts/validate_wp027.R", "--dry-run")
    ),
    wp027_external_spec("Lint", "make", "lint"),
    wp027_external_spec("JC demonstration", "make", "pipeline", .wp027_jc_environment),
    wp027_external_spec("Quarto", "make", "docs"),
    wp027_external_spec("pkgdown", "make", "site"),
    wp027_external_spec(
      "Report",
      "quarto",
      c("render", "reports/paper.qmd", "--output-dir", "outputs/reports"),
      .wp027_report_environment
    ),
    wp027_internal_spec(
      "Artifact assertions",
      function(run_dir) wp027_artifact_assertions(root),
      "assert-required-products"
    ),
    wp027_internal_spec(
      "Relative links",
      function(run_dir) wp027_write_link_scan(root, run_dir),
      "scan-generated-relative-links"
    ),
    wp027_external_spec("Package check", "make", "check"),
    wp027_external_spec("Diff hygiene", "git", c("diff", "--check")),
    wp027_internal_spec(
      "Evidence collection",
      function(run_dir) wp027_collect_evidence(root, run_dir),
      "collect-accepted-evidence"
    )
  )
  if (!identical(vapply(specs, `[[`, character(1), "gate"), .wp027_gate_order)) {
    stop("Canonical gate order changed.", call. = FALSE)
  }
  specs
}

wp027_assert_make_test_recipe <- function(root) {
  lines <- readLines(file.path(root, "Makefile"), warn = FALSE)
  headers <- grep(
    "^[A-Za-z0-9_.-]+([[:space:]]+[A-Za-z0-9_.-]+)*[[:space:]]*:",
    lines
  )
  test_header <- which(lines == "test:")
  if (length(test_header) != 1L) stop("Makefile test target changed.", call. = FALSE)
  next_header <- headers[headers > test_header[[1L]]][[1L]]
  recipe <- lines[(test_header[[1L]] + 1L):(next_header - 1L)]
  recipe <- recipe[nzchar(recipe)]
  expected <- "\t@$(RSCRIPT) -e \"devtools::test(reporter='summary', stop_on_failure=TRUE)\""
  if (!identical(recipe, expected)) stop("Makefile Tests command changed.", call. = FALSE)
  invisible(TRUE)
}

wp027_git_head <- function(root) {
  output <- wp027_git(root, c("rev-parse", "HEAD"))
  if (length(output) != 1L) stop("Unable to resolve validation HEAD.", call. = FALSE)
  unname(output[[1L]])
}

wp027_write_metadata <- function(run_dir, root, status, started_utc, ended_utc = "") {
  writeLines(
    c(
      "work_package=WP-027",
      paste0("status=", status),
      paste0("validated_head=", wp027_git_head(root)),
      paste0("started_utc=", started_utc),
      paste0("ended_utc=", ended_utc),
      "canonical_evidence=true",
      "release_payload=false"
    ),
    file.path(run_dir, "metadata.txt")
  )
}

wp027_run_canonical <- function(root = .wp027_root) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  old <- setwd(root)
  on.exit(setwd(old), add = TRUE)
  wp027_assert_make_test_recipe(root)
  wp027_assert_protected_metadata(root)

  canonical_parent <- file.path(root, "outputs", "canonical_runs")
  existing <- if (dir.exists(canonical_parent)) {
    list.dirs(canonical_parent, recursive = FALSE, full.names = TRUE)
  } else {
    character()
  }
  existing <- existing[grepl("^WP-027_", basename(existing))]
  if (length(existing) > 0L) {
    stop("A canonical WP-027 run already exists.", call. = FALSE)
  }

  dir.create(canonical_parent, recursive = TRUE, showWarnings = FALSE)
  timestamp <- format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")
  temp_run <- file.path(canonical_parent, paste0(".WP-027_", timestamp, ".tmp"))
  final_run <- file.path(canonical_parent, paste0("WP-027_", timestamp))
  if (file.exists(temp_run) || file.exists(final_run)) {
    stop("WP-027 timestamp destination already exists.", call. = FALSE)
  }
  dir.create(temp_run)
  started <- wp027_utc()
  wp027_write_metadata(temp_run, root, "RUNNING", started)

  tryCatch(
    wp027_execute_specs(wp027_canonical_specs(root), temp_run),
    error = function(error) {
      wp027_write_metadata(temp_run, root, "FAILED", started, wp027_utc())
      stop(conditionMessage(error), call. = FALSE)
    }
  )
  wp027_write_metadata(temp_run, root, "PASS", started, wp027_utc())
  wp027_hash_manifest(temp_run)
  wp027_verify_hash_manifest_system2(temp_run)
  promoted <- wp027_promote_verified(temp_run, final_run)
  cat(promoted, "\n", sep = "")
  invisible(promoted)
}

wp027_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (identical(args, "--dry-run")) return(wp027_run_dry_run())
  if (length(args) == 0L) return(wp027_run_canonical())
  stop("Usage: Rscript scripts/validate_wp027.R [--dry-run]", call. = FALSE)
}

wp027_is_direct_invocation <- function() {
  if (is.na(.wp027_script_file)) return(FALSE)
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg) != 1L) return(FALSE)
  invoked <- sub("^--file=", "", file_arg)
  identical(
    normalizePath(invoked, winslash = "/", mustWork = FALSE),
    .wp027_script_file
  )
}

if (wp027_is_direct_invocation()) {
  status <- tryCatch(
    {
      wp027_main()
      0L
    },
    error = function(error) {
      message(conditionMessage(error))
      1L
    }
  )
  quit(save = "no", status = status, runLast = FALSE)
}
