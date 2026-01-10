# WP-025 — Container parity (Docker) (2026-01-10)

## Summary
Validated the JC workflow in a Docker container built from `inst/containers/Dockerfile`, using offline mode and host-mounted `data/` + `outputs/`. Outputs match the local JC run shape and appear coherent.

## Commands (prose)
Built Docker image `localmap_tas:wp025` and ran it with JC config in offline mode, mounting `data/` and `outputs/` from the host, then restored the lockfile inside the container and ran `targets::tar_make()`.

## Artefacts inspected
- `outputs/canonical_runs/WP-025_2026-01-10_container-parity/jc_overview_map.png`
- `outputs/canonical_runs/WP-025_2026-01-10_container-parity/jc_panel_figure.png`
- `outputs/canonical_runs/WP-025_2026-01-10_container-parity/jc_camera_sites.png`
- `outputs/canonical_runs/WP-025_2026-01-10_container-parity/jc_species_occurrences.png`
- `outputs/canonical_runs/WP-025_2026-01-10_container-parity/jc_species_topo.png`
- `outputs/canonical_runs/WP-025_2026-01-10_container-parity/analysis_layers.csv`
- `outputs/canonical_runs/WP-025_2026-01-10_container-parity/attribution.md`
- `outputs/canonical_runs/WP-025_2026-01-10_container-parity/run_manifest.yml`

## Sanity + interpretation notes
- Overview map: rotated AOI polygon encloses all JC points; scale bar looks plausible (200 m).
- Camera sites map: points cluster within AOI; basemap placeholders are expected offline but still render; north arrow placement consistent.
- Species occurrence/topo maps: points match JC extents; axes/labels correct; no obvious offsets.
- Panel figure: all four panels render; labels and spacing consistent.

## Limitations
- Offline mode produces placeholder WMS/ArcGIS imagery, which is expected for `LOCALMAP_ALLOW_NETWORK=0`.
- Container restore required installing `rnaturalearthdata` and system libs for text rendering.

## Next steps
- Proceed to WP-026 canonical Tasmania layer set (orthophoto + TASVEG + DEM), keeping network-gated behaviour.
