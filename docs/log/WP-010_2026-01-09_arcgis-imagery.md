# WP-010 Log — ArcGIS export imagery fetch v1

Date: 2026-01-09

## Summary
- Implemented ArcGIS REST export imagery fetch with deterministic caching and provenance.
- JC profile now exercises live ArcGIS imagery using explicit layer IDs.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-010_2026-01-09_arcgis-imagery/`
  - `outputs/layers/jc/topography_arcgis.png`
  - `outputs/layers/jc/topography_arcgis.png.yml`

## Sanity checks
- Live ArcGIS imagery downloaded for the JC AOI using `layers=show:65` (Elevation Bands).
- Provenance sidecar records request metadata and cache path.

## Notes
- ArcGIS export and WMS follow the same caching/provenance conventions.
