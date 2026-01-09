# Roadmap (autonomous work queue)

This file is the **authoritative work queue** for the Codex CLI engineer.
It is written to enable long autonomous runs without “wiggle room”.

---

## 1) Opening contract

### 1.1 What “Follow the roadmap” means
When the human maintainer says **“Follow the roadmap”**, Codex must:

1) Select the **first unchecked** Work Package (WP) in the **Priority Queue** (Section 3), in the order shown.  
2) Complete it **end-to-end**:
   - implementation (code),
   - tests,
   - docs updates,
   - required artefacts,
   - Artefact Review Cycle and log.
3) Mark it complete by:
   - changing `- [ ]` to `- [x]` in the Priority Queue,
   - appending completion metadata inline: `(completed YYYY-MM-DD; evidence: …; canonical run: …)`

Codex must not skip ahead, partially complete multiple WPs, or “bundle” WPs unless the roadmap explicitly says a WP is “Large” and should be done in sub-slices.

### 1.2 Reordering and scope control
Reordering priorities is allowed **only** if:
- a rationale is recorded in `docs/decisions.md`, **and**
- a log entry is created in `docs/log/` describing:
  - what moved,
  - why,
  - what risks this introduces,
  - how success will be measured.

If in doubt, do not reorder: proceed in order.

### 1.3 If the Priority Queue is empty
If **all** WPs in the Priority Queue are checked:
- Codex must stop and report that more work must be promoted into the queue
  (do not invent new WPs silently).

### 1.4 Definitions and conventions
- **WP (Work Package):** the smallest unit of autonomous work. Standard WPs should be sized to fit a single focused session; only a few WPs are marked **Large**.
- **Canonical run folder:** a folder of outputs produced during the WP that serves as the concrete evidence for PI review.
- **Artefact Review Cycle:** build → sanity inspection → interpretation notes → iteration until coherent (see WP-DoD).
- **Schema versioning:** the config schema and output schema are versioned. Breaking changes require explicit migrations and tests.

---

## 2) Work Package Definition of Done (WP-DoD)

A WP is **not complete** until all items below are satisfied.

### 2.1 Acceptance + tests
- All WP acceptance criteria are met.
- Tests exist and pass for the WP’s new/changed behavior.
- Any newly introduced failure modes have explicit, user-actionable errors/warnings.

### 2.2 Documentation update (minimum bar)
Docs must be updated to reflect the WP:
- Config reference (new/changed keys, defaults, examples).
- Interpretation of outputs and assumptions (what the outputs mean; CRS assumptions; layer limitations).

### 2.3 Artefact Review Cycle completed and logged
For each WP, Codex must:
- Generate required artefacts (maps/figures/tables/provenance as relevant).
- Perform a domain sanity inspection (spatial alignment, extent correctness, plausible scale/labels).
- Record inspection notes in a log entry (see evidence requirements).
- Iterate until outputs are coherent.

### 2.4 Schema change discipline
If the WP changes the **config schema**:
- bump `schema_version`,
- provide a migration path (old → new),
- add migration tests.

If the WP changes an **output schema**:
- document the change (what changed, why),
- update/extend regression or sanity tests to lock in the new contract.

### 2.5 Required evidence artefacts
Every WP must create or update:
- a log entry in `docs/log/` (one file per WP is acceptable),
- a canonical run folder under `outputs/canonical_runs/` with the WP’s artefacts (not committed, but present in the ZIP sent to PI),
- a short update in `docs/AGENT_NOTES.md` summarizing what changed and what was inspected.

---

## 3) Priority Queue (strict order)

> Codex must always take the **first unchecked** WP below.

### Line 0.3.x — Baseline autonomy contracts + reproducible JC example
- [x] **WP-001:** Logging + evidence conventions (docs/log + canonical run standard) (completed 2026-01-09; evidence: docs/log/WP-001_2026-01-09_logging-evidence.md; canonical run: outputs/canonical_runs/WP-001_2026-01-09_logging-evidence)  
- [x] **WP-002:** Config schema v1 + validation + config reference doc (completed 2026-01-09; evidence: docs/log/WP-002_2026-01-09_config-schema-v1.md; canonical run: outputs/canonical_runs/WP-002_2026-01-09_config-schema-v1)  
- [x] **WP-003:** JC profile produces coherent maps/figures offline (placeholders allowed) (completed 2026-01-09; evidence: docs/log/WP-003_2026-01-09_demo-offline.md; canonical run: outputs/canonical_runs/WP-003_2026-01-09_demo-offline — JC artefacts)  
- [x] **WP-004:** Output schema v1 (maps/figures/tables/provenance) + regression tests (completed 2026-01-09; evidence: docs/log/WP-004_2026-01-09_output-schema-v1.md; canonical run: outputs/canonical_runs/WP-004_2026-01-09_output-schema-v1)  
- [x] **WP-005:** Packaging hygiene (MIT license consistency, clean check) (completed 2026-01-09; evidence: docs/log/WP-005_2026-01-09_packaging-hygiene.md; canonical run: outputs/canonical_runs/WP-005_2026-01-09_packaging-hygiene)  
- [x] **WP-006:** CI gates v1 (check/test/lint + JC smoke run artefact) (completed 2026-01-09; evidence: docs/log/WP-006_2026-01-09_ci-gates-v1.md; canonical run: outputs/canonical_runs/WP-006_2026-01-09_ci-gates-v1 — JC artefacts)

