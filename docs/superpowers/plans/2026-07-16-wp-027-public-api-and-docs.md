# WP-027 Public API and Documentation Freeze Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Freeze `localmap` at exactly 17 tiered exports, present one coherent settings-first documentation system, and close WP-027 with reproducible hash-verified local evidence without changing runtime behavior.

**Architecture:** Treat roxygen blocks, Markdown/QMD/Rmd sources, and one sourceable base-R validation script as the only authoring surfaces. Deliver four serial, locally committed units: API metadata and tests, user documentation and renders, the validation harness, then canonical validation and tracked closeout; generated products under `outputs/` are evidence only.

**Tech Stack:** R 4.6.x (validated on 4.6.1), roxygen2 8.0.0, devtools, testthat edition 3, yaml, targets, renv, pkgdown, Quarto, GNU Make, base R `system2()`, `shasum`, ripgrep, Git.

## Global Constraints

- Dependency order is strict: Task 1 -> Task 2 -> Task 3 -> Task 4.
- Preserve all runtime features, function bodies, target names/dependencies, settings semantics, output schemas, output locations, and artifact contents.
- Preserve the names, ordered formals, default expressions, return contracts, and behavior of all 13 stable functions.
- Keep four transitional exports callable, document them as experimental, and add no runtime warning or lifecycle dependency.
- Internalize 13 helpers by removing `@export` only; do not move, rename, delete, wrap, alias, deprecate, or refactor them.
- `NAMESPACE` and `.Rd` files are roxygen-generated. Never hand-edit generated package metadata.
- Keep `settings.example.yaml` a prerequisite-backed real-data template; never give it clean-clone fixture semantics.
- The clean demonstration is exactly `jc_ci`, offline, fixture-backed, and does not promise `outputs/jc/maps/species_topo.png`.
- Generated sites, reports, maps, tables, logs, and canonical runs remain under ignored `outputs/` paths and are evidence, never authoring sources.
- Do not alter `_targets.R`, `config/config.yaml`, `renv.lock`, `docs/release_checklist.md`, versions, tags, or release metadata. For Task 2 only, the independent-review amendment below permits `DESCRIPTION` `Title` and `Description`; all other DESCRIPTION fields remain protected.
- Do not fetch, pull, push, publish, contact remotes, create a release payload, or begin WP-028 packaging.
- Use local commits with the exact task messages below. Stage exact paths only.
- Stop on a dirty or conflicting owned path, unexplained inventory drift, any warning/skip outside the exact accepted baselines below, failed gate, or scope expansion; preserve evidence and report the owning task.

## Execution And Review Protocol

- Use a fresh implementer for each task. Give that worker only the approved design, this plan, prior task commit SHAs, and its task section.
- After each task, dispatch an independent specification reviewer, then an independent code/document quality reviewer. Fix findings in the owning task before accepting its commit.
- After Task 4, run a broad final review against the complete design and A1-A15 matrix rather than relying on task summaries.
- A reviewer must inspect raw diffs, commands, logs, artifacts, and hashes in proportion to risk; a claimed pass or completion flag is not evidence.

## Independent-review amendment (2026-07-16)

This amendment records the Task 2 independent-review adjudication and
supersedes conflicting Task 2 scope or protection wording:

- Task 2 additionally authorizes only the `Title` and `Description` fields in
  `DESCRIPTION`, `scripts/build_public_site.R`,
  `tests/testthat/test-documentation-site.R`, and the single public-site
  Makefile recipe `@$(RSCRIPT) scripts/build_public_site.R`.
- `DESCRIPTION` remains at `Version: 0.0.0.9000`; every other DESCRIPTION
  field and all version, tag, packaging, and release metadata remain protected.
- The product has exactly two workflows: the deterministic offline JC
  demonstration and the real-data settings workflow. The checkout wrapper and
  installed-package API are two invocation contexts for the same real-data
  workflow, not additional workflows or routes.
- The known non-fatal Quarto external-output warning is explicitly waived for
  WP-027 because `outputs/quarto` is the binding generated/source destination.
- For future Task 3 and Task 4 protected-path validation, accept `9938ba8` as
  the post-Task-2 DESCRIPTION baseline. Parse DESCRIPTION as DCF against the
  approved design baseline, allow only `Title` and `Description` to differ,
  and require `Version: 0.0.0.9000` plus all other release metadata to match.

## Pre-flight Conflict Scan

- [ ] From `/Users/bwbrook/git/localmap_tas`, prove the approved baseline is present and this plan is tracked before implementation begins:

```sh
pwd
git branch --show-current
git rev-parse --short HEAD
git status --short --branch
git merge-base --is-ancestor a55733d860f78e48753749977ce69d6a2e0d2b41 HEAD
git cat-file -e a55733d860f78e48753749977ce69d6a2e0d2b41:docs/plans/2026-07-16-wp-027-public-api-and-docs-design.md
git ls-files --error-unmatch docs/superpowers/plans/2026-07-16-wp-027-public-api-and-docs.md
```

Expected: repository root, `main`, baseline ancestor check exit `0`, both design and tracked plan resolve, and no uncommitted path. Being locally ahead of `origin/main` is expected and must not trigger remote contact.

- [ ] Reject pre-existing implementation or evidence conflicts:

```sh
test ! -e docs/log/WP-027_2026-07-16_public-api-docs-freeze.md
test -z "$(find outputs/canonical_runs -mindepth 1 -maxdepth 1 -type d -name 'WP-027_*' -print 2>/dev/null)"
if rg -n '^(<<<<<<< |=======|>>>>>>> )' README.md R tests docs scripts reports Makefile NAMESPACE _pkgdown.yml quarto.yml settings.example.yaml; then exit 1; fi
```

Expected: no closeout log, no promoted WP-027 run, no conflict markers. Stop without cleaning or overwriting if any command fails.

---

### Task 1: Freeze the 17-Export API and Migrate Internal Test Access

**Files:**
- Create: `tests/testthat/test-public-api.R`
- Modify roxygen only: `R/ala_configure.R`, `R/ala_default_occurrence_fields.R`, `R/analysis_layer_validation.R`, `R/coverage_zone.R`, `R/data_preview.R`, `R/data_readers.R`, `R/imagery_arcgis.R`, `R/imagery_wms.R`, `R/layer_registry.R`, `R/manifest.R`, `R/map_species_occurrences.R`, `R/provenance_outputs.R`, `R/site_attributes.R`
- Modify namespace operators only: `tests/testthat/test_provenance_outputs.R`, `tests/testthat/test_combine.R`, `tests/testthat/test_imagery_arcgis.R`, `tests/testthat/test_imagery_wms.R`, `tests/testthat/test_network_optional.R`, `tests/testthat/test_preview.R`, `tests/testthat/test_analysis_layers.R`, `tests/testthat/test_layer_registry.R`, `tests/testthat/test_site_attributes.R`
- Generate: `NAMESPACE`, `man/ala_configure.Rd`, `man/fetch_layer_registry.Rd`, `man/generate_topo_tile_map.Rd`, `man/read_manifest.Rd`

