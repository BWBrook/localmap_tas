# WP-018a Log — Analysis layer preview PNGs

Date: 2026-01-10

## Summary
- Added quick-look PNG previews alongside AOI-clipped vector/raster outputs.
- Previews are generated for each analysis layer to support rapid visual QA.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-018a_2026-01-10_analysis-previews/`
  - `jc_habitats.png`
  - `jc_dem.png`
  - `jc_multiband.png`
  - `jc_slope.png`
  - `jc_ndvi.png`
  - `jc_nbr.png`

## Sanity checks
- Preview PNGs render without errors and align with AOI extent.
- Multiband preview uses RGB composite (bands 1–3).
- Derived indices show expected gradients rather than flat/noisy output.

## Notes
- Previews are intended for fast QC and are not publication figures.
