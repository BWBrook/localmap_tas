# WP-003 Log — Demo profile offline maps/panels

Date: 2026-01-09

## Summary
- Updated the canonical run to use the JC camera-site example for the core demo maps.
- Produced JC species + camera-site maps and a 2-panel stack for quick visual inspection.
- Camera-site tile is now drawn from the LIST WMS (no placeholder for JC).

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-003_2026-01-09_demo-offline/`
  - `jc_species_occurrences.png`
  - `jc_camera_sites.png`
  - `jc_camera_sites_panel.png`
  - `jc_camera_sites_tile.png`

## Sanity checks
- JC species map shows clustered occurrences within the camera AOI; extent is tight and coherent.
- Camera-sites map renders JC sites over the TASVEG basemap; scale bar + north arrow present.
- Panel figure stacks the two maps with labels; both panels are fully visible and aligned.

## Next steps
- Consider tightening layout/typography for the demo panel (padding, label colour) in later WPs.