**Interfaces:**
- Consumes: the current 30 exports, 13 stable function objects, 13 internal helper implementations, and fixed pre-edit test inventories.
- Produces stable exports: `cfg_read`, `run_settings`, `ala_fetch_occurrences`, `ala_resolve_species`, `assemble_panel_figure`, `build_aoi_from_config`, `build_coverage_zone`, `build_site_attributes_long`, `fetch_analysis_layers`, `map_species_occurrences`, `read_species_requests`, `render_overview_map`, `validate_output_manifest`.
- Produces experimental exports: `ala_configure`, `fetch_layer_registry`, `generate_topo_tile_map`, `read_manifest`.
- Produces internal names: `ala_default_occurrence_fields`, `build_layer_provenance`, `combine_manifest_csvs`, `fetch_arcgis_imagery`, `fetch_wms_imagery`, `preview_manifest`, `validate_analysis_layers`, `validate_layer_registry`, `write_attribution_report`, `write_coverage_summary`, `write_run_manifest`, `write_site_attributes_long`, `write_site_attributes_wide`.
- Provides Task 2 with `stable_exports`, `experimental_exports`, `internal_names`, `expected_exports`, and `canonical_formals()` in `test-public-api.R`.

**Stop Conditions:** Stop if `NAMESPACE` is not the 30-export baseline, any stable formal differs, direct internal references are not exactly 17 calls in the nine named files, any function body/assertion changes, roxygen generates an unexpected path, or a focused/full test fails.

- [ ] **Step 1: Record immutable API and test baselines**

```sh
sed -n '/^export(/p' NAMESPACE
rg --pcre2 -n 'localmap::(?!:)(ala_default_occurrence_fields|build_layer_provenance|combine_manifest_csvs|fetch_arcgis_imagery|fetch_wms_imagery|preview_manifest|validate_analysis_layers|validate_layer_registry|write_attribution_report|write_coverage_summary|write_run_manifest|write_site_attributes_long|write_site_attributes_wide)\b' tests
rg -o --no-filename 'testthat::test_that\(' tests/testthat | wc -l
rg -o --no-filename 'testthat::expect_[[:alnum:]_]+\(' tests/testthat | wc -l
```

Expected: 30 exports, 17 direct calls across nine files, 92 `test_that` blocks, and 243 `expect_*` calls. Record per-file baselines: provenance `2/13`, combine `1/3`, ArcGIS `3/6`, WMS `4/7`, network optional `1/1`, preview `1/2`, analysis layers `12/27`, registry `3/4`, site attributes `5/17`.

- [ ] **Step 2: Write the failing export and exact stable-formals contract**

Create the vectors above and encode every ordered default exactly:

```r
stable_formals <- list(
  cfg_read = c(profile = "Sys.getenv(\"R_CONFIG_ACTIVE\", \"default\")", config_path = "NULL"),
  run_settings = c(settings_path = "<missing>", targets = "NULL", base_profile = "NULL", config_path = "NULL"),
  ala_fetch_occurrences = c(taxa = "<missing>", min_year = "NULL", boundary = "NULL", boundary_simplify = "NULL", columns = "ala_default_occurrence_fields()", min_lat = "NULL", state_province = "NULL", fetch_fun = "NULL", config = "NULL"),
  ala_resolve_species = c(species_requests = "<missing>", search_fun = "galah::search_taxa"),
  assemble_panel_figure = c(panel_cfg = "<missing>", prerequisites = "NULL"),
  build_aoi_from_config = c(aoi_cfg = "<missing>", sites = "NULL"),
  build_coverage_zone = c(sites = "<missing>", coverage_cfg = "NULL", analysis_crs = "\"EPSG:28355\""),
  build_site_attributes_long = c(sites = "<missing>", analysis_layers = "<missing>", aoi = "NULL", analysis_crs = "NULL", distance_layers = "NULL"),
  fetch_analysis_layers = c(layers = "<missing>", aoi = "<missing>", cache_dir = "NULL"),
  map_species_occurrences = c(occurrences = "<missing>", mapping_settings = "NULL", aoi = "NULL", output_path = "NULL"),
  read_species_requests = c(path = "<missing>"),
  render_overview_map = c(aoi = "<missing>", sites = "<missing>", coverage = "NULL", layers = "NULL", map_cfg = "NULL"),
  validate_output_manifest = c(manifest = "<missing>", expected_outputs = "NULL")
)

canonical_formals <- function(fn) {
  values <- formals(fn)
  out <- vapply(seq_along(values), function(i) {
    if (identical(values[[i]], quote(expr=))) "<missing>" else deparse1(values[[i]], width.cutoff = 500L)
  }, character(1))
  names(out) <- names(values)
  out
}
```

Add two `test_that` blocks: one compares sorted namespace exports to the exact 17-name union and proves the three tier vectors are disjoint/complete; the other compares `canonical_formals(getExportedValue("localmap", name))` to every entry above without evaluating defaults.

- [ ] **Step 3: Prove the intended red state**

```sh
Rscript -e "devtools::test(filter = 'public-api', reporter = 'summary', stop_on_failure = TRUE)"
```

Expected: only export-tier expectations fail because the 13 helpers remain exported; all 13 formal comparisons already pass. Stop on any other failure.

- [ ] **Step 4: Change roxygen export metadata only**

Remove `#' @export` from the 13 internal helpers. Add one lifecycle section before the existing `@export` for each transitional function, following this exact pattern and function-specific replacement:

```r
#' @section Lifecycle:
#' **Experimental.** Prefer [cfg_read()] or [run_settings()]. This export is
#' retained for current callers without a runtime warning while the
#' configuration interface settles.
#' @export
```

For `fetch_layer_registry()`, state that no stable direct replacement exists; for `generate_topo_tile_map()`, prefer `map_species_occurrences()` or `render_overview_map()`; for `read_manifest()`, retain inspection while directing new workflows to `cfg_read()` or `run_settings()`. Do not add `lifecycle`, warnings, `@keywords internal`, or implementation edits.

- [ ] **Step 5: Make exactly 17 test-only operator substitutions**

| Test file | Exact substitutions and occurrence counts |
|---|---|
| `test_provenance_outputs.R` | `build_layer_provenance` (1), `write_attribution_report` (1), `write_run_manifest` (1) |
| `test_combine.R` | `combine_manifest_csvs` (1) |
| `test_imagery_arcgis.R` | `fetch_arcgis_imagery` (2) |
| `test_imagery_wms.R` | `fetch_wms_imagery` (2) |
| `test_network_optional.R` | `fetch_wms_imagery` (1) |
| `test_preview.R` | `preview_manifest` (1) |
| `test_analysis_layers.R` | `validate_analysis_layers` (1) |
| `test_layer_registry.R` | `validate_layer_registry` (3) |
| `test_site_attributes.R` | `write_site_attributes_long` (1), `write_site_attributes_wide` (2) |

