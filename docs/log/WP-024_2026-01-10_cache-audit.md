# WP-024 Log — Cache correctness audit

Date: 2026-01-10

## Summary
- Added cache-hit test for analysis layers and explicit cache invalidation notes.
- Verified deterministic cache keys by re-running analysis layers and observing cache hits.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-024_2026-01-10_cache-audit/`
  - `jc_habitats.gpkg.yml`
  - `jc_dem.tif.yml`
  - `jc_slope.tif.yml`
  - `jc_ndvi.tif.yml`
  - `jc_nbr.tif.yml`

## Sanity checks
- Provenance sidecars show `status: cache_hit` after invalidating the target and re-running.
- Cache keys remain stable for identical AOI + layer params.

## Notes
- Cache invalidation is documented: delete `data/cache/` or change cache_dir / cache version.
