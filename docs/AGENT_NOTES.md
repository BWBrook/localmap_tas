# AGENT NOTES

- 2026-03-08: Diagnosed GitHub Actions bootstrap failure on `main`.
  - Investigated failing Actions run `22795216013` for commit `07e85cf`; the `ci` workflow failed in `Bootstrap QA environment` before lint/tests/checks ran.
  - Pulled the job log via `gh api` and confirmed `renv::restore()` was entering a `pak` subprocess despite the workflow exporting `RENV_CONFIG_PAK_ENABLED=FALSE`.
  - Root cause was `.Rprofile` unconditionally forcing `RENV_CONFIG_PAK_ENABLED=TRUE`, overriding CI/container startup intent.
  - Updated `.Rprofile` to respect an existing `RENV_CONFIG_PAK_ENABLED` value while preserving the repo default (`TRUE`) for ordinary interactive sessions.
  - Verification:
    - clean startup probe with `Rscript --vanilla` now reports `pak env: FALSE` and `pak config: FALSE` when `RENV_CONFIG_PAK_ENABLED=FALSE` is supplied,
    - `make lint` passed,
    - `make test` passed with the same expected offline/spatial warnings and 1 expected skip.
  - Follow-up after push: run `22814104696` showed the `pak` override was fixed, but `Bootstrap QA environment` then failed while loading `units` because `libudunits2.so.0` was unavailable on the runner.
  - Narrow workflow fix applied: added `libudunits2-dev` to the CI apt packages, validated the workflow with `actionlint 1.7.11`, and left broader system-package expansion deferred unless CI exposes another concrete missing library.

- 2026-03-07: Whole-repo QA repairs + characterization tests + conservative internal refactors.
  - Repaired the documented quality gates so runtime bootstrap, QA bootstrap, lint, tests, demo pipeline, and `R CMD check` now agree on the same repo entrypoints; reactivated GitHub Actions CI under `.github/workflows/ci.yaml`.
  - Added contract tests for demo output manifests, provenance sidecars, output-path resolution, site-attribute wide-table mapping, `_targets.R` helper behavior, overview-map aspect ratio, and `run_settings()` environment restoration.
  - Thinned `_targets.R` and config loading by extracting internal helpers for profile-aware output schemas, TASVEG lookup/legend handling, report rendering fallback, and config load/resolve phases while preserving target names, output paths, and schema semantics.
  - Split large internal modules into narrower files without changing public entrypoints: analysis-layer remote/validation helpers now live outside `R/analysis_layers.R`, and camera-site defaults, graticules, and panel assembly now live outside `R/camera_sites_map.R`.
  - Verification (2026-03-07): `make bootstrap`, `make bootstrap-qa`, `make lint`, `make test`, `R_CONFIG_ACTIVE=demo TARGETS_PROFILE=ci Rscript -e 'targets::tar_make()'`, and `make check` all completed successfully (`0 errors | 0 warnings | 0 notes` for package check).
  - Artefact review (demo outputs, 2026-03-07):
    - `outputs/demo/maps/camera_sites.png` still shows the expected coastal camera cluster with plausible point scaling; dark basemap styling and graticule placement remain coherent after the refactor.
    - `outputs/demo/maps/panel_figure.png` still assembles as a 2x2 figure with the expected map mix and stable aspect ratios; no new panel spacing or legend regressions were evident.
    - `outputs/demo/maps/overview_map.png` remains intentionally sparse in the demo profile, with the AOI border and scale bar preserved; this is still a presentation limitation of the demo fixtures rather than a regression from the refactor.
    - Demo provenance remained coherent; `run_manifest.yml` records the demo profile, schema hash, and imagery provenance keys expected by the characterization tests.
  - Remaining deferred work: structured provenance/output-schema redesigns and any schema/API/numerical changes still require explicit PI approval before implementation.

- 2025-09-19: Extended camera site panel stacking.
  - Enhanced `camera_sites_stack_maps()` to deduplicate glob/directories, accept
    explicit grid sizing via `columns`/`rows`, honour regex-based `order`, and
    render configurable bottom-right labels (`a)`, `b)`, `c)`, …).
  - Configuration now accepts `input_dir`, regex `pattern`, ordering, and label
    settings; README/PIPELINE/CHANGELOG updated accordingly with overlay examples.
  - Tests expanded for duplicate handling, layout overrides, ordering, and label
    rendering.

- 2025-09-18: Hardened camera site basemap fetch against WMS scale limits.
  - Auto-clamp camera map half-width to comply with LIST TASVEG visibility scaling, added graticule styling controls, WMS overlay support (e.g., roads/towns), and a configurable legend inset.
  - Added `max_scale` config knob (default 1:100k) and scale diagnostics in `fetch_camera_wms_tile()`; default DPI now 96 to keep 40 km windows renderable.

