# Changelog

All notable changes to this project will be documented in this file.

The format follows Keep a Changelog. This project adheres to Semantic Versioning where applicable.

## [Unreleased]
### Added
- Analysis-layer pipeline for AOI-clipped vector/raster data with cached GeoPackage/GeoTIFF outputs and provenance sidecars.
- ArcGIS raster analysis layers (`raster_arcgis`) with MapServer export support and fixture fallback when offline.
- Derived raster products (slope from DEM, NDVI/NBR from multiband rasters) with JC fixtures in `inst/extdata/`.
- Run-level provenance outputs (`analysis_layers.csv`, `attribution.md`, `run_manifest.yml`) for publication-ready attribution.
- Quick-look PNG previews alongside each analysis vector/raster output for rapid QA.
- Site attribute extraction outputs (long parquet + wide CSV) from raster and vector analysis layers.
- Offline-first network gating via `LOCALMAP_ALLOW_NETWORK` with placeholder imagery by default.
- Cache audit coverage: deterministic cache keys + cache-hit tests for analysis layers.
- Container bootstrap script (`scripts/bootstrap_container.R`) for Docker/Apptainer builds with renv-only restores.
- AOI builder (`build_aoi_from_config`) with centroid/size/rotation and AOI debug plots (`aoi_debug_plot` target).
- AOI auto mode to derive extents from site bounds with a buffered heuristic (median nearest-neighbour distance).
- `jc` camera-sites source to derive effort (`rd`) and observations (`obs`) from Judbury camera study inputs.
- Simplified `settings.yaml` overlay + runner (`scripts/run_project.R`) for end users, with run-specific config generation and `LOCALMAP_CONFIG_PATH` support.
- JC fixture occurrences (`inst/extdata/occurrences_jc.csv`) and species list (`metadata/species_requests_jc.csv`) for local camera-scale demo maps.
- Coverage zone polygons (convex hull + buffer) with summary tables.
- WMS imagery fetch with caching, provenance, and offline placeholders.
- ArcGIS export imagery fetch with caching, provenance, and offline placeholders.
- RS layer expansion: canopy height (LIST CHM), soil pH (SoilGrids), WorldClim BIO1/BIO12 normals, TASVEG fire attributes, and geology/tenure/reserve vectors, with output previews and attribute extraction.
- `raster_remote` analysis-layer type with large-download gating and placeholder handling.
- Layer registry v1 with config-driven imagery definitions and `docs/layers_guide.md`.
- Overview map renderer with AOI/sites/coverage and cartographic annotations.
- Multi-panel figure assembler with PNG + PDF outputs.
- `camera_sites_panel` target and stacking helper to combine multiple camera
  site map PNGs into a vertically aligned comparison panel.
- Panel stacking now deduplicates glob/dir matches, supports up to nine panes in
  configurable grids (via `stack$columns`/`rows`), honours regex ordering, and
  provides configurable bottom-right panel labels via
  `data$camera_sites$stack$labels`.
- Panel figures now accept explicit `panels` entries, optional size normalization,
  and per-panel legend overlays for tightly abutting layouts.
- Camera site mapping workflow: new configuration (`data$camera_sites`),
- Camera map now offers configurable graticules aligned to the bounding box extent, optional WMS overlay tiles (e.g., roads, towns), and a configurable legend inset.
- Camera site tile helper now warns when requested scale exceeds the LIST TASVEG visibility threshold; configuration adds `max_scale` and defaults to DPI 96.
  helper functions, and targets (`camera_sites_file`, `camera_sites_data`,
  `camera_sites_context`, `camera_sites_tile`, `camera_sites_map`) to visualise
  wildlife camera deployments with LIST TASVEG basemap support.
- Localmap branding and species occurrence framing across README and docs.
- Species request workflow (`read_species_requests()`, `ala_resolve_species()`,
  `ala_fetch_occurrences()`) to query the Atlas of Living Australia via
  `{galah}`.
- `metadata/species_requests.csv` sample input and config entries for Atlas
  access.
