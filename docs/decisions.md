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
