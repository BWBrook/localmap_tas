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
