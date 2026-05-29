# Workflow (how work must be done in this repo)

This workflow is mandatory for the Codex CLI engineer and is also recommended for human contributors.

## 1) Core loop

1. Update plan and scope:
   - Keep `docs/roadmap.md` current (what is “in scope” right now).
   - Record any major design choices in `docs/decisions.md`.

2. Implement incrementally:
   - Keep `_targets.R` thin; implement logic in `R/`.
   - Prefer small, composable functions.

3. Verify technically:
   - Run unit tests and lint.
   - Ensure the demo profile runs end-to-end.
   - Use the QA bootstrap before lint/package checks.

4. Verify scientifically (Artefact Review Cycle):
   - Generate maps/panels/tables.
   - Inspect them and write interpretation notes.
   - Iterate until outputs are coherent.

5. Document:
   - Update README and relevant docs when behavior/config changes.
   - Add changelog entries for user-facing changes.
   - Record WP evidence in `docs/log/` and create canonical run folders under
     `outputs/canonical_runs/` (see `docs/log/README.md`).

## 2) Artefact Review Cycle (maps are “results”)

For any mapping-related change:

### 2.1 Build artefacts
Generate:
- overview map(s)
- panel figure(s)
- optional attribute tables
- provenance files

### 2.2 Sanity checks (domain-level)
Confirm:
- site points are inside the AOI
- basemap and overlays align (no obvious offsets)
- scale bar distance is plausible for AOI size
- north arrow behaves sensibly
- legends/labels match configuration
- output resolution matches expectations (e.g., 300 DPI)

### 2.3 Interpretation notes
Add a short section to `docs/AGENT_NOTES.md`:
- what the map shows
- what looks wrong
- what you will change next

Also add a WP log entry in `docs/log/` with:
- artefacts inspected,
- sanity/interpretation notes,
- canonical run folder path.

### 2.4 Iterate
Fix and repeat until coherent.

## 3) Reproducibility rules

- All dependencies are managed via `renv`.
- The current Mac mini baseline is Homebrew R 4.6.0; use the repo Makefile or
  `Rscript` on `PATH` unless a future lockfile deliberately says otherwise.
- Do not edit `renv.lock` manually.
- Avoid hidden state:
  - no `setwd()`
  - resolve paths via `here::here()`
- All outputs go to `outputs/` and runtime caches to `data/`.

### Container builds
- Use `scripts/bootstrap_container.R` for Docker/Apptainer images (renv restore only).
- The container bootstrap prefers r2u binaries to keep build times reasonable.
- The container run should mount `data/` from the host when using local datasets (e.g., `data/raw/jc_camera_study/`).

### macOS prerequisites
- On macOS, install the required Homebrew geospatial/runtime stack before the
  first restore:
  - `brew install gdal geos proj udunits apache-arrow`
- `scripts/bootstrap.R` and `make bootstrap-qa` now preflight these tools and
  stop early with an actionable message if they are missing.

### Local datasets
- Real-world datasets belong under `data/` (gitignored).
- The Judbury camera study example lives at `data/raw/jc_camera_study/`.
- Use profile `jc` to derive a compatible camera-site table at `data/interim/jc_camera_sites.csv`.
- Simplified run (recommended for new users):
  - Copy `settings.example.yaml` to `settings.yaml` and edit the paths/toggles.
  - Run `Rscript scripts/run_project.R settings.yaml` (writes a run-specific config in `outputs/<project>/run_config.yaml`).
- Minimal JC run:
  - `R_CONFIG_ACTIVE=jc TARGETS_PROFILE=ci Rscript -e 'targets::tar_make(names = c(\"camera_sites_file\",\"camera_sites_data\",\"aoi\",\"aoi_debug_plot\",\"species_map\"))'`
  - JC fixtures: `inst/extdata/occurrences_jc.csv` with species list `metadata/species_requests_jc.csv`.
- Offline JC run for CI:
  - `R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci make pipeline`
- Tasmania canonical example (LIST orthophoto + TASVEG + LIST DEM export with fixture fallback; optional roads/localities overlays):
  - `R_CONFIG_ACTIVE=tas_canonical LOCALMAP_ALLOW_NETWORK=1 Rscript -e 'targets::tar_make()'`
  - Offline/CI-safe variant: `R_CONFIG_ACTIVE=tas_canonical_ci TARGETS_PROFILE=ci Rscript -e 'targets::tar_make()'`

## 4) Data acquisition rules

- Remote layers must be cached deterministically.
- Remote failures must be explicit (warnings/errors) and never silently produce empty maps.
- Network-dependent tests must be gated (off by default).
- See `docs/layers_guide.md` for adding WMS/ArcGIS/file layers via the registry.

### Offline/network contract
- Offline mode is the default for CI and fixture profiles (`demo`, `jc_ci`).
- `jc_ci` and `tas_canonical_ci` are clean-clone profiles and must use packaged
  camera-site/vector fixtures rather than raw files under `data/`.
- Network fetches are disabled unless `LOCALMAP_ALLOW_NETWORK=1` is set.
- When network is disabled, imagery fetches fall back to placeholders with a warning.
- ArcGIS vector layers must provide a `fixture_path` when offline; otherwise the run fails with an actionable error.
- Large downloads (e.g., canopy height) are gated by `LOCALMAP_ALLOW_LARGE_DOWNLOADS`; when disabled, placeholder rasters are written with a warning and no cache is saved.

## 5) When to ask the human

Write succinct questions into `docs/questions_for_human.md` only when:
- blocked by missing credentials or a required dataset choice,
- a major design fork is ambiguous and costly to reverse,
- repeated attempts fail and you need guidance.

Default is to decide and proceed.

## 6) QA command set

Recommended command sequence for QA-enabled environments:

- `make bootstrap-qa`
- `make actionlint`
- `make lint`
- `make test`
- `R_CONFIG_ACTIVE=demo TARGETS_PROFILE=ci Rscript -e 'targets::tar_make()'`
- `R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci make pipeline`
- `R_CONFIG_ACTIVE=tas_canonical_ci TARGETS_PROFILE=ci make pipeline`
- `make check`

### CI environment notes
- GitHub Actions provisions the system libraries required by the QA bootstrap:
  - `libudunits2-dev` for `{units}`
  - `libproj-dev`, `libgdal-dev`, and `libgeos-dev` for `{sf}`
  - `libglpk-dev` for `{igraph}`
- GitHub Actions provisions Pandoc via `r-lib/actions/setup-pandoc@v2` so `R CMD check` can rebuild the package vignette.
- Validate workflow edits locally with `make actionlint` before pushing CI changes.