Change only `localmap::name` to `localmap:::name`; preserve all 32 tests and 80 assertions.

- [ ] **Step 6: Regenerate and inspect package metadata**

```sh
manuals=(
  man/ala_configure.Rd
  man/fetch_layer_registry.Rd
  man/generate_topo_tile_map.Rd
  man/read_manifest.Rd
)
first_diff="$(mktemp "${TMPDIR:-/tmp}/wp027-roxygen-first.XXXXXX")"
second_diff="$(mktemp "${TMPDIR:-/tmp}/wp027-roxygen-second.XXXXXX")"
trap 'rm -f "$first_diff" "$second_diff"' EXIT HUP INT TERM

Rscript -e "devtools::document()"
git diff --name-only -- DESCRIPTION NAMESPACE man
sed -n '/^export(/p' NAMESPACE

first_hashes="$(shasum -a 256 "${manuals[@]}")"
git diff --binary -- NAMESPACE "${manuals[@]}" > "$first_diff"

Rscript -e "devtools::document()"
second_hashes="$(shasum -a 256 "${manuals[@]}")"
git diff --binary -- NAMESPACE "${manuals[@]}" > "$second_diff"
test "$first_hashes" = "$second_hashes"
cmp -s "$first_diff" "$second_diff"

for file in "${manuals[@]}"; do
  perl -0777 -e 'exit((/\n\n\z/ && !/\n\n\n\z/) ? 0 : 1)' "$file"
done

rm -f "$first_diff" "$second_diff"
trap - EXIT HUP INT TERM
```

Expected: only `NAMESPACE` and the four transitional manuals change; `NAMESPACE` contains the exact 17 exports and retains `importFrom(rlang,.data)`; `DESCRIPTION` and internal manuals remain unchanged. Roxygen2 8.0.0 generates exactly one terminal blank line in each named transitional manual. The second `devtools::document()` preserves all four manual hashes and the full `NAMESPACE`/manual diff byte-for-byte. Never hand-edit `NAMESPACE` or any `.Rd` file to remove these generator-owned blank lines.

- [ ] **Step 7: Run focused and full verification**

```sh
Rscript -e "devtools::test(filter = 'public-api', reporter = 'summary', stop_on_failure = TRUE)"
LOCALMAP_ALLOW_NETWORK=0 Rscript -e "devtools::test(filter = 'provenance_outputs|combine|imagery_arcgis|imagery_wms|network_optional|preview|analysis_layers|layer_registry|site_attributes', reporter = 'summary', stop_on_failure = TRUE)"
LOCALMAP_ALLOW_NETWORK=0 Rscript -e "devtools::test(reporter = 'summary', stop_on_failure = TRUE)"
git diff --check -- R tests/testthat NAMESPACE
```

Expected: the public-API run has `FAIL 0`, `WARN 0`, `SKIP 0`. The focused migrated run has exactly `FAIL 0`, six pre-existing offline/spatial warnings, and one skip with exact reason `Network fetch disabled (set LOCALMAP_ALLOW_NETWORK=1 to enable).` The full suite has exactly `FAIL 0`, seven pre-existing offline/spatial warnings, and that same single network skip. Capture the complete warning text and test context from both summaries; any additional warning, skip, or failure blocks Task 1. Internal public-access scan is empty, triple-colon files equal the nine-file allowlist, migrated counts remain `32/80`, and post-Task-1 lexical totals are exactly `94/252`. The scoped diff check reports no finding outside the four generator-owned manuals handled after staging.

- [ ] **Step 8: Review checkpoint and exact local commit**

Independent spec review must compare the 30-function disposition and all defaults to the design. Quality review must prove R diffs are roxygen-only and migrated tests are operator-only.

```sh
git add R/ala_configure.R R/ala_default_occurrence_fields.R R/analysis_layer_validation.R R/coverage_zone.R R/data_preview.R R/data_readers.R R/imagery_arcgis.R R/imagery_wms.R R/layer_registry.R R/manifest.R R/map_species_occurrences.R R/provenance_outputs.R R/site_attributes.R tests/testthat/test-public-api.R tests/testthat/test_provenance_outputs.R tests/testthat/test_combine.R tests/testthat/test_imagery_arcgis.R tests/testthat/test_imagery_wms.R tests/testthat/test_network_optional.R tests/testthat/test_preview.R tests/testthat/test_analysis_layers.R tests/testthat/test_layer_registry.R tests/testthat/test_site_attributes.R NAMESPACE man/ala_configure.Rd man/fetch_layer_registry.Rd man/generate_topo_tile_map.Rd man/read_manifest.Rd
cached_check="$(git diff --cached --check 2>&1)" || cached_status=$?
cached_status="${cached_status:-0}"
test "$cached_status" -ne 0
actual="$(printf '%s\n' "$cached_check" | sed -E 's/:[0-9]+:/:LINE:/' | LC_ALL=C sort)"
expected="$(printf '%s\n' \
  'man/ala_configure.Rd:LINE: new blank line at EOF.' \
  'man/fetch_layer_registry.Rd:LINE: new blank line at EOF.' \
  'man/generate_topo_tile_map.Rd:LINE: new blank line at EOF.' \
  'man/read_manifest.Rd:LINE: new blank line at EOF.' | LC_ALL=C sort)"
test "$actual" = "$expected"
git diff --cached --name-only
git commit -m "agent: refactor(WP-027): freeze public API contract"
```

Expected: exactly 28 staged paths. The cached diff check has exactly four findings, each `new blank line at EOF.` for one named roxygen2-generated transitional manual, and no other whitespace finding; these are accepted only because Step 6 proved one terminal blank line plus idempotent hashes/full diff. Any different path, duplicate finding, trailing whitespace, or other cached warning blocks the commit. Commit locally, record its SHA, and do not push.

---

### Task 2: Align Settings-First Documentation, Sites, and JC Report

**Files:**
- Modify: `README.md`, `settings.example.yaml`, `docs/product_brief.md`, `docs/index.qmd`, `docs/settings.md`, `docs/DEVELOPMENT.qmd`, `docs/PIPELINE.md`, `docs/workflow.md`, `docs/config_reference.md`, `docs/layers_guide.md`, `docs/output_schema_v1.md`, `vignettes/intro.Rmd`
- Modify: `_pkgdown.yml`, `Makefile`, `reports/paper.qmd`, `docs/CHANGELOG.md`, `tests/testthat/test-public-api.R`, and only `Title`/`Description` in `DESCRIPTION`
- Create: `scripts/build_public_site.R`, `tests/testthat/test-documentation-site.R`
- Rename: `quarto.yml` -> `docs/_quarto.yml` and update it as the recognized docs-root Quarto project file
- Generate but never stage: `outputs/jc/**`, `outputs/quarto/**`, `outputs/pkgdown/**`, `outputs/reports/paper.html`

