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

## Addendum (2026-01-11)
- Added GA DEM 1 Second (WCS) as the default analysis DEM source via `raster_wcs`, with SRTM 3s fallback and offline fixtures.
- DEM ingestion now supports `data.dem_variant` overrides so the DEM source stays consistent across profiles.
- Re-ran JC/TAS DEM ingestion and inspected updated previews (`outputs/jc/analysis/raster/jc_dem.png`, `outputs/tas/analysis/raster/tas_dem.png`).
