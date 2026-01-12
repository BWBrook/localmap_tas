This roadmap is authoritative for priorities and scope. It is organised by milestone.

## Milestone: MVP (v0.1.0) — Config → maps/panels (imagery-first)

### Deliverables
- A generalized site mapping workflow (not camera-specific) that can:
  - read site points (CSV)
  - define an AOI from centroid + size
  - fetch imagery layers (WMS and/or ArcGIS export) with caching
  - render an overview map and a multi-panel figure
- A `demo` config profile that runs end-to-end on a clean clone
- Repo hygiene fixes:
  - correct MIT license
  - fix `.Rbuildignore`
  - ensure AGENTS.md is tracked
  - replace placeholder repo URL in CITATION (or document TODO)

### Acceptance criteria
- `targets::tar_make()` on demo profile completes without manual downloads
- Outputs exist under `outputs/`:
  - at least 1 overview map
  - at least 1 multi-panel figure (>= 2 panels)
- Unit tests cover:
  - AOI/bbox math
  - panel assembly behavior
  - request builder logic (offline)

### Stop conditions
- The demo workflow is reliable and produces coherent figures.
- There is a clean extension point for adding new panels/layers via config.

## Milestone: Beta (v0.5.0) — Analysis-grade layers + attribute extraction

### Deliverables
- Vector layer acquisition suitable for analysis:
  - ArcGIS REST feature query clipped to AOI
- Optional raster acquisition beyond imagery tiles (at least one working path)
- Derived layers (e.g., slope from DEM) using `terra`
- Attribute extraction:
  - extract values/classes at sites
  - write `outputs/tables/<profile>/site_attributes.csv` (or parquet)
- Provenance outputs:
  - `outputs/provenance/` with per-layer metadata and run summary

### Acceptance criteria
- Configured run produces maps + attribute table + provenance summary
- Extraction logic is tested on small fixtures

### Stop conditions
- At least one vector and one raster analysis-grade path are stable and documented.

## Milestone: 1.0 (v1.0.0) — Hardened, stable product

### Deliverables
- Stable exported API + stable config schema
- CI gates:
  - R CMD check
  - tests
  - lint
  - demo pipeline smoke run
- Documentation:
  - README quickstart
  - “Adding layers” guide
  - at least one end-to-end vignette
- Release engineering:
  - semantic versioning
  - changelog discipline
  - release checklist is satisfied

### Stop conditions
- Definition of Done is met and verified with a real Tasmania example.

## Backlog (post-1.0 candidates)
- Inset/locator map of Tasmania automatically generated
- Templates for common ecology figure styles (journal-ready themes)
- Layer browser utilities (list and test capabilities of a WMS/ArcGIS endpoint)
- Optional PDF/SVG outputs and typography control
- Support for multiple AOIs in one run (multiple sites/centroids)
