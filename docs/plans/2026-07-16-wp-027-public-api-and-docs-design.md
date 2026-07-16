# WP-027 Public API and Documentation Design

## Problem and product posture

The current 30 exports and stale, inconsistent guides expose implementation
details as peers of user workflows. WP-027 establishes a tiered, settings-first
contract without changing runtime behavior: users start with `cfg_read()` and
`run_settings()`, advanced stable functions are grouped by task, experimental
exports are separated, and sourced pipeline helpers disappear from `localmap::`.
This pre-release freeze is not a compatibility epoch or `1.0.0` contract.

## Complete API disposition

The post-WP-027 `NAMESPACE` must contain exactly 17 exports: 13 stable and four
transitional. `NAMESPACE` remains roxygen-generated; implementation changes the
owning `R/` roxygen blocks and regenerates it rather than editing it by hand.

| Function | Tier | Rationale or replacement |
|---|---|---|
| `cfg_read` | Primary stable | Canonical configuration interface; document profiles and resolved settings. |
| `run_settings` | Primary stable | Canonical settings-first end-to-end entry point used by `scripts/run_project.R`. |
| `ala_fetch_occurrences` | Advanced stable | Supported occurrence retrieval for callers needing control below settings. |
| `ala_resolve_species` | Advanced stable | Supported species-resolution step paired with occurrence retrieval. |
| `assemble_panel_figure` | Advanced stable | Supported composition of configured publication panels. |
| `build_aoi_from_config` | Advanced stable | Supported AOI construction from resolved configuration. |
| `build_coverage_zone` | Advanced stable | Supported spatial coverage construction. |
| `build_site_attributes_long` | Advanced stable | Supported in-memory long-form attribute product. |
| `fetch_analysis_layers` | Advanced stable | Supported analysis-layer acquisition interface. |
| `map_species_occurrences` | Advanced stable | Supported species occurrence map renderer. |
| `read_species_requests` | Advanced stable | Supported parser for configured species requests. |
| `render_overview_map` | Advanced stable | Supported configured overview-map renderer. |
| `validate_output_manifest` | Advanced stable | Supported validation boundary for completed output products. |
| `ala_configure` | Transitional, experimental export | Prefer `cfg_read()` or `run_settings()`; retain for current callers without a warning. |
| `fetch_layer_registry` | Transitional, experimental export | No stable direct replacement yet; keep callable while registry design settles. |
| `generate_topo_tile_map` | Transitional, experimental export | Prefer stable occurrence or overview renderers for documented workflows. |
| `read_manifest` | Transitional, experimental export | Retain manifest inspection for current callers; do not use as the onboarding path. |
| `ala_default_occurrence_fields` | Internal | Read configured occurrence fields through `cfg_read()` instead. |
| `build_layer_provenance` | Internal | Pipeline composition detail; consumers use final outputs and `validate_output_manifest()`. |
| `combine_manifest_csvs` | Internal | Pipeline aggregation detail; no direct public replacement. |
| `fetch_arcgis_imagery` | Internal | Backend detail behind configured map-layer workflows. |
| `fetch_wms_imagery` | Internal | Backend detail behind configured map-layer workflows. |
| `preview_manifest` | Internal | Use `read_manifest()` and ordinary table inspection during the transition. |
| `validate_analysis_layers` | Internal | Validation invoked through configuration and analysis-layer workflows. |
| `validate_layer_registry` | Internal | Registry implementation detail; no direct public replacement. |
| `write_attribution_report` | Internal | Pipeline writer; users consume the generated attribution product. |
| `write_coverage_summary` | Internal | Pipeline writer; users consume the generated coverage summary. |
| `write_run_manifest` | Internal | Pipeline writer; users consume and validate the final manifest. |
| `write_site_attributes_long` | Internal | Pipeline writer; use `build_site_attributes_long()` for in-memory construction. |
| `write_site_attributes_wide` | Internal | Pipeline writer; derive or consume the generated wide table. |

## Stable signature baseline

Freeze this observed pre-edit baseline, including missing arguments and default
expressions, for all 13 stable functions:

```text
cfg_read = pairlist(profile = Sys.getenv("R_CONFIG_ACTIVE", "default"), config_path = NULL)
run_settings = (settings_path missing, targets = NULL, base_profile = NULL, config_path = NULL)
ala_fetch_occurrences = (taxa missing, min_year = NULL, boundary = NULL, boundary_simplify = NULL, columns = ala_default_occurrence_fields(), min_lat = NULL, state_province = NULL, fetch_fun = NULL, config = NULL)
ala_resolve_species = (species_requests missing, search_fun = galah::search_taxa)
assemble_panel_figure = (panel_cfg missing, prerequisites = NULL)
build_aoi_from_config = (aoi_cfg missing, sites = NULL)
build_coverage_zone = (sites missing, coverage_cfg = NULL, analysis_crs = "EPSG:28355")
build_site_attributes_long = (sites missing, analysis_layers missing, aoi = NULL, analysis_crs = NULL, distance_layers = NULL)
fetch_analysis_layers = (layers missing, aoi missing, cache_dir = NULL)
map_species_occurrences = (occurrences missing, mapping_settings = NULL, aoi = NULL, output_path = NULL)
read_species_requests = (path missing)
render_overview_map = (aoi missing, sites missing, coverage = NULL, layers = NULL, map_cfg = NULL)
validate_output_manifest = (manifest missing, expected_outputs = NULL)
```

`tests/testthat/test-public-api.R` must compare ordered `formals()` after mapping
a missing default to `<missing>` and every other expression through one-line
`deparse1(..., width.cutoff = 500L)`. Compare both argument names and canonical
default text; do not evaluate defaults during the comparison.

## Documentation information architecture

Each source has one job; generated HTML is never an authoring surface.

| Exact source file | Responsibility |
|---|---|
| `README.md` | Package promise, two-step JC demonstration, real-data settings route, expected products, and contributor links. |
| `settings.example.yaml` | Real-data template; state required user inputs and never present it as clean-clone fixture input. |
| `docs/product_brief.md` | Product posture and both primary routes: clean JC demonstration and prerequisite-backed real-data settings. |
| `docs/index.qmd` | Quarto project home, correct YAML front matter, workflow overview, and links to settings, vignette, report, and reference. |
| `docs/settings.md` | Authoritative settings workflow, inputs, fields, `run_settings()` behavior, and output location. |
| `docs/DEVELOPMENT.qmd` | Contributor commands, validation order, and current product framing. |
| `docs/PIPELINE.md` | Settings/config-first DAG explanation and exact deterministic profile command. |
| `docs/workflow.md` | Authoritative run and artifact-review workflow. |
| `docs/config_reference.md` | Authoritative profile and configuration reference. |
| `docs/layers_guide.md` | Authoritative layer selection, attribution, and interpretation guide. |
| `docs/output_schema_v1.md` | Authoritative output, provenance, and attribution interpretation. |
| `vignettes/intro.Rmd` | Package-level onboarding: primary API first, then one bounded advanced example, then experimental signposting. |
| `_pkgdown.yml` | Complete reference index grouped as Primary, Advanced: configuration/spatial, Advanced: ALA, Advanced: rendering/outputs, and Experimental. |
| `quarto.yml` | Quarto website metadata, navigation, and generated destination `outputs/quarto`. |
| `reports/paper.qmd` | JC evidence report that reads current `outputs/jc/` products and target summaries. |
| `Makefile` | Supported commands; add `site` to `.PHONY` and `help` while `make site` remains a validation gate. |
| `scripts/validate_wp027.R` | Tracked base-R/system2 validation harness, evidence capture, hash verification, and atomic promotion. |
| `tests/testthat/test-public-api.R` | Exact export/tier/signature and pkgdown reference contracts. |
| `tests/testthat/test-wp027-harness.R` | Pure-helper and dry-run/fixture tests for evidence mechanics. |
| `tests/testthat/test_provenance_outputs.R` | Migrate internal provenance/writer calls from `::` to `:::` only. |
| `tests/testthat/test_combine.R` | Migrate `combine_manifest_csvs` internal access only. |
| `tests/testthat/test_imagery_arcgis.R` | Migrate `fetch_arcgis_imagery` internal access only. |
| `tests/testthat/test_imagery_wms.R` | Migrate `fetch_wms_imagery` internal access only. |
| `tests/testthat/test_network_optional.R` | Migrate its `fetch_wms_imagery` internal access only. |
| `tests/testthat/test_preview.R` | Migrate `preview_manifest` internal access only. |
| `tests/testthat/test_analysis_layers.R` | Migrate `validate_analysis_layers` internal access only. |
| `tests/testthat/test_layer_registry.R` | Migrate `validate_layer_registry` internal access only. |
| `tests/testthat/test_site_attributes.R` | Migrate internal site-attribute writer access only. |
| `docs/log/WP-027_2026-07-16_public-api-docs-freeze.md` | Tracked validation/evidence ledger and canonical run pointer. |
| `docs/AGENT_NOTES.md` | Concise closeout plus required generated-artifact interpretation. |
| `docs/CHANGELOG.md` | Unreleased API tiers, removed exports/migration posture, and user-doc/report changes. |
| `NAMESPACE` | Generated declaration of the exact 17-function export set; never hand-edited. |

