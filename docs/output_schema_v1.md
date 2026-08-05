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

### Profile entry template

- `species_map` → `outputs/<profile>/maps/species_occurrences.png`
- `camera_sites_map` → `outputs/<profile>/maps/camera_sites.png`
- `camera_sites_tile` → `outputs/<profile>/tiles/camera_sites_tile.png`
- `coverage_summary` → `outputs/<profile>/tables/coverage_summary.csv`
- `site_attributes_long` → `outputs/<profile>/tables/site_attributes_long.parquet`
- `site_attributes_wide` → `outputs/<profile>/tables/site_attributes_wide.csv`
- `wms_layer` → `outputs/<profile>/layers/tasveg_wms.png`
- `wms_layer_provenance` → `outputs/<profile>/layers/tasveg_wms.png.yml`
- `tasveg_class_wms_layer` → `outputs/<profile>/layers/tasveg_class_wms.png`
- `tasveg_class_wms_layer_provenance` → `outputs/<profile>/layers/tasveg_class_wms.png.yml`
- `tasveg_class_wms_legend` → `outputs/<profile>/layers/tasveg_class_wms_legend.png`
- `arcgis_layer` → `outputs/<profile>/layers/topography_arcgis.png`
- `arcgis_layer_provenance` → `outputs/<profile>/layers/topography_arcgis.png.yml`
- `orthophoto_arcgis_layer` → `outputs/<profile>/layers/orthophoto_arcgis.png`
- `orthophoto_arcgis_layer_provenance` → `outputs/<profile>/layers/orthophoto_arcgis.png.yml`
- `roads_wms_layer` → `outputs/<profile>/layers/roads_wms.png`
- `roads_wms_layer_provenance` → `outputs/<profile>/layers/roads_wms.png.yml`
- `localities_wms_layer` → `outputs/<profile>/layers/localities_wms.png`
- `localities_wms_layer_provenance` → `outputs/<profile>/layers/localities_wms.png.yml`
- `fire_attributes_arcgis_layer` → `outputs/<profile>/layers/fire_attributes_arcgis.png`
- `fire_attributes_arcgis_layer_provenance` → `outputs/<profile>/layers/fire_attributes_arcgis.png.yml`
- `soil_ph_wms_layer` → `outputs/<profile>/layers/soil_ph_wms.png`
- `soil_ph_wms_layer_provenance` → `outputs/<profile>/layers/soil_ph_wms.png.yml`
- `overview_map` → `outputs/<profile>/maps/overview_map.png`
- `panel_figure_png` → `outputs/<profile>/maps/panel_figure.png`
- `panel_figure_pdf` → `outputs/<profile>/maps/panel_figure.pdf`
- `vector_tasveg` → `outputs/<profile>/analysis/vector/<profile>_tasveg.gpkg`
- `vector_tasveg_provenance` → `outputs/<profile>/analysis/vector/<profile>_tasveg.gpkg.yml`
- `vector_tasveg_preview` → `outputs/<profile>/analysis/vector/<profile>_tasveg.png`
- `vector_tasveg_class` → `outputs/<profile>/analysis/vector/<profile>_tasveg_class.gpkg`
- `vector_tasveg_class_provenance` → `outputs/<profile>/analysis/vector/<profile>_tasveg_class.gpkg.yml`
- `vector_tasveg_class_preview` → `outputs/<profile>/analysis/vector/<profile>_tasveg_class.png`
- `tasveg_class_lookup` → `outputs/<profile>/analysis/vector/<profile>_tasveg_class_lookup.csv`
- `tasveg_group_lookup` → `outputs/<profile>/analysis/vector/<profile>_tasveg_group_lookup.csv`
- `geology_lookup` → `outputs/<profile>/analysis/vector/<profile>_geology_lookup.csv`
- `land_tenure_lookup` → `outputs/<profile>/analysis/vector/<profile>_land_tenure_lookup.csv`
- `reserve_estate_lookup` → `outputs/<profile>/analysis/vector/<profile>_reserve_estate_lookup.csv`
- `vector_fire_attributes` → `outputs/<profile>/analysis/vector/<profile>_fire_attributes.gpkg`
- `vector_fire_attributes_provenance` → `outputs/<profile>/analysis/vector/<profile>_fire_attributes.gpkg.yml`
- `vector_fire_attributes_preview` → `outputs/<profile>/analysis/vector/<profile>_fire_attributes.png`
- `vector_geology` → `outputs/<profile>/analysis/vector/<profile>_geology.gpkg`
- `vector_geology_provenance` → `outputs/<profile>/analysis/vector/<profile>_geology.gpkg.yml`
- `vector_geology_preview` → `outputs/<profile>/analysis/vector/<profile>_geology.png`
- `vector_land_tenure` → `outputs/<profile>/analysis/vector/<profile>_land_tenure.gpkg`
- `vector_land_tenure_provenance` → `outputs/<profile>/analysis/vector/<profile>_land_tenure.gpkg.yml`
- `vector_land_tenure_preview` → `outputs/<profile>/analysis/vector/<profile>_land_tenure.png`
- `vector_reserve_estate` → `outputs/<profile>/analysis/vector/<profile>_reserve_estate.gpkg`
- `vector_reserve_estate_provenance` → `outputs/<profile>/analysis/vector/<profile>_reserve_estate.gpkg.yml`
- `vector_reserve_estate_preview` → `outputs/<profile>/analysis/vector/<profile>_reserve_estate.png`
- `raster_dem` → `outputs/<profile>/analysis/raster/<profile>_dem.tif`
- `raster_dem_provenance` → `outputs/<profile>/analysis/raster/<profile>_dem.tif.yml`
- `raster_dem_preview` → `outputs/<profile>/analysis/raster/<profile>_dem.png`
- `raster_multiband` → `outputs/<profile>/analysis/raster/<profile>_multiband.tif`
- `raster_multiband_provenance` → `outputs/<profile>/analysis/raster/<profile>_multiband.tif.yml`
- `raster_multiband_preview` → `outputs/<profile>/analysis/raster/<profile>_multiband.png`
- `raster_slope` → `outputs/<profile>/analysis/raster/<profile>_slope.tif`
- `raster_slope_provenance` → `outputs/<profile>/analysis/raster/<profile>_slope.tif.yml`
- `raster_slope_preview` → `outputs/<profile>/analysis/raster/<profile>_slope.png`
- `raster_ndvi` → `outputs/<profile>/analysis/raster/<profile>_ndvi.tif`
- `raster_ndvi_provenance` → `outputs/<profile>/analysis/raster/<profile>_ndvi.tif.yml`
- `raster_ndvi_preview` → `outputs/<profile>/analysis/raster/<profile>_ndvi.png`
- `raster_nbr` → `outputs/<profile>/analysis/raster/<profile>_nbr.tif`
- `raster_nbr_provenance` → `outputs/<profile>/analysis/raster/<profile>_nbr.tif.yml`
- `raster_nbr_preview` → `outputs/<profile>/analysis/raster/<profile>_nbr.png`
- `raster_chm` → `outputs/<profile>/analysis/raster/<profile>_chm.tif`
- `raster_chm_provenance` → `outputs/<profile>/analysis/raster/<profile>_chm.tif.yml`
- `raster_chm_preview` → `outputs/<profile>/analysis/raster/<profile>_chm.png`
- `raster_soil_ph` → `outputs/<profile>/analysis/raster/<profile>_soil_ph.tif`
- `raster_soil_ph_provenance` → `outputs/<profile>/analysis/raster/<profile>_soil_ph.tif.yml`
- `raster_soil_ph_preview` → `outputs/<profile>/analysis/raster/<profile>_soil_ph.png`
- `raster_bio1` → `outputs/<profile>/analysis/raster/<profile>_bio1.tif`
- `raster_bio1_provenance` → `outputs/<profile>/analysis/raster/<profile>_bio1.tif.yml`
- `raster_bio1_preview` → `outputs/<profile>/analysis/raster/<profile>_bio1.png`
- `raster_bio12` → `outputs/<profile>/analysis/raster/<profile>_bio12.tif`
- `raster_bio12_provenance` → `outputs/<profile>/analysis/raster/<profile>_bio12.tif.yml`
- `raster_bio12_preview` → `outputs/<profile>/analysis/raster/<profile>_bio12.png`
- `analysis_provenance` → `outputs/<profile>/provenance/analysis_layers.csv`
- `attribution_report` → `outputs/<profile>/provenance/attribution.md`
- `run_manifest` → `outputs/<profile>/provenance/run_manifest.yml`
- `aoi_debug_plot` → `outputs/<profile>/maps/aoi_debug.png`

