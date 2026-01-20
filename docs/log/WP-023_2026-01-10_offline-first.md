# WP-023 Log — Offline-first contract + network gating

Date: 2026-01-10

## Summary
- Added `LOCALMAP_ALLOW_NETWORK` gating: network fetches are disabled by default.
- Imagery fetches fall back to placeholders with explicit warnings when network is disabled.
- Added tests confirming offline placeholders and gating, plus an opt-in network test.
- Documented offline/network contract in workflow + config reference.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-023_2026-01-10_offline-first/`
  - `outputs/jc/layers/tasveg_wms.png` + `.yml`
  - `outputs/jc/layers/topography_arcgis.png` + `.yml`
  - `jc_overview_map.png`
  - `jc_panel_figure.png` + `.pdf`
  - `jc_camera_sites.png`
  - `jc_species_occurrences.png`

## Sanity checks
- Offline imagery files are placeholders with provenance `status: offline_placeholder`.
- Overview/panel figures render with JC AOI and sites; imagery overlays are blank as expected.

## Notes
- To enable live network fetches, set `LOCALMAP_ALLOW_NETWORK=1` before running the pipeline.