Required content changes:

1. Replace species-compendium framing with configured Tasmanian site mapping.
2. Repair `docs/index.qmd` front matter and stale links; update only stale
   framing/examples in the authoritative workflow, config, layer, and output guides.
3. Align README, product brief, Quarto home, settings guide, and vignette on the
   two primary routes; keep `scripts/run_project.R` as the `run_settings()` wrapper.
4. Group every export once in pkgdown, label experimental exports, and exclude
   all internal functions from the public reference index.
5. Repair report YAML and paths without changing analysis or target behavior.

## Deterministic clean-checkout quickstart

The README and Quarto home must use this exact two-step shell contract:

```sh
make bootstrap
LOCALMAP_ALLOW_NETWORK=0 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci make pipeline
```

`make bootstrap` restores the clean checkout before `make pipeline` invokes
`targets::tar_make()`. `config/config.yaml` defines `jc_ci` inheriting `jc`,
using packaged occurrence and camera-site fixtures, disabling topographic tiles,
and marking configured WMS/ArcGIS layers offline. Network and large downloads
are disabled by default; the explicit zero-valued flags make the deterministic
guarantee visible and reviewable at the command boundary.

This `jc_ci` contract is the repository demonstration path. The primary
real-data path is `run_settings("settings.example.yaml")` only after the user
provides the template's prerequisites, including `site.csv` with `site`, `lat`,
and `lon` in the configured input directory. Document both primary workflows,
but do not give `settings.example.yaml` new fixture or clean-clone semantics.

The quickstart acceptance check must assert non-empty products at least at:

| Maps | Tables | Layers |
|---|---|---|
| `outputs/jc/maps/species_occurrences.png` | `outputs/jc/tables/coverage_summary.csv` | `outputs/jc/layers/tasveg_wms.png` |
| `outputs/jc/maps/overview_map.png` | `outputs/jc/tables/site_attributes_long.parquet` | `outputs/jc/layers/topography_arcgis.png` |
| `outputs/jc/maps/panel_figure.png` | `outputs/jc/tables/site_attributes_wide.csv` | |
| `outputs/jc/maps/panel_figure.pdf` | | |
| `outputs/jc/maps/camera_sites.png` | | |
| `outputs/jc/maps/camera_sites_panel.png` | | |

Do not promise `outputs/jc/maps/species_topo.png` in the deterministic profile;
`jc_ci` explicitly disables topographic tiles.

## Report path corrections

Apply these literal replacements in `reports/paper.qmd`:

| Stale path | Correct path |
|---|---|
| `outputs/maps/jc_overview_map.png` | `outputs/jc/maps/overview_map.png` |
| `outputs/maps/jc_panel_figure.png` | `outputs/jc/maps/panel_figure.png` |
| `outputs/tables/jc/site_attributes_long.parquet` | `outputs/jc/tables/site_attributes_long.parquet` |
| `outputs/tables/jc/site_attributes_wide.csv` | `outputs/jc/tables/site_attributes_wide.csv` |
| `outputs/provenance/attribution.md` | `outputs/jc/provenance/attribution.md` |
| `outputs/provenance/run_manifest.yml` | `outputs/jc/provenance/run_manifest.yml` |

## Generated documentation and evidence destinations

- Render Quarto sources to existing `outputs/quarto/`.
- Change pkgdown destination from `docs/pkgdown` to `outputs/pkgdown`.
- Keep `vignettes/intro.Rmd` and `reports/paper.qmd` as sources; render the report to `outputs/reports/` and copy accepted products into canonical evidence.
- Generated sites, reports, maps, tables, and logs are evidence, not source replacements. Roxygen blocks in `R/` remain the source of generated manuals and `NAMESPACE`.

