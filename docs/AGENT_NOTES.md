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