- 2025-09-18: Added camera site mapping workflow for wildlife camera deployments.
  - Introduced `camera_sites_default()` helpers, camera site readers, context
    preparation, WMS tile fetching with placeholder handling, and map rendering
    with scale bar/north arrow.
  - Added config block (`data$camera_sites`) plus new targets to `_targets.R` for
    CSV tracking, WMS tile acquisition, and map generation.
  - Created tests covering the camera site helpers and updated docs/changelog
    to describe the new pipeline branch.

- 2025-09-17: Added mapping workflow for occurrence records.
  - Introduced `map_species_occurrences()` helper with bounding box logic and
    new dependencies (`ggplot2`, `geosphere`, `rnaturalearth`, `rnaturalearthdata`).
  - Extended configuration (`data$occurrence$map`) with Tasmania-focused bounding
    box defaults and wired `species_map` target into `_targets.R`.
  - Documented the new target and config in README and pipeline notes; added
    tests covering map generation.
  - Added optional Google terrain/satellite basemaps via `{ggmap}` with a plain
    fallback, configurable point styling (colour/size/species legend), Natural
    Earth land shading as the default, support for OpenStreetMap/Stamen tiles,
    and removal of the on-plot bounding box.
  - Added `src/basemap_debug.R` to run manual basemap diagnostics outside the
    `{targets}` pipeline (saves previews + summary under
    `outputs/scratch/basemap_debug/`).

- 2025-09-17: Restored mapping workflow for occurrence records after rollback.
  - Reintroduced `map_species_occurrences()` helper, `species_map` target, and
    supporting configuration/docs/tests aligned with the original approach.
  - Tweaked defaults to remove the bounding box outline, hide title/legend via
    config flags, and render smaller green points by default. Added optional
    CSV-driven ancillary points (defaulting to red) layered on the map, plus a
    new `topo_tile_map` target using slippy tiles (OpenTopoMap by default).

- 2025-09-16: Rebranded template to the localmap species occurrence project.
  - Renamed package metadata, Quarto, and pkgdown references to `localmap`.
  - Updated README, docs, and vignette language for species mapping context.
  - Renamed the RStudio project file to `localmap.Rproj` and refreshed ignores/changelog.
  - Added ALA workflow helpers (`read_species_requests()`, `ala_resolve_species()`,
    `ala_fetch_occurrences()`) plus supporting tests/config/docs; introduced
    `metadata/species_requests.csv` sample input.
  - Extended occurrence configuration with minimum latitude filtering and
    hardened galah downloads to handle varying return types.
  - Added state province filtering and enforced galah `download_reason_id`
    configuration (defaulting to scientific research).
  - **Important:** galah 2.x only accepts literal pipelines for filters. The
    downloader builds a single string (`galah_call() |> ...`) and evaluates it.
    Do not replace this with tidy-eval/quosure logic unless galah relaxes that
    restriction.
  - Added `scripts/ala_scratch.R` to debug galah calls outside the pipeline.
- 2025-09-12: Genericized template per AGENTS.md.
  - Rename package to `rcompendium`; update README and Quarto title.
  - Add `cfg_read()` and `read_manifest()` helpers; create tests.
  - Update `_targets.R` with `input_files`, `data_preview`, `manifest_summary`; fix report target.
  - Add sample data and update manifest.
  - Add `.Rproj`, `.Rbuildignore`, CI workflow, and docs scaffolding.
  - Clean `.gitignore`; fix profiles to use local SLURM template.
  - Add vignette placeholder, docs index, and Makefile.
  - Add `_pkgdown.yml` and `combined_data` target with reader helper.

- 2025-12-17: Hygiene + reproducibility gates; add offline-safe demo profile.
  - Fixed MIT license metadata (MIT stub `LICENSE` + full `LICENSE.md`) and removed placeholder repository URL from `CITATION.cff` (now a TODO recorded in `docs/decisions.md`).
  - Repaired `.Rbuildignore` (removed literal `\\n` artefacts) and added ignore rules to avoid packaging `CITATION.cff` files outside `inst/`.
  - Added CI scaffolding under `.github/workflows/ci.yaml` running lint + R CMD check (no secrets).
  - Regenerated roxygen docs (`devtools::document()`): updated `NAMESPACE` and `man/` files, and fixed roxygen mismatches for camera-site helpers and ALA functions.
  - Hardened config/metadata resolution so installed packages can find `inst/config/config.yaml` and `inst/metadata/*.csv`.
  - Added `demo` config profile that runs end-to-end offline via small fixtures in `inst/extdata/` and ALA fixture helpers (`R/ala_fixture.R`).
  - Verification gates (local, 2025-12-17):
    - `renv::restore()` + `renv::status()` OK (consistent state).
    - `lintr::lint_package()` OK (0 lints).
    - `devtools::test()` OK (80 passing).
    - `rcmdcheck::rcmdcheck(args = \"--no-manual\")` OK with 2 NOTEs (import usage + `import::from` checks).
    - Demo pipeline: `R_CONFIG_ACTIVE=demo TARGETS_PROFILE=ci targets::tar_make()` completed; outputs inspected:
      - `outputs/demo/maps/species_occurrences.png` shows Tasmania outline with fixture points within the configured bounding box.
      - `outputs/demo/maps/camera_sites.png` shows camera sites on placeholder basemap; extent and symbol scaling appear coherent.
      - `outputs/demo/maps/camera_sites_panel.png` renders as expected for a 1×1 panel.
    - Remaining: demo camera basemap intentionally uses a placeholder tile (warnings expected when provider URL is empty).

