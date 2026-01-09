# Output schema v1

This document defines the expected output artefacts produced by the pipeline.
The schema is represented by a manifest CSV (`inst/extdata/output_manifest_v1.csv`).

## Manifest fields

- `output_id` (string): stable identifier for the output.
- `type` (string): `map`, `figure`, `table`, `basemap`, `provenance` (extensible).
- `description` (string): short human-readable description.
- `path` (string): default output path (relative to project root).
- `format` (string): file format (e.g., `png`, `csv`).
- `crs` (string): CRS identifier (e.g., `EPSG:4326`).
- `profile` (string): config profile used to generate the artefact.
- `producer` (string): function or target producing the artefact.

## Current outputs (v1)

The current manifest entries live in `inst/extdata/output_manifest_v1.csv` and
are validated in the pipeline via the `output_schema_v1` target.

### Demo profile entries

- `species_map` → `outputs/maps/demo_species_occurrences.png`
- `camera_sites_map` → `outputs/maps/demo_camera_sites.png`
- `camera_sites_panel` → `outputs/maps/demo_camera_sites_panel.png`
- `camera_sites_tile` → `outputs/tiles/demo_camera_sites_tile.png`
- `coverage_summary` → `outputs/tables/demo_coverage_summary.csv`
- `wms_layer` → `outputs/layers/demo_tasveg_wms.png`
- `wms_layer_provenance` → `outputs/layers/demo_tasveg_wms.png.yml`
- `arcgis_layer` → `outputs/layers/demo_topography_arcgis.png`
- `arcgis_layer_provenance` → `outputs/layers/demo_topography_arcgis.png.yml`
- `overview_map` → `outputs/maps/demo_overview_map.png`
- `panel_figure_png` → `outputs/maps/demo_panel_figure.png`
- `panel_figure_pdf` → `outputs/maps/demo_panel_figure.pdf`

### Default profile entries

- `aoi_debug_plot` → `outputs/maps/aoi_debug.png`

## Validation

The `validate_output_manifest()` helper checks:
- required fields are present,
- declared output IDs exist when expected outputs are supplied,
- declared output files exist on disk.

## Notes

The manifest is schema-level metadata; it does not enforce rendering settings.
Output versions should be updated when filenames, formats, or CRS assumptions change.