### Line 0.4.x — Core spatial primitives + imagery panels (publication-first)
- [x] **WP-007:** AOI builder v1 (centroid/extent/rotation) with tests + documented assumptions (completed 2026-01-09; evidence: docs/log/WP-007_2026-01-09_aoi-builder.md; canonical run: outputs/canonical_runs/WP-007_2026-01-09_aoi-builder)  
- [x] **WP-008:** Coverage zone polygon v1 (convex hull + buffer) with tests + optional config (completed 2026-01-09; evidence: docs/log/WP-008_2026-01-09_coverage-zone.md; canonical run: outputs/canonical_runs/WP-008_2026-01-09_coverage-zone)  
- [x] **WP-009:** WMS imagery fetch v1 (GetMap) with caching + provenance + offline fallback (completed 2026-01-09; evidence: docs/log/WP-009_2026-01-09_wms-imagery.md; canonical run: outputs/canonical_runs/WP-009_2026-01-09_wms-imagery)  
- [x] **WP-010:** ArcGIS export imagery fetch v1 with caching + provenance + offline fallback (completed 2026-01-09; evidence: docs/log/WP-010_2026-01-09_arcgis-imagery.md; canonical run: outputs/canonical_runs/WP-010_2026-01-09_arcgis-imagery)  
- [x] **WP-011:** Layer registry v1 (config-driven) + “add a layer” guide (completed 2026-01-09; evidence: docs/log/WP-011_2026-01-09_layer-registry.md; canonical run: outputs/canonical_runs/WP-011_2026-01-09_layer-registry — JC imagery)  
- [x] **WP-012:** Overview map renderer v1 (sites + AOI + scale/north + optional overlays) (completed 2026-01-09; evidence: docs/log/WP-012_2026-01-09_overview-map.md; canonical run: outputs/canonical_runs/WP-012_2026-01-09_overview-map — JC)  
- [x] **WP-013:** Multi-panel figure assembler v1 (labels, layout, PNG+PDF outputs) (completed 2026-01-09; evidence: docs/log/WP-013_2026-01-09_panel-figure.md; canonical run: outputs/canonical_runs/WP-013_2026-01-09_panel-figure — JC)

### Line 0.5.x — Analysis-grade layers (clipped data, not just imagery)
- [ ] **WP-014:** Vector acquisition v1 (AOI-clipped) + cached GeoPackage + provenance  
- [ ] **WP-015:** Raster ingestion v1 (AOI-clipped) + cached GeoTIFF + resampling rules  
- [ ] **WP-016:** Derived rasters v1 (DEM → slope) + categorical-safe resampling policy  
- [ ] **WP-017:** Spectral indices v1 (NDVI, NBR) from configured multiband raster  
- [ ] **WP-018:** Provenance + attribution outputs v1 (machine + human-readable)

### Line 0.6.x — Site attribute extraction (tables for analysis and reporting)
- [ ] **WP-019:** Raster point extraction v1 → canonical long table + tests  
- [ ] **WP-020:** Vector point-in-polygon extraction v1 → canonical long table + tests  
- [ ] **WP-021:** Site attributes “products” v1 (long parquet + convenience wide CSV)  
- [ ] **WP-022:** End-to-end Quarto vignette/report (figures + tables + interpretation)

### Line 0.7.x — Hardening, portability, and realism
- [ ] **WP-023:** Offline-first contract + network-gated tests (explicit, documented)  
- [ ] **WP-024:** Cache correctness audit (deterministic keys; cache hit guarantees)  
- [ ] **WP-025 (Large):** Container parity (Docker and/or Apptainer JC run) + docs  
- [ ] **WP-026:** “Tasmania canonical example” layer set (Orthophoto + TASVEG + DEM) runs end-to-end

### Line 1.0.x — Release readiness
- [ ] **WP-027 (Large):** Public API freeze + docs polish (user-facing)  
- [ ] **WP-028:** Release artefact checklist (tarball + example outputs bundle + changelog)

---

## 4) Detailed WP specs

### WP-001 — Logging + evidence conventions (docs/log + canonical run standard)
**Outcome**  
Create a non-optional, standardised evidence and logging system so each WP produces inspectable artefacts and traceable decisions, enabling reliable PI review by ZIP.

**Scope**
- In scope:
  - Establish `docs/log/` structure and naming conventions for WP logs.
  - Define a canonical run folder convention under `outputs/canonical_runs/`.
  - Define what “evidence” means for maps/figures/tables/provenance.
- Out of scope:
  - Any new mapping features beyond what is needed to demonstrate the conventions.

**Acceptance criteria**
- A documented convention exists for:
  - where WP logs live (`docs/log/`),
  - where Artefact Review notes live (can be within WP log),
  - where canonical run artefacts live (`outputs/canonical_runs/`).
- The conventions are referenced from docs (at minimum `docs/workflow.md` or equivalent).
- At least one example log entry exists demonstrating the structure (can be for WP-001 itself).

**Artefact evidence**
- `docs/log/` directory exists with:
  - a README or index file (short) describing conventions, **or**
  - conventions written directly into `docs/workflow.md` plus a sample WP log file.
- `docs/log/WP-001_*.md` exists and includes:
  - what changed,
  - what artefacts were produced/inspected,
  - sanity-check notes (even if minimal).
- A placeholder canonical run folder exists: `outputs/canonical_runs/WP-001_*` (may be empty, but must exist).

**Stop condition**
- Stop once conventions are written, one example log exists, and the next WP can follow the system without ambiguity.

---

