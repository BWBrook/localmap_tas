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

- `species_map` → `outputs/maps/jc/species_occurrences.png`
- `camera_sites_map` → `outputs/maps/jc/camera_sites.png`
- `camera_sites_panel` → `outputs/maps/jc/camera_sites_panel.png`
- `camera_sites_tile` → `outputs/tiles/jc_camera_sites_tile.png`
- `coverage_summary` → `outputs/tables/jc/coverage_summary.csv`
- `site_attributes_long` → `outputs/tables/jc/site_attributes_long.parquet`
- `site_attributes_wide` → `outputs/tables/jc/site_attributes_wide.csv`
- `wms_layer` → `outputs/layers/jc/tasveg_wms.png`
- `wms_layer_provenance` → `outputs/layers/jc/tasveg_wms.png.yml`
- `tasveg_class_wms_layer` → `outputs/layers/jc/tasveg_class_wms.png`
- `tasveg_class_wms_layer_provenance` → `outputs/layers/jc/tasveg_class_wms.png.yml`
- `tasveg_class_wms_legend` → `outputs/layers/jc/tasveg_class_wms_legend.png`
- `arcgis_layer` → `outputs/layers/jc/topography_arcgis.png`
- `arcgis_layer_provenance` → `outputs/layers/jc/topography_arcgis.png.yml`
- `orthophoto_arcgis_layer` → `outputs/layers/jc/orthophoto_arcgis.png`
- `orthophoto_arcgis_layer_provenance` → `outputs/layers/jc/orthophoto_arcgis.png.yml`
- `roads_wms_layer` → `outputs/layers/jc/roads_wms.png`
- `roads_wms_layer_provenance` → `outputs/layers/jc/roads_wms.png.yml`
- `localities_wms_layer` → `outputs/layers/jc/localities_wms.png`
- `localities_wms_layer_provenance` → `outputs/layers/jc/localities_wms.png.yml`
- `fire_attributes_arcgis_layer` → `outputs/layers/jc/fire_attributes_arcgis.png`
- `fire_attributes_arcgis_layer_provenance` → `outputs/layers/jc/fire_attributes_arcgis.png.yml`
- `soil_ph_wms_layer` → `outputs/layers/jc/soil_ph_wms.png`
- `soil_ph_wms_layer_provenance` → `outputs/layers/jc/soil_ph_wms.png.yml`
- `overview_map` → `outputs/maps/jc/overview_map.png`
- `panel_figure_png` → `outputs/maps/jc/panel_figure.png`
- `panel_figure_pdf` → `outputs/maps/jc/panel_figure.pdf`
- `vector_tasveg` → `outputs/analysis/jc/vector/jc_tasveg.gpkg`
- `vector_tasveg_provenance` → `outputs/analysis/jc/vector/jc_tasveg.gpkg.yml`
- `vector_tasveg_preview` → `outputs/analysis/jc/vector/jc_tasveg.png`
- `vector_tasveg_class` → `outputs/analysis/jc/vector/jc_tasveg_class.gpkg`
- `vector_tasveg_class_provenance` → `outputs/analysis/jc/vector/jc_tasveg_class.gpkg.yml`
- `vector_tasveg_class_preview` → `outputs/analysis/jc/vector/jc_tasveg_class.png`
- `tasveg_class_lookup` → `outputs/analysis/jc/vector/jc_tasveg_class_lookup.csv`
- `tasveg_group_lookup` → `outputs/analysis/jc/vector/jc_tasveg_group_lookup.csv`
- `geology_lookup` → `outputs/analysis/jc/vector/jc_geology_lookup.csv`
- `land_tenure_lookup` → `outputs/analysis/jc/vector/jc_land_tenure_lookup.csv`
- `reserve_estate_lookup` → `outputs/analysis/jc/vector/jc_reserve_estate_lookup.csv`
- `vector_fire_attributes` → `outputs/analysis/jc/vector/jc_fire_attributes.gpkg`
- `vector_fire_attributes_provenance` → `outputs/analysis/jc/vector/jc_fire_attributes.gpkg.yml`
- `vector_fire_attributes_preview` → `outputs/analysis/jc/vector/jc_fire_attributes.png`
- `vector_geology` → `outputs/analysis/jc/vector/jc_geology.gpkg`
- `vector_geology_provenance` → `outputs/analysis/jc/vector/jc_geology.gpkg.yml`
- `vector_geology_preview` → `outputs/analysis/jc/vector/jc_geology.png`
- `vector_land_tenure` → `outputs/analysis/jc/vector/jc_land_tenure.gpkg`
- `vector_land_tenure_provenance` → `outputs/analysis/jc/vector/jc_land_tenure.gpkg.yml`
- `vector_land_tenure_preview` → `outputs/analysis/jc/vector/jc_land_tenure.png`
- `vector_reserve_estate` → `outputs/analysis/jc/vector/jc_reserve_estate.gpkg`
- `vector_reserve_estate_provenance` → `outputs/analysis/jc/vector/jc_reserve_estate.gpkg.yml`
- `vector_reserve_estate_preview` → `outputs/analysis/jc/vector/jc_reserve_estate.png`
- `raster_dem` → `outputs/analysis/jc/raster/jc_dem.tif`
- `raster_dem_provenance` → `outputs/analysis/jc/raster/jc_dem.tif.yml`
- `raster_dem_preview` → `outputs/analysis/jc/raster/jc_dem.png`
- `raster_multiband` → `outputs/analysis/jc/raster/jc_multiband.tif`
- `raster_multiband_provenance` → `outputs/analysis/jc/raster/jc_multiband.tif.yml`
- `raster_multiband_preview` → `outputs/analysis/jc/raster/jc_multiband.png`
- `raster_slope` → `outputs/analysis/jc/raster/jc_slope.tif`
- `raster_slope_provenance` → `outputs/analysis/jc/raster/jc_slope.tif.yml`
- `raster_slope_preview` → `outputs/analysis/jc/raster/jc_slope.png`
- `raster_ndvi` → `outputs/analysis/jc/raster/jc_ndvi.tif`
- `raster_ndvi_provenance` → `outputs/analysis/jc/raster/jc_ndvi.tif.yml`
- `raster_ndvi_preview` → `outputs/analysis/jc/raster/jc_ndvi.png`
- `raster_nbr` → `outputs/analysis/jc/raster/jc_nbr.tif`
- `raster_nbr_provenance` → `outputs/analysis/jc/raster/jc_nbr.tif.yml`
- `raster_nbr_preview` → `outputs/analysis/jc/raster/jc_nbr.png`
- `raster_chm` → `outputs/analysis/jc/raster/jc_chm.tif`
- `raster_chm_provenance` → `outputs/analysis/jc/raster/jc_chm.tif.yml`
- `raster_chm_preview` → `outputs/analysis/jc/raster/jc_chm.png`
- `raster_soil_ph` → `outputs/analysis/jc/raster/jc_soil_ph.tif`
- `raster_soil_ph_provenance` → `outputs/analysis/jc/raster/jc_soil_ph.tif.yml`
- `raster_soil_ph_preview` → `outputs/analysis/jc/raster/jc_soil_ph.png`
- `raster_bio1` → `outputs/analysis/jc/raster/jc_bio1.tif`
- `raster_bio1_provenance` → `outputs/analysis/jc/raster/jc_bio1.tif.yml`
- `raster_bio1_preview` → `outputs/analysis/jc/raster/jc_bio1.png`
- `raster_bio12` → `outputs/analysis/jc/raster/jc_bio12.tif`
- `raster_bio12_provenance` → `outputs/analysis/jc/raster/jc_bio12.tif.yml`
- `raster_bio12_preview` → `outputs/analysis/jc/raster/jc_bio12.png`
- `analysis_provenance` → `outputs/provenance/analysis_layers.csv`
- `attribution_report` → `outputs/provenance/attribution.md`
- `run_manifest` → `outputs/provenance/run_manifest.yml`

### Default profile entry

- `aoi_debug_plot` → `outputs/maps/aoi/aoi_debug.png`

## Validation

The `validate_output_manifest()` helper checks:
- required fields are present,
- declared output IDs exist when expected outputs are supplied,
- declared output files exist on disk.

## Notes

The manifest is schema-level metadata; it does not enforce rendering settings.
Output versions should be updated when filenames, formats, or CRS assumptions change.
