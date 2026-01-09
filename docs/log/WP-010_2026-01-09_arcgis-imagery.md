# WP-010 Log — ArcGIS export imagery fetch v1

Date: 2026-01-09

## Summary
- Implemented ArcGIS REST export imagery fetch with deterministic caching and provenance.
- Offline mode generates placeholder imagery with warnings.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-010_2026-01-09_arcgis-imagery/`
  - `demo_topography_arcgis.png`
  - `demo_topography_arcgis.png.yml`

## Sanity checks
- Placeholder imagery produced for offline demo profile (layer set to `offline: true`).
- Provenance sidecar records request metadata and cache path.

## Notes
- ArcGIS export and WMS follow the same caching/provenance conventions.
