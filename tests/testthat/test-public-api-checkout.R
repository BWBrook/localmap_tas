checkout_stable_exports <- c(
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
  "render_overview_map"
)

checkout_experimental_exports <- c(
  "ala_configure",
  "fetch_layer_registry",
  "generate_topo_tile_map"
)

checkout_expected_exports <- sort(c(
  checkout_stable_exports,
  checkout_experimental_exports
))

checkout_internal_names <- c(
  "ala_default_occurrence_fields",
  "build_layer_provenance",
  "fetch_arcgis_imagery",
  "fetch_wms_imagery",
  "validate_analysis_layers",
  "validate_layer_registry",
  "write_attribution_report",
  "write_coverage_summary",
  "write_run_manifest",
  "write_site_attributes_long",
  "write_site_attributes_wide"
)

checkout_documented_internal_topics <- c(
  "ala_default_occurrence_fields",
  "analysis_layer_types",
  "build_layer_provenance",
  "fetch_arcgis_imagery",
  "fetch_camera_wms_tile",
  "fetch_wms_imagery",
  "prepare_camera_site_context",
  "render_aoi_debug_plot",
  "validate_analysis_layers",
  "validate_layer_registry",
  "write_attribution_report",
  "write_coverage_summary",
  "write_run_manifest",
  "write_site_attributes_long",
  "write_site_attributes_wide"
)

testthat::test_that("pkgdown indexes every public export exactly once", {
  config <- yaml::read_yaml(testthat::test_path("..", "..", "_pkgdown.yml"))
  internal_sections <- vapply(
    config$reference,
    function(section) identical(tolower(section$title), "internal"),
    logical(1)
  )
  public_reference <- config$reference[!internal_sections]
  indexed <- unname(unlist(
    lapply(public_reference, `[[`, "contents"),
    use.names = FALSE
  ))
  suppressed <- unname(unlist(
    lapply(config$reference[internal_sections], `[[`, "contents"),
    use.names = FALSE
  ))

  testthat::expect_identical(sum(internal_sections), 1L)
  testthat::expect_length(public_reference, 5L)
  testthat::expect_identical(
    vapply(public_reference, function(section) length(section$contents), integer(1)),
    c(2L, 4L, 3L, 3L, 3L)
  )
  testthat::expect_identical(sort(indexed), checkout_expected_exports)
  testthat::expect_identical(anyDuplicated(indexed), 0L)
  testthat::expect_false(any(checkout_internal_names %in% indexed))
  testthat::expect_identical(
    sort(suppressed),
    sort(checkout_documented_internal_topics)
  )
  testthat::expect_length(intersect(suppressed, checkout_expected_exports), 0L)
})

testthat::test_that("documentation namespace calls use public exports", {
  root <- testthat::test_path("..", "..")
  paths <- c(
    file.path(root, "README.md"),
    list.files(
      file.path(root, "docs"),
      "[.](md|qmd)$",
      recursive = TRUE,
      full.names = TRUE
    ),
    file.path(root, "vignettes", "intro.Rmd"),
    file.path(root, "reports", "paper.qmd")
  )
  text <- paste(
    vapply(
      paths,
      function(path) paste(readLines(path, warn = FALSE), collapse = "\n"),
      character(1)
    ),
    collapse = "\n"
  )
  hits <- regmatches(
    text,
    gregexpr(
      "localmap::(?!:)[A-Za-z][A-Za-z0-9_.]*(?=\\s*\\()",
      text,
      perl = TRUE
    )
  )[[1]]
  names_used <- sub("localmap::", "", hits, fixed = TRUE)
  testthat::expect_true(all(names_used %in% checkout_expected_exports))
})

testthat::test_that("Makefile test target stops on test failure", {
  makefile <- testthat::test_path("..", "..", "Makefile")
  lines <- readLines(makefile, warn = FALSE)
  headers <- grep(
    "^[A-Za-z0-9_.-]+([[:space:]]+[A-Za-z0-9_.-]+)*[[:space:]]*:",
    lines
  )
  test_headers <- which(lines == "test:")
  testthat::expect_identical(length(test_headers), 1L)

  next_header <- headers[headers > test_headers[[1L]]][[1L]]
  recipe <- lines[(test_headers[[1L]] + 1L):(next_header - 1L)]
  recipe <- recipe[nzchar(recipe)]
  testthat::expect_identical(
    recipe,
    "\t@$(RSCRIPT) -e \"devtools::test(reporter='summary', stop_on_failure=TRUE)\""
  )
})

testthat::test_that("report output stays outside the source tree", {
  root <- testthat::test_path("..", "..")
  tracked <- system2(
    "git",
    c("-C", root, "ls-files", "--", "reports/paper.html"),
    stdout = TRUE,
    stderr = TRUE
  )
  ignored <- system2(
    "git",
    c("-C", root, "check-ignore", "-q", "reports/paper.html"),
    stdout = FALSE,
    stderr = FALSE
  )

  testthat::expect_length(tracked, 0L)
  testthat::expect_identical(ignored, 0L)
  testthat::expect_true(
    "/reports/paper.html" %in% readLines(file.path(root, ".gitignore"), warn = FALSE)
  )
})

testthat::test_that("standalone report embeds generated media", {
  report <- readLines(
    testthat::test_path("..", "..", "reports", "paper.qmd"),
    warn = FALSE
  )
  front_matter_end <- which(report == "---")[[2L]]
  metadata <- yaml::yaml.load(
    paste(report[2L:(front_matter_end - 1L)], collapse = "\n")
  )

  embeds_media <- is.list(metadata$format) &&
    is.list(metadata$format$html) &&
    isTRUE(metadata$format$html$`embed-resources`)
  testthat::expect_true(embeds_media)
  testthat::expect_length(grep("knitr::asis_output", report, fixed = TRUE), 2L)
  testthat::expect_length(grep("knitr::image_uri", report, fixed = TRUE), 2L)
  testthat::expect_length(grep("knitr::include_graphics", report, fixed = TRUE), 0L)
})
