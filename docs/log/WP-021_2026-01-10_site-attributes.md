# WP-021 Log — Site attributes products v1

Date: 2026-01-10

## Summary
- Produced canonical long parquet plus convenience wide CSV for site attributes.
- Wide column naming: `{layer_id}__{attribute_name}` for deterministic pivots.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-021_2026-01-10_site-attributes/`
  - `outputs/jc/tables/site_attributes_long.parquet`
  - `outputs/jc/tables/site_attributes_wide.csv`

## Sanity checks
- Wide table has 13 rows (one per site) and 9 attribute columns + `site_id`.
- Column names include `jc_dem__value`, `jc_ndvi__ndvi`, `jc_nbr__nbr`.

## Notes
- Long table remains the canonical product; wide CSV is a convenience view.
