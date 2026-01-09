# WP-004 Log — Output schema v1 + regression tests

Date: 2026-01-09

## Summary
- Added output schema manifest v1 (`inst/extdata/output_manifest_v1.csv`) and validation helper.
- Introduced `output_schema_v1` target to validate declared outputs.
- Documented output schema in `docs/output_schema_v1.md` and added tests for validation errors.

## Artefacts
- Output schema doc: `docs/output_schema_v1.md`.
- Manifest: `inst/extdata/output_manifest_v1.csv`.
- Tests: `tests/testthat/test_output_manifest.R`.
- Canonical run folder: `outputs/canonical_runs/WP-004_2026-01-09_output-schema-v1/`.

## Sanity checks
- Manifest entries align with demo output files (species map, camera-sites map, panel, basemap tile).
- Validation catches missing output IDs and missing declared paths.

## Next steps
- Extend manifest entries once additional maps/figures/tables are added.
