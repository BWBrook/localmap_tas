# WP-011 Log — Layer registry v1

Date: 2026-01-09

## Summary
- Added config-driven layer registry with validation and attribution.
- Added `docs/layers_guide.md` describing how to add layers.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-011_2026-01-09_layer-registry/`
  - `jc_tasveg_wms.png`
  - `jc_topography_arcgis.png`

## Sanity checks
- Layer registry validated on config load; missing fields produce actionable errors.
- JC layers return live imagery for the camera-scale AOI.

## Notes
- Registry supports `wms`, `arcgis_export`, and `file` layers.