## Interpreting outputs

The manifest declares expected products and locations; file existence alone is
not scientific validation. Interpret each product with its run context:

- Maps and panel figures should be checked for AOI coverage, site placement,
  CRS/alignment, annotation, source scale, and resolution.
- Long attributes preserve one row per site/layer/attribute observation and are
  the primary audit surface. The wide CSV is a convenience representation;
  confirm its columns map back to the long table before analysis.
- Layer `.yml` sidecars identify acquisition and cache status. In particular,
  `offline_placeholder` or `placeholder` is layout-only imagery,
  `offline_fixture` is deterministic fixture-backed evidence, and `cache_hit`
  reuses a prior acquisition.
- `provenance/analysis_layers.csv` records analysis-layer processing;
  `provenance/attribution.md` supplies source credits; and
  `provenance/run_manifest.yml` ties expected products to the completed run.
- A placeholder must never be described as imagery fetched live, and its pixels
  must not be used for ecological interpretation or attribute extraction.

Read [Layer registry guide](layers_guide.md) for source selection and placeholder
policy, and follow [Workflow](workflow.md) for visual and table review.

## Validation

The `validate_output_manifest()` helper checks:
- required fields are present,
- declared output IDs exist when expected outputs are supplied,
- declared output files exist on disk.

## Notes

The manifest is schema-level metadata; it does not enforce rendering settings.
Output versions should be updated when filenames, formats, or CRS assumptions change.