- 2025-12-17: Refactor away from `{import}`/`import::from()` toward explicit `pkg::fun()` usage.
  - Removed all `import::from()` blocks and function-local import environments; use explicit namespace qualifiers throughout `R/`.
  - Dropped `{import}` from `DESCRIPTION` and updated `_targets.R` comments + `docs/DEVELOPMENT.qmd` to reflect the new convention.
  - Added a minimal roxygen import for `rlang::.data` (`R/imports.R`) so tidy-eval pronouns work correctly without triggering `R CMD check` notes.
  - Dependency tidy-up: pruned unused `Imports:` (moved pipeline-only deps such as `{targets}`/`{tarchetypes}` to `Suggests:`), re-snapshotted `renv.lock`.
  - Verification gates (local, 2025-12-17):
    - `devtools::document()` OK.
    - `lintr::lint_package()` OK (0 lints).
    - `devtools::test()` OK (80 passing).
    - `rcmdcheck::rcmdcheck(args = \"--no-manual\")` OK (0 errors, 0 warnings, 0 notes).
    - Demo pipeline: `R_CONFIG_ACTIVE=demo TARGETS_PROFILE=ci targets::tar_make()` completed with expected warning (placeholder WMS tile when URL is empty).
  - Artefact review (demo outputs, 2025-12-17):
    - `outputs/demo/maps/species_occurrences.png`: Tasmania outline and occurrence points appear spatially plausible (points clustered in NW TAS; graticule labels plausible).
    - `outputs/demo/maps/camera_sites.png`: camera site points render within the expected coastal extent; scale bar + north arrow present; placeholder basemap expected in demo.
    - `outputs/demo/maps/camera_sites_panel.png`: panel renders but contains substantial whitespace (likely config/layout choice); consider tightening demo panel layout in a follow-up.

- 2026-01-09: WP-001 logging + evidence conventions.
  - Added `docs/log/README.md` and documented naming conventions in `docs/workflow.md`.
  - Created example log `docs/log/WP-001_2026-01-09_logging-evidence.md` and placeholder canonical run folder under `outputs/canonical_runs/`.
  - Decision recorded in `docs/decisions.md` for log/run naming.

- 2026-01-09: WP-002 config schema v1 + validation + reference.
  - Added `schema_version: 1` to config profiles and implemented `cfg_validate()` in `cfg_read()`.
  - Documented schema in `docs/config_reference.md` and linked from README.
  - Moved camera-site legend config under `data.camera_sites.map.legend` to match renderer expectations.
  - Validation tests added in `tests/testthat/test_config.R` (missing schema, missing required keys, unsupported version).

- 2026-01-09: WP-003 demo profile offline maps/panels.
  - Demo stack now produces a 2-panel figure combining species overview + camera-sites map.
  - Added normalization for mixed RGB/RGBA panel inputs; placeholder WMS tile handled as expected.
  - Canonical run saved under `outputs/canonical_runs/WP-003_2026-01-09_demo-offline` with inspected artefacts.

- 2026-01-09: WP-004 output schema v1 + regression tests.
  - Added `inst/extdata/output_manifest_v1.csv`, `docs/output_schema_v1.md`, and `output_schema_v1` target to validate declared outputs.
  - New validation helper `validate_output_manifest()` plus tests in `tests/testthat/test_output_manifest.R`.

- 2026-01-09: WP-005 packaging hygiene.
  - Ran `devtools::document()` + `rcmdcheck::rcmdcheck(args = "--no-manual")` with 0 errors/warnings/notes.
  - Canonical run folder recorded under `outputs/canonical_runs/WP-005_2026-01-09_packaging-hygiene`.

- 2026-01-09: WP-006 CI gates v1.
  - Added CI steps for lint, unit tests, demo pipeline run, and artifact uploads (test summary + demo PNGs).
  - Fixed output schema target to read the manifest via `readr::read_csv()` for pipeline validation.
  - Demo pipeline rerun (`R_CONFIG_ACTIVE=demo TARGETS_PROFILE=ci targets::tar_make()`), outputs inspected and captured under `outputs/canonical_runs/WP-006_2026-01-09_ci-gates-v1`.
  - Verification gates rerun: `renv::restore()`/`renv::status()` OK, `lintr::lint_package()` OK, `devtools::test()` OK (87 pass), `rcmdcheck::rcmdcheck(args = "--no-manual")` OK.

