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

### JC profile entries

- `species_map` → `outputs/maps/jc_species_occurrences.png`
- `camera_sites_map` → `outputs/maps/jc_camera_sites.png`
- `camera_sites_panel` → `outputs/maps/jc_camera_sites_panel.png`
- `camera_sites_tile` → `outputs/tiles/jc_camera_sites_tile.png`
- `coverage_summary` → `outputs/tables/jc_coverage_summary.csv`
- `wms_layer` → `outputs/layers/jc_tasveg_wms.png`
- `wms_layer_provenance` → `outputs/layers/jc_tasveg_wms.png.yml`
- `arcgis_layer` → `outputs/layers/jc_topography_arcgis.png`
- `arcgis_layer_provenance` → `outputs/layers/jc_topography_arcgis.png.yml`
- `overview_map` → `outputs/maps/jc_overview_map.png`
- `panel_figure_png` → `outputs/maps/jc_panel_figure.png`
- `panel_figure_pdf` → `outputs/maps/jc_panel_figure.pdf`
- `vector_habitats` → `outputs/analysis/vector/jc_habitats.gpkg`
- `vector_habitats_provenance` → `outputs/analysis/vector/jc_habitats.gpkg.yml`
- `raster_dem` → `outputs/analysis/raster/jc_dem.tif`
- `raster_dem_provenance` → `outputs/analysis/raster/jc_dem.tif.yml`
- `raster_multiband` → `outputs/analysis/raster/jc_multiband.tif`
- `raster_multiband_provenance` → `outputs/analysis/raster/jc_multiband.tif.yml`
- `raster_slope` → `outputs/analysis/raster/jc_slope.tif`
- `raster_slope_provenance` → `outputs/analysis/raster/jc_slope.tif.yml`
- `raster_ndvi` → `outputs/analysis/raster/jc_ndvi.tif`
- `raster_ndvi_provenance` → `outputs/analysis/raster/jc_ndvi.tif.yml`
- `raster_nbr` → `outputs/analysis/raster/jc_nbr.tif`
- `raster_nbr_provenance` → `outputs/analysis/raster/jc_nbr.tif.yml`
- `analysis_provenance` → `outputs/provenance/analysis_layers.csv`
- `attribution_report` → `outputs/provenance/attribution.md`
- `run_manifest` → `outputs/provenance/run_manifest.yml`

### Default profile entry

- `aoi_debug_plot` → `outputs/maps/aoi_debug.png`

## Validation

The `validate_output_manifest()` helper checks:
- required fields are present,
- declared output IDs exist when expected outputs are supplied,
- declared output files exist on disk.

## Notes

The manifest is schema-level metadata; it does not enforce rendering settings.
Output versions should be updated when filenames, formats, or CRS assumptions change.
