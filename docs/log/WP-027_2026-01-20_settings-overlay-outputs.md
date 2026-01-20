# WP-027 — Settings overlay + outputs hierarchy (2026-01-20)

## What changed
- Standardised outputs under `outputs/<profile>/<type>/` and updated configs, manifests, and docs accordingly.
- Settings overlay now strips the base profile output prefix, so user runs write directly under `outputs/<project>/`.
- `cfg_read()` prefers the repo `config/config.yaml` when present and rewrites `outputs/default/*` paths to the active output directory.
- Ensured `cfg_file` always re-evaluates so `LOCALMAP_CONFIG_PATH` overrides are respected.
- Added JC/TAS camera-site overlay output paths (roads/localities/legend) and regenerated outputs.

## Commands run
- `R_CONFIG_ACTIVE=jc LOCALMAP_ALLOW_NETWORK=1 Rscript -e 'targets::tar_make()'`
- `R_CONFIG_ACTIVE=tas_canonical LOCALMAP_ALLOW_NETWORK=1 Rscript -e 'targets::tar_make()'`
- `LOCALMAP_ALLOW_NETWORK=1 Rscript scripts/run_project.R settings.yaml`
- `Rscript -e 'devtools::test(filter = "config|settings_runner")'`

## Artefacts inspected
- `outputs/jc/maps/overview_map.png`
- `outputs/jc/maps/camera_sites.png`
- `outputs/jc/analysis/raster/jc_dem.png`
- `outputs/judbury_cameras/maps/overview_map.png`

## Sanity + interpretation notes
- AOI outlines and camera sites align across orthophoto and TASVEG basemaps.
- DEM gradients look plausible for the JC AOI at 30 m scale.
- Settings run outputs land directly in `outputs/judbury_cameras/` without nested `jc/` folders.

## Canonical run folder
- Not created for this interim refactor (will be included with the WP-027 artefact bundle).