### WP-002 — Config schema v1 + validation + config reference doc
**Outcome**  
Make configuration a stable public interface: versioned, validated, and documented. Codex must not allow “mystery config” to creep in.

**Scope**
- In scope:
  - Introduce a `schema_version` for the config.
  - Define required vs optional config keys for the workflow.
  - Add validation that fails fast with actionable errors when config is invalid.
  - Create/update a config reference doc (e.g., `docs/config_reference.md`).
- Out of scope:
  - Changing feature behavior beyond what validation requires.

**Acceptance criteria**
- Config has an explicit `schema_version` and is validated on pipeline start.
- Missing required keys produce clear, actionable errors (not cryptic stack traces).
- `docs/config_reference.md` exists (or an equivalent single authoritative doc) documenting:
  - all config keys,
  - defaults,
  - expected units (e.g., km vs metres),
  - CRS assumptions.
- If `schema_version` changes within this WP, a migration path and migration tests exist.

**Artefact evidence**
- `docs/config_reference.md` (or named equivalent) exists and is referenced from README.
- Validation tests exist and cover:
  - at least one “valid config” case,
  - at least two “invalid config” cases with expected error messages.
- `docs/log/WP-002_*.md` includes validation decisions and any schema choices.

**Stop condition**
- Stop when schema versioning + validation are in place and config reference is coherent and complete.

---

### WP-003 — JC profile produces coherent maps/figures offline (placeholders allowed)
**Outcome**  
A clean clone can run the JC profile end-to-end without manual downloads, producing coherent map outputs suitable for testing, CI smoke runs, and PI review.

**Scope**
- In scope:
  - A committed JC fixture dataset (small, under `inst/extdata/`).
  - A JC config profile (plus `jc_ci` for offline CI) that produces:
    - an overview map,
    - at least a 2-panel figure.
  - Offline-safe behavior:
    - if remote imagery is unavailable, produce placeholders with warnings (not failure).
- Out of scope:
  - Full fidelity Tasmania layers for the JC profile (those come later).
  - Network-dependent tests enabled by default.

**Acceptance criteria**
- JC profile completes end-to-end on a clean environment with no manual data downloads.
- Outputs are coherent:
  - sites appear within AOI frame,
  - scale/north and basic annotations are present,
  - panel figure has correct panel labeling.
- The run emits warnings (or a structured “offline mode” message) if placeholders were used.
- A minimal Artefact Review Cycle is performed and logged.

**Artefact evidence**
- `inst/extdata/` contains JC fixtures (CSV or GeoPackage).
- Canonical run folder exists: `outputs/canonical_runs/WP-003_*` containing JC outputs:
  - `jc_species_occurrences.png`,
  - `jc_camera_sites.png`,
  - `jc_camera_sites_panel.png`,
  - `jc_camera_sites_tile.png`.
- `docs/log/WP-003_*.md` includes:
  - which outputs were inspected,
  - sanity-check notes (alignment, extent, legibility).

**Stop condition**
- Stop once the JC run reliably produces the required outputs and the artefacts are visually coherent.

---

### WP-004 — Output schema v1 (maps/figures/tables/provenance) + regression tests
**Outcome**  
Define and enforce stable output contracts (paths, filenames, minimal metadata). This prevents drift and allows CI/agents to verify “we got the right things”.

**Scope**
- In scope:
  - Define the output directory structure and required files for:
    - maps/figures,
    - tables (even if stubbed),
    - provenance.
  - Introduce an `output_schema_version`.
  - Add regression/sanity tests that assert outputs exist and are non-trivial.
- Out of scope:
  - Adding new outputs not needed for schema definition.

**Acceptance criteria**
- A single authoritative output schema document exists (e.g., `docs/output_schema.md`) describing:
  - required outputs and their meaning,
  - expected naming,
  - where provenance lives,
  - expected image resolution constraints (e.g., DPI or pixel dimensions).
- Output schema is versioned (explicit version value recorded somewhere stable).
- Tests verify, for the JC profile:
  - required output files exist,
  - image outputs are non-empty and meet minimum dimension constraints,
  - provenance file(s) exist.

**Artefact evidence**
- `docs/output_schema.md` exists and is referenced from README or docs index.
- Test coverage exists for output presence and minimal sanity.
- Canonical run folder: `outputs/canonical_runs/WP-004_*` contains the JC outputs matching the schema.
- `docs/log/WP-004_*.md` records any changes and includes a short “schema rationale”.

**Stop condition**
- Stop when output schema is documented, versioned, and locked in by tests.

---

### WP-005 — Packaging hygiene (MIT license consistency, clean check)
**Outcome**  
Make the project behave like a reliable, distributable R package: correct licensing, clean checks, and no structural foot-guns.

**Scope**
- In scope:
  - Ensure MIT licensing is correct and consistent across DESCRIPTION and license files.
  - Ensure build ignore rules are valid.
  - Ensure package check completes cleanly (warnings triaged and documented).
- Out of scope:
  - Feature additions not required to pass checks.

**Acceptance criteria**
- License is MIT and consistent everywhere it appears.
- Package check passes in the standard development environment.
- Any unavoidable warnings are explicitly documented with rationale and mitigation (ideally none).

**Artefact evidence**
- License files and DESCRIPTION reflect MIT coherently.
- `docs/log/WP-005_*.md` includes:
  - what changed,
  - any check issues found and resolved,
  - any remaining known limitations (if any).

**Stop condition**
- Stop when the package is structurally correct and checks are clean (or consciously triaged).

---

### WP-006 — CI gates v1 (check/test/lint + JC smoke run artefact)
**Outcome**  
Establish CI that enforces correctness and produces artifacts that can be inspected when things break.