- 2026-01-09: Dataset intake + AOI pre-work.
  - Reviewed `data/jc_camera_study/` (camera sites, observations, operations, taxa, data dictionary); dataset is ~15k observations and 13 sites with WGS84 lat/lon.
  - Added `data/` to `.gitignore` per runtime-data policy; recorded decision to keep real datasets out of package defaults.
  - Documented AOI conventions (analysis CRS, units, rotation) in `docs/config_reference.md`.
  - Added `render_aoi_debug_plot()` and `aoi_debug_plot` target for AOI sanity previews (bounding box + sites).
  - Ran `devtools::test()` (88 pass) and regenerated `outputs/jc/maps/aoi_debug.png` for inspection.

- 2026-01-09: WP-007 AOI builder + JC dataset integration.
  - Implemented `build_aoi_from_config()` with centroid/size/rotation and schema v2 migration from v1 bounding boxes.
  - Hooked AOI into species mapping and tile maps; added AOI debug plots (including a rotated example).
  - Added JC dataset derivation (`derive_camera_sites_from_jc`) and `jc` profile config to produce `data/interim/jc_camera_sites.csv`.
  - Demo pipeline rebuilt after `targets::tar_destroy()`; outputs inspected and logged in `docs/log/WP-007_2026-01-09_aoi-builder.md`.
  - Validation: `lintr::lint_package()` OK, `devtools::test()` OK (104 pass), `rcmdcheck::rcmdcheck(args = "--no-manual")` OK.

- 2026-01-09: JC AOI rescaled to camera-region extent.
  - Updated the `jc` profile AOI size to 4 km and regenerated AOI debug + species occurrence maps in the JC extent.
  - Added `aoi_debug_jc.png` and `species_occurrences_jc.png` to the WP-007 canonical run folder; logged the sanity notes.

- 2026-01-09: JC fixture occurrences + tighter AOI.
  - Added `inst/extdata/occurrences_jc.csv` and `metadata/species_requests_jc.csv` to render JC points in the species map.
  - Enabled AOI auto mode (sites bbox + buffered extent) for the JC profile and regenerated JC AOI debug + occurrence maps.
  - Validation: `devtools::test()` OK (108 pass), `devtools::document()` updated AOI docs.
  - AOI debug plots now omit the centroid dot by default (optional plus marker available).

- 2026-01-09: Line 0.4 completion work (WP-008–WP-013).
  - Added coverage zone polygons + summary table outputs.
  - Implemented WMS and ArcGIS imagery fetch with caching/provenance and offline placeholders.
  - Added layer registry + overview map renderer + panel figure assembler.
  - Generated canonical run artefacts for WP-008 through WP-013 and recorded logs in `docs/log/`.
  - Validation: `devtools::test()` OK (134 pass), `lintr::lint_package()` clean; demo pipeline run `targets::tar_make()` completed.

- 2026-01-09: WP-008 canonical run switched to JC sites.
  - Rebuilt coverage zone + overview map with `R_CONFIG_ACTIVE=jc` to exercise the JC dataset.
  - Updated `outputs/canonical_runs/WP-008_2026-01-09_coverage-zone/overview_map.png` and `coverage_summary.csv`.
  - Logged new coverage area (≈0.426 km², 13 sites, 50 m buffer) in `docs/log/WP-008_2026-01-09_coverage-zone.md`.

- 2026-01-09: Overview map aspect ratio fix (WP-008).
  - Enabled AOI aspect-matching by default in `render_overview_map()` to remove transparent padding bands.
  - Regenerated the JC overview map and canonical WP-008 artefacts with the corrected aspect ratio.

- 2026-01-09: WP-009 WMS imagery re-run for JC profile.
  - Fixed provenance writer to preserve field names (`imagery_write_provenance`).
  - Fixed cache key generation to preserve parameter names (`imagery_cache_key`).
  - Set JC WMS layer to `offline: false` and regenerated live TASVEG imagery + provenance sidecar.
  - Updated WP-009 canonical run artefacts and log to use JC outputs.

- 2026-01-09: WP-010 ArcGIS imagery re-run for JC profile.
  - Added ArcGIS `layers` support (using `layers=show:65` for Elevation Bands).
  - Set JC ArcGIS layer to `offline: false` and regenerated live topography imagery + provenance sidecar.
  - Updated WP-010 canonical run artefacts and log to use JC outputs.

- 2026-01-09: Re-aligned early WP artefacts to JC examples + CI fixes.
  - Switched JC profile to emit `jc_*` output paths for species, camera-site maps, tiles, and panels.
  - Rebuilt WP-003/WP-006 canonical runs using JC artefacts; updated logs.
  - Regenerated `aoi_debug.png` + `aoi_debug_rotated.png` from JC AOI for WP-007.
  - Fixed CI lint/test steps to rely on renv-installed packages and added a placeholder artifact file.

- 2026-01-09: CI + layer registry alignment for JC.
  - Added `jc_ci` profile (offline-safe JC outputs) and CI step to collect JC artefacts alongside demo outputs.
  - Regenerated JC overview + panel figures and updated WP-011–WP-013 canonical runs/logs to use JC imagery.

