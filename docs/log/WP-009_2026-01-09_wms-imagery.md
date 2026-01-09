# WP-009 Log — WMS imagery fetch v1

Date: 2026-01-09

## Summary
- Implemented WMS GetMap fetch with deterministic caching and provenance sidecars.
- JC profile now exercises live WMS imagery (placeholder still available via `offline: true`).
- Fixed cache key/provenance generation to preserve parameter names in sidecars.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-009_2026-01-09_wms-imagery/`
  - `jc_tasveg_wms.png`
  - `jc_tasveg_wms.png.yml`

## Sanity checks
- Live WMS imagery downloaded for the JC AOI (LIST TASVEG layer).
- Provenance file records URL, cache key, and output path.
  - Status set to `downloaded` in the sidecar.
  - Cache keys now differ by bbox parameters (verified via JC vs demo runs).

## Notes
- Use `offline: true` in layer config to force placeholders for CI/offline runs.
