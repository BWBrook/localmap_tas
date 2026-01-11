# Decisions

This file records irreversible or costly-to-reverse decisions.

Format:
- Date (YYYY-MM-DD)
- Decision
- Rationale
- Status (active/superseded)

---

## 2025-12-17 — Default analysis CRS is EPSG:28355 (GDA94 / MGA Zone 55)
**Decision:** Use EPSG:28355 as the default CRS for AOI geometry, clipping, and attribute extraction.
**Rationale:** Tasmania-centric local mapping aligns with common state datasets and the existing notes/workflows.
**Status:** Active.

## 2025-12-17 — Imagery fetch CRS default is EPSG:3857
**Decision:** Use EPSG:3857 for imagery tile/export requests unless a service requires otherwise.
**Rationale:** Many WMS/ArcGIS export endpoints and tile providers use Web Mercator; simplifies consistent image output.
**Status:** Active.

## 2025-12-17 — Orchestration is `{targets}`; configuration is YAML via `{config}`
**Decision:** All core workflows run through `_targets.R` driven by `config/config.yaml` profiles.
**Rationale:** Reproducibility, caching, and clear DAGs; already aligned with existing repo structure.
**Status:** Active.

## 2025-12-17 — MVP prioritises imagery-first panels; analysis-grade extraction is Beta
**Decision:** MVP focuses on generating coherent map panels using imagery requests (WMS GetMap / ArcGIS export).
**Rationale:** Provides immediate user value and de-risks service integration; extraction requires additional complexity and fixtures.
**Status:** Active.

## 2025-12-17 — Plotting stack defaults to ggplot2-based rendering
**Decision:** Use `ggplot2` (+ spatial helpers) as the default rendering engine for v0.x–v1.0.
**Rationale:** Existing codebase uses ggplot2; integrates well with compositing and testing; avoids dual plotting stacks early.
**Status:** Active.

## 2025-12-17 — Caching policy: deterministic cache keys + provenance metadata
**Decision:** Every remote fetch must write:
- a cached artefact (PNG/TIFF/GeoPackage/GeoTIFF),
- and a sidecar metadata file (YAML/JSON) including request params and timestamp.
**Rationale:** Scientific traceability and reproducibility.
**Status:** Active.

## 2025-12-17 — CITATION repository URL is a TODO until we have a canonical remote
**Decision:** Remove placeholder repository URLs from `CITATION.cff` and leave an explicit TODO comment until the canonical repository URL is known.
**Rationale:** Avoid publishing incorrect metadata; the correct URL depends on where the repo is hosted and may change before v1.0.
**Status:** Active.

## 2025-12-17 — Package code uses `pkg::fun()` namespaces (no `import::from()`)
**Decision:** Use explicit namespace qualifiers (`pkg::fun()`) inside functions, avoid `import::from()` and avoid `library()` calls in package code.
**Rationale:** More idiomatic for typical R users; keeps dependency usage explicit at call sites; avoids check notes driven by the `{import}` package and reduces search-path side effects.
**Status:** Active.

## 2026-01-09 — WP log and canonical run naming convention
**Decision:** WP logs live in `docs/log/` named `WP-###_YYYY-MM-DD_short-slug.md`; canonical run folders live in `outputs/canonical_runs/WP-###_YYYY-MM-DD_short-slug/`.
**Rationale:** A consistent, sortable naming scheme makes PI review easier and keeps evidence bundled with each WP.
**Status:** Active.

## 2026-01-09 — Config schema v1 with explicit validation
**Decision:** Introduce `schema_version: 1` and validate required config keys at `cfg_read()` time.
**Rationale:** Configuration is a public interface; failing fast with clear errors reduces silent misconfiguration.
**Status:** Active.

## 2026-01-09 — Camera-site legend config lives under `data.camera_sites.map.legend`
**Decision:** Store legend display settings inside the camera-site map config block.
**Rationale:** The renderer consumes `map_cfg$legend`; keeping legend settings co-located avoids unused config keys.
**Status:** Active.

## 2026-01-09 — Output schema v1 manifest
**Decision:** Track expected artefacts in a manifest CSV (`inst/extdata/output_manifest_v1.csv`) and validate via `output_schema_v1` target.
**Rationale:** Makes output contracts explicit and testable, reducing silent output drift.
**Status:** Active.

## 2026-01-09 — AOI rotation convention (planned)
**Decision:** Define AOI `rotation_deg` as clockwise from geographic north, applied in the analysis CRS (EPSG:28355).
**Rationale:** Matches common GIS bearing conventions and keeps rotation deterministic after projection.
**Status:** Active.

## 2026-01-09 — Handling user-supplied datasets in `data/`
**Decision:** Treat real-world user datasets under `data/` as runtime inputs (gitignored) and derive any package-included demos as small fixtures in `inst/extdata/`.
**Rationale:** Keeps the repo lightweight, avoids shipping user data by default, and preserves reproducibility through curated fixtures.
**Status:** Active.

## 2026-01-09 — Config schema v2 introduces AOI definition
**Decision:** Bump config schema to v2 and add `data$aoi` (centroid/size/rotation) as the authoritative AOI definition, with a migration from v1 bounding boxes.
**Rationale:** AOI provides a single, reusable spatial frame for mapping and acquisition, and reduces duplicated extent definitions.
**Status:** Active.

## 2026-01-09 — JC dataset effort metrics
**Decision:** Derive `rd` (recording days) from unique observation dates and `obs` from summed counts (or row counts if counts missing) when building a JC-compatible camera site table.
**Rationale:** JC observations are the only guaranteed source in the local dataset; this yields a deterministic effort metric without requiring operational logs.
**Status:** Active.

