# WP-002 Log — Config schema v1 + validation + reference

Date: 2026-01-09

## Summary
- Added `schema_version: 1` to config profiles and introduced validation on `cfg_read()`.
- Documented the configuration schema in `docs/config_reference.md` and linked it from README.
- Aligned camera-site legend config to live under `data.camera_sites.map.legend`.

## Artefacts
- Config reference: `docs/config_reference.md`.
- Validation tests: `tests/testthat/test_config.R`.
- Canonical run folder: `outputs/canonical_runs/WP-002_2026-01-09_config-schema-v1/`.

## Sanity checks
- Validation rejects missing `schema_version`, missing required keys, and unsupported schema versions with actionable errors.
- Demo/default configs now declare `schema_version: 1` and pass validation.

## Next steps
- Apply schema validation to subsequent WPs (including output schema checks).
