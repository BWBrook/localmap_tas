# Architecture

## System overview

localmap_tas is an R package + `{targets}` pipeline with a config-driven interface.

High-level flow:

1. Read configuration (`config/config.yaml`)
2. Read site points and define an area-of-interest (AOI)
3. Fetch/cache requested layers (imagery and/or analysis-grade)
4. Render maps and multi-panel figures
5. Optionally extract attributes at sites and write a table
6. Write provenance metadata for all outputs

## Major components

### 1) Configuration layer

- `cfg_read()` reads YAML via `{config}` with profiles (e.g., `default`, `demo`, `ci`)
- A project-level schema defines:
  - site inputs
  - AOI definition
  - layer registry (what to fetch, how)
  - panel definitions (what to render)

### 2) Domain objects (conceptual)

These are implemented as lists / tibbles but should be treated as stable interfaces:

- **SiteTable**
  - columns: `site_id`, `lat`, `lon`, plus optional fields
- **AOI (Area of Interest)**
  - square/rectangle polygon in a chosen analysis CRS (default EPSG:28355)
  - derived bounding boxes in EPSG:3857 for imagery fetches
- **LayerSpec**
  - `id`, `type`, `source`, `params`, `attribution`, `cache_key`
  - types (incremental):
    - `wms_getmap` (imagery)
    - `arcgis_export` (imagery)
    - `arcgis_feature_query` (vector, clipped)
    - `file_raster` / `file_vector` (user-provided)
- **PanelSpec**
  - references one or more LayerSpecs plus styling for overlays and annotations
  - output path and dimensions

### 3) Data acquisition subsystem

Responsibilities:
- build requests
- enforce CRS correctness (WMS 1.3.0 axis rules)
- cache responses deterministically
- record provenance

Key idea:
- Imagery-first layers produce PNG/TIFF suitable for plotting.
- Analysis-grade layers produce GeoPackage / GeoTIFF clipped to AOI.

### 4) Spatial processing subsystem

Responsibilities:
- project sites into analysis CRS
- derive AOI polygons and any coverage polygons
- crop and mask layers where needed
- derive covariate rasters (e.g., slope from DEM) when configured

### 5) Map rendering subsystem

Responsibilities:
- render single overview maps
- render multiple panels with consistent styling
- assemble panels into a single figure with labels
- write outputs at configured DPI

### 6) Targets pipeline

The pipeline is the orchestration layer and should remain thin:
- declare targets
- call functions implemented in `R/`

Expected targets (new branch, names may evolve):
- `cfg`
- `site_points_file` → `site_points`
- `aoi`
- `layers` (dynamic branching where appropriate)
- `panel_maps` → `panel_figure`
- `site_attributes` (optional)
- `provenance_summary`

## Repository layout

- `R/` — all functions (no heavy logic in `_targets.R`)
- `config/` — YAML config
- `metadata/` — small reference tables (optional)
- `inst/extdata/` — small demo inputs only
- `outputs/` — generated artefacts (ignored by git)
- `data/` — runtime caches and downloaded layers (ignored by git)
- `docs/` — product/engineering docs
- `tests/` — unit and smoke tests

## Interfaces and stability

- Export only a small, intentional API surface for v1.0.
- Everything else remains internal and can change without breaking users.
- Config keys are part of the public interface; changes require changelog entries.
