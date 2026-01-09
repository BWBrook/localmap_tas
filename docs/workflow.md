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
- Do not edit `renv.lock` manually.
- Avoid hidden state:
  - no `setwd()`
  - resolve paths via `here::here()`
- All outputs go to `outputs/` and runtime caches to `data/`.

## 4) Data acquisition rules

- Remote layers must be cached deterministically.
- Remote failures must be explicit (warnings/errors) and never silently produce empty maps.
- Network-dependent tests must be gated (off by default).

## 5) When to ask the human

Write succinct questions into `docs/questions_for_human.md` only when:
- blocked by missing credentials or a required dataset choice,
- a major design fork is ambiguous and costly to reverse,
- repeated attempts fail and you need guidance.

Default is to decide and proceed.