## 2026-01-09 — AOI auto sizing heuristic
**Decision:** Add `data.aoi.mode = "auto"` to derive AOI size from site bounds plus a buffer, where the default buffer is the median nearest-neighbour distance between sites (scaled and bounded by optional min/max).
**Rationale:** Provides a sensible, camera-scale default extent without hard-coding sizes, while allowing explicit AOI sizes to override the heuristic.
**Status:** Active.

## 2026-01-09 — Imagery caching + provenance sidecars
**Decision:** Remote imagery (WMS and ArcGIS export) writes cached PNGs under `data/cache/` with deterministic keys and a `.yml` provenance sidecar alongside each output.
**Rationale:** Enables reproducible imagery panels, auditability, and offline-safe runs with placeholders.
**Status:** Active.

## 2026-01-09 — Analysis raster resampling policy
**Decision:** Analysis rasters default to nearest-neighbor resampling for categorical layers and bilinear resampling for continuous layers, unless explicitly overridden.
**Rationale:** Preserves class integrity for categorical data while smoothing continuous surfaces appropriately.
**Status:** Active.

## 2026-01-09 — Run-level provenance + attribution outputs
**Decision:** Each canonical run writes a machine-readable run manifest (`outputs/provenance/run_manifest.yml`) and a human-readable attribution report (`outputs/provenance/attribution.md`), alongside a combined layer provenance table.
**Rationale:** Provides traceable, publication-ready metadata for reproducibility and attribution requirements.
**Status:** Active.

## 2026-01-10 — Site attributes output format (long parquet + wide CSV)
**Decision:** Site attribute extraction writes a canonical long table in parquet (via `{arrow}`) and a convenience wide CSV for quick inspection.
**Rationale:** Parquet keeps the primary dataset compact and analysis-ready, while a wide CSV offers a familiar format for spreadsheet and reporting workflows.
**Status:** Active.

## 2026-01-10 — Offline-first network gating via `LOCALMAP_ALLOW_NETWORK`
**Decision:** Network fetches are disabled by default and only run when `LOCALMAP_ALLOW_NETWORK=1` is set; otherwise imagery renders placeholders and ArcGIS vectors require fixtures.
**Rationale:** Keeps CI and offline runs deterministic while still allowing explicit opt-in for live network checks.
**Status:** Active.

## 2026-01-10 — Container bootstrap uses renv restore only
**Decision:** Docker/Apptainer builds run `scripts/bootstrap_container.R`, which performs a renv restore only (no dependency reinstall or roxygen documentation).
**Rationale:** Keeps container builds deterministic and tractable by relying on the lockfile and r2u binaries rather than re-installing the dependency manifest.
**Status:** Active.

## 2026-01-10 — Tasmania canonical layer set (Orthophoto + TASVEG + DEM)
**Decision:** The canonical Tasmania example uses The LIST Orthophoto ArcGIS export, TASVEG 4.0 Groups (WMS for imagery + ArcGIS layer 84 for vectors), and a DEM fixture (with derived slope) for deterministic analysis layers.
**Rationale:** Provides a realistic, Tasmania-focused layer stack while keeping the example reproducible and offline-safe with fixtures where needed.
**Status:** Superseded by the LIST DEM export decision below.

## 2026-01-10 — LIST DEM export with fixture fallback for canonical run
**Decision:** Use The LIST RasterMisc MapServer export (layer 73, DTM 10m) as the canonical DEM source when network access is enabled, with the JC DEM fixture as the offline fallback.
**Rationale:** Aligns the canonical example with a real LIST DEM service while preserving offline reproducibility; the export is a rendered raster, so we coerce it to a single-band surface for demo purposes and retain the fixture for deterministic analysis.
**Status:** Superseded by the 2026-01-11 geodata DEM decision below.

## 2026-01-11 — Geodata DEM for analysis layers (LIST export retained for imagery only)
**Decision:** Switch analysis-layer `tas_dem` to a geodata SRTM DEM (3 arc-second) because the LIST RasterMisc MapServer export delivers rendered imagery only (no raw elevation values), which breaks slope/attribute calculations and misleads previews. Keep the LIST DEM export available for imagery/visual checks and retain the JC DEM fixture for offline CI.
**Rationale:** Ensures numeric DEM values and derived slope/attributes are meaningful while acknowledging the LIST MapServer export cannot provide raw elevation grids.
**Status:** Superseded by the 2026-01-11 GA DEM 1 Second baseline decision below.

## 2026-01-11 — GA DEM 1 Second baseline with SRTM fallback
**Decision:** Use the Geoscience Australia DEM 1 Second (2024) WCS as the default analysis DEM for JC and TAS profiles, with a fallback to geodata SRTM 3 arc-second and optional user-supplied ELVIS 2m DEMs when available.
**Rationale:** The GA DEM provides a national, higher-resolution elevation baseline for Tasmania while retaining a stable global fallback and offline fixtures.
**Status:** Active.

## 2026-01-11 — `dem_variant` config switch for DEM sources
**Decision:** Add a config-level `data.dem_variant` switch to select DEM sources (GA 1s, GA 1s hydro, SRTM 3s/30s, or ELVIS 2m file) and apply overrides to `_dem` analysis layers.
**Rationale:** Keeps DEM selection consistent across profiles without duplicating WCS/paths in every layer definition.
**Status:** Active.