**Scope**
- In scope:
  - CI runs:
    - package check,
    - unit tests,
    - linting,
    - JC smoke run (offline-safe via `jc_ci`).
  - CI stores key artefacts (test reports and/or JC outputs) as build artefacts.
- Out of scope:
  - Network-dependent integration tests enabled by default.

**Acceptance criteria**
- CI is present and green on default branch.
- CI runs include a JC smoke run that is offline-safe.
- CI uploads artefacts that include at least:
  - a test summary,
  - JC output images or a small provenance summary.

**Artefact evidence**
- CI configuration exists in repo (workflows).
- `docs/log/WP-006_*.md` includes:
  - what gates are enforced,
  - where to find uploaded artefacts.

**Stop condition**
- Stop when CI gates are in place, reliable, and producing inspectable artefacts.

---

### WP-007 — AOI builder v1 (centroid/extent/rotation) with tests + documented assumptions
**Outcome**  
Users can define an Area of Interest (AOI) reproducibly using a centroid and an extent, with optional rotation, and the AOI behaves consistently across map rendering and layer fetching.

**Scope**
- In scope:
  - AOI defined by:
    - centroid coordinate or “centroid site_id”,
    - width/height (or square size),
    - optional rotation.
  - AOI created in the default analysis CRS.
  - Documented unit conventions (metres/km) and CRS assumptions.
- Out of scope:
  - Complex AOIs (multi-polygons, arbitrary user polygons) beyond a single rectangle/square.

**Acceptance criteria**
- Given a config, AOI is deterministic and stable.
- Rotation is supported and explicitly tested (at least one rotated AOI test).
- AOI assumptions are documented (CRS, units, what “size” means).
- AOI is used consistently by downstream steps (maps and layer requests use the same intended frame).

**Artefact evidence**
- Unit tests cover:
  - unrotated AOI geometry,
  - rotated AOI geometry,
  - centroid chosen from site table.
- `docs/log/WP-007_*.md` includes:
  - examples of AOI definitions,
  - sanity check: sites lie inside AOI.
- Canonical run: `outputs/canonical_runs/WP-007_*` contains at least one AOI debug plot or derived artefact demonstrating rotation.

**Stop condition**
- Stop when AOI behavior is deterministic, tested, and documented.

---

### WP-008 — Coverage zone polygon v1 (convex hull + buffer) with tests + optional config
**Outcome**  
Support an optional “monitoring/coverage zone” polygon derived from a subset of site points (e.g., camera array), suitable for displaying on maps and for reporting approximate monitored area.

**Scope**
- In scope:
  - Coverage polygon derived via:
    - convex hull of selected points,
    - buffer distance (configurable, in metres),
    - area calculation output (m² and km²).
  - Coverage polygon is optional; absence must not break maps.
- Out of scope:
  - Advanced home-range kernels, MCP variants, or density estimation.

**Acceptance criteria**
- Coverage polygon generation is optional and controlled by config.
- When enabled, coverage polygon is:
  - created deterministically,
  - included in overview map output,
  - area is computed and recorded in provenance or a summary table.
- Tests cover:
  - hull creation,
  - buffering,
  - area computation in expected units.

**Artefact evidence**
- Unit tests for hull/buffer/area.
- Canonical run: `outputs/canonical_runs/WP-008_*` includes an overview map with the coverage polygon visible.
- Log includes sanity notes about polygon location and plausible area.

**Stop condition**
- Stop when coverage polygon is optional, tested, visible in maps, and its area is recorded.

---

### WP-009 — WMS imagery fetch v1 (GetMap) with caching + provenance + offline fallback
**Outcome**  
Provide a robust WMS imagery acquisition path for map panels, with deterministic caching and provenance so maps can be reproduced and audited.

**Scope**
- In scope:
  - WMS GetMap request builder supports:
    - AOI bbox,
    - requested output size,
    - CRS selection appropriate for imagery,
    - layer selection and styles.
  - Caching:
    - deterministic cache key from request parameters,
    - cache reuse.
  - Provenance:
    - record URL, parameters, timestamp, cache path.
  - Offline fallback:
    - if request fails, produce a placeholder image with a warning.
- Out of scope:
  - WMS feature info; WFS; complex style negotiation.

**Acceptance criteria**
- For a configured WMS layer:
  - imagery artefact is produced (real or placeholder, depending on connectivity),
  - cache behavior is deterministic and documented.
- Provenance file exists for each imagery artefact.
- Tests cover:
  - request builder determinism,
  - cache key determinism,
  - placeholder behavior when fetch is disabled or fails.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-009_*` includes:
  - at least one WMS panel image artefact,
  - at least one corresponding provenance sidecar.
- Log includes:
  - whether real imagery or placeholder was used,
  - sanity notes about alignment and labeling.

**Stop condition**
- Stop when WMS imagery fetch works end-to-end with caching, provenance, and offline fallback.

---

### WP-010 — ArcGIS export imagery fetch v1 with caching + provenance + offline fallback
**Outcome**  
Provide an ArcGIS REST “export image” acquisition path for basemaps/imagery, matching the same caching and provenance standards as WMS.

**Scope**
- In scope:
  - ArcGIS export requests with:
    - AOI bbox in the appropriate CRS,
    - output size parameters,
    - format choices (PNG is sufficient for v1).
  - Deterministic caching and provenance.
  - Offline fallback placeholders.
- Out of scope:
  - ArcGIS feature queries (handled later in vector acquisition WP).

**Acceptance criteria**
- For a configured ArcGIS export layer:
  - imagery artefact is produced (real or placeholder),
  - provenance sidecar exists.
- Cache reuse occurs (second run does not re-download when cache present).
- Tests cover:
  - request builder,
  - cache key stability,
  - failure/placeholder behavior.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-010_*` includes:
  - at least one ArcGIS export panel,
  - provenance sidecar.