- Configuration knobs for occurrence filtering (`min_year`, `state_province`,
  optional `min_lat`, boundary geometry) surfaced in `config/config.yaml`, along
  with explicit galah `download_reason_id` support.
- Hard-code the galah pipeline as a literal string (`galah_call() |> ...`)
  because galah 2.x rejects dynamically constructed quosures; do not refactor
  to tidy-eval forms unless the upstream API changes.
- Static mapping utilities for occurrence points, including the
  `map_species_occurrences()` helper and `species_map` target that renders a
  bounding-box constrained image.
- Configuration entries for mapping (bounding box, basemap, output path) under
  `data$occurrence$map`.
- Optional ancillary point overlays drawn from CSV files (configured under
  `data$occurrence$map$additional_points`).
- Added `topo_tile_map` target to render OpenTopoMap-based tile imagery (or
  other providers) beneath species and ancillary points.
- Tile maps now support optional latitude/longitude graticule overlays with
  labelled degrees and default to blue occurrence markers for better contrast
  on satellite imagery.

### Changed
- `_targets.R` now delegates profile-specific expected-output assembly, report fallback rendering, TASVEG class lookup resolution, and manifest selection to internal helper functions to keep the pipeline declarative without changing target names or outputs.
- Config handling is now split into load, migrate, validate, and resolve phases behind the existing `cfg_read()` entrypoint, preserving the schema and output layout while reducing coupling in `R/config.R`.
- Camera-site internals are now separated by responsibility: defaults, graticule generation, and panel assembly live in dedicated helper modules instead of one oversized renderer file.
- Analysis-layer internals are now separated by responsibility: validation and remote download/WCS fallback helpers live outside the main acquisition module, reducing the size and coupling of `R/analysis_layers.R`.
- Config schema bumped to v2 with AOI as the authoritative extent definition; v1 configs are migrated.
- Species mapping now accepts AOI input and only falls back to bounding-box config when needed.
- JC profile now uses AOI auto mode for a camera-scale extent.
- JC multiband source now uses DEA Landsat 8/9 geomedian via WCS with name-based band resolution (fixture fallback retained).
- Tasmania canonical profile now uses LIST DTM (MapServer export) for DEM with fixture fallback and adds roads/localities overlays to overview maps.
- Outputs now live under `outputs/<profile>/<type>/` (maps, layers, analysis, tables, tiles, provenance) with AOI debug plots under `outputs/<profile>/maps/aoi_debug.png`.
- Rename project metadata, Quarto site, and pkgdown home content from `rcompendium`
  to `localmap`.
- Update vignette examples and namespace-qualified calls to use `localmap::`.
- Refresh `DESCRIPTION` summary and `CITATION.cff` keywords to describe the
  species occurrence mapping focus.
- Expand `_targets.R` with ALA configuration, species resolution, and
  occurrence download targets.
- Default species map styling now hides the title/legend, removes the bounding
  box overlay, and uses smaller green points (configurable via
  `data$occurrence$map`).

### Fixed
- Bootstrap now relies on `renv::restore()` as the canonical dependency source instead of a stale hand-maintained package list.
- `dependencies.R` now derives its optional helper installs from `DESCRIPTION`, so contributor instructions stay aligned with the package metadata.
- `make test` and `R CMD check` now use package-aware test entrypoints, so the canonical checks exercise `localmap` instead of skipping most tests.
- Demo output-schema validation now handles profiles without analysis layers and validates against a demo-specific expected-output map.
- Removed the no-longer-required `pak` suggestion from the project metadata and refreshed `renv.lock`, restoring a clean `renv::status()`.
- Added a separate QA bootstrap path and active CI workflow so lint, offline pipelines, and package checks match the documented release gates.
- `tests/run-tests.R` is now `R CMD check` compatible, and `.renvignore` is excluded from package builds.
- Added positive contract tests for demo output manifests, provenance keys, overview-map aspect ratio, site-attribute wide-table mapping, and `run_settings()` environment restoration.