**Interfaces:**
- Consumes: Task 1's exact tier vectors and unchanged `scripts/run_project.R <settings-path>` wrapper around `localmap::run_settings(settings_path)`.
- Produces: one two-workflow wording contract, with checkout and installed-package invocation contexts for the real-data workflow; five pkgdown groups with counts `2,4,3,4,4`; Quarto at `outputs/quarto`; pkgdown at `outputs/pkgdown`; and a JC report at `outputs/reports/paper.html`.
- Extends: `test-public-api.R` with pkgdown completeness/no-duplicates/no-internals and documentation namespace checks.
- The design's `quarto.yml` ownership is fulfilled by the tracked rename to Quarto's valid `docs/_quarto.yml`; generated HTML never replaces this source.

**Stop Conditions:** Stop if Task 1 is not committed and clean, a source path conflicts, a requested correction requires runtime/target/schema behavior, any render or link check fails, or generated output becomes staged.

- [ ] **Step 1: Confirm Task 1 and the documentation boundary**

```sh
git status --short
git show -s --format=%s HEAD
Rscript -e "devtools::test(filter = 'public-api', reporter = 'summary', stop_on_failure = TRUE)"
```

Expected: clean tree; HEAD message is Task 1's exact commit message; the working checkout's exact export/formals contract passes.

- [ ] **Step 2: Establish the two workflows and real-data invocation contexts**

Use this exact clean-checkout shell block in `README.md`, `docs/product_brief.md`, `docs/index.qmd`, `docs/PIPELINE.md`, and `docs/workflow.md`:

```sh
make bootstrap
LOCALMAP_ALLOW_NETWORK=0 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci make pipeline
```

Keep the checkout wrapper and installed-package API distinct, but identify both
as invocation contexts for the same real-data settings workflow. Use this exact
installed-package call in README, product brief, Quarto home, settings guide,
and vignette only after stating that `localmap` must be installed:

```r
localmap::run_settings("settings.example.yaml")
```

State before that call that `site.csv` must exist in the configured input directory with `site`, `lat`, and `lon`; `obs.csv` and `op.csv` are optional. Label `settings.example.yaml` as real-data only. State that `jc_ci` uses packaged occurrence/camera fixtures, offline WMS/ArcGIS placeholders, disabled topographic tiles, and no `species_topo.png` promise.

- [ ] **Step 3: Give every design-owned source one coherent job**

| Source | Required edit |
|---|---|
| `README.md` | Package promise, two-step JC workflow, real-data workflow and both invocation contexts, expected products, contributor links |
| `settings.example.yaml` | Commented prerequisites; no clean-clone claim |
| `docs/product_brief.md` | Configured Tasmanian site mapping posture and both workflows |
| `docs/index.qmd` | Valid front matter, workflow overview, settings/vignette/report/reference links |
| `docs/settings.md` | Authoritative fields, resolution, `run_settings()`, inputs, outputs |
| `docs/DEVELOPMENT.qmd` | Contributor commands and validation order |
| `docs/PIPELINE.md` | Settings/config-first DAG and exact deterministic profile command |
| `docs/workflow.md` | Authoritative run and artifact-review cycle |
| `docs/config_reference.md` | Profiles/configuration reference without changing semantics |
| `docs/layers_guide.md` | Selection, attribution, placeholder, interpretation guidance |
| `docs/output_schema_v1.md` | Output/provenance/attribution interpretation without schema edits |
| `vignettes/intro.Rmd` | Primary APIs, one bounded advanced ALA example, experimental signposting |

Replace stale species-compendium framing only where present. Do not reproduce source prose across files; link from concise onboarding pages to the authoritative guide.

- [ ] **Step 4: Extend executable public documentation contracts**

Append tests equivalent to these exact checks in `test-public-api.R`:

