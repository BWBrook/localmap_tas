# WP-016 Log — Derived slope raster v1

Date: 2026-01-09

## Summary
- Added DEM → slope derivation as a first-class analysis layer with caching and provenance.
- Slope inherits AOI clipping and CRS from the source DEM.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-016_2026-01-09_derived-slope/`
  - `jc_slope.tif`
  - `jc_slope.tif.yml`

## Sanity checks
- Slope raster aligns with DEM extent and AOI.
- Value range on fixture is stable (~4.60–4.61 degrees) with no unexpected NA expansion.

## Notes
- Provenance sidecar references the `jc_dem` source layer via `source_id`.
