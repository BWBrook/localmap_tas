# WP-020 Log — Vector point-in-polygon extraction v1

Date: 2026-01-10

## Summary
- Extracted polygon attributes (`habitat`, `zone`) for JC camera sites.
- No-hit cases are handled explicitly as NA (covered in unit tests).

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-020_2026-01-10_vector-extraction/`
  - `outputs/tables/jc/site_attributes_long.parquet`

## Sanity checks
- Habitat values are `forest` / `grassland`; zone values `west` / `east`.
- All JC sites receive vector attributes with no unexpected drops.

## Notes
- Extraction uses first-match when multiple polygons intersect a site.
