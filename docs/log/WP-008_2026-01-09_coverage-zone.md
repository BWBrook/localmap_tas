# WP-008 Log — Coverage zone polygon v1

Date: 2026-01-09

## Summary
- Added optional coverage polygon builder (convex hull + buffer) and summary table.
- Canonical run now uses the JC camera sites dataset (13 sites) as the default test case.
- Coverage summary is recorded in `coverage_summary.csv` (area ≈ 0.426 km² with 50 m buffer).
- Overview map now auto-matches AOI aspect ratio to avoid transparent padding bands.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-008_2026-01-09_coverage-zone/`
  - `overview_map.png`
  - `coverage_summary.csv`

## Sanity checks
- Coverage polygon encloses the JC camera sites and aligns with the auto AOI extent.
- Coverage area is positive and plausible for the JC array scale (≈0.426 km²).
- Coverage polygon is visible in the overview map as a translucent fill beneath the AOI outline.

## Notes
- Coverage is optional and controlled by `data.coverage.enabled`.
- Canonical run command uses `R_CONFIG_ACTIVE=jc` to ensure the JC dataset is exercised.