- Log includes a short comparison of ArcGIS export vs WMS behavior (what’s different, what’s the same).

**Stop condition**
- Stop when ArcGIS export imagery fetch is reliable and consistent with WMS conventions.

---

### WP-011 — Layer registry v1 (config-driven) + “add a layer” guide
**Outcome**  
Users can add/modify layers and panels via config without editing code, using a stable “layer registry” model that supports multiple acquisition types.

**Scope**
- In scope:
  - A config-driven registry with:
    - layer IDs (stable),
    - acquisition type (WMS vs ArcGIS export vs file),
    - parameters,
    - attribution metadata (source/credit/license strings).
  - A clear “how to add a layer” guide.
- Out of scope:
  - Automatically discovering capabilities of remote services.

**Acceptance criteria**
- Config supports declaring multiple layers with stable IDs.
- At least two acquisition types are supported via registry (from earlier WPs).
- Documentation explains, in concrete terms:
  - required fields for a layer entry,
  - attribution expectations,
  - how to attach a layer to a panel.
- Tests verify that:
  - registry entries are validated,
  - missing fields produce actionable errors.

**Artefact evidence**
- `docs/layers_guide.md` (or equivalent) exists and is referenced.
- Canonical run: `outputs/canonical_runs/WP-011_*` includes:
  - `jc_tasveg_wms.png`,
  - `jc_topography_arcgis.png`.
- Log includes: “added/validated registry model; verified by JC imagery outputs”.

**Stop condition**
- Stop when layers are configurable without code edits and the guide is unambiguous.

---

### WP-012 — Overview map renderer v1 (sites + AOI + scale/north + optional overlays)
**Outcome**  
Produce a publication-ready single “overview” map panel: basemap + sites + optional AOI/coverage + consistent annotations.

**Scope**
- In scope:
  - Rendering an overview map that includes:
    - site points (with configurable labels),
    - AOI outline,
    - optional coverage polygon,
    - scale bar and north arrow,
    - optional simple overlays if available (e.g., locality labels or roads).
  - Output resolution and dimensions controlled by config.
- Out of scope:
  - Complex cartographic styling or custom typography beyond baseline.

**Acceptance criteria**
- Overview map output exists for JC and is visually coherent.
- Baseline cartographic elements present (scale + north).
- Labels are legible and configurable (on/off, size, offset).
- Artefact Review Cycle includes a sanity inspection of alignment and legibility.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-012_*` includes `overview_map.png` (JC profile).
- Output schema tests (from WP-004) pass for the overview map.
- Log includes at least:
  - a bullet on label legibility,
  - a bullet on AOI/coverage correctness,
  - a bullet on any known limitations.

**Stop condition**
- Stop when overview map meets acceptance criteria and is stable under JC config.

---

### WP-013 — Multi-panel figure assembler v1 (labels, layout, PNG+PDF outputs)
**Outcome**  
Generate a multi-panel figure suitable for manuscripts, with deterministic layout, panel labels, and consistent dimensions.

**Scope**
- In scope:
  - Assemble at least a 2×2 (or configurable) panel figure.
  - Panel labels (a, b, c, …) with consistent placement.
  - Output PNG and PDF (PDF optional if not feasible; if omitted, document why).
- Out of scope:
  - Journal-specific theme packs.

**Acceptance criteria**
- Multi-panel figure is produced deterministically.
- Panel order is deterministic (registry order or explicit panel list).
- Labels appear correctly and are legible.
- Tests verify:
  - output exists,
  - minimum dimensions,
  - deterministic panel ordering.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-013_*` includes:
  - `panel_figure.png` (JC profile),
  - `panel_figure.pdf` (JC profile).
- Log includes:
  - sanity check that labels correspond to intended panels,
  - quick note on whether legends overlap or clutter.

**Stop condition**
- Stop once panel assembly is stable, deterministic, and produces the required outputs.

---

### WP-014 — Vector acquisition v1 (AOI-clipped) + cached GeoPackage + provenance
**Outcome**  
Acquire analysis-grade vector data clipped to AOI and store as a cached GeoPackage with provenance, enabling attribute extraction and vector-based mapping.

**Scope**
- In scope:
  - At least one vector acquisition path (prefer ArcGIS feature query where feasible).
  - AOI clipping performed deterministically.
  - Cached GeoPackage output and provenance metadata.
  - Offline-safe tests using fixtures (network use gated).
- Out of scope:
  - Bulk downloads of entire statewide datasets by default.

**Acceptance criteria**
- A configured vector layer can be acquired (or stubbed under offline mode) and results in:
  - an AOI-clipped GeoPackage in cache,
  - provenance sidecar.
