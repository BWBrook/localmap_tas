# WP-019 Log — Raster point extraction v1

Date: 2026-01-10

## Summary
- Extracted raster values at JC camera sites for DEM, slope, NDVI, NBR, and multiband rasters.
- Canonical long table stored as parquet with stable schema and provenance linkage.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-019_2026-01-10_raster-extraction/`
  - `outputs/tables/jc/site_attributes_long.parquet`

## Sanity checks
- Long table has 117 rows (13 sites × 9 attributes per site).
- DEM attribute name is `value`; derived indices use `ndvi` / `nbr`.
- NDVI/NBR values are within expected [-1, 1] ranges for fixtures.

## Notes
- Multiband raster contributes three attributes (`red`, `nir`, `swir2`).
