# WP-018 Log — Provenance + attribution outputs v1

Date: 2026-01-09

## Summary
- Added run-level provenance outputs: combined layer table, human-readable attribution, and run manifest.
- Manifest includes config hash, output schema hash, and per-layer metadata.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-018_2026-01-09_provenance-attribution/`
  - `analysis_layers.csv`
  - `attribution.md`
  - `run_manifest.yml`

## Sanity checks
- `analysis_layers.csv` enumerates imagery + analysis layers with attribution and cache paths.
- `attribution.md` lists imagery and analysis sources with licenses/credits.
- `run_manifest.yml` captures config hash, schema version, and layer parameters.

## Notes
- Attribution text is ready for figure captions; update layer credit strings as sources evolve.