- Tests cover:
  - clipping correctness on fixture geometries,
  - schema stability (expected fields preserved).

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-014_*` includes:
  - at least one cached GeoPackage artefact (may be fixture-based),
  - provenance sidecar.
- Log includes:
  - sanity check that vector extent matches AOI,
  - note on categorical fields and CRS.

**Stop condition**
- Stop when vector acquisition is usable for downstream extraction and mapping.

---

### WP-015 — Raster ingestion v1 (AOI-clipped) + cached GeoTIFF + resampling rules
**Outcome**  
Support analysis-grade raster ingestion (from local file paths and/or remote COG when feasible), clipped to AOI and cached as GeoTIFF with explicit resampling rules.

**Scope**
- In scope:
  - Raster ingestion path that produces:
    - AOI-clipped raster,
    - cached GeoTIFF,
    - provenance sidecar.
  - Explicit resampling rules:
    - nearest neighbor for categorical rasters,
    - bilinear/cubic for continuous rasters (policy documented).
  - Offline tests using fixture rasters.
- Out of scope:
  - Managing extremely large rasters without AOI clipping.

**Acceptance criteria**
- Raster ingestion produces an AOI-clipped GeoTIFF that is:
  - in the expected analysis CRS,
  - aligned with AOI extent.
- Resampling rules are documented and applied consistently.
- Tests cover:
  - categorical vs continuous resampling policy using fixtures,
  - output CRS and extent sanity.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-015_*` includes:
  - at least one clipped GeoTIFF,
  - provenance sidecar.
- Log includes a brief rationale for resampling choices.

**Stop condition**
- Stop once raster ingestion is reliable and policy is documented and tested.

---

### WP-016 — Derived rasters v1 (DEM → slope) + categorical-safe resampling policy
**Outcome**  
Enable derived raster products (starting with slope from DEM) as first-class layers with provenance and tests.

**Scope**
- In scope:
  - Derived slope (degrees) from DEM.
  - Derived layer treated as a layer in registry/pipeline.
  - Document assumptions (units, method).
- Out of scope:
  - Full terrain suite (aspect, curvature) unless easy follow-on.

**Acceptance criteria**
- Given a DEM raster layer, slope layer can be produced deterministically.
- Derived layer has provenance that references the source DEM.
- Tests cover:
  - slope output exists,
  - plausible value range and NA handling on fixtures.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-016_*` includes:
  - a slope GeoTIFF,
  - provenance linking slope to DEM.
- Log includes sanity check on slope range and spatial alignment.

**Stop condition**
- Stop once slope derivation is stable, documented, and tested.

---

### WP-017 — Spectral indices v1 (NDVI, NBR) from configured multiband raster
**Outcome**  
Support NDVI and NBR derivation from a configured multiband raster source, producing analysis-grade outputs and enabling extraction at sites.

**Scope**
- In scope:
  - NDVI and NBR derived from a multiband raster with band mapping specified in config.
  - Outputs cached as rasters with provenance.
  - Tests using small fixture multiband rasters.
- Out of scope:
  - Automated cloud masking, time series processing, or full Landsat workflows.

**Acceptance criteria**
- Given a configured multiband raster and band mapping:
  - NDVI raster is produced,
  - NBR raster is produced,
  - provenance references the source raster and band mapping.
- Tests cover:
  - correct handling of division by zero,
  - plausible output ranges on fixtures.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-017_*` includes:
  - NDVI GeoTIFF,
  - NBR GeoTIFF,
  - provenance sidecars.
- Log includes sanity check on value ranges and NA patterns.

**Stop condition**
- Stop once indices are reproducible, tested, and integrated as derived layers.

---

### WP-018 — Provenance + attribution outputs v1 (machine + human-readable)
**Outcome**  
Produce strong provenance that supports scientific reproducibility and publication attribution for maps/figures/tables.

**Scope**
- In scope:
  - A machine-readable run manifest:
    - config snapshot or hash,
    - layer list with sources and parameters,
    - timestamps,
    - schema versions.
  - A human-readable attribution snippet suitable for figure captions/acknowledgements.
- Out of scope:
  - Automated DOI citation generation beyond basic metadata.

**Acceptance criteria**
- For each canonical run, provenance outputs include:
  - a machine-readable manifest (JSON/YAML),
  - a human-readable attribution file (Markdown/text).
- Layer attribution metadata is required/validated for configured layers intended for publication output.
- Tests verify:
  - manifest exists and includes required fields,
  - attribution file exists and includes layer IDs and sources.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-018_*` includes provenance outputs.
- Log includes:
  - note on what attribution text looks like,
  - any known gaps to resolve later.

**Stop condition**
- Stop once provenance outputs are present, validated, and useful for publication documentation.

---

### WP-019 — Raster point extraction v1 → canonical long table + tests
**Outcome**  
Extract raster values at site points into a tidy, canonical long-format table suitable for analysis and reproducibility.

**Scope**
- In scope:
  - Raster extraction at points for configured raster layers.
  - Canonical long table design (stable schema).
  - Tests using fixture rasters and sites.
- Out of scope:
  - Complex spatial summaries (buffers, zonal stats) unless explicitly added later.

**Acceptance criteria**
- A canonical long table is produced with at least:
  - `site_id`, `layer_id`, `attribute_name`, `value`, `units` (when known), and provenance linkage.
- Missing data is represented explicitly (NA) and does not silently drop sites.
- Tests cover:
  - row counts (sites × layers expectations),
  - data types and NA handling.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-019_*` includes:
  - `site_attributes_long.parquet` (or equivalent),
  - a small preview CSV is acceptable if parquet is not yet introduced.
- Log includes sanity checks:
  - values look plausible,
  - sites not unexpectedly missing.

**Stop condition**
- Stop when raster extraction produces a stable, tested long table and is integrated into pipeline.

---

### WP-020 — Vector point-in-polygon extraction v1 → canonical long table + tests
**Outcome**  
Extract vector polygon attributes at site points (point-in-polygon) into the same canonical long table model.

