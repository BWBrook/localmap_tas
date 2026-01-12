# WP-017 Log — Spectral indices v1 (NDVI, NBR)

Date: 2026-01-09

## Summary
- Added NDVI and NBR derivations from a configured multiband raster.
- Outputs cached as GeoTIFF with provenance linking to the source raster and band mapping.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-017_2026-01-09_spectral-indices/`
  - `jc_ndvi.tif`
  - `jc_ndvi.tif.yml`
  - `jc_nbr.tif`
  - `jc_nbr.tif.yml`

## Sanity checks
- NDVI range on JC fixture: ~-0.01 to 0.20 (within [-1, 1]).
- NBR range on JC fixture: ~0.03 to 0.48 (within [-1, 1]).
- Index rasters align with multiband AOI extent.

## Notes
- Division-by-zero handling sets undefined pixels to NA (verified via unit tests).

## Update (2026-01-12)
- Switched `jc_multiband` to DEA Landsat 8/9 geomedian (WCS) with offline fixture fallback.
- NDVI/NBR band mapping now resolves by name (e.g., `nbart_red`, `nbart_nir`, `nbart_swir_2`).
