# WP-007 Log — AOI builder v1

Date: 2026-01-09

## Summary
- Added AOI builder (`build_aoi_from_config`) with centroid/size/rotation support in EPSG:28355.
- Added AOI auto mode (sites bbox + buffered extent) for camera-scale defaults.
- Wired AOI into species mapping and tile map generation; bounding-box config is now optional fallback.
- Added AOI debug plot target and tests; created a rotated AOI debug plot using JC sites for sanity inspection.
- Introduced `jc` camera-sites source to derive `rd`/`obs` from the Judbury camera study inputs.
- Bumped config schema to v2 with migration from v1 bounding boxes.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-007_2026-01-09_aoi-builder/`
  - `aoi_debug.png`
  - `aoi_debug_rotated.png`
  - `aoi_debug_jc.png`
  - `species_occurrences_jc.png`

## Sanity checks
- `aoi_debug.png`: AOI polygon encloses the JC camera sites; extent aligns with the local outline.
- Centroid marker removed from AOI debug plots by default (no dot).
- `aoi_debug_rotated.png`: AOI rotation is visible for the JC extent; polygon rotates around centroid as expected.
- Species map + camera-sites panel rebuilt in JC run; extents and overlay alignment consistent with prior outputs.
- `aoi_debug_jc.png`: JC camera sites are tightly enclosed by the AOI, with a small buffer derived from site spacing (auto mode).
- `species_occurrences_jc.png`: JC fixture occurrences render at the camera-site locations; extent matches the JC AOI.

## Notes on JC dataset
- `jc_site.csv` + `jc_obs.csv` now derive a compatible camera-site table (`rd` = unique observation days, `obs` = summed counts).
- Profile `jc` is configured to generate `data/interim/jc_camera_sites.csv`.
- Fixture occurrences are generated from `jc_obs.csv` + `jc_site.csv` and stored in `inst/extdata/occurrences_jc.csv` with `metadata/species_requests_jc.csv`.

## Next steps
- Continue with WP-008 once PI reviews schema v2 and AOI behavior.