- 2026-01-09: Line 0.5 work (WP-014–WP-018).
  - Implemented analysis-layer acquisition for vector/raster inputs plus derived slope/indices with caching + provenance.
  - Added run-level provenance outputs (analysis_layers.csv, attribution.md, run_manifest.yml) and updated schema/tests/docs.
  - Generated JC analysis fixtures (habitat polygons, DEM, multiband raster) and canonical runs for WP-014–WP-018.
  - Artefact review: vector bbox matches AOI; DEM extent aligns; slope range ~4.60–4.61°; NDVI range ~-0.01–0.20; NBR range ~0.03–0.48; attribution report lists imagery + analysis layers.
  - Note: `sf::st_intersection` warning about attribute variables is expected for polygon clipping.

- 2026-01-10: Analysis layer preview PNGs.
  - Added quick-look PNG previews for analysis vectors/rasters (auto-generated beside outputs).
  - Updated output schema/manifest and added tests to ensure preview files are created.
- 2026-01-10: Analysis preview overlays and derived-layer ordering guard.
  - Vector previews now colour by an attribute (prefers `habitat`) with legend and AOI outline.
  - Raster previews overlay AOI and camera sites for quick orientation checks.
  - Added validation to ensure derived layers appear after their source_id.

- 2026-01-10: Line 0.6 site attributes + report outputs.
  - Implemented raster/vector site attribute extraction with long parquet + wide CSV products and new unit tests.
  - Generated JC artefacts for WP-019–WP-022, including attribute tables, overview/panel figures, and report HTML.
  - Sanity checks: long table has 117 rows (13 sites × 9 attributes), NDVI/NBR within expected ranges, habitats show two classes, raster previews align with sites.
  - Validation: `devtools::document()` ran clean; `devtools::test()` (163 pass), `lintr::lint_package()` clean, `rcmdcheck::rcmdcheck(--no-manual)` OK.
  - JC pipeline run: `R_CONFIG_ACTIVE=jc TARGETS_PROFILE=ci targets::tar_make()` completed with expected `sf::st_intersection` warnings.

## 2026-01-10 — Line 0.6 (WP-025 container parity)
- Built Docker image using `inst/containers/Dockerfile` and ran JC profile in offline mode with host-mounted `data/` and `outputs/`.
- Resolved container build issues by adding system deps (harfbuzz/fribidi/pkg-config) and disabling pak auto-install in container bootstrap.
- Captured container outputs and provenance in `outputs/canonical_runs/WP-025_2026-01-10_container-parity/` and logged inspection notes.
- Remaining: update roadmap WP checkboxes, run local QA gates, commit + push at Line 0.6 gate.

## 2026-01-10 — WP-026 Tasmania canonical example
- Added `tas_canonical`/`tas_canonical_ci` profiles and a dedicated output manifest for Tasmania canonical outputs.
- Ran `R_CONFIG_ACTIVE=tas_canonical LOCALMAP_ALLOW_NETWORK=1 targets::tar_make()` and captured outputs in `outputs/canonical_runs/WP-026_2026-01-10_tas-canonical/`.
- Artefact review: orthophoto aligns with AOI + sites; TASVEG vector preview shows multiple vegetation groups; DEM/slope previews align with sites and show coherent gradients.
- Panel figure assembled all four maps with expected labels and no blank panels.
- Refreshed canonical DEM to LIST DTM export with overlays.
  - Added ArcGIS raster analysis layer support and switched `tas_canonical` DEM to LIST RasterMisc MapServer (layer 73) with JC fixture fallback.
  - Added roads/localities WMS overlays to the Tasmania canonical overview map.
  - Regenerated canonical artefacts (overview map, DEM/slope rasters + previews, overlay layers, provenance) and refreshed WP-026 canonical run folder.
  - Sanity: orthophoto + overlays align with AOI; DEM gradient looks plausible; slope shows expected terrain pattern; AOI/illustrative points overlay correctly.
  - Validation: `devtools::test()` OK (172 pass, expected warnings), `lintr::lint_package()` clean, `targets::tar_make()` for `tas_canonical` ran to completion.
  - `rcmdcheck::rcmdcheck(--no-manual --as-cran)` reported qpdf warning + NOTEs about top-level files (expected for dev repo); no errors.
  - CI fix: added `lintr`, `rex`, `xmlparsedata`, and `lazyeval` to `renv.lock` and removed in-step installs; ensured `ci_artifacts` placeholder exists before upload.
  - CI fix: added demo-specific output manifest so the demo pipeline validates `output_schema_v1` against demo outputs.

- 2026-01-11: CI JC fixture override for offline pipeline.
  - Added `inst/extdata/jc_camera_sites_fixture.csv` and configured `config/config.yaml` `jc_ci.data.camera_sites` to use fixture path.
  - Purpose: avoid CI failure when `data/jc_camera_study/jc_site.csv` is unavailable (data/ is gitignored).
  - Next: re-run JC CI profile and confirm outputs complete.
  - Ran `R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci targets::tar_make()` successfully; expected offline placeholder warnings only.

