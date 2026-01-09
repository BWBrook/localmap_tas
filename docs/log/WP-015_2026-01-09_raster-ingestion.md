# WP-015 Log — Raster ingestion v1

Date: 2026-01-09

## Summary
- Added AOI-clipped raster ingestion with cached GeoTIFF outputs and provenance sidecars.
- Resampling policy documented and enforced (categorical = nearest neighbour, continuous = bilinear by default).

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-015_2026-01-09_raster-ingestion/`
  - `jc_dem.tif`
  - `jc_dem.tif.yml`

## Sanity checks
- DEM extent aligns with AOI in EPSG:28355 (approx 494925–495891 E, 5238883–5239744 N).
- Continuous raster resampling uses bilinear interpolation (categorical defaults verified in unit tests).

## Notes
- Multiband raster ingestion uses the same clipping + resampling path, enabling downstream indices.
