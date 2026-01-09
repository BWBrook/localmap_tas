# WP-003 Log — Demo profile offline maps/panels

Date: 2026-01-09

## Summary
- Updated the demo profile to generate a 2-panel figure by stacking the species overview map and camera-sites map.
- Ensured panel assembly handles mixed-channel PNGs (RGB + RGBA).
- Demo run completed offline with expected placeholder warning for WMS.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-003_2026-01-09_demo-offline/`
  - `demo_species_occurrences.png`
  - `demo_camera_sites.png`
  - `demo_camera_sites_panel.png`
  - `demo_camera_sites_tile.png` (placeholder basemap)

## Sanity checks
- Species overview map shows Tasmania outline with points clustered in NW TAS; graticules and labels are plausible.
- Camera-sites map shows two points within the coastal extent; scale bar + north arrow present; placeholder basemap expected (black tile).
- Panel figure stacks the two maps with labels; both panels are fully visible and aligned.

## Next steps
- Consider tightening layout/typography for the demo panel (padding, label colour) in later WPs.
