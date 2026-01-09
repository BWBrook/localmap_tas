# WP-009 Log — WMS imagery fetch v1

Date: 2026-01-09

## Summary
- Implemented WMS GetMap fetch with deterministic caching and provenance sidecars.
- Offline mode generates placeholder imagery with warnings.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-009_2026-01-09_wms-imagery/`
  - `demo_tasveg_wms.png`
  - `demo_tasveg_wms.png.yml`

## Sanity checks
- Placeholder imagery produced for offline demo profile (layer set to `offline: true`).
- Provenance file records URL, cache key, and output path.

## Notes
- Use `offline: true` in layer config to force placeholders for CI/offline runs.