**Scope**
- In scope:
  - For configured polygon vector layers:
    - determine containing polygon for each site,
    - extract specified attribute fields.
  - Handle no-hit cases explicitly (NA with reason).
  - Tests using fixture polygons and sites.
- Out of scope:
  - Multi-hit resolution strategies beyond “first match” or clearly documented rule.

**Acceptance criteria**
- Vector extraction appends rows into the canonical long table with:
  - stable field naming,
  - explicit NA behavior when a site is outside polygons.
- Tests cover:
  - correct extraction on fixtures,
  - explicit NA behavior.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-020_*` includes updated long table including vector-derived attributes.
- Log includes sanity notes:
  - categorical values look plausible,
  - no-hit behavior observed and acceptable.

**Stop condition**
- Stop when vector extraction works end-to-end and is tested.

---

### WP-021 — Site attributes “products” v1 (long parquet + convenience wide CSV)
**Outcome**  
Turn extraction results into stable, user-consumable output products: a canonical long table plus a convenience wide table.

**Scope**
- In scope:
  - Canonical long table stored in an efficient format (parquet preferred).
  - Convenience wide CSV produced deterministically from the long table.
  - Output schema documented and tested.
- Out of scope:
  - Custom user-defined pivoting beyond the deterministic wide output.

**Acceptance criteria**
- Outputs exist under the defined output schema:
  - `site_attributes_long.parquet` (canonical),
  - `site_attributes_wide.csv` (convenience).
- Wide table has:
  - one row per site,
  - deterministic column naming derived from layer_id + attribute_name.
- Regression tests lock down:
  - required columns,
  - row counts,
  - deterministic ordering.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-021_*` includes both long and wide products.
- Output schema doc updated to include these tables.
- Log includes a short note on how wide column names are formed and why.

**Stop condition**
- Stop when both tables exist, are documented, and are protected by tests.

---

### WP-022 — End-to-end Quarto vignette/report (figures + tables + interpretation)
**Outcome**  
Provide a single end-to-end narrative example showing how to configure, run, and interpret outputs (maps + attribute tables) for a local site mapping workflow.

**Scope**
- In scope:
  - One Quarto doc that:
    - explains config inputs,
    - shows generated overview map and panel figure,
    - shows extracted attributes table (preview),
    - explains provenance and attribution outputs.
  - The doc must be reproducible under the JC profile.
- Out of scope:
  - Multiple vignettes; keep to one canonical example.

**Acceptance criteria**
- The doc renders successfully in the standard workflow.
- It includes:
  - at least one figure (overview or panels),
  - at least one table preview (attributes),
  - interpretation text that explains what a user should look for.
- Artefact Review Cycle is logged for the final outputs.

**Artefact evidence**
- Quarto source file exists under docs/reports structure (repo convention).
- Canonical run: `outputs/canonical_runs/WP-022_*` includes:
  - rendered HTML/PDF (as configured),
  - referenced figures/tables.
- Log includes inspection notes about figure/table coherence.

**Stop condition**
- Stop when the vignette is reproducible, coherent, and demonstrates the full workflow.

---

### WP-023 — Offline-first contract + network-gated tests (explicit, documented)
**Outcome**  
Make offline behavior explicit, predictable, and tested. Network functionality must exist but be gated to avoid flaky CI.

**Scope**
- In scope:
  - A documented contract for:
    - offline default behavior,
    - how to enable network fetch,
    - what happens on network failure.
  - Network-dependent tests are gated behind an explicit opt-in.
- Out of scope:
  - Guaranteeing remote service uptime.

**Acceptance criteria**
- Offline mode is the default behavior for CI and JC runs.
- When network fetch is enabled:
  - remote imagery/vector acquisition can be verified manually,
  - results are recorded in a log.
- Tests verify:
  - offline placeholder generation works and does not fail the pipeline,
  - gating mechanism prevents accidental network calls in CI.

**Artefact evidence**
- Docs updated describing offline/network modes and how to interpret warnings.
- Canonical run: `outputs/canonical_runs/WP-023_*` includes an offline run artefact set.
- Log includes:
  - offline run inspection,
  - optional manual network verification notes (if performed).

**Stop condition**
- Stop when offline behavior is deterministic and network tests are gated and documented.

---

### WP-024 — Cache correctness audit (deterministic keys; cache hit guarantees)
**Outcome**  
Ensure that caching is correct, deterministic, and testable—so repeated runs do not re-fetch and do not silently drift.

**Scope**
- In scope:
  - Deterministic cache keys for each layer acquisition type.
  - Tests that assert cache hit behavior for stable requests.
  - Document cache invalidation strategy (manual clear or versioned).
- Out of scope:
  - Sophisticated cache eviction or LRU.

**Acceptance criteria**
- For stable requests, cache key does not change across runs.
- Tests cover:
  - cache key determinism,
  - cache hit behavior (no re-fetch) under controlled conditions.
