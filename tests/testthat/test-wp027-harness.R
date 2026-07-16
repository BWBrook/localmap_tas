wp027_test_root <- normalizePath(
  testthat::test_path("..", ".."),
  winslash = "/",
  mustWork = TRUE
)
wp027_test_script <- file.path(wp027_test_root, "scripts", "validate_wp027.R")

sys.source(wp027_test_script, envir = environment())

wp027_snapshot_tree <- function(path) {
  if (!dir.exists(path)) {
    return(data.frame(
      path = character(),
      size = numeric(),
      modified = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  paths <- list.files(
    path,
    recursive = TRUE,
    all.files = TRUE,
    full.names = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  )
  info <- file.info(paths)
  files <- paths[!is.na(info$isdir) & !info$isdir]
  info <- file.info(files)
  data.frame(
    path = substring(files, nchar(path) + 2L),
    size = unname(info$size),
    modified = as.numeric(info$mtime),
    stringsAsFactors = FALSE
  )
}

testthat::test_that("the harness is source-safe", {
  sandbox <- tempfile("wp027-source-")
  dir.create(file.path(sandbox, "scripts"), recursive = TRUE)
  sandbox_script <- file.path(sandbox, "scripts", "validate_wp027.R")
  testthat::expect_true(file.copy(wp027_test_script, sandbox_script))

  source_env <- new.env(parent = globalenv())
  sys.source(sandbox_script, envir = source_env)

  required <- c(
    "wp027_normalize_formals",
    "wp027_inventory_tests",
    "wp027_scan_internal_references",
    "wp027_assert_nonempty",
    "wp027_extract_relative_links",
    "wp027_scan_relative_links",
    "wp027_hash_manifest",
    "wp027_verify_hash_manifest",
    "wp027_promote_verified",
    "wp027_run_gate",
    "wp027_execute_specs",
    "wp027_run_dry_run",
    "wp027_run_canonical",
    "wp027_main"
  )
  testthat::expect_true(all(vapply(
    required,
    exists,
    logical(1),
    envir = source_env,
    inherits = FALSE
  )))
  testthat::expect_false(dir.exists(file.path(sandbox, "outputs")))
})

testthat::test_that("canonical formals and test inventories match their contracts", {
  testthat::expect_identical(names(.wp027_stable_formals), .wp027_stable_exports)
  for (function_name in .wp027_stable_exports) {
    testthat::expect_identical(
      wp027_normalize_formals(getExportedValue("localmap", function_name)),
      .wp027_stable_formals[[function_name]],
      info = function_name
    )
  }

  inventory <- wp027_inventory_tests(wp027_test_root)
  expected_migrated <- data.frame(
    path = .wp027_allowed_internal_paths,
    test_that = unname(.wp027_migrated_test_counts),
    expectations = unname(.wp027_migrated_expectation_counts),
    stringsAsFactors = FALSE
  )
  observed_migrated <- inventory[
    match(expected_migrated$path, inventory$path),
    names(expected_migrated),
    drop = FALSE
  ]
  rownames(observed_migrated) <- NULL

  testthat::expect_identical(observed_migrated, expected_migrated)
  testthat::expect_gte(sum(inventory$test_that), .wp027_suite_minima[["test_that"]])
  testthat::expect_gte(
    sum(inventory$expectations),
    .wp027_suite_minima[["expectations"]]
  )
  harness <- inventory[inventory$path == "tests/testthat/test-wp027-harness.R", ]
  testthat::expect_identical(harness$test_that, 11L)

  summary_stdout <- tempfile("wp027-summary-", fileext = ".log")
  summary_stderr <- tempfile("wp027-summary-stderr-", fileext = ".log")
  writeLines(c(
    "══ Skipped ══",
    paste0(
      "1. network imagery fetch is gated behind LOCALMAP_ALLOW_NETWORK ",
      "('test_network_optional.R:3:5') - Reason: ",
      .wp027_network_skip
    ),
    "",
    "══ Warnings ══",
    paste0(
      "1. arcgis vector fetch is gated without network or fixture ",
      "('test_analysis_layers.R:289:3') - Network access disabled; ArcGIS ",
      "vector layer 'arcgis_vec' requires a fixture or LOCALMAP_ALLOW_NETWORK=1."
    ),
    "",
    paste0(
      "2. arcgis raster fetch falls back to fixture when offline ",
      "('test_analysis_layers.R:323:3') - Network access disabled; ArcGIS ",
      "raster layer 'arcgis_raster' requires a fixture or LOCALMAP_ALLOW_NETWORK=1."
    ),
    "",
    paste0(
      "3. arcgis raster fetch errors when offline without fixture ",
      "('test_analysis_layers.R:354:3') - Network access disabled; ArcGIS ",
      "raster layer 'arcgis_raster' requires a fixture or LOCALMAP_ALLOW_NETWORK=1."
    ),
    "",
    paste0(
      "4. arcgis vector fixtures are clipped in AOI CRS ",
      "('test_analysis_layers.R:382:3') - attribute variables are assumed to ",
      "be spatially constant throughout all geometries"
    ),
    "",
    paste0(
      "5. fetch_arcgis_imagery respects network gating ",
      "('test_imagery_arcgis.R:75:3') - Network access disabled; using offline ",
      "placeholder for ArcGIS imagery."
    ),
    "",
    paste0(
      "6. fetch_wms_imagery respects network gating ",
      "('test_imagery_wms.R:80:3') - Network access disabled; using offline ",
      "placeholder for WMS imagery."
    ),
    "",
    paste0(
      "7. camera_sites_stack_maps stacks PNGs vertically ",
      "('test-camera-sites-map.R:156:3') - Panel images differ in size; bounding ",
      "boxes may not match. Consider normalize_sizes = TRUE."
    ),
    "",
    "══ DONE ══"
  ), summary_stdout)
  file.create(summary_stderr)
  warning_inventory <- wp027_test_warning_inventory(
    summary_stdout,
    summary_stderr,
    "full"
  )
  testthat::expect_identical(
    names(warning_inventory),
    c("scope", "kind", "ordinal", "test", "text", "accepted")
  )
  warning_counts <- table(warning_inventory$kind)
  testthat::expect_identical(
    as.integer(warning_counts[c("skip", "warning")]),
    c(1L, 7L)
  )
  testthat::expect_true(all(warning_inventory$accepted))

  contract_run <- tempfile("wp027-contract-")
  dir.create(file.path(contract_run, "steps"), recursive = TRUE)
  file.copy(
    summary_stdout,
    file.path(contract_run, "steps", "04-tests.stdout.log")
  )
  file.copy(
    summary_stderr,
    file.path(contract_run, "steps", "04-tests.stderr.log")
  )
  testthat::expect_match(
    wp027_validate_test_contracts(wp027_test_root, contract_run),
    "test counts, internal references, warnings, and skip match",
    fixed = TRUE
  )
  contract_counts <- utils::read.delim(
    file.path(contract_run, "test-contract-counts.tsv"),
    stringsAsFactors = FALSE
  )
  testthat::expect_true(all(contract_counts$accepted))

  specs <- wp027_canonical_specs(wp027_test_root)
  testthat::expect_identical(
    vapply(specs, `[[`, character(1), "gate"),
    .wp027_gate_order
  )
  testthat::expect_identical(
    vapply(specs, `[[`, character(1), "command"),
    c(
      "make", "make", "Rscript", "make", "<internal>", "Rscript", "make",
      "make", "make", "make", "quarto", "<internal>", "<internal>",
      "make", "git", "<internal>"
    )
  )
  testthat::expect_identical(specs[[4L]]$arguments, "test")
  testthat::expect_identical(specs[[8L]]$environment, .wp027_jc_environment)
  testthat::expect_identical(specs[[11L]]$environment, .wp027_report_environment)
  testthat::expect_identical(
    .wp027_command_columns,
    c(
      "sequence", "gate", "kind", "started_utc", "ended_utc", "command",
      "arguments", "environment", "exit_status", "stdout_path", "stderr_path"
    )
  )
})

testthat::test_that("internal test references use only the nine-file allowlist", {
  references <- wp027_scan_internal_references(wp027_test_root)
  expected_counts <- c(
    "tests/testthat/test_provenance_outputs.R" = 3L,
    "tests/testthat/test_combine.R" = 1L,
    "tests/testthat/test_imagery_arcgis.R" = 2L,
    "tests/testthat/test_imagery_wms.R" = 2L,
    "tests/testthat/test_network_optional.R" = 1L,
    "tests/testthat/test_preview.R" = 1L,
    "tests/testthat/test_analysis_layers.R" = 1L,
    "tests/testthat/test_layer_registry.R" = 3L,
    "tests/testthat/test_site_attributes.R" = 3L
  )
  observed_counts <- table(factor(
    references$path,
    levels = names(expected_counts)
  ))

  testthat::expect_false(any(references$operator == "::"))
  testthat::expect_identical(nrow(references), 17L)
  testthat::expect_identical(as.integer(observed_counts), unname(expected_counts))
  testthat::expect_setequal(unique(references$path), .wp027_allowed_internal_paths)
  testthat::expect_true(all(references$name %in% .wp027_internal_names))
})

testthat::test_that("non-empty artifacts and generated relative links are verified", {
  site <- tempfile("wp027-links-")
  dir.create(file.path(site, "nested"), recursive = TRUE)
  writeLines("page", file.path(site, "page.html"))
  writeLines("nested", file.path(site, "nested", "index.html"))
  index <- file.path(site, "index.html")
  writeLines(c(
    '<a href="page.html?mode=print#result">Page</a>',
    '<a href="nested/">Nested</a>',
    '<a href="#local">Anchor</a>',
    '<a href="mailto:test@example.org">Mail</a>',
    '<a href="https://example.org/remote">Remote</a>',
    '<a href="/site-root">Site root</a>'
  ), index)

  testthat::expect_identical(
    wp027_extract_relative_links(index),
    c("page.html", "nested/")
  )
  links <- wp027_scan_relative_links(site)
  testthat::expect_identical(links$href, c("page.html", "nested/"))
  testthat::expect_true(all(links$exists))
  testthat::expect_invisible(wp027_assert_nonempty(c(index, file.path(site, "page.html"))))

  empty <- file.path(site, "empty.txt")
  file.create(empty)
  testthat::expect_error(wp027_assert_nonempty(empty), "Missing or empty artifact")
  writeLines('<a href="missing.html">Missing</a>', index, sep = "\n", useBytes = TRUE)
  missing <- wp027_scan_relative_links(site)
  testthat::expect_false(missing$exists[[1L]])

  generated_root <- tempfile("wp027-generated-")
  for (scope in c("quarto", "pkgdown", "reports")) {
    dir.create(file.path(generated_root, "outputs", scope), recursive = TRUE)
  }
  writeLines(
    '<a href="page.html">Page</a>',
    file.path(generated_root, "outputs", "quarto", "index.html")
  )
  writeLines(
    "page",
    file.path(generated_root, "outputs", "quarto", "page.html")
  )
  writeLines(
    '<a href="reference.html">Reference</a>',
    file.path(generated_root, "outputs", "pkgdown", "index.html")
  )
  writeLines(
    "reference",
    file.path(generated_root, "outputs", "pkgdown", "reference.html")
  )
  writeLines(
    '<a href="https://example.org">External only</a>',
    file.path(generated_root, "outputs", "reports", "paper.html")
  )
  link_run <- tempfile("wp027-link-ledger-")
  dir.create(link_run)
  testthat::expect_match(
    wp027_write_link_scan(generated_root, link_run),
    "verified 2 generated relative links",
    fixed = TRUE
  )
})

testthat::test_that("hash manifests exclude themselves and gate atomic promotion", {
  parent <- tempfile("wp027-promote-")
  dir.create(parent)
  temp_run <- file.path(parent, ".WP-027_GOOD.tmp")
  final_run <- file.path(parent, "WP-027_GOOD")
  dir.create(temp_run)
  writeLines("before", file.path(temp_run, "metadata.txt"))
  writeLines("payload", file.path(temp_run, "payload.txt"))

  wp027_hash_manifest(temp_run)
  testthat::expect_false(any(grepl(
    "  SHA256SUMS$",
    readLines(file.path(temp_run, "SHA256SUMS"), warn = FALSE)
  )))
  testthat::expect_invisible(wp027_verify_hash_manifest(temp_run))
  testthat::expect_identical(
    wp027_promote_verified(temp_run, final_run),
    normalizePath(final_run, winslash = "/", mustWork = TRUE)
  )

  bad_run <- file.path(parent, ".WP-027_BAD.tmp")
  bad_final <- file.path(parent, "WP-027_BAD")
  dir.create(bad_run)
  writeLines("before", file.path(bad_run, "metadata.txt"))
  wp027_hash_manifest(bad_run)
  writeLines("unlisted", file.path(bad_run, "unlisted.txt"))
  testthat::expect_error(
    wp027_verify_hash_manifest(bad_run),
    "SHA256 verification failed",
    fixed = TRUE
  )
  unlink(file.path(bad_run, "unlisted.txt"))
  writeLines("after", file.path(bad_run, "metadata.txt"))
  testthat::expect_error(
    wp027_promote_verified(bad_run, bad_final),
    "SHA256 verification failed",
    fixed = TRUE
  )
  testthat::expect_true(dir.exists(bad_run))
  testthat::expect_false(dir.exists(bad_final))

  sibling_run <- file.path(parent, ".WP-027_SIBLING.tmp")
  dir.create(sibling_run)
  writeLines("sibling", file.path(sibling_run, "metadata.txt"))
  wp027_hash_manifest(sibling_run)
  other_parent <- tempfile("wp027-other-parent-")
  dir.create(other_parent)
  testthat::expect_error(
    wp027_promote_verified(sibling_run, file.path(other_parent, "WP-027_SIBLING")),
    "source and destination siblings",
    fixed = TRUE
  )
  testthat::expect_true(dir.exists(sibling_run))

  occupied_run <- file.path(parent, ".WP-027_OCCUPIED.tmp")
  occupied_final <- file.path(parent, "WP-027_OCCUPIED")
  dir.create(occupied_run)
  dir.create(occupied_final)
  writeLines("occupied", file.path(occupied_run, "metadata.txt"))
  wp027_hash_manifest(occupied_run)
  testthat::expect_error(
    wp027_promote_verified(occupied_run, occupied_final),
    "Canonical destination already exists",
    fixed = TRUE
  )
  testthat::expect_true(dir.exists(occupied_run))
})

testthat::test_that("execution stops at first failure and retains raw logs", {
  run_dir <- tempfile("wp027-failure-")
  final_dir <- tempfile("wp027-final-")
  calls <- new.env(parent = emptyenv())
  calls$commands <- character()
  fake_executor <- function(command, arguments, environment, stdout, stderr) {
    calls$commands <- c(calls$commands, command)
    writeLines(paste("stdout", command), stdout)
    writeLines(paste("stderr", command), stderr)
    if (identical(command, "fail")) 7L else 0L
  }
  specs <- lapply(c("pass", "fail", "after"), function(command) {
    list(
      gate = command,
      kind = "fixture",
      command = command,
      arguments = paste0("arg-", command),
      environment = paste0("MODE=", command)
    )
  })

  testthat::expect_error(
    suppressMessages(wp027_execute_specs(specs, run_dir, executor = fake_executor)),
    "Gate failed: fail"
  )
  commands <- utils::read.delim(
    file.path(run_dir, "commands.tsv"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  testthat::expect_identical(calls$commands, c("pass", "fail"))
  testthat::expect_identical(names(commands), .wp027_command_columns)
  testthat::expect_identical(commands$exit_status, c(0L, 7L))
  testthat::expect_true(all(file.exists(c(
    file.path(run_dir, commands$stdout_path),
    file.path(run_dir, commands$stderr_path)
  ))))
  failed <- readLines(file.path(run_dir, "FAILED"), warn = FALSE)
  testthat::expect_true(any(failed == "gate=fail"))
  testthat::expect_true(any(failed == "status=7"))
  testthat::expect_true(dir.exists(run_dir))
  testthat::expect_false(dir.exists(final_dir))
})

testthat::test_that("dry-run uses fake non-recursive specs and no repository outputs", {
  specs <- wp027_dry_run_specs()
  encoded <- paste(vapply(specs, function(spec) {
    paste(c(spec$command, spec$arguments), collapse = " ")
  }, character(1)), collapse = "\n")
  before <- wp027_snapshot_tree(file.path(wp027_test_root, "outputs"))

  output <- capture.output(wp027_run_dry_run())
  after <- wp027_snapshot_tree(file.path(wp027_test_root, "outputs"))

  testthat::expect_false(grepl(
    "Rscript|make|quarto|git|validate_wp027",
    encoded,
    ignore.case = TRUE
  ))
  testthat::expect_identical(output, "WP-027 dry run PASS")
  testthat::expect_identical(after, before)
})

testthat::test_that("the CLI rejects invalid input and passes both dry-run fixtures", {
  rscript <- file.path(R.home("bin"), "Rscript")
  invalid <- suppressWarnings(system2(
    rscript,
    c(wp027_test_script, "--invalid"),
    stdout = TRUE,
    stderr = TRUE
  ))
  invalid_status <- attr(invalid, "status")
  if (is.null(invalid_status)) invalid_status <- 0L
  testthat::expect_false(identical(as.integer(invalid_status), 0L))
  testthat::expect_true(any(grepl(
    "Usage: Rscript scripts/validate_wp027.R [--dry-run]",
    invalid,
    fixed = TRUE
  )))

  success <- suppressWarnings(system2(
    rscript,
    c(wp027_test_script, "--dry-run"),
    stdout = TRUE,
    stderr = TRUE
  ))
  success_status <- attr(success, "status")
  if (is.null(success_status)) success_status <- 0L
  testthat::expect_identical(as.integer(success_status), 0L)
  testthat::expect_identical(as.character(success), "WP-027 dry run PASS")
})

testthat::test_that("nested Rscript sourcing returns without invoking main", {
  sandbox <- tempfile("wp027-nested-source-")
  dir.create(file.path(sandbox, "scripts"), recursive = TRUE)
  wrapper <- file.path(sandbox, "scripts", "validate_wp027.R")
  writeLines(c(
    "source_env <- new.env(parent = globalenv())",
    sprintf(
      "sys.source(%s, envir = source_env)",
      encodeString(wp027_test_script, quote = "\"")
    ),
    "cat('WP-027 nested source returned\\n')"
  ), wrapper)
  before <- wp027_snapshot_tree(file.path(wp027_test_root, "outputs"))

  output <- local({
    old <- setwd(sandbox)
    on.exit(setwd(old), add = TRUE)
    suppressWarnings(system2(
      file.path(R.home("bin"), "Rscript"),
      wrapper,
      stdout = TRUE,
      stderr = TRUE
    ))
  })
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  after <- wp027_snapshot_tree(file.path(wp027_test_root, "outputs"))

  testthat::expect_identical(as.integer(status), 0L)
  testthat::expect_identical(
    as.character(output),
    "WP-027 nested source returned"
  )
  testthat::expect_false(dir.exists(file.path(sandbox, "outputs")))
  testthat::expect_identical(after, before)
})

testthat::test_that("post-gate finalization failures retain explicit failed evidence", {
  clean_state <- function(root) {
    list(
      head = "abc123",
      clean = TRUE,
      detail = character()
    )
  }
  fail_at <- function(stage) {
    force(stage)
    function(...) stop(paste("injected", stage, "failure"), call. = FALSE)
  }
  pass <- function(...) invisible(TRUE)
  scenarios <- list(
    hash = list(
      hash_manifest = fail_at("hash"),
      external_verify = pass,
      promote = pass
    ),
    `external-verification` = list(
      hash_manifest = pass,
      external_verify = fail_at("external verification"),
      promote = pass
    ),
    promotion = list(
      hash_manifest = pass,
      external_verify = pass,
      promote = fail_at("promotion")
    )
  )

  for (stage in names(scenarios)) {
    parent <- tempfile(paste0("wp027-finalize-", stage, "-"))
    dir.create(parent)
    temp_run <- file.path(parent, ".WP-027_TEST.tmp")
    final_run <- file.path(parent, "WP-027_TEST")
    dir.create(temp_run)
    writeLines("payload", file.path(temp_run, "payload.txt"))
    scenario <- scenarios[[stage]]

    testthat::expect_error(
      wp027_finalize_canonical(
        temp_run = temp_run,
        final_run = final_run,
        root = "unused",
        validated_head = "abc123",
        started_utc = "2026-07-16T00:00:00Z",
        state_reader = clean_state,
        hash_manifest = scenario$hash_manifest,
        external_verify = scenario$external_verify,
        promote = scenario$promote
      ),
      "injected",
      fixed = TRUE
    )
    metadata <- readLines(file.path(temp_run, "metadata.txt"), warn = FALSE)
    failed <- readLines(file.path(temp_run, "FAILED"), warn = FALSE)
    testthat::expect_true(dir.exists(temp_run), info = stage)
    testthat::expect_false(dir.exists(final_run), info = stage)
    testthat::expect_true("status=FAILED" %in% metadata, info = stage)
    testthat::expect_false("status=PASS" %in% metadata, info = stage)
    testthat::expect_true(paste0("stage=", stage) %in% failed, info = stage)
    testthat::expect_true(any(startsWith(failed, "detail=injected")), info = stage)
  }
})

testthat::test_that("canonical repository state is clean and immutable", {
  dirty_state <- function(root) {
    list(
      head = "abc123",
      clean = FALSE,
      detail = " M scripts/validate_wp027.R"
    )
  }
  testthat::expect_error(
    wp027_require_clean_repo("unused", state_reader = dirty_state),
    "Tracked repository state is not clean",
    fixed = TRUE
  )

  canonical_body <- paste(deparse(body(wp027_run_canonical)), collapse = "\n")
  preflight_position <- regexpr(
    "wp027_require_clean_repo",
    canonical_body,
    fixed = TRUE
  )
  gates_position <- regexpr("wp027_execute_specs", canonical_body, fixed = TRUE)
  testthat::expect_gt(preflight_position, 0L)
  testthat::expect_lt(preflight_position, gates_position)

  changed_states <- list(
    dirty = list(
      state = list(head = "abc123", clean = FALSE, detail = " M tracked-file"),
      message = "Tracked repository state is not clean"
    ),
    head = list(
      state = list(head = "def456", clean = TRUE, detail = character()),
      message = "Validation HEAD changed"
    )
  )
  for (name in names(changed_states)) {
    parent <- tempfile(paste0("wp027-repo-state-", name, "-"))
    dir.create(parent)
    temp_run <- file.path(parent, ".WP-027_TEST.tmp")
    final_run <- file.path(parent, "WP-027_TEST")
    dir.create(temp_run)
    writeLines("payload", file.path(temp_run, "payload.txt"))
    hash_calls <- 0L
    hash_manifest <- function(...) {
      hash_calls <<- hash_calls + 1L
      invisible(TRUE)
    }
    state <- changed_states[[name]]
    state_reader <- function(root) state$state

    testthat::expect_error(
      wp027_finalize_canonical(
        temp_run = temp_run,
        final_run = final_run,
        root = "unused",
        validated_head = "abc123",
        started_utc = "2026-07-16T00:00:00Z",
        state_reader = state_reader,
        hash_manifest = hash_manifest,
        external_verify = function(...) invisible(TRUE),
        promote = function(...) invisible(TRUE)
      ),
      state$message,
      fixed = TRUE
    )
    metadata <- readLines(file.path(temp_run, "metadata.txt"), warn = FALSE)
    failed <- readLines(file.path(temp_run, "FAILED"), warn = FALSE)
    testthat::expect_identical(hash_calls, 0L, info = name)
    testthat::expect_true(dir.exists(temp_run), info = name)
    testthat::expect_false(dir.exists(final_run), info = name)
    testthat::expect_true("status=FAILED" %in% metadata, info = name)
    testthat::expect_true("validated_head=abc123" %in% metadata, info = name)
    testthat::expect_true("stage=repository-state" %in% failed, info = name)
  }

  parent <- tempfile("wp027-repo-state-after-hash-")
  dir.create(parent)
  temp_run <- file.path(parent, ".WP-027_TEST.tmp")
  final_run <- file.path(parent, "WP-027_TEST")
  dir.create(temp_run)
  writeLines("payload", file.path(temp_run, "payload.txt"))
  mutated <- FALSE
  promotion_calls <- 0L
  state_reader <- function(root) {
    if (mutated) {
      list(head = "abc123", clean = FALSE, detail = " M hash-mutated-file")
    } else {
      list(head = "abc123", clean = TRUE, detail = character())
    }
  }
  hash_manifest <- function(...) {
    mutated <<- TRUE
    invisible(TRUE)
  }
  promote <- function(...) {
    promotion_calls <<- promotion_calls + 1L
    invisible(TRUE)
  }

  testthat::expect_error(
    wp027_finalize_canonical(
      temp_run = temp_run,
      final_run = final_run,
      root = "unused",
      validated_head = "abc123",
      started_utc = "2026-07-16T00:00:00Z",
      state_reader = state_reader,
      hash_manifest = hash_manifest,
      external_verify = function(...) invisible(TRUE),
      promote = promote
    ),
    "Tracked repository state is not clean",
    fixed = TRUE
  )
  metadata <- readLines(file.path(temp_run, "metadata.txt"), warn = FALSE)
  failed <- readLines(file.path(temp_run, "FAILED"), warn = FALSE)
  testthat::expect_identical(promotion_calls, 0L)
  testthat::expect_true(dir.exists(temp_run))
  testthat::expect_false(dir.exists(final_run))
  testthat::expect_true("status=FAILED" %in% metadata)
  testthat::expect_true("stage=repository-state" %in% failed)
  testthat::expect_true(any(grepl("hash-mutated-file", failed, fixed = TRUE)))
})