- 2026-01-11: DEM alignment/cache + profile tracking fix.
  - Added `config_profile` target so `{targets}` invalidates when `R_CONFIG_ACTIVE` changes.
  - Added `params.offline` to analysis-layer cache key to avoid reusing offline fixtures when network is available.
  - Re-ran `R_CONFIG_ACTIVE=tas_canonical LOCALMAP_ALLOW_NETWORK=1 targets::tar_make()`; `tas_dem.tif` regenerated from LIST export with offline=false provenance.

- 2026-01-11: Analysis outputs split by profile + JC DEM source aligned.
  - Moved analysis outputs under `outputs/jc/analysis/` and `outputs/tas/analysis/` to avoid mixed files.
  - Switched JC DEM to geodata SRTM (same as TAS) so DEM/slope previews align; fixtures remain for offline CI.
  - Added `config_profile` target cue `mode=always` so profile changes invalidate pipeline.
  - Regenerated analysis layers/previews for `jc` and `tas_canonical` profiles.

- 2026-01-11: GA DEM 1 Second baseline + WCS support.
  - Added `raster_wcs` analysis layer type with WCS GetCoverage fetch, fallback support, and provenance notes.
  - Updated JC/TAS configs to use GA DEM 1 Second (WCS) with SRTM 3s fallback and offline fixtures.
  - Updated config reference + output manifests to reflect GA DEM source.
  - Added offline WCS fixture test in `tests/testthat/test_analysis_layers.R`.

- 2026-01-11: DEM variant switch + derived cache invalidation.
  - Added `data.dem_variant`/`data.dem_variant_path` support with GA/SRTM/ELVIS options and config tests.
  - Derived raster cache keys now include source cache keys to refresh slope/indices when DEM sources change.

- 2026-01-12: Analysis preview frame cleanup.
  - Removed the extra raster plot frame so preview PNGs only show the AOI outline (no inner black border).
  - Regenerated JC analysis previews to confirm AOI/points overlay without the plot box.

- 2026-01-12: Multiband RS source switch to DEA Landsat 8/9 geomedian.
  - Updated JC multiband analysis layer to use DEA Landsat 8/9 geomedian (WCS) with fixture fallback.
  - Added band-name resolution for NDVI/NBR so mappings work for both real RS data and the offline fixture.
  - Refreshed JC analysis previews and derived indices with the new multiband source.

- 2026-01-12: Layer output tidy-up.
  - Moved imagery outputs under `outputs/{jc|tas|demo}/layers/` to match the analysis output hierarchy.
  - Updated manifests and schema docs to point to the new layer output paths.

- 2026-01-12: Map output tidy-up + layer parity.
  - Moved map outputs under `outputs/{jc|tas|demo}/maps/` and placed AOI debug output under `outputs/<profile>/maps/aoi_debug.png`.
  - Regenerated JC/TAS map artefacts at the new paths; removed legacy top-level map files.
  - Added JC orthophoto/roads/localities layers and TAS topography layer to keep layer outputs consistent across profiles.

- 2026-01-12: Tables output hierarchy cleanup.
  - Moved table artefacts into `outputs/{jc|tas|demo|default}/tables/` and updated config + manifests.
  - Fixed demo layer registry duplicates (roads/localities) and aligned demo layer output paths.
  - Regenerated demo coverage + site attribute tables at the new paths.

- 2026-01-12: Tables output consolidation.
  - Removed default/demo table directories; tables now only under `outputs/jc/tables/` and `outputs/tas/tables/`.
  - Updated config + manifests + fallback paths to align with JC/TAS-only table layout.

- 2026-01-12: Table schema + distance metrics.
  - Coverage summaries now report `area_km2` only (no `area_m2`).
  - Site attributes now include raster_wcs layers (DEM + multiband) and derived distance columns (`distance_to_road`, `distance_to_locality`).
  - Added distance-layer config + fixtures for roads/localities; regenerated JC/TAS site attribute tables.

- 2026-01-12: Site attribute curation + TAS multiband.
  - Site attribute CSVs now emit a curated column set (lat/lon, DEM, slope, NDVI, NBR, TASVEG category, distances).
  - Multiband stacks are still produced but skipped for attribute extraction by default.
  - Added TAS multiband + NDVI/NBR analysis layers to mirror JC outputs; distance-to-locality now stays NA if no features intersect the AOI.

- 2026-01-12: TASVEG classes layer + site attributes.
  - Added TASVEG 4.0 Classes vector layers for JC and TAS profiles (MapServer/85) with class attribute extraction.
  - Site attribute tables now include `tasveg_class` alongside the existing `tasveg_category`.
  - Updated manifests/schema docs for the new class vector outputs.

- 2026-01-12: TASVEG classes WMS overlays + legend.
  - Added TASVEG 4.0 Classes WMS layers for JC/TAS with legend graphics via GetLegendGraphic.
  - Layer registry now tracks legend paths; output manifests updated accordingly.
  - Verified class WMS tiles + legend PNGs are non-empty for JC/TAS (file sizes ~130 KB and ~79 KB).