## Compatibility and migration rules

1. Preserve names, formals, return contracts, and behavior of all 13 stable functions.
2. Keep four transitional exports, label them experimental, and add no warnings.
3. Remove `@export` only from 13 internal functions; do not move or delete them.
4. Add no aliases or compatibility wrappers; the package is unreleased and untagged.
5. Replace documented internal-helper calls with the table's public route.
6. Preserve target names, dependencies, output locations, and artifact contents.
7. Treat later stable export changes as explicit API decisions, not roxygen churn.

## Test migration and behavior evidence

Search all of `tests/` for each internalized name before changing exports. The
current direct-reference inventory is:

| Internal function | Existing test file(s) and migration |
|---|---|
| `ala_default_occurrence_fields` | No direct reference; no access edit. |
| `build_layer_provenance` | `tests/testthat/test_provenance_outputs.R`: change `localmap::` to `localmap:::`. |
| `combine_manifest_csvs` | `tests/testthat/test_combine.R`: change `localmap::` to `localmap:::`. |
| `fetch_arcgis_imagery` | `tests/testthat/test_imagery_arcgis.R`: change `localmap::` to `localmap:::`. |
| `fetch_wms_imagery` | `tests/testthat/test_imagery_wms.R`, `tests/testthat/test_network_optional.R`: change `localmap::` to `localmap:::`. |
| `preview_manifest` | `tests/testthat/test_preview.R`: change `localmap::` to `localmap:::`. |
| `validate_analysis_layers` | `tests/testthat/test_analysis_layers.R`: change `localmap::` to `localmap:::`. |
| `validate_layer_registry` | `tests/testthat/test_layer_registry.R`: change `localmap::` to `localmap:::`. |
| `write_attribution_report` | `tests/testthat/test_provenance_outputs.R`: change `localmap::` to `localmap:::`. |
| `write_coverage_summary` | No direct reference; no access edit. |
| `write_run_manifest` | `tests/testthat/test_provenance_outputs.R`: change `localmap::` to `localmap:::`. |
| `write_site_attributes_long` | `tests/testthat/test_site_attributes.R`: change `localmap::` to `localmap:::`. |
| `write_site_attributes_wide` | `tests/testthat/test_site_attributes.R`: change `localmap::` to `localmap:::`. |

The harness must scan every file under `tests/` against the fixed 13-name vector,
fail on any remaining `localmap::internal_name`, and allow `localmap:::` only in
the nine migration files above (or a documented established test helper).

Preserve every behavioral assertion. This lexical pre-edit baseline must be
recorded in the WP log and reproduced after migration:

| Migrated test file | `test_that` | `expect_*` |
|---|---:|---:|
| `test_provenance_outputs.R` | 2 | 13 |
| `test_combine.R` | 1 | 3 |
| `test_imagery_arcgis.R` | 3 | 6 |
| `test_imagery_wms.R` | 4 | 7 |
| `test_network_optional.R` | 1 | 1 |
| `test_preview.R` | 1 | 2 |
| `test_analysis_layers.R` | 12 | 27 |
| `test_layer_registry.R` | 3 | 4 |
| `test_site_attributes.R` | 5 | 17 |

The full pre-edit suite has 92 `test_that` blocks and 243 `expect_*` calls by
text scan. Post-edit migrated-file counts must be identical, full-suite counts
must not decrease, and the runtime suite must not lose completed behavior
evidence. New API/harness contract tests may increase counts. Any discrepancy
must be explained in the tracked WP log and blocks canonical promotion.
Encode these fixed baselines in the harness's test-inventory gate.

Map stable behavior and return-value evidence to these focused tests:

| Stable function | Existing focused test evidence |
|---|---|
| `cfg_read` | `tests/testthat/test_config.R`; integration in `test_settings_runner.R`. |
| `run_settings` | `tests/testthat/test_settings_runner.R`. |
| `ala_fetch_occurrences` | `tests/testthat/test_ala_fetch_occurrences.R`. |
| `ala_resolve_species` | `tests/testthat/test_ala_resolve_species.R`. |
| `assemble_panel_figure` | `tests/testthat/test_panel_figure.R`. |
| `build_aoi_from_config` | `tests/testthat/test_aoi_builder.R`; integration in `test_aoi_debug.R`, `test_overview_map.R`, and `test_analysis_layers.R`. |
| `build_coverage_zone` | `tests/testthat/test_coverage_zone.R`; integration in `test_overview_map.R`. |
| `build_site_attributes_long` | `tests/testthat/test_site_attributes.R`. |
| `fetch_analysis_layers` | `tests/testthat/test_analysis_layers.R`. |
| `map_species_occurrences` | `tests/testthat/test_map_species.R`. |
| `read_species_requests` | `tests/testthat/test_species_requests.R`. |
| `render_overview_map` | `tests/testthat/test_overview_map.R`. |
| `validate_output_manifest` | `tests/testthat/test_output_manifest.R`. |

Audit each mapped file for both behavior and return assertions and record the
result in the WP log. Add a focused behavioral test only when that audit finds
a real gap; existing behavioral tests remain the primary behavior evidence.

## Tests and validation

Add `tests/testthat/test-public-api.R` with these contract checks:

- `getNamespaceExports("localmap")` equals the exact sorted 17-name set above.
- Each stable export's normalized/deparsed `formals()` equals the exact baseline,
  including argument order, missingness, and unevaluated default expressions.
- Tier vectors are disjoint and complete; all 13 internal names are unexported.
- Flattened `_pkgdown.yml` reference contents equal the 17 exports with no
  duplicates; every internalized function is absent from the public index.
- Documentation examples use only exported names through `localmap::`.

Add `tests/testthat/test-wp027-harness.R` for pure helpers that canonicalize
formals, inventory test/assertion counts, assert non-empty files, extract and
resolve relative HTML links, build a sorted hash manifest, and gate promotion.
Also provide `Rscript scripts/validate_wp027.R --dry-run`: it uses temporary
fixtures and fake command results, creates no repository outputs, exercises
failure retention and successful atomic promotion, and verifies hash exclusion.

## Canonical evidence and log contract

Implement `scripts/validate_wp027.R` in base R, using `system2()` for external
commands. A single non-dry run must refuse to start if a canonical
`outputs/canonical_runs/WP-027_*` already exists, create
`outputs/canonical_runs/.WP-027_<UTC_TIMESTAMP>.tmp` before validation, and run
these ordered gates with explicit environment and no shell interpolation:

| Gate | Harness action |
|---|---|
| Bootstrap | `make bootstrap`. |
| QA bootstrap | `make bootstrap-qa`, before both lint and package check. |
| Package metadata | `Rscript -e "devtools::document()"`. |
| Tests | `make test`; enforce internal-reference and pre/post count contracts. |
| Harness fixture | `Rscript scripts/validate_wp027.R --dry-run`. |
| Lint | `make lint`. |
| JC demonstration | `LOCALMAP_ALLOW_NETWORK=0 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci make pipeline`. |
| Quarto | `make docs`. |
| pkgdown | `make site`; `site` must be in Makefile `.PHONY` and help. |
| Report | `R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci quarto render reports/paper.qmd --output-dir outputs/reports`. |
| Artifact assertions | Base R verifies every listed JC output plus rendered Quarto, pkgdown, and report files exists and is non-empty. |
| Relative links | Base R scans generated HTML `href` values, ignores external/mail/anchor links, strips query/fragment suffixes, and fails on missing relative targets. |
| Package check | `make check`. |
| Diff hygiene | `git diff --check`. |

For every gate, record UTC start/end, exact command/arguments/environment, exit
status, and separate stdout/stderr paths in `commands.tsv`; append a concise
result to `validation.log`. The runner stops at the first failure, writes a
`FAILED` marker naming the gate, prints the retained temporary evidence path,
and never creates or replaces a canonical directory.

After all gates pass, copy the accepted `outputs/jc/`, `outputs/quarto/`,
`outputs/pkgdown/`, `outputs/reports/paper.html`, link results, and test-count
inventory into the temporary directory. Finalize metadata and logs, generate a
sorted `SHA256SUMS` over every regular file except `SHA256SUMS`, verify it with
`shasum -a 256 -c SHA256SUMS`, make no later content changes, then atomically promote with
`file.rename()` to exactly one `outputs/canonical_runs/WP-027_<UTC_TIMESTAMP>`.
Cross-filesystem or pre-existing-destination rename failure retains the temp
directory and reports failure rather than copying into place.

