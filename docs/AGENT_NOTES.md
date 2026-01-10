# AGENT NOTES

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
      - `outputs/maps/demo_species_occurrences.png` shows Tasmania outline with fixture points within the configured bounding box.
      - `outputs/maps/demo_camera_sites.png` shows camera sites on placeholder basemap; extent and symbol scaling appear coherent.
      - `outputs/maps/demo_camera_sites_panel.png` renders as expected for a 1×1 panel.
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
    - `outputs/maps/demo_species_occurrences.png`: Tasmania outline and occurrence points appear spatially plausible (points clustered in NW TAS; graticule labels plausible).
    - `outputs/maps/demo_camera_sites.png`: camera site points render within the expected coastal extent; scale bar + north arrow present; placeholder basemap expected in demo.
    - `outputs/maps/demo_camera_sites_panel.png`: panel renders but contains substantial whitespace (likely config/layout choice); consider tightening demo panel layout in a follow-up.

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
  - Ran `devtools::test()` (88 pass) and regenerated `outputs/maps/aoi_debug.png` for inspection.

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