- Cache invalidation is documented (how a user forces a refresh).

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-024_*` includes:
  - cached artefacts,
  - provenance showing stable request fingerprints.
- Log includes:
  - short “cache audit” summary,
  - any remaining known risks.

**Stop condition**
- Stop when caching is demonstrably deterministic and protected by tests.

---

### WP-025 (Large) — Container parity (Docker and/or Apptainer JC run) + docs
**Outcome**  
Demonstrate that the workflow can run reproducibly in a container environment suitable for collaborators, CI, or HPC contexts.

**Scope**
- In scope:
  - Container run for the JC profile produces the same required outputs.
  - Container docs explain how to run and where outputs appear.
- Out of scope:
  - Optimising container size or multi-arch builds unless required.

**Acceptance criteria**
- At least one container pathway (Docker or Apptainer) runs the JC workflow end-to-end and produces:
  - overview map,
  - panel figure,
  - provenance outputs.
- Differences vs local execution are documented (paths, permissions, performance).
- Artefact Review Cycle is performed on container outputs.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-025_*` includes outputs produced from container execution (clearly labeled).
- Log includes:
  - command summary in prose (not code block required),
  - sanity inspection notes,
  - any limitations.

**Stop condition**
- Stop when one container pathway is validated and documented for the JC workflow.

---

### WP-026 — “Tasmania canonical example” layer set (Orthophoto + TASVEG + DEM) runs end-to-end
**Outcome**  
Provide a canonical Tasmania-focused configuration that matches typical ecological mapping needs and demonstrates real layer usage (where feasible), without breaking offline defaults.

**Scope**
- In scope:
  - A canonical example layer set including:
    - Orthophoto basemap (imagery),
    - TASVEG (vector),
    - DEM (raster) and optionally slope derived output.
  - The canonical set runs end-to-end with:
    - maps/panels,
    - provenance,
    - (optional) extraction products if already available.
  - Network usage remains gated; offline still works with placeholders/fixtures.
- Out of scope:
  - Adding every possible LIST layer.

**Acceptance criteria**
- A documented canonical config profile exists for Tasmania mapping.
- Running that profile produces coherent outputs with the intended layer set (real or fixture-backed depending on connectivity).
- Provenance and attribution outputs enumerate those layers clearly.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-026_*` includes:
  - maps/panels demonstrating the canonical layer set,
  - provenance + attribution outputs.
- Log includes:
  - sanity inspection notes about alignment between layers (veg polygons vs basemap, DEM-derived slope alignment, etc.).

**Stop condition**
- Stop when the canonical example profile exists, is documented, and yields coherent artefacts.

---

### WP-027 (Large) — Public API freeze + docs polish (user-facing)
**Outcome**  
Make the package feel “real” to external users: stable exported API, clean docs, and a coherent README quickstart aligned with the actual workflow.

**Scope**
- In scope:
  - Decide and document the minimal exported API surface.
  - Ensure documentation is accurate and complete for:
    - installation,
    - configuration,
    - running workflows,
    - interpreting outputs,
    - attribution.
- Out of scope:
  - Major feature expansion; this is a stabilization WP.

**Acceptance criteria**
- Exported API surface is explicitly documented and stable.
- README quickstart works against JC config/profile.
- Docs site or docs index is coherent and cross-linked.
- Changelog entries exist for user-visible behavior changes up to this point.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-027_*` includes at least the JC outputs and the rendered documentation artefact (if applicable).
- Log includes:
  - list of exported functions (names only),
  - sanity check that docs match actual behavior.

**Stop condition**
- Stop when user-facing docs are coherent and API changes are intentionally frozen.

---

### WP-028 — Release artefact checklist (tarball + example outputs bundle + changelog)
**Outcome**  
Make releases repeatable: versioning, changelog discipline, and a standard release artefact set that can be attached to a GitHub release by the human.

**Scope**
- In scope:
  - Ensure release checklist is satisfied.
  - Produce:
    - source tarball,
    - example outputs bundle (canonical run artefacts),
    - release notes from changelog.
- Out of scope:
  - Publishing to CRAN unless explicitly requested later.

**Acceptance criteria**
- Release checklist items are satisfied and documented.
- A release bundle can be created reproducibly from a clean environment.
- Changelog follows a consistent format and includes release notes for the release.

**Artefact evidence**
- Canonical run: `outputs/canonical_runs/WP-028_*` includes:
  - built package artefact(s),
  - example outputs bundle,
  - release notes text file.
- Log includes:
  - confirmation checklist completed,
  - any remaining known limitations (if any).

**Stop condition**
- Stop once the release artefacts and checklist are complete and reproducible.

---

## 5) Milestone/review gates (when Codex must stop for PI ZIP review)

Codex must stop and request a PI ZIP review when any of the following occur:

### 5.1 End-of-line gates (mandatory)
- After completing **Line 0.3.x** (WP-001 through WP-006).
- After completing **Line 0.4.x** (WP-007 through WP-013).
- After completing **Line 0.5.x** (WP-014 through WP-018).
- After completing **Line 0.6.x** (WP-019 through WP-022).
- After completing **Line 0.7.x** (WP-023 through WP-026).
- After completing **Line 1.0.x** (WP-027 through WP-028).

### 5.2 Safety gates (must stop immediately)
Stop and request PI review ZIP immediately if:
- `schema_version` is bumped, or output schema version changes (to confirm contracts),
- a major dependency change is introduced (especially spatial system deps),
- CI policy changes meaningfully (new gates or gating strategy),
- the agent encounters persistent spatial sanity concerns (misalignment, CRS confusion) that are not trivially resolved.

### 5.3 What the PI ZIP must contain
- The full repo snapshot at a clean commit.
- `docs/log/` updated for all completed WPs in the line.
- `docs/AGENT_NOTES.md` updated with a short summary of the line.
- `outputs/canonical_runs/` containing the canonical run folders for all WPs completed since the last PI review gate.

If outputs are too large, include at minimum:
- the final canonical run folder for the line,
- plus a small “index” text file listing omitted artefacts and how to regenerate them.