The promoted structure is:

```text
outputs/canonical_runs/WP-027_<UTC_TIMESTAMP>/
  metadata.txt
  commands.tsv
  validation.log
  test-contract-counts.tsv
  SHA256SUMS
  steps/
  jc/
  docs/quarto/
  docs/pkgdown/
  docs/link-scan.tsv
  reports/paper.html
```

Canonical-directory existence means all hashes verified before atomic rename;
summary booleans alone are insufficient. This is validation evidence, not
release packaging or a WP-028 payload.

## Tracked closeout records

- `docs/log/WP-027_2026-07-16_public-api-docs-freeze.md`: exported names by
  tier; pre/post test counts; behavior/return audit; validation commands/results;
  canonical run pointer; docs-versus-behavior sanity; inspected artifacts; and
  remaining uncertainty.
- `docs/AGENT_NOTES.md`: concise WP-027 closeout plus 3-6 bullets interpreting
  inspected maps, tables, documentation, and anything suspicious.
- `docs/CHANGELOG.md` under Unreleased: API tiers, all 13 removed exports and
  migration posture, and user-documentation/report changes.

## Non-goals and WP-028 boundary

- No WP-028 release packaging, release checklist execution, or release claims.
- Do not promote the canonical evidence directory into a release payload.
- No feature work, target graph edits, output-schema changes, or output-path
  changes except correcting documentation that points at existing `outputs/jc/`.
- No runtime deprecation warnings or compatibility framework.
- No refactor of internal helpers, data acquisition, rendering, or settings
  semantics solely because export status changes.
- No replacement of source documents with generated HTML or canonical evidence.
- No revisiting the completed bootstrap-hygiene commit.

## Acceptance matrix

| Requirement | Required evidence |
|---|---|
| Goal 002: one implementation-ready WP-027 design | This file exists at the requested path and no other design-task mutation exists. |
| Goal 002: complete API decision | 30-row table; exact 17-name export test; exact ordered names, missingness, and deparsed defaults for 13 stable functions. |
| Goal 002: settings-first product posture | Docs distinguish the clean-clone JC demonstration from `run_settings("settings.example.yaml")` after real-data prerequisites exist. |
| Goal 002: exact deterministic quickstart | `make bootstrap`, then the two offline flags plus `R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci make pipeline`; listed paths pass the harness's Base R existence and non-empty-file assertions. |
| Goal 002: documentation architecture | Every ownership-table path, including `docs/product_brief.md`, guides, template, records, harness, tests, and Makefile, satisfies its role. |
| Goal 002: report correction | The profiled report render resolves all six corrected `outputs/jc/` paths under the accepted JC target context. |
| Goal 002: compatibility boundary | Stable signatures unchanged; four experimental exports remain; 13 helpers lose export only; no warnings. |
| Goal 002: validation | Harness records bootstrap, bootstrap-qa, document, tests, dry run, lint, offline pipeline, sites, report, artifacts, links, check, and diff gates. |
| WP-027: test migration | All nine named files use `:::` for internal access; per-file counts are unchanged, suite counts do not fall, and behavior assertions remain. |
| WP-027: public API freeze | Exact names and normalized defaults pass; pkgdown contains every export once and no internalized function. |
| WP-027: user-facing docs polish | Both sites and the report render; link scan and inspection find no stale framing, path, or unresolved relative link. |
| WP-027: validation harness | Pure-helper tests and dry-run fixtures pass; a failed gate retains temp evidence; only verified hashes permit atomic promotion. |
| WP-027: tracked closeout | WP log, AGENT_NOTES, and Unreleased CHANGELOG contain every required result, interpretation, migration note, pointer, and uncertainty. |
| WP-027: canonical run | Exactly one `WP-027_*` is atomically promoted with raw logs, verified hashes, JC outputs, docs, report, link scan, and counts; it is not a release payload. |
| WP-027/WP-028 separation | Diff contains no version, release, runtime behavior, target graph, or release-packaging changes. |

WP-027 is complete only when every row has direct evidence and the diff is
limited to API metadata, migrated/contract tests, the validation harness,
tracked records, documentation sources, and required generated package metadata.