- 2026-01-12: TASVEG class legend refinement.
  - Switched TASVEG class legends to custom AOI-only legends (codes only) derived from class vectors.
  - Added per-AOI lookup CSV mapping code → full class name for reference.
  - Legend swatches now use LIST service colors when online, with greyscale fallback offline.

- 2026-01-18: TASVEG class legend defaults.
  - Updated legend rendering to attempt LIST legend colors by default (no opt-in), with grey fallback on failed fetch.
  - Added a JC TASVEG class fixture (`inst/extdata/jc_tasveg_class.gpkg`) so offline runs still have VEGCODE fields.
  - Regenerated JC/TAS class legends; confirmed legends include non-grey swatches when network available.

- 2026-01-18: RS layer expansion (CHM, fire, soils, climate normals).
  - Added `raster_remote` support (CHM) with large-download gating + placeholder handling; switched WorldClim to tile downloads; optimized raster clipping (crop before reprojection).
  - Added soil pH + WorldClim BIO1/BIO12 rasters, fire/geology/tenure/reserve vectors, and TAS fire/soil WMS overlays; updated site-attributes mapping + ordering.
  - Ran `R_CONFIG_ACTIVE=jc LOCALMAP_ALLOW_NETWORK=1 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 Rscript -e 'targets::tar_make()'` and `R_CONFIG_ACTIVE=tas_canonical LOCALMAP_ALLOW_NETWORK=1 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 Rscript -e 'targets::tar_make()'`.
  - Artefacts inspected: `outputs/jc/analysis/raster/jc_soil_ph.png`, `outputs/jc/analysis/raster/jc_bio1.png`, `outputs/jc/analysis/raster/jc_bio12.png`, `outputs/jc/analysis/raster/jc_chm.png`, `outputs/jc/analysis/vector/jc_fire_attributes.png`, `outputs/jc/analysis/vector/jc_geology.png`, `outputs/jc/layers/fire_attributes_arcgis.png`, `outputs/jc/layers/soil_ph_wms.png`, `outputs/jc/tables/site_attributes_wide.csv` (and TAS equivalents in `outputs/tas/analysis/`).
  - Sanity notes: soil pH values ~5.4–5.7; BIO1 ~10–11 °C after scaling; BIO12 ~900–1078 mm; NDVI/NBR within expected ranges. CHM preview is placeholder due to large-download gating. Fire/geology/tenure/reserve vectors return multiple classes; distance-to-road/locality remain NA at current AOI.
  - Next steps: run once with `LOCALMAP_ALLOW_LARGE_DOWNLOADS=1` to fetch CHM when bandwidth permits; review CHM alignment and consider finer climate resolution if needed.

- 2026-01-19: BIO1 scaling + grid check.
  - Removed the extra 0.1 scale on WorldClim BIO1 so values are in deg C (now ~10.6–11.4 for JC).
  - Rebuilt JC/TAS analysis layers, previews, and site attribute tables with the corrected BIO1 scale.
  - Checked WorldClim grid alignment: closest camera to a cell intersection is ~0.00157 deg lon and ~0.00021 deg lat away (~130 m x 23 m), so the near-center intersection is coincidence, not a misalignment.

- 2026-01-19: CHM extraction + attributes.
  - Fixed CHM extract pattern (`\\.tif$`) so cached TAS_CHM_2m.tif is detected.
  - Added 7z fallback for deflate64 ZIP extraction to avoid base unzip failures.
  - Rebuilt JC/TAS CHM outputs with `LOCALMAP_ALLOW_LARGE_DOWNLOADS=1`; CHM rasters now contain values (0–45 m) and site attributes populate `canopy_height_m`.

- 2026-01-19: Attribute code lookups.
  - Added lookup CSVs for TASVEG groups, geology, land tenure, and reserve estate classes.
  - Site attributes now use compact codes for `tasveg_category`, `land_tenure_class`, and `reserve_estate_class`; geology uses `map_symb`.
  - Full labels are preserved in the new lookup tables alongside the analysis vectors.

- 2026-01-19: JC inputs moved to data/raw + rd/obs derivation update.
  - Updated JC config + fixtures to read `data/raw/jc_camera_study/{site,obs,op}.csv` instead of `data/jc_camera_study`.
  - `derive_camera_sites_from_jc()` now uses `site.csv` `count`/`rd` when present, otherwise computes `obs` from `obs.csv` and `rd` from `op.csv` with NA fallbacks + warnings.
  - `site_attributes_wide.csv` now carries extra columns from the site input (non-conflicting names preserved, conflicts prefixed `site_`).

- 2026-01-19: Rebuild with JC inputs under data/raw.
  - Ran `R_CONFIG_ACTIVE=jc LOCALMAP_ALLOW_NETWORK=1 LOCALMAP_ALLOW_LARGE_DOWNLOADS=1 Rscript -e 'targets::tar_make()'`.
  - Pipeline completed (54 targets) with warnings about missing `data/raw/lyr_pt.csv` and spatially-constant attribute assumptions.
  - Outputs refreshed under `outputs/` including updated `camera_sites` and `site_attributes` tables using the new `site/obs/op` inputs.