```r
testthat::test_that("pkgdown indexes every public export exactly once", {
  config <- yaml::read_yaml("_pkgdown.yml")
  indexed <- unname(unlist(lapply(config$reference, `[[`, "contents"), use.names = FALSE))
  testthat::expect_identical(sort(indexed), expected_exports)
  testthat::expect_false(anyDuplicated(indexed))
  testthat::expect_false(any(internal_names %in% indexed))
})

testthat::test_that("documentation namespace calls use public exports", {
  paths <- c("README.md", list.files("docs", "[.](md|qmd)$", recursive = TRUE, full.names = TRUE), "vignettes/intro.Rmd", "reports/paper.qmd")
  text <- paste(vapply(paths, function(path) paste(readLines(path, warn = FALSE), collapse = "\n"), character(1)), collapse = "\n")
  hits <- regmatches(text, gregexpr("localmap::(?!:)[A-Za-z][A-Za-z0-9_.]*", text, perl = TRUE))[[1]]
  names_used <- sub("localmap::", "", hits, fixed = TRUE)
  testthat::expect_true(all(names_used %in% expected_exports))
})

testthat::test_that("Makefile test target stops on test failure", {
  expected <- paste0(
    "\t@$(RSCRIPT) -e \"",
    "devtools::test(reporter='summary', stop_on_failure=TRUE)\""
  )
  testthat::expect_true(expected %in% readLines("Makefile", warn = FALSE))
})
```

Run the focused test with `stop_on_failure = TRUE` before editing docs and expect the new pkgdown/Makefile contracts to fail on stale configuration; after source changes all contract tests must pass.

- [ ] **Step 5: Define pkgdown, Quarto, and Makefile interfaces**

Set `_pkgdown.yml` destination to `outputs/pkgdown` and group each export once:

```yaml
reference:
  - title: Primary
    contents: [cfg_read, run_settings]
  - title: "Advanced: configuration and spatial"
    contents: [build_aoi_from_config, build_coverage_zone, fetch_analysis_layers, build_site_attributes_long]
  - title: "Advanced: ALA"
    contents: [read_species_requests, ala_resolve_species, ala_fetch_occurrences]
  - title: "Advanced: rendering and outputs"
    contents: [render_overview_map, map_species_occurrences, assemble_panel_figure, validate_output_manifest]
  - title: Experimental
    contents: [ala_configure, fetch_layer_registry, generate_topo_tile_map, read_manifest]
```

Rename the invalid root config and set the docs-root project contract:

```yaml
project:
  title: localmap
  type: website
  output-dir: ../outputs/quarto
  render: [index.qmd, settings.md, PIPELINE.md, config_reference.md, layers_guide.md, output_schema_v1.md, workflow.md, DEVELOPMENT.qmd]
```

Navigation must link Home, Get started, Pipeline, all guides, `../pkgdown/articles/intro.html`, `../pkgdown/reference/index.html`, and `../reports/paper.html`. Add `site` to `.PHONY` and Makefile help; retain the existing `site` recipe and `docs: quarto render docs/` recipe. Replace the Makefile test recipe with this exact decisive gate:

```make
test:
	@$(RSCRIPT) -e "devtools::test(reporter='summary', stop_on_failure=TRUE)"
```

After the static contract test passes, run this controlled probe to prove an actual failing test makes `make test` return nonzero without retaining a probe file:

```sh
probe=tests/testthat/test-wp027-make-failure-probe.R
probe_log="$(mktemp "${TMPDIR:-/tmp}/wp027-make-test.XXXXXX")"
test ! -e "$probe"
cleanup_probe() { rm -f "$probe" "$probe_log"; }
trap cleanup_probe EXIT HUP INT TERM
printf '%s\n' \
  'testthat::test_that("WP-027 controlled make failure", {' \
  '  testthat::expect_true(FALSE, info = "WP027 controlled failure")' \
  '})' > "$probe"
set +e
LOCALMAP_ALLOW_NETWORK=0 make test > "$probe_log" 2>&1
probe_status=$?
set -e
test "$probe_status" -ne 0
rg -n -F 'WP027 controlled failure' "$probe_log"
cleanup_probe
trap - EXIT HUP INT TERM
test ! -e "$probe"
```

Expected: the controlled run is nonzero and its raw output contains the named failure. A zero status blocks Task 2. After cleanup, rerun the normal focused/full gates; no probe file or log may enter Git.

- [ ] **Step 6: Correct the report and Unreleased changelog**

Give `reports/paper.qmd` valid YAML, a hidden setup chunk setting knitr root to the repository root, and preserve `targets::tar_read(manifest_summary)` plus existing previews. Apply exactly:

| Stale | Correct |
|---|---|
| `outputs/maps/jc_overview_map.png` | `outputs/jc/maps/overview_map.png` |
| `outputs/maps/jc_panel_figure.png` | `outputs/jc/maps/panel_figure.png` |
| `outputs/tables/jc/site_attributes_long.parquet` | `outputs/jc/tables/site_attributes_long.parquet` |
| `outputs/tables/jc/site_attributes_wide.csv` | `outputs/jc/tables/site_attributes_wide.csv` |
| `outputs/provenance/attribution.md` | `outputs/jc/provenance/attribution.md` |
| `outputs/provenance/run_manifest.yml` | `outputs/jc/provenance/run_manifest.yml` |

Under Unreleased in `docs/CHANGELOG.md`, record settings-first onboarding, 13 stable plus four experimental tiers, all 13 internalized names and migration routes, output destinations, Quarto/report fixes, and no-warning pre-release posture. Do not add a version heading or release claim.

- [ ] **Step 7: Run source, pipeline, render, and link checks in order**

```sh
Rscript -e "devtools::test(filter = 'public-api', reporter = 'summary', stop_on_failure = TRUE)"
LOCALMAP_ALLOW_NETWORK=0 make test
make bootstrap
LOCALMAP_ALLOW_NETWORK=0 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci make pipeline
make docs
make site
R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci quarto render reports/paper.qmd --output-dir outputs/reports
git diff --check
```

Expected: all commands exit `0`; hardened `make test` reports exactly `FAIL 0`, seven accepted offline/spatial warnings, and one established network skip with no additional warning/skip; every required JC product from A4 is non-empty; Quarto, pkgdown, and report entry points are non-empty. Run a base-R HTML scan that extracts `href`, ignores scheme/protocol-relative/mail/data/anchor links, strips query/fragment suffixes, resolves relative targets, and reports zero missing links.

The non-empty JC assertion must use exactly these paths:

```text
outputs/jc/maps/species_occurrences.png
outputs/jc/maps/overview_map.png
outputs/jc/maps/panel_figure.png
outputs/jc/maps/panel_figure.pdf
outputs/jc/maps/camera_sites.png
outputs/jc/maps/camera_sites_panel.png
outputs/jc/tables/coverage_summary.csv
outputs/jc/tables/site_attributes_long.parquet
outputs/jc/tables/site_attributes_wide.csv
outputs/jc/layers/tasveg_wms.png
outputs/jc/layers/topography_arcgis.png
```

- [ ] **Step 8: Inspect generated evidence without authoring from it**

Open `outputs/quarto/index.html`, `outputs/quarto/settings.html`, `outputs/pkgdown/index.html`, `outputs/pkgdown/reference/index.html`, `outputs/pkgdown/articles/intro.html`, and `outputs/reports/paper.html`. Confirm the two workflows remain distinct, the real-data invocation contexts remain correctly conditioned, reference group counts are `2,4,3,4,4`, no internal helper is indexed, report maps/tables/provenance are populated, and no placeholder is described as fetched live imagery.

- [ ] **Step 9: Review checkpoint and exact local commit**

Spec review must cover every ownership-table row and report path. Quality review must verify `test-public-api.R` ownership, the Quarto rename, link behavior, generated/source separation, and no runtime diff.

```sh
git add -A -- README.md settings.example.yaml docs/product_brief.md docs/index.qmd docs/settings.md docs/DEVELOPMENT.qmd docs/PIPELINE.md docs/workflow.md docs/config_reference.md docs/layers_guide.md docs/output_schema_v1.md vignettes/intro.Rmd _pkgdown.yml quarto.yml docs/_quarto.yml Makefile reports/paper.qmd docs/CHANGELOG.md tests/testthat/test-public-api.R
git diff --cached --check
git commit -m "agent: docs(wp-027): align settings-first user guides"
```

Expected: only named sources are staged; no `outputs/` path is staged; commit succeeds and worktree is clean. Record SHA; do not push.

---

### Task 3: Add the Sourceable WP-027 Validation and Evidence Harness

**Files:**
- Create: `scripts/validate_wp027.R`
- Create: `tests/testthat/test-wp027-harness.R`

**Interfaces:**
- `scripts/validate_wp027.R` uses base R only and is sourceable without running `main`; external commands use `system2()` with separate command, argument, and environment vectors.
- Pure/tested helpers: `wp027_normalize_formals()`, `wp027_inventory_tests()`, `wp027_scan_internal_references()`, `wp027_assert_nonempty()`, `wp027_extract_relative_links()`, `wp027_scan_relative_links()`, `wp027_hash_manifest()`, `wp027_verify_hash_manifest()`, `wp027_promote_verified()`, `wp027_run_gate()`, `wp027_execute_specs()`.
- Entry points: `wp027_run_dry_run()`, `wp027_run_canonical()`, `wp027_main()`; CLI is `Rscript scripts/validate_wp027.R [--dry-run]`.
- `commands.tsv` columns are exactly `sequence`, `gate`, `kind`, `started_utc`, `ended_utc`, `command`, `arguments`, `environment`, `exit_status`, `stdout_path`, `stderr_path`.
- The Tests gate consumes Task 2's hardened `make test` recipe, so any test failure returns nonzero. Its separate raw stdout/stderr remain under `steps/`; Test contracts writes `test-warning-inventory.tsv` with exact columns `scope`, `kind`, `ordinal`, `test`, `text`, `accepted` and rejects a full-suite inventory other than seven accepted offline/spatial warnings plus the one established network skip.
- Canonical output is exactly one `outputs/canonical_runs/WP-027_<UTC_TIMESTAMP>` promoted from sibling `.WP-027_<UTC_TIMESTAMP>.tmp` by verified `file.rename()` only.

**Stop Conditions:** Do not run the canonical no-argument harness in Task 3. Stop if the script runs when sourced, dry-run touches repository outputs or real commands, failure evidence is lost, hashes can be bypassed, command order differs, or full tests regress. Any Task 3 protected-path check must use `9938ba8` as the accepted post-Task-2 DESCRIPTION baseline and retain the amendment's structural Version/release-metadata check.

- [ ] **Step 1: Write failing pure-helper and fixture tests first**

Source the script into the test environment and add exactly eight focused tests covering: source safety; canonical formals and test counts; forbidden `::` plus nine-file `:::` allowlist; non-empty artifacts and relative links; hash-self exclusion and atomic promotion; first-failure logs; dry-run non-recursion; dry-run CLI failure/success fixtures.

Key promotion test:

```r
wp027_hash_manifest(temp_run)
testthat::expect_false(any(grepl("  SHA256SUMS$", readLines(file.path(temp_run, "SHA256SUMS")))))
testthat::expect_invisible(wp027_verify_hash_manifest(temp_run))
testthat::expect_identical(wp027_promote_verified(temp_run, final_run), normalizePath(final_run, winslash = "/", mustWork = TRUE))
writeLines("after", file.path(bad_run, "metadata.txt"))
testthat::expect_error(wp027_promote_verified(bad_run, bad_final), "SHA256 verification failed", fixed = TRUE)
testthat::expect_true(dir.exists(bad_run))
testthat::expect_false(dir.exists(bad_final))
```

Run `Rscript -e "devtools::test(filter = 'wp027-harness', reporter = 'summary', stop_on_failure = TRUE)"`; expected controlled nonzero red state is inability to source the absent script, not unrelated package failure.

- [ ] **Step 2: Implement fixed inventories and source-safe dispatch**

Encode the 13 internal names, nine allowed test paths, per-file `test_that`/`expect_*` baselines, suite minima `92/243`, warning baselines `focused = 6 warnings + 1 network skip` and `full = 7 warnings + 1 network skip`, 11 command columns, and required JC/docs/report paths as constants. Guard direct invocation:

```r
wp027_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (identical(args, "--dry-run")) return(wp027_run_dry_run())
  if (length(args) == 0L) return(wp027_run_canonical())
  stop("Usage: Rscript scripts/validate_wp027.R [--dry-run]", call. = FALSE)
}

if (wp027_is_direct_invocation()) {
  status <- tryCatch({ wp027_main(); 0L }, error = function(error) { message(conditionMessage(error)); 1L })
  quit(save = "no", status = status, runLast = FALSE)
}
```

`sys.source()` must define functions and create no `outputs/` directory.

- [ ] **Step 3: Implement the exact ordered gate specification**

```r
c(
  "Bootstrap", "QA bootstrap", "Package metadata", "Tests",
  "Test contracts", "Harness fixture", "Lint", "JC demonstration",
  "Quarto", "pkgdown", "Report", "Artifact assertions",
  "Relative links", "Package check", "Diff hygiene", "Evidence collection"
)
```

Map them respectively to: `make bootstrap`; `make bootstrap-qa`; `Rscript -e "devtools::document()"`; hardened `make test`; internal test/warning contracts; `Rscript scripts/validate_wp027.R --dry-run`; `make lint`; offline profiled `make pipeline`; `make docs`; `make site`; profiled Quarto report render; internal artifact assertions; internal link scan; `make check`; `git diff --check`; internal evidence collection.

Bootstrap must precede QA bootstrap, and QA bootstrap must precede both lint and package check. Before canonical execution, assert the Makefile Tests command is exactly `devtools::test(reporter='summary', stop_on_failure=TRUE)`; do not duplicate or bypass it with a softer direct test call. The JC environment is exactly `LOCALMAP_ALLOW_NETWORK=0`, `LOCALMAP_ALLOW_LARGE_DOWNLOADS=0`, `R_CONFIG_ACTIVE=jc_ci`, `TARGETS_PROFILE=ci`; report environment is exactly `R_CONFIG_ACTIVE=jc_ci`, `TARGETS_PROFILE=ci`.

- [ ] **Step 4: Implement first-failure logging and evidence collection**

For each gate, write separate `steps/<sequence>-<slug>.stdout.log` and `.stderr.log`, UTC start/end, exact ordered argument/environment encodings, integer status, and one concise `validation.log` record. Preserve the Tests gate's raw summary output, extract every warning/skip with its test context into `test-warning-inventory.tsv`, and require exactly seven accepted offline/spatial warnings plus one skip with text `Network fetch disabled (set LOCALMAP_ALLOW_NETWORK=1 to enable).`; any additional warning, skip, or failure stops the run. On first nonzero status, write `FAILED` with gate/status/detail, print the retained temp path, stop, and never create/replace canonical output.

The Test contracts and Relative links gates write `test-contract-counts.tsv` and `docs/link-scan.tsv` directly inside the temporary run. After all gates pass, retain those ledger files and copy accepted `outputs/jc/`, `outputs/quarto/`, `outputs/pkgdown/`, and `outputs/reports/paper.html` into:

```text
metadata.txt
commands.tsv
validation.log
test-contract-counts.tsv
test-warning-inventory.tsv
SHA256SUMS
steps/
jc/
docs/quarto/
docs/pkgdown/
docs/link-scan.tsv
reports/paper.html
```

Finalize metadata/logs, generate sorted `SHA256SUMS` over every regular file except itself, verify with `shasum -a 256 -c SHA256SUMS`, make no later content change, and promote using same-parent `file.rename()`. Pre-existing canonical destination, cross-filesystem parent mismatch, rename failure, or hash failure retains temp evidence and fails without copy fallback.

- [ ] **Step 5: Implement dry-run failure and success fixtures**

Use `tempfile()`/`tempdir()` only with a fake executor. Failure fixture runs pass, fail, after; proves only first two run, `FAILED` and temp remain, final does not exist. Success fixture runs two fake gates, writes metadata/payload, hashes excluding `SHA256SUMS`, verifies, atomically renames, and prints exactly:

```text
WP-027 dry run PASS
```

Dry-run specs must contain none of `Rscript`, `make`, `quarto`, `git`, or `validate_wp027`, preventing recursion through `make test`.

- [ ] **Step 6: Verify focused tests, dry run, and full suite**

```sh
Rscript -e "devtools::test(filter = 'wp027-harness', reporter = 'summary', stop_on_failure = TRUE)"
Rscript scripts/validate_wp027.R --dry-run
make test
git diff --check
```

Expected: eight focused blocks pass; dry-run prints its exact pass line and creates no repository output; hardened `make test` returns zero with exactly seven accepted offline/spatial warnings and one established network skip, while the suite remains above `92/243`; all migrated-file counts and internal-reference rules remain exact. Any extra warning/skip or absent raw warning inventory blocks Task 3.

- [ ] **Step 7: Review checkpoint and exact local commit**

Spec review must trace every design harness contract to a helper/test. Quality review must adversarially test sourceability, system2 argument separation, first-failure retention, link resolution, hash finalization order, and rename-only promotion.

```sh
git add scripts/validate_wp027.R tests/testthat/test-wp027-harness.R
git diff --cached --check
git commit -m "agent: feat(validation): add WP-027 evidence harness"
```

Expected: exactly two staged files, successful local commit, clean worktree. Record SHA; do not push.

---

### Task 4: Run Canonical Validation, Inspect Evidence, and Close WP-027

**Files:**
- Create: `docs/log/WP-027_2026-07-16_public-api-docs-freeze.md`
- Modify: `docs/AGENT_NOTES.md`
- Verify without editing: `docs/CHANGELOG.md`, approved design, implementation plan, Tasks 1-3 diffs, and `outputs/canonical_runs/WP-027_*/**`

**Interfaces:**
- Consumes: a committed clean Tasks 1-3 tree and no-argument `Rscript scripts/validate_wp027.R`.
- Consumes canonical `metadata.txt`, `commands.tsv`, `validation.log`, `test-contract-counts.tsv`, `test-warning-inventory.tsv`, `docs/link-scan.tsv`, `SHA256SUMS`, gate logs, JC products, both sites, and report.
- Produces: one evidence ledger, one AGENT_NOTES closeout with six artifact interpretation bullets, and exact commit `agent: docs(WP-027): record validation closeout`.
- Does not edit canonical evidence or produce release/version/tag/push/WP-028 artifacts.

**Stop Conditions:** Stop before canonical execution unless Tasks 1-3 are committed, HEAD is unchanged during validation, tracked tree is clean, no prior canonical directory exists, and all A1-A15 owners are present. Any canonical or inspection defect returns to its owning task; never patch promoted/generated evidence.

- [ ] **Step 1: Prove committed clean preconditions and scope**

```sh
git status --short
git log --format='%s' -3
test ! -e docs/log/WP-027_2026-07-16_public-api-docs-freeze.md
test -z "$(find outputs/canonical_runs -mindepth 1 -maxdepth 1 -type d -name 'WP-027_*' -print 2>/dev/null)"
git diff --exit-code a55733d860f78e48753749977ce69d6a2e0d2b41..HEAD -- _targets.R config/config.yaml renv.lock docs/release_checklist.md docs/AGENT_NOTES.md
git diff --exit-code 9938ba84a80e10773cf5dab19bca54cf0e60f1be..HEAD -- DESCRIPTION
Rscript -e 'baseline <- read.dcf(textConnection(paste(system("git show a55733d860f78e48753749977ce69d6a2e0d2b41:DESCRIPTION", intern = TRUE), collapse = "\n"))); current <- read.dcf("DESCRIPTION"); stopifnot(setequal(colnames(current), colnames(baseline))); protected <- setdiff(colnames(baseline), c("Title", "Description")); stopifnot(identical(current[1, protected], baseline[1, protected])); stopifnot(identical(unname(current[1, "Version"]), "0.0.0.9000"))'
```

Expected: clean tree; last three implementation messages are Tasks 1-3 in order; no closeout/canonical conflict; protected files unchanged after the authorized Task 2 DESCRIPTION title/description update. The post-Task-2 DESCRIPTION is unchanged, its DCF fields other than `Title` and `Description` equal the approved baseline, and `Version` is exactly `0.0.0.9000`. Audit baseline-to-HEAD paths against Tasks 1-3 plus this tracked plan, and inspect `git diff --word-diff=plain ... -- R` to prove roxygen-only R changes.

- [ ] **Step 2: Run the canonical harness once against the committed HEAD**

```sh
validated_head="$(git rev-parse HEAD)"
test -z "$(git status --porcelain --untracked-files=no)"
Rscript scripts/validate_wp027.R
test "$validated_head" = "$(git rev-parse HEAD)"
test -z "$(git status --porcelain --untracked-files=no)"
```

Expected: all 16 records pass in Task 3 order, exact environments are logged, hashes verify before promotion, one canonical directory is printed, and tracked HEAD/tree remain unchanged. On failure inspect retained `.WP-027_*.tmp/FAILED`, log, and gate streams; do not continue.

- [ ] **Step 3: Independently verify structure, raw logs, and hashes**

```sh
canonical="$(find outputs/canonical_runs -mindepth 1 -maxdepth 1 -type d -name 'WP-027_*' -print)"
test "$(printf '%s\n' "$canonical" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 1
test ! -e "$canonical/FAILED"
(cd "$canonical" && shasum -a 256 -c SHA256SUMS)
column -t -s $'\t' "$canonical/commands.tsv"
column -t -s $'\t' "$canonical/test-contract-counts.tsv"
column -t -s $'\t' "$canonical/test-warning-inventory.tsv"
column -t -s $'\t' "$canonical/docs/link-scan.tsv"
```

Expected: canonical structure matches Task 3; 16 ordered status-zero command rows have separate existing streams; nine migrated baselines are unchanged and suite totals do not fall; the warning inventory has exactly seven accepted offline/spatial warning rows and one established network-skip row with no additional warning/skip/failure; link columns are `source,href,target,exists` with all `TRUE`; no `FAILED`; every hash is `OK`.

Audit behavior and return-value evidence with this exact stable-function map:

| Stable function | Focused test evidence |
|---|---|
| `cfg_read` | `test_config.R`; integration in `test_settings_runner.R` |
| `run_settings` | `test_settings_runner.R` |
| `ala_fetch_occurrences` | `test_ala_fetch_occurrences.R` |
| `ala_resolve_species` | `test_ala_resolve_species.R` |
| `assemble_panel_figure` | `test_panel_figure.R` |
| `build_aoi_from_config` | `test_aoi_builder.R`; integration in `test_aoi_debug.R`, `test_overview_map.R`, `test_analysis_layers.R` |
| `build_coverage_zone` | `test_coverage_zone.R`; integration in `test_overview_map.R` |
| `build_site_attributes_long` | `test_site_attributes.R` |
| `fetch_analysis_layers` | `test_analysis_layers.R` |
| `map_species_occurrences` | `test_map_species.R` |
| `read_species_requests` | `test_species_requests.R` |
| `render_overview_map` | `test_overview_map.R` |
| `validate_output_manifest` | `test_output_manifest.R` |

For each row, cite at least one behavioral assertion and one returned value/class/shape/name/path assertion in the WP log. Add a focused test only if this audit finds a real gap; never weaken an existing assertion.

- [ ] **Step 4: Inspect named maps and layer evidence**

Inspect canonical, not live, copies: `overview_map.png`, `species_occurrences.png`, `camera_sites.png`, `camera_sites_panel.png`, `panel_figure.png`, `panel_figure.pdf`, `tasveg_wms.png`, `topography_arcgis.png`. Verify 13 fixture sites, plausible Tasmanian point/frame alignment, AOI/coverage registration, legends/graticules/scale/north arrow, panel order and PNG/PDF consistency, no clipping/blank panels, and clearly labelled offline imagery placeholders that are not claimed as live data.

- [ ] **Step 5: Inspect named tables and cross-product consistency**

Read canonical `coverage_summary.csv`, `site_attributes_long.parquet`, and `site_attributes_wide.csv`. Assert one enabled positive-area coverage row, 13 sites, 50 m buffer, `EPSG:28355`; 13 unique wide `site_id` values with plausible Tasmania coordinates; required scientific/provenance columns; unique long `(site_id, layer_id, attribute_name)` keys; matching site sets; and at least one non-missing value. Review DEM/slope/index/effort/observation magnitudes and missingness for scientific plausibility.

- [ ] **Step 6: Inspect both sites and the report**

Open canonical Quarto home, settings page, pkgdown home/reference and representative stable/experimental pages, plus `reports/paper.html`. Confirm settings-first posture, clean-vs-real workflow separation, the two correctly conditioned real-data invocation contexts, valid navigation/assets, exact five reference tiers and 17 unique exports, visible experimental guidance, populated maps/table previews/attribution/manifest, all six corrected paths, no stale framing, and zero unresolved generated relative links.

- [ ] **Step 7: Write the evidence ledger and AGENT_NOTES from observations**

Create the WP log with exactly these headings:

```markdown
# WP-027 Public API and Documentation Freeze
## Scope and posture
## API disposition
## Test migration and behavior evidence
## Canonical validation
## Documentation and behavior sanity
## Artifact inspection
## Remaining uncertainty
## Acceptance audit
```

Record baseline and validated HEAD; 13/4/13 disposition; nine pre/post rows and full counts; all 13 focused behavior/return test mappings; all 16 command/environment/results with raw relative pointers; literal canonical path; dry-run, check, link, hash, and atomic rename results; two-workflow/report sanity; every inspected artifact and observed concern; A1-A15 direct evidence. Under test evidence, record the exact accepted baseline: public API `0 warnings/0 skips/0 failures`; focused migrations `6 warnings/1 established network skip/0 failures`; full suite `7 warnings/1 established network skip/0 failures`, with the complete normalized warning text/test context and a statement that no additional warning or skip occurred. Under generated metadata, record that roxygen2 8.0.0 produced exactly one terminal blank line in each of `man/ala_configure.Rd`, `man/fetch_layer_registry.Rd`, `man/generate_topo_tile_map.Rd`, and `man/read_manifest.Rd`; a second `devtools::document()` preserved their SHA-256 hashes and full generated diff; the cached diff check contained exactly those four `new blank line at EOF.` findings; and no generated file was hand-edited. Retain three uncertainties: fixtures are demonstration evidence, offline placeholders do not test live services, and visual review is not quantitative spatial-accuracy validation.

Append a dated `2026-07-16` WP-027 closeout near the top of `docs/AGENT_NOTES.md`. Include exactly six interpretation bullets for: overview/species maps; camera/panel maps; two imagery placeholders; three tables; Quarto/pkgdown; report. Re-read, but do not rewrite, the complete Unreleased changelog.

- [ ] **Step 8: Commit tracked closeout only**

```sh
git status --short
git diff --check
(cd "$canonical" && shasum -a 256 -c SHA256SUMS)
git add -- docs/log/WP-027_2026-07-16_public-api-docs-freeze.md docs/AGENT_NOTES.md
git diff --cached --name-only
git diff --cached --check
git commit -m "agent: docs(WP-027): record validation closeout"
```

Expected: only the two tracked closeout paths are staged; canonical hashes remain `OK`; commit succeeds; worktree is clean. Do not push.

- [ ] **Step 9: Broad final review checkpoint and whole-goal completion audit**

Run a fresh independent review of baseline-to-HEAD diff, all four commits, protected files, raw canonical evidence, and the matrix below. Search added lines for incomplete markers with `rg '^\+.*\b(T[B]D|T[O]DO|F[I]XME)\b'`; expect no matches. Reverify `git diff --check`, clean `main`, baseline ancestry, one canonical directory, and all hashes.

## Completion Matrix

| ID | Approved-design acceptance row | Direct completion evidence |
|---|---|---|
| A1 | Goal 002: one implementation-ready WP-027 design | Baseline design object plus this single tracked plan; neither rewritten during Tasks 1-4 |
| A2 | Goal 002: complete API decision | 30-name disposition, exact 17 exports, exact 13 normalized ordered signatures |
| A3 | Goal 002: settings-first product posture | Source and rendered review separates clean JC from prerequisite-backed real-data settings |
| A4 | Goal 002: exact deterministic quickstart | Harness bootstrap/offline pipeline records and every required non-empty JC map/table/layer; no `species_topo.png` promise |
| A5 | Goal 002: documentation architecture | Every ownership source has its assigned role; valid `docs/_quarto.yml`; generated HTML remains evidence |
| A6 | Goal 002: report correction | Profiled report gate and visual inspection prove all six corrected `outputs/jc/` paths |
| A7 | Goal 002: compatibility boundary | Stable formals/behavior unchanged; four experimental exports retained; 13 helpers lose export only; no new runtime lifecycle warning |
| A8 | Goal 002: validation | 16 ordered command records cover the 14 design gates plus Test contracts and Evidence collection with streams/status/environment/raw warning inventory |
| A9 | WP-027: test migration | Nine `:::` files, unchanged per-file counts, no forbidden `::`, nondecreasing suite, exact 6-warning focused and 7-warning full baselines, one established network skip |
| A10 | WP-027: public API freeze | API/formals tests and pkgdown prove 17 unique exports, no internal index entries |
| A11 | WP-027: user-facing docs polish | Quarto/pkgdown/report render, zero missing relative links, manual stale-framing/path review |
| A12 | WP-027: validation harness | Pure helpers, sourceability, hardened nonzero `make test`, warning inventory, dry-run failure retention/success promotion, hash-gated rename evidence |
| A13 | WP-027: tracked closeout | WP log records exact warning/manual-generator exceptions; six-bullet AGENT_NOTES interpretation and complete Unreleased changelog |
| A14 | WP-027: canonical run | Exactly one verified promoted directory with raw logs, counts, links, JC products, docs, report; explicitly not release payload |
| A15 | WP-027/WP-028 separation | Protected runtime/release diff empty; no version, tag, push, release packaging, target/schema/output behavior change |

WP-027 is complete only when every row is supported by direct evidence. On any failed row, report the ID, raw evidence, and owning task; do not claim completion, create a second canonical run, modify promoted evidence, or begin WP-028.
