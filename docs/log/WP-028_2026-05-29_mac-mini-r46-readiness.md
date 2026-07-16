# WP-028 — Mac mini R 4.6 readiness

## Summary

- Migrated the local Mac mini workflow from the stale R 4.5.3 pin to the
  Homebrew R 4.6.0 + `renv` 1.2.3 baseline.
- Added packaged offline vector fixtures for fire attributes, geology, land
  tenure, and reserve estate so the full JC/TAS CI profiles do not depend on
  live ArcGIS vector fetches.
- Fixed `tas_canonical_ci` to use the packaged camera-site fixture rather than
  raw Judbury study files under `data/`.

## Artefacts

Canonical run folder:

- `outputs/canonical_runs/WP-028_2026-05-29_mac-mini-r46-readiness/`

Inspected artefacts:

- `outputs/jc/maps/panel_figure.png`
- `outputs/tas/maps/panel_figure.png`
- `outputs/jc/analysis/vector/jc_fire_attributes.png`
- `outputs/tas/analysis/vector/tas_fire_attributes.png`
- `outputs/jc/tables/site_attributes_wide.csv`
- `outputs/tas/tables/site_attributes_wide.csv`
- `outputs/jc/provenance/analysis_layers.csv`
- `outputs/tas/provenance/analysis_layers.csv`

Verification commands:

- `make bootstrap-qa`
- `make actionlint`
- `make lint`
- `make test`
- `R_CONFIG_ACTIVE=demo TARGETS_PROFILE=ci make pipeline`
- `R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci make pipeline`
- `R_CONFIG_ACTIVE=tas_canonical_ci TARGETS_PROFILE=ci make pipeline`
- `make check`
- `Rscript -e "renv::status()"`

## Sanity Checks

- JC and TAS panel figures are both 4200 x 3742 px, with camera-site points
  inside the AOI and a plausible 200 m scale bar for the local extent.
- Offline grey/placeholder imagery panels are expected in CI profiles because
  network fetches remain gated by `LOCALMAP_ALLOW_NETWORK`.
- Fire-attribute previews show the two-class fixture split and site points on
  both sides of the split, confirming vector clipping/rendering is coherent.
- Wide attribute tables populate DEM, slope, NDVI, NBR, fire, geology, land
  tenure, and reserve estate columns for the packaged camera sites.

## Next Steps

- Treat the new vector fixtures as deterministic CI fixtures only; live
  analyses that need authoritative LIST/MRT data should run with
  `LOCALMAP_ALLOW_NETWORK=1`.
- Resolved in the WP-027 opening hygiene gate: fixture-backed ArcGIS vectors
  report an explicit `offline_fixture` status in their sidecar YAML.