- 2026-01-19: Updated config to look for `data/raw/lyr/lyr_pt.csv` after raw-data reorg.
- 2026-01-19: Re-ran JC pipeline after lyr_pt path update; missing points warning resolved (remaining warnings are spatially-constant attributes + row names).
- 2026-01-19: Added settings overlay + runner.
  - Added `settings.example.yaml` and `scripts/run_project.R` to support a simplified user workflow.
  - Added `run_settings()` and helpers to merge settings into a base config and run the pipeline.
  - `_targets.R` now respects `LOCALMAP_CONFIG_PATH` so runs can use a generated config file.
  - Ran `devtools::test(filter = "settings_runner")` to validate the settings overlay logic.
  - Sanity check: `pkgload::load_all("."); run_settings("settings.example.yaml", targets = "cfg")` created `outputs/judbury_cameras/run_config.yaml`.
- 2026-01-19: Fixed attribute lookup handling for missing layers and re-ran user settings.
  - `render_attribute_lookups()` now returns NA for missing layer IDs instead of erroring.
  - Ran `Rscript scripts/run_project.R settings.yaml`; pipeline completed (20 targets) with a TASVEG class placeholder warning.
- 2026-01-19: Settings overlay now auto-includes TASVEG class when TASVEG is requested (avoids class-legend warnings).

- 2026-01-20: Outputs hierarchy refactor + settings run fixes.
  - Reworked outputs to `outputs/<profile>/<type>/` across config, manifests, docs, and targets; settings runs now drop artefacts directly under the project root (no nested `jc/` subfolders).
  - `cfg_read()` now prefers the repo `config/config.yaml` when present and rewrites `outputs/default/*` to the active `data.outputs.output_dir` for profile-specific paths.
  - Settings overlay now strips the base profile output prefix and `_targets.R` re-evaluates `cfg_file` on every run so `LOCALMAP_CONFIG_PATH` changes are respected.
  - Added JC/TAS camera-site overlay output paths and regenerated JC/TAS/`judbury_cameras` runs to refresh outputs.
  - Artefacts inspected: `outputs/jc/maps/overview_map.png`, `outputs/jc/maps/camera_sites.png`, `outputs/jc/analysis/raster/jc_dem.png`, `outputs/judbury_cameras/maps/overview_map.png`.
  - Sanity notes: AOI polygons align with camera sites; orthophoto basemap and TASVEG overlays align; DEM gradients look plausible at the AOI scale.
  - Remaining: address recurring “spatially constant attributes” and row-name warnings in a later cleanup pass.

- 2026-01-20: renv snapshot preflight fix.
  - Added `.renvignore` to exclude `dependencies.R` from renv scanning.
  - Updated renv settings to drop `Suggests` from dependency fields so snapshotting does not require the full devtool dependency tree.
  - `renv::snapshot()` now completes without missing-package errors.

- 2026-01-20: Flexible panel assembly updates.
  - `panel_figure` now supports explicit `panels` entries (path + optional label/legend) with size normalization and zero-gap layouts for abutting panels.
  - Added panel legend overlay support with per-panel defaults (alpha/position/size) and kept legacy `paths` support.
  - Camera-site legend overlay now supports transparency via `legend.alpha`.
  - Ran `R_CONFIG_ACTIVE=jc Rscript -e 'targets::tar_make(names = c(\"panel_figure\"))'`; panel figure regenerated (PNG size 4200×3818 px) with zero gap; warnings persisted from earlier runs.

- 2026-03-06: Bootstrap workflow aligned with renv.
  - Cloned `BWBrook/localmap_tas` into `/home/bwbrook/git/localmap_tas` and ran `make bootstrap`; `renv::restore()` completed, but the follow-on `pak::pkg_install(project_dependencies())` step failed because `dependencies.R` no longer matched the repo.
  - Simplified `make bootstrap` and `scripts/bootstrap.R` to rely on `renv::restore()` plus `devtools::document()`, avoiding the stale secondary install path.
  - Reworked `dependencies.R` to derive its optional helper installs from `DESCRIPTION`, and updated README/development docs to stop recommending a redundant post-restore package install.
  - Fixed the canonical test entrypoints by switching `make test` / `tests/run-tests.R` to package-aware runners and adding `tests/testthat.R` for `R CMD check`.
  - Fixed demo output-schema validation by giving `demo` its own expected-output map in `_targets.R` and normalizing empty attribute lookup paths in `render_attribute_lookups()`.
  - Removed `pak` from `DESCRIPTION` Suggests and refreshed `renv.lock`; `renv::status()` now reports a consistent state.
  - Verification (2026-03-06): `make bootstrap` OK; `make test` OK (1 expected skip, 7 expected offline warnings); `R_CONFIG_ACTIVE=demo TARGETS_PROFILE=ci targets::tar_make()` OK.
