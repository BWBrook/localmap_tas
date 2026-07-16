# WP-027 Public API and Documentation Freeze

## Scope and posture

WP-027 implements the approved design at
`docs/plans/2026-07-16-wp-027-public-api-and-docs-design.md` from baseline
`a55733d860f78e48753749977ce69d6a2e0d2b41`, under the tracked execution
contract in
`docs/superpowers/plans/2026-07-16-wp-027-public-api-and-docs.md`. The final
validated HEAD is `cc363426bebcf4275dba8275f11a45c5ceefcef5`.

The product posture has two workflows: the deterministic, offline,
fixture-backed `jc_ci` demonstration and the prerequisite-backed real-data
settings workflow. Checkout and installed-package entrypoints are two
invocation contexts for the same real-data workflow, not additional workflows.
WP-027 freezes API and documentation behavior while including bounded
validation hygiene approved by the plan's `Final-review adjudication
(2026-07-16)`: byte-idempotent/CWD-stable bootstrap corrections (`eba2cfa`,
`db214eb`) and development-only source-package/test partitioning for truthful
`make check`. These changes do not alter targets, schemas, product runtime
behavior, output contracts, version metadata, or release state.

The final canonical root is
`outputs/canonical_runs/WP-027_20260716T140421Z`. All evidence paths below are
repository-relative. Its `metadata.txt` records `status=PASS`,
`validated_head=cc363426bebcf4275dba8275f11a45c5ceefcef5`,
`canonical_evidence=true`, and `release_payload=false`.

## API disposition

The public namespace contains exactly 17 unique exports:

- Stable (13): `cfg_read`, `run_settings`, `ala_fetch_occurrences`,
  `ala_resolve_species`, `assemble_panel_figure`, `build_aoi_from_config`,
  `build_coverage_zone`, `build_site_attributes_long`,
  `fetch_analysis_layers`, `map_species_occurrences`,
  `read_species_requests`, `render_overview_map`, and
  `validate_output_manifest`.
- Experimental (4): `ala_configure`, `fetch_layer_registry`,
  `generate_topo_tile_map`, and `read_manifest`. These remain callable without
  runtime lifecycle warnings.
- Internalized (13): `ala_default_occurrence_fields`,
  `build_layer_provenance`, `combine_manifest_csvs`, `fetch_arcgis_imagery`,
  `fetch_wms_imagery`, `preview_manifest`, `validate_analysis_layers`,
  `validate_layer_registry`, `write_attribution_report`,
  `write_coverage_summary`, `write_run_manifest`,
  `write_site_attributes_long`, and `write_site_attributes_wide`.

`tests/testthat/test-public-api.R` proves the 17-name namespace and all 13
ordered stable signatures; `tests/testthat/test-public-api-checkout.R` proves
the five pkgdown tiers, no duplicate or internal index entries, public-only
documentation calls, and repository output contracts. Canonical raw execution
is in `outputs/canonical_runs/WP-027_20260716T140421Z/steps/04-tests.stdout.log`;
the static ledger records public API rows in
`outputs/canonical_runs/WP-027_20260716T140421Z/test-contract-counts.tsv`.

Roxygen2 8.0.0 generated exactly one terminal blank line in each transitional
manual: `man/ala_configure.Rd`, `man/fetch_layer_registry.Rd`,
`man/generate_topo_tile_map.Rd`, and `man/read_manifest.Rd`. The stable
second-document SHA-256 values are:

| Manual | SHA-256 |
|---|---|
| `man/ala_configure.Rd` | `77182169d888b6d420beb733b6f9e6cefe7b21754bee0beb7e8b5445c5884a22` |
| `man/fetch_layer_registry.Rd` | `a71dcc65e62760815ee56dbf4f6285d016e0cb178f8871e7c4ceb68a5293c4d9` |
| `man/generate_topo_tile_map.Rd` | `ba37508f43ffd0476e41aba885a9da14e200278a2510f6c32e403741bdf1098d` |
| `man/read_manifest.Rd` | `4259b6166880778b1392b8354fcada44acc3cf7f4aa1de00e1a8fde5f88922af` |

The second `devtools::document()` preserved all four hashes and the full
`NAMESPACE`/manual generated diff byte-for-byte. The staged diff check contained
exactly four `new blank line at EOF.` findings, one for each manual, and no
other finding. No generated metadata was hand-edited; these files and
`NAMESPACE` remain unchanged from `fcb317abcc8966156cc194c4673b5ac0c7b67bbe`.

## Test migration and behavior evidence

The nine internal-access migration rows remain unchanged and total exactly 32
test blocks and 80 expectation calls:

| Test file | Blocks | Expectations | Internal substitutions |
|---|---:|---:|---|
| `tests/testthat/test_provenance_outputs.R` | 2 | 13 | `build_layer_provenance` (1), `write_attribution_report` (1), `write_run_manifest` (1) |
| `tests/testthat/test_combine.R` | 1 | 3 | `combine_manifest_csvs` (1) |
| `tests/testthat/test_imagery_arcgis.R` | 3 | 6 | `fetch_arcgis_imagery` (2) |
| `tests/testthat/test_imagery_wms.R` | 4 | 7 | `fetch_wms_imagery` (2) |
| `tests/testthat/test_network_optional.R` | 1 | 1 | `fetch_wms_imagery` (1) |
| `tests/testthat/test_preview.R` | 1 | 2 | `preview_manifest` (1) |
| `tests/testthat/test_analysis_layers.R` | 12 | 27 | `validate_analysis_layers` (1) |
| `tests/testthat/test_layer_registry.R` | 3 | 4 | `validate_layer_registry` (3) |
| `tests/testthat/test_site_attributes.R` | 5 | 17 | `write_site_attributes_long` (1), `write_site_attributes_wide` (2) |

The current canonical suite is 122 test blocks and 403 static expectation
calls, all accepted in `test-contract-counts.tsv`. The internal-reference scan
found exactly 17 `localmap:::` uses across those nine files, no forbidden
`localmap::` access to internal names, and the expected per-file counts.

The exact stable behavior and return-value audit is:

| Stable function | Behavioral assertion | Return assertion and focused evidence |
|---|---|---|
| `cfg_read` | Validates required/schema fields and migrates schema v1 to v2. | Returns a list with non-null `data_dir` and `schema_version == 2`; `tests/testthat/test_config.R`, integrated in `test_settings_runner.R`. |
| `run_settings` | Applies a settings overlay to the requested `cfg` target and restores `LOCALMAP_CONFIG_PATH` and `R_CONFIG_ACTIVE`. | Returns an existing generated YAML path whose output directory and central site match settings; `tests/testthat/test_settings_runner.R`. |
| `ala_fetch_occurrences` | Iterates resolved taxa, applies latitude filtering, and skips unresolved taxa. | Returns one correctly identified row after filtering, or zero rows for unresolved taxa; `tests/testthat/test_ala_fetch_occurrences.R`. |
| `ala_resolve_species` | Prefers exact scientific-name matches and warns when no match exists. | Returns matched scientific name plus `match_type`, including `not_found` with `NA`; `tests/testthat/test_ala_resolve_species.R`. |
| `assemble_panel_figure` | Builds PNG/PDF panels and normalizes differently sized inputs. | Returns existing `png` and `pdf` paths; normalized PNG dimensions are asserted; `tests/testthat/test_panel_figure.R`. |
| `build_aoi_from_config` | Honors centroid, named site, rotation, auto sizing, and missing-site errors. | Returns an `aoi$aoi` `sfc` with expected centroid and dimensions; `tests/testthat/test_aoi_builder.R`, with integration in `test_aoi_debug.R`, `test_overview_map.R`, and `test_analysis_layers.R`. |
| `build_coverage_zone` | Computes hull/buffer growth and handles disabled or undersized inputs. | Returns enabled state, `sf` polygon or `NULL`, positive area, and exact site count; `tests/testthat/test_coverage_zone.R`, integrated in `test_overview_map.R`. |
| `build_site_attributes_long` | Extracts raster bands and represents vector no-hits as `NA`. | Returns sites-by-band rows with named attributes and stable long/wide products; `tests/testthat/test_site_attributes.R`. |
| `fetch_analysis_layers` | Clips vectors, uses offline fixtures, computes derivatives, and reuses deterministic cache keys. | Returns existing layer/provenance paths and identical cache paths; raster cells and NDVI range are asserted; `tests/testthat/test_analysis_layers.R`. |
| `map_species_occurrences` | Accepts configured bounds or AOI and continues with a warning when ancillary points are absent. | Returns the exact existing PNG output path; `tests/testthat/test_map_species.R`. |
| `read_species_requests` | Validates schema and requires a common or scientific query. | Returns a `tbl_df` with exactly `species_id`, `common_name`, and `scientific_name`; `tests/testthat/test_species_requests.R`. |
| `render_overview_map` | Renders AOI, sites, and optional coverage using AOI aspect ratio. | Returns an existing PNG whose pixel ratio matches the AOI; `tests/testthat/test_overview_map.R`. |
| `validate_output_manifest` | Rejects missing fields, IDs, and declared files, then accepts matching expected outputs. | Returns a `tbl_df` with the expected ordered output IDs; `tests/testthat/test_output_manifest.R`. |

Accepted test-result baselines are:

- Public API: 0 warnings, 0 skips, 0 failures.
- Focused migrations: 6 warnings, 1 established network skip, 0 failures.
- Full suite: 7 warnings, 1 established network skip, 0 failures.

The canonical normalized warning inventory is complete:

| Context | Normalized text | Focused/full |
|---|---|---|
| `arcgis vector fetch is gated without network or fixture ('test_analysis_layers.R:289:3')` | `Network access disabled; ArcGIS vector layer 'arcgis_vec' requires a fixture or LOCALMAP_ALLOW_NETWORK=1.` | both |
| `arcgis raster fetch falls back to fixture when offline ('test_analysis_layers.R:323:3')` | `Network access disabled; ArcGIS raster layer 'arcgis_raster' requires a fixture or LOCALMAP_ALLOW_NETWORK=1.` | both |
| `arcgis raster fetch errors when offline without fixture ('test_analysis_layers.R:354:3')` | `Network access disabled; ArcGIS raster layer 'arcgis_raster' requires a fixture or LOCALMAP_ALLOW_NETWORK=1.` | both |
| `arcgis vector fixtures are clipped in AOI CRS ('test_analysis_layers.R:382:3')` | `attribute variables are assumed to be spatially constant throughout all geometries` | both |
| `fetch_arcgis_imagery respects network gating ('test_imagery_arcgis.R:75:3')` | `Network access disabled; using offline placeholder for ArcGIS imagery.` | both |
| `fetch_wms_imagery respects network gating ('test_imagery_wms.R:80:3')` | `Network access disabled; using offline placeholder for WMS imagery.` | both |
| `camera_sites_stack_maps stacks PNGs vertically ('test-camera-sites-map.R:156:3')` | `Panel images differ in size; bounding boxes may not match. Consider normalize_sizes = TRUE.` | full only |

The one accepted skip in focused and full runs is
`network imagery fetch is gated behind LOCALMAP_ALLOW_NETWORK
('test_network_optional.R:3:5')`, with reason `Network fetch disabled (set
LOCALMAP_ALLOW_NETWORK=1 to enable).` No additional warning, skip, or failure
occurred. Raw normalized evidence is
`outputs/canonical_runs/WP-027_20260716T140421Z/test-warning-inventory.tsv`;
raw test output is under `steps/04-tests.*.log`.

## Canonical validation

The canonical command was `Rscript scripts/validate_wp027.R`. It ran from
`2026-07-16T14:04:21Z` to `2026-07-16T14:09:07Z` and atomically promoted only
after tracked-state revalidation, final hashing, and external hash
verification. `commands.tsv` and `validation.log` are the authoritative command
and status ledgers. Every row below has status 0 and `PASS`:

| # | Gate | Recorded command / arguments | Environment | Raw streams |
|---:|---|---|---|---|
| 1 | Bootstrap | `make bootstrap` | `[]` | `steps/01-bootstrap.stdout.log`, `steps/01-bootstrap.stderr.log` |
| 2 | QA bootstrap | `make bootstrap-qa` | `[]` | `steps/02-qa-bootstrap.stdout.log`, `steps/02-qa-bootstrap.stderr.log` |
| 3 | Package metadata | `Rscript -e devtools::document()` | `[]` | `steps/03-package-metadata.stdout.log`, `steps/03-package-metadata.stderr.log` |
| 4 | Tests | `make test` | `[]` | `steps/04-tests.stdout.log`, `steps/04-tests.stderr.log` |
| 5 | Test contracts | `<internal> test-and-warning-contracts` | `[]` | `steps/05-test-contracts.stdout.log`, `steps/05-test-contracts.stderr.log` |
| 6 | Harness fixture | `Rscript scripts/validate_wp027.R --dry-run` | `[]` | `steps/06-harness-fixture.stdout.log`, `steps/06-harness-fixture.stderr.log` |
| 7 | Lint | `make lint` | `[]` | `steps/07-lint.stdout.log`, `steps/07-lint.stderr.log` |
| 8 | JC demonstration | `make pipeline` | `LOCALMAP_ALLOW_NETWORK=0`; `LOCALMAP_ALLOW_LARGE_DOWNLOADS=0`; `R_CONFIG_ACTIVE=jc_ci`; `TARGETS_PROFILE=ci` | `steps/08-jc-demonstration.stdout.log`, `steps/08-jc-demonstration.stderr.log` |
| 9 | Quarto | `make docs` | `[]` | `steps/09-quarto.stdout.log`, `steps/09-quarto.stderr.log` |
| 10 | pkgdown | `make site` | `[]` | `steps/10-pkgdown.stdout.log`, `steps/10-pkgdown.stderr.log` |
| 11 | Report | `quarto render reports/paper.qmd --output-dir outputs/reports` | `R_CONFIG_ACTIVE=jc_ci`; `TARGETS_PROFILE=ci` | `steps/11-report.stdout.log`, `steps/11-report.stderr.log` |
| 12 | Artifact assertions | `<internal> assert-required-products` | `[]` | `steps/12-artifact-assertions.stdout.log`, `steps/12-artifact-assertions.stderr.log` |
| 13 | Relative links | `<internal> scan-generated-relative-links` | `[]` | `steps/13-relative-links.stdout.log`, `steps/13-relative-links.stderr.log` |
| 14 | Package check | `make check` | `[]` | `steps/14-package-check.stdout.log`, `steps/14-package-check.stderr.log` |
| 15 | Diff hygiene | `git diff --check` | `[]` | `steps/15-diff-hygiene.stdout.log`, `steps/15-diff-hygiene.stderr.log` |
| 16 | Evidence collection | `<internal> collect-accepted-evidence` | `[]` | `steps/16-evidence-collection.stdout.log`, `steps/16-evidence-collection.stderr.log` |

All stream paths in this table are relative to the canonical root. The dry-run
stream contains exact success and used fake execution. Package check reports
`Status: OK`, 0 errors, 0 warnings, and 0 notes. Artifact assertions verified
31 required non-empty products. `docs/link-scan.tsv` contains 395 generated
links: 272 pkgdown and 123 Quarto, with 0 missing. `SHA256SUMS` contains 207
entries; independent `shasum -a 256 -c SHA256SUMS` returned 207/207 `OK`.

Two earlier attempts are retained honestly and separately:

- `outputs/canonical_runs/.WP-027_20260716T133524Z.tmp` stopped at Lint and
  led to mechanical repair `e0c1282`; its `FAILED`, `metadata.txt`, and
  `steps/07-lint.stdout.log` retain the raw failure. It never promoted.
- `outputs/canonical_runs/.WP-027_20260716T134344Z.tmp` stopped at Package
  check and led to checkout/package separation repair `cc36342`; its `FAILED`,
  `metadata.txt`, and `steps/14-package-check.stdout.log` retain the raw
  failure. It never promoted.

The failed inventories remained byte-identical through the final attempt
(20/20 and 35/35 files). Exactly one promoted `WP-027_*` directory exists, it
has no `FAILED` marker, and the two failed temps remain separate.

## Documentation and behavior sanity

Browser review of canonical Quarto, pkgdown, and report copies passed. Quarto
maintains settings-first framing and distinguishes the offline demonstration
from prerequisite-backed real data. The checkout wrapper and installed API are
conditioned as invocation contexts, not separate workflows. The accepted
non-fatal Quarto external-output warning is retained in
`steps/09-quarto.stderr.log`; `outputs/quarto` is the binding destination.

Pkgdown presents exactly five reference tiers and 17 unique public exports,
with no internal reference pages. Representative canonical evidence is
`docs/pkgdown/index.html`, `docs/pkgdown/reference/index.html`, stable page
`docs/pkgdown/reference/cfg_read.html`, and experimental page
`docs/pkgdown/reference/read_manifest.html`, all under the canonical root.

The standalone report `reports/paper.html` contains two embedded maps, two
table previews, attribution, and run-manifest content. All six corrected
`outputs/jc/` source paths resolve. Quarto, pkgdown, and report navigation had
zero missing relative links; the report is self-contained and contributes no
relative-link ledger rows.

## Artifact inspection

Canonical map and table observations are tied to
`outputs/canonical_runs/WP-027_20260716T140421Z/jc/`:

- The maps contain 13 internally aligned fixture sites. `maps/overview_map.png`
  and `maps/species_occurrences.png` pass the visual sanity review for
  Tasmanian frame, point placement, AOI/coverage registration, and cartographic
  elements.
- `maps/camera_sites.png`, `maps/camera_sites_panel.png`,
  `maps/panel_figure.png`, and `maps/panel_figure.pdf` preserve site alignment.
  Transparency can appear black in some viewers, right-side annotations can be
  clipped, and the panel topography fallback duplicates the occurrence map;
  these are bounded presentation caveats rather than evidence-integrity
  failures.
- `layers/tasveg_wms.png` and `layers/topography_arcgis.png` are uniform
  offline fixture placeholders without an in-image label. Their adjacent YAML
  sidecars and documentation explicitly record `offline_placeholder`. They are
  accepted as non-live fixture evidence, not as release imagery.
- `tables/coverage_summary.csv` has one enabled positive row:
  `0.4353884464` km2, 50 m buffer, `EPSG:28355`, and 13 sites.
  `tables/site_attributes_long.parquet` has 234 rows, 156 non-missing values,
  and unique `(site_id, layer_id, attribute_name)` keys.
  `tables/site_attributes_wide.csv` has 13 rows and 182 of 273 scientific cells
  non-missing. Site sets agree and DEM, slope, index, effort, observation, and
  coordinate ranges are plausible.
- Non-blocking table limitations are all-null placeholder variables, 26 null
  row-level provenance paths, and a TASVEG category fixture-schema gap. These
  are explicit fixture/data-provenance limitations, not contradictions in the
  populated values or keys.

The artifact gate's 31 required products comprise 11 JC files, 19 documentation
pages, and the report. All are non-empty in `SHA256SUMS`; the eight reviewed map
files, three tables, representative site pages, and report also passed direct
non-empty inspection.

## Remaining uncertainty

- The packaged fixtures are deterministic demonstration evidence, not
  authoritative current extracts from each upstream provider.
- Offline placeholders prove gating and provenance behavior but do not test
  live WMS, ArcGIS, ALA, or large-download services.
- Visual review establishes internal coherence but is not quantitative
  spatial-accuracy validation against independent control data.
- Browser review used desktop Chromium. Additional mobile, accessibility, and
  cross-browser review is optional extra evidence, not a WP-027 blocker.

## Acceptance audit

**Final-review adjudication (2026-07-16).** The auditor's dissent and the
orchestrator's bounded disposition are retained rather than folded into a
generic pass claim:

| Auditor finding | Bounded orchestrator adjudication |
|---|---|
| Strict visual Step 4 wording was not literally met by uniform offline placeholders, minor edge-annotation clipping, viewer-dependent transparency, and a duplicated occurrence fallback. | Accepted proportionately under the tracked plan amendment: primary fixture maps are nonblank/aligned; placeholder status is explicit in sidecars/docs; these caveats are waived for deterministic validation evidence with `release_payload=false`, not release imagery. No coverage registration is claimed for blank layers. |
| `.Rbuildignore` exclusions and checkout/package test partitioning could be read as WP-028 packaging work. | Accepted as WP-027 validation hygiene required for truthful mandatory `make check`: package-safe API tests remain included, checkout-only contracts still run under `make test`, and no release payload/checklist/version/tag/push occurred. |
| The bootstrap no-revisit wording appeared to conflict with the two hygiene corrections. | The prohibition applies to opportunistic redesign. User-authorized commits `eba2cfa` and `db214eb` narrowly provide byte-idempotent restore and CWD-stable sandbox paths without target, schema, or product-runtime change. |

| ID | Status | Direct evidence |
|---|---|---|
| A1 | Accepted | Approved design `docs/plans/2026-07-16-wp-027-public-api-and-docs-design.md` plus the single tracked execution plan; neither was rewritten during implementation. |
| A2 | Accepted | `NAMESPACE`, `tests/testthat/test-public-api.R`, and canonical test streams prove the complete 30-name disposition, 17 exports, and 13 exact ordered signatures. |
| A3 | Accepted | Source and canonical Quarto/pkgdown/report review separates `jc_ci` demonstration from prerequisite-backed settings while treating checkout/API as invocation contexts. |
| A4 | Accepted | `commands.tsv` gate 8 and `steps/08-jc-demonstration.*.log` record the exact offline environment; artifact gate verifies required JC products without promising `species_topo.png`. |
| A5 | Accepted | `docs/_quarto.yml` remains the source contract; canonical `docs/quarto/` and `docs/pkgdown/` are generated evidence with assigned roles and no missing links. |
| A6 | Accepted | `steps/11-report.*.log` and canonical `reports/paper.html` prove profiled render, two maps, two tables, attribution, manifest, and all six corrected paths. |
| A7 | Accepted | Public API/formals tests, roxygen-only commit `fcb317a`, four retained experimental exports, 13 internal names, and absence of lifecycle warnings preserve the compatibility boundary. |
| A8 | Accepted | `commands.tsv` and `validation.log` contain all 16 ordered status-zero gates, exact environments, and separate streams. |
| A9 | Accepted | `test-contract-counts.tsv` preserves the nine 32/80 rows and 122/403 suite; `test-warning-inventory.tsv` proves exact 6/7 warning baselines, one established skip, and no extras. |
| A10 | Accepted | Namespace/API tests and 17 canonical pkgdown reference pages prove unique public exports and no internal index entries. |
| A11 | Accepted | Canonical Quarto/pkgdown/report inspection plus `docs/link-scan.tsv` proves 395 links and 0 missing, with stale framing and corrected paths reviewed. |
| A12 | Accepted | `scripts/validate_wp027.R`, `tests/testthat/test-wp027-harness.R`, dry-run stream, retained failures, final `SHA256SUMS`, and rename-only promotion prove harness safety. |
| A13 | Accepted | This ledger, the exactly six interpretation bullets in `docs/AGENT_NOTES.md`, and the complete reread of `docs/CHANGELOG.md` Unreleased close the tracked record. |
| A14 | Accepted | `metadata.txt`, 16 gate records, 31 products, 395-link ledger, and 207/207 independent hashes support the single promoted canonical directory. Under the plan's final-review amendment, bounded visual caveats are accepted as deterministic evidence; blank placeholder layers carry no coverage-registration claim, and the result is explicitly not release imagery or a release payload. |
| A15 | Accepted | Validated HEAD remains clean at Version `0.0.0.9000`; metadata says `release_payload=false`. The `.Rbuildignore`/test partition and approved bootstrap commits `eba2cfa`/`db214eb` are development validation hygiene, not release packaging or product-runtime redesign; no checklist, version, tag, push, payload, publication, or WP-028 work occurred. |
