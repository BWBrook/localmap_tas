# WP-008 Log — Coverage zone polygon v1

Date: 2026-01-09

## Summary
- Added optional coverage polygon builder (convex hull + buffer) and summary table.
- Coverage is derived from selected site points and stored in `coverage_summary.csv`.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-008_2026-01-09_coverage-zone/`
  - `overview_map.png`
  - `coverage_summary.csv`

## Sanity checks
- Coverage polygon encloses the demo camera sites and aligns with AOI.
- Coverage area values are positive and plausible for the demo extent.
- Coverage polygon is visible in the overview map as a translucent fill beneath the AOI outline.

## Notes
- Coverage is optional and controlled by `data.coverage.enabled`.
