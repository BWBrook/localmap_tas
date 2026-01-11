# WP-026 — Tasmania canonical example layer set (2026-01-10)

## What changed
- Added `tas_canonical`/`tas_canonical_ci` profiles with LIST Orthophoto + TASVEG 4.0 Groups and DEM/slope layers.
- Switched the canonical DEM to LIST RasterMisc DTM 10m export with JC fixture fallback.
- Added optional roads/localities WMS overlays for the overview map.
- Added dedicated output manifest for the Tasmania canonical profile.

## Commands run
- `R_CONFIG_ACTIVE=tas_canonical LOCALMAP_ALLOW_NETWORK=1 R -q -e 'targets::tar_make()'`

## Artefacts inspected
- `outputs/canonical_runs/WP-026_2026-01-10_tas-canonical/tas_overview_map.png`
- `outputs/canonical_runs/WP-026_2026-01-10_tas-canonical/tas_panel_figure.png`
- `outputs/canonical_runs/WP-026_2026-01-10_tas-canonical/tas_tasveg.png`
- `outputs/canonical_runs/WP-026_2026-01-10_tas-canonical/tas_dem.png`
- `outputs/canonical_runs/WP-026_2026-01-10_tas-canonical/tas_slope.png`
- `outputs/canonical_runs/WP-026_2026-01-10_tas-canonical/tas_roads_wms.png`
- `outputs/canonical_runs/WP-026_2026-01-10_tas-canonical/tas_localities_wms.png`

## Sanity + interpretation notes
- Orthophoto basemap aligns with AOI polygon and JC site points; coverage polygon matches AOI extent.
- TASVEG vector preview shows multiple vegetation groups within the AOI; site crosses fall inside class polygons.
- Roads/localities overlays align with visible features on the orthophoto without obvious offsets.
- DEM and slope previews show consistent gradients with site markers; no rotation or offset artifacts.
- Panel figure assembles the four maps with expected labels and no empty panels.

## Canonical run folder
- `outputs/canonical_runs/WP-026_2026-01-10_tas-canonical/`
