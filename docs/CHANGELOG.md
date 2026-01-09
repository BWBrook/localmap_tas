# Changelog

All notable changes to this project will be documented in this file.

The format follows Keep a Changelog. This project adheres to Semantic Versioning where applicable.

## [Unreleased]
### Added
- AOI builder (`build_aoi_from_config`) with centroid/size/rotation and AOI debug plots (`aoi_debug_plot` target).
- AOI auto mode to derive extents from site bounds with a buffered heuristic (median nearest-neighbour distance).
- `jc` camera-sites source to derive effort (`rd`) and observations (`obs`) from Judbury camera study inputs.
- JC fixture occurrences (`inst/extdata/occurrences_jc.csv`) and species list (`metadata/species_requests_jc.csv`) for local camera-scale demo maps.
- Coverage zone polygons (convex hull + buffer) with summary tables.
- WMS imagery fetch with caching, provenance, and offline placeholders.
- ArcGIS export imagery fetch with caching, provenance, and offline placeholders.
- Layer registry v1 with config-driven imagery definitions and `docs/layers_guide.md`.
- Overview map renderer with AOI/sites/coverage and cartographic annotations.
- Multi-panel figure assembler with PNG + PDF outputs.
- `camera_sites_panel` target and stacking helper to combine multiple camera
  site map PNGs into a vertically aligned comparison panel.
- Panel stacking now deduplicates glob/dir matches, supports up to nine panes in
  configurable grids (via `stack$columns`/`rows`), honours regex ordering, and
  provides configurable bottom-right panel labels via
  `data$camera_sites$stack$labels`.
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
- Config schema bumped to v2 with AOI as the authoritative extent definition; v1 configs are migrated.
- Species mapping now accepts AOI input and only falls back to bounding-box config when needed.
- JC profile now uses AOI auto mode for a camera-scale extent.
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
- n/a
