# WP-018a Log — Analysis layer preview PNGs

Date: 2026-01-10

## Summary
- Added quick-look PNG previews alongside AOI-clipped vector/raster outputs.
- Vector previews colour by a categorical attribute (prefers `habitat`) and include AOI outline.
- Raster previews overlay AOI and camera sites; multiband preview uses RGB composite (bands 1–3).

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-018a_2026-01-10_analysis-previews/`
  - `jc_habitats.png`
  - `jc_dem.png`
  - `jc_multiband.png`
  - `jc_slope.png`
  - `jc_ndvi.png`
  - `jc_nbr.png`

## Sanity checks
- Vector preview shows two habitat classes with distinct colours and legend.
- Raster previews align with camera sites; no apparent rotation.
- Derived indices show expected gradients rather than flat/noisy output.

## Notes
- Previews are intended for rapid QC and are not publication figures.
