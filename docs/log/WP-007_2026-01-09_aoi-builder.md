# WP-007 Log — AOI builder v1

Date: 2026-01-09

## Summary
- Added AOI builder (`build_aoi_from_config`) with centroid/size/rotation support in EPSG:28355.
- Wired AOI into species mapping and tile map generation; bounding-box config is now optional fallback.
- Added AOI debug plot target and tests; created a rotated AOI debug plot for sanity inspection.
- Introduced `jc` camera-sites source to derive `rd`/`obs` from the Judbury camera study inputs.
- Bumped config schema to v2 with migration from v1 bounding boxes.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-007_2026-01-09_aoi-builder/`
  - `aoi_debug.png`
  - `aoi_debug_rotated.png`

## Sanity checks
- `aoi_debug.png`: AOI polygon encloses the demo camera sites; centroid appears near mid-Tasmania.
- `aoi_debug_rotated.png`: AOI rotation is visible; polygon rotates around centroid as expected.
- Species map + camera-sites panel rebuilt in demo run; extents and overlay alignment consistent with prior outputs.

## Notes on JC dataset
- `jc_site.csv` + `jc_obs.csv` now derive a compatible camera-site table (`rd` = unique observation days, `obs` = summed counts).
- Profile `jc` is configured to generate `data/interim/jc_camera_sites.csv`.

## Next steps
- Continue with WP-008 once PI reviews schema v2 and AOI behavior.
