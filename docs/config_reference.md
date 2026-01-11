# Config reference (schema v2)

This document describes the configuration schema used by `config/config.yaml`.
The active profile is selected via `R_CONFIG_ACTIVE` (default: `default`).

## Schema version

- `schema_version` (integer, required): current schema version. Must be `2`.

## Top-level keys (profile root)

- `data_dir` (string, default: `"data"`): root folder for runtime data.
- `db_path` (string, default: `"data/interim/local.duckdb"`): optional local DB path.
- `sample_frac` (numeric, default: `1.0`): optional sampling fraction for large datasets.
- `data` (list, required): workflow inputs and map settings.
- `ala` (list, required): ALA / galah configuration.

## `data`

Required:
- `aoi` (list, required): area of interest definition.
- `manifest` (string): CSV manifest path (e.g., `metadata/data_manifest.csv`).
- `species_requests` (string): species query CSV path (e.g., `metadata/species_requests.csv`).
  - JC profile uses `metadata/species_requests_jc.csv` (species codes from `jc_obs.csv`).
- `occurrence` (list): occurrence settings.
- `camera_sites` (list): camera-site settings.
- `coverage` (list, optional): coverage polygon settings.
- `layers` (list, optional): registry of imagery layers (WMS/ArcGIS/file).
- `analysis_layers` (list, optional): analysis-grade vector/raster layers and derived products.
- `overview_map` (list, optional): overview map rendering settings.
- `panel_figure` (list, optional): multi-panel figure assembly settings.

### `data.aoi`

The AOI (Area of Interest) standardizes map extents and data acquisition.

- `centroid` (list): lat/lon centroid in EPSG:4326.
  - `lat` (numeric, degrees).
  - `lon` (numeric, degrees).
- `centroid_site` (string, optional): site ID to use as centroid (from camera sites table).
- `mode` (string, optional): `fixed` (default when size is provided) or `auto` to derive AOI from site bounds.
- `width_km`/`height_km` (numeric, km): AOI width/height (total size).
- `size_km` (numeric, km): square AOI size (overrides width/height).
- `rotation_deg` (numeric, default 0): clockwise from geographic north.
- `crs` (string, default `"EPSG:28355"`): analysis CRS for AOI geometry.
- `buffer_km` (numeric, optional): AOI auto-mode buffer (km) added to all sides.
- `buffer_multiplier` (numeric, optional): scale factor applied to the auto buffer (default 1.0).
- `min_buffer_km` (numeric, optional): minimum auto buffer (default 0.25 km).
- `max_buffer_km` (numeric, optional): maximum auto buffer (no cap if omitted).

Notes:
- **Analysis CRS:** AOI geometry is built in EPSG:28355 (GDA94 / MGA Zone 55).
- **Centroid inputs:** lat/lon centroid coordinates are interpreted as EPSG:4326.
- **Dimensions:** `width_km`/`height_km` define total AOI size (not half-widths).
- **Rotation:** `rotation_deg` is clockwise from geographic north, applied after projection to EPSG:28355.
- **Auto mode:** when `mode: auto`, the AOI size is derived from site bounds plus a buffer; centroid/centroid_site are ignored.
- **Mode default:** if `mode` is omitted and no size/width/height is provided, `auto` is assumed.
- **Auto buffer heuristic:** default buffer is the median nearest-neighbour distance between sites (in the AOI CRS), scaled by `buffer_multiplier` and bounded by `min_buffer_km`/`max_buffer_km`.

### `data.occurrence`

- `min_year` (numeric, optional): filter by event year (>= min_year).
- `min_lat` (numeric, optional): latitude cutoff (see docs; negative keeps southerly records).
- `state_province` (string, optional): e.g., `"Tasmania"`.
- `boundary` (string or null, optional): spatial boundary file path.
- `boundary_simplify` (numeric, optional): simplify tolerance in boundary CRS units.
- `fields` (character vector, required): ALA occurrence fields to request.
- `map` (list, required): map rendering settings.

### `data.occurrence.map`

- `basemap` (string, default: `"rnaturalearth"`): `rnaturalearth` or `none`.
- `show_title` (logical, default: `false`).
- `show_legend` (logical, default: `false`).
- `point_colour` (string hex, default: `"#2171b5"`).
- `point_size` (numeric, default: `1.6`).
- `additional_points` (list): optional CSV of extra points.
  - `path` (string or null): CSV with `lat`, `lon` columns.
  - `colour` (string hex, default: `"#d73027"`).
  - `size` (numeric or null): overrides point size.
- `tile_provider` (string, optional): e.g., `"Esri.WorldImagery"`.
- `tile_zoom` (numeric, optional): slippy tile zoom level.
- `tile_outline_colour` (string hex, optional).
- `tile_graticule` (logical, optional): draw graticule on tile map.
- `topo_output_path` (string, optional): output path for tile map.
- `output_path` (string, optional): output path for vector basemap map.
- `bounding_box` (list, required): AOI box definition.
  - NOTE: optional when `data.aoi` is present; retained for backward compatibility.
  - `top_left` (list, required):
    - `lat` (numeric, degrees, EPSG:4326).
    - `lon` (numeric, degrees, EPSG:4326).
  - `length_km` (numeric, km): side length in kilometres.

### `data.camera_sites`

- `source` (string, optional): `"file"` (default) or `"jc"` for the Judbury camera study.
- `path` (string, required for `source: file`): camera site CSV (must include `site`, `lat`, `lon`, `rd`, `obs`).
- `central_site` (string, required): focal site name.
- `bbox_half_km` (numeric, km, required): half-width of the map extent in kilometres.
- `basemap` (list, optional): WMS settings (placeholders allowed for demo).
- `map` (list, optional): camera-site map styling settings.
- `stack` (list, optional): panel assembly settings.

### `data.camera_sites.jc`

For `source: jc`, derive a compatible camera-site table from the Judbury camera study:

- `site_path` (string, required): path to `jc_site.csv` (lat/lon).
- `obs_path` (string, required): path to `jc_obs.csv` (datetime + site).
- `output_path` (string, optional): derived output CSV (defaults to `data/interim/jc_camera_sites.csv`).

Derived fields:
- `rd`: number of unique observation dates per site (from `jc_obs.csv`).
- `obs`: total observed individuals per site (sum of `count` if present; otherwise row count).

### `data.camera_sites.basemap`

- `url` (string): WMS GetMap endpoint.
- `layers` (character vector): WMS layer names.
- `crs` (string, default: `"EPSG:3857"`).
- `version` (string, default: `"1.3.0"`).
- `styles` (string, default: `""`).
- `format` (string, default: `"image/png"`).
- `transparent` (logical, default: `true`).
- `width`/`height` (integer, default: `2048`).
- `dpi` (numeric, default: `96`).
- `max_scale` (numeric, optional): upper bound for scale (1:xx).
- `output_path` (string): cached tile path.
- `legend_path` (string, optional): cached legend path.
- `overlays` (list, optional): overlay WMS definitions.

### `data.camera_sites.map`

- `output_path` (string): map output path.
- `scale_bar_location` (string): `"tl"`, `"tr"`, `"bl"`, `"br"`.
- `north_arrow_location` (string): `"tl"`, `"tr"`, `"bl"`, `"br"`.
- `point_size_min`/`point_size_max` (numeric).
- `zero_obs_colour`/`positive_obs_colour` (string hex).
- `show_graticule` (logical).
- `graticule_colour` (string hex).
- `graticule_alpha` (numeric 0–1).
- `graticule_label_size` (numeric).
- `legend` (list, optional): legend display settings.

### `data.camera_sites.stack`

- `paths` (character vector): explicit input PNGs.
- `glob` (character vector): glob patterns.
- `input_dir` (character vector): directories to scan.
- `pattern` (string): file name regex.
- `order` (character vector): preferred ordering patterns.
- `columns`/`rows` (integer): panel layout.
- `gap_px` (numeric): gap between panels.
- `background` (string hex): background colour.
- `labels` (list): panel labels.
- `output_path` (string): panel output path.

## `ala`

- `email` (string): required unless `use_fixture: true` or `ALA_EMAIL` is set.
- `atlas` (string, default: `"ALA"`).
- `caching` (logical, default: `true`).
- `verbose` (logical, default: `false`).
- `download_reason_id` (integer, default: `4`).
- `use_fixture` (logical, optional): use fixture data for offline demo.
- `fixture_occurrences` (string, required if `use_fixture: true`).

## CRS assumptions

- Lat/lon inputs are in EPSG:4326 (degrees).
- Camera site basemap requests default to EPSG:3857 (Web Mercator).
- Occurrence bounding boxes are built in EPSG:4326, then reprojected as needed.

## Profiles

Profiles can `inherit` from `default` and override keys (e.g., `demo`, `ci`).
Always keep `schema_version` in the active profile (inherited from `default` if not overridden).
The `jc_ci` profile inherits `jc` but forces offline-safe settings for CI runs.
The `tas_canonical` profile provides the Tasmania layer stack (Orthophoto + TASVEG + DEM) anchored to the JC AOI.
The `tas_canonical_ci` profile inherits `tas_canonical` and forces offline-safe imagery/vector settings.
### `data.coverage`

Coverage polygons describe the monitored region derived from site points.

- `enabled` (logical, default: `false`): whether to compute the coverage polygon.
- `buffer_m` (numeric, default: `0`): buffer distance in metres applied to the convex hull.
- `site_ids` (character vector, optional): restrict coverage to specific sites.
- `summary_path` (string, optional): output CSV path for coverage summary.

### `data.layers`

Layer registry entries define imagery sources and attribution metadata.

Required fields per layer:
- `id` (string): unique layer ID.
- `type` (string): `wms`, `arcgis_export`, or `file`.
- `attribution` (list): attribution metadata (at least `source`).

WMS fields:
- `url` (string): WMS endpoint.
- `layers` (string or list): WMS layer names.
- `styles` (string, optional), `crs` (string, optional), `width`/`height` (integer px), `format` (string).
- `offline` (logical, optional): skip network fetch and generate a placeholder.

ArcGIS export fields:
- `url` (string): ArcGIS REST export endpoint.
- `layers` (list, optional): layer IDs to draw (sent as `layers=show:...`).
- `layers_mode` (string, optional): `show` (default), `hide`, `include`, or `exclude`.
- `crs` (string, optional), `width`/`height` (integer px), `format` (string).
- `offline` (logical, optional): skip network fetch and generate a placeholder.

File fields:
- `path` (string): path to a local image file.

Attribution fields (per layer):
- `source` (string, required).
- `license` (string, optional).
- `credit` (string, optional).

### `data.analysis_layers`

Analysis layers describe AOI-clipped vector/raster inputs and derived rasters.

Common fields:
- `id` (string, required): unique layer ID.
- `type` (string, required): one of `vector_file`, `vector_arcgis`, `raster_file`,
  `raster_arcgis`, `raster_wcs`, `raster_geodata`, `derived_slope`, `derived_ndvi`, `derived_nbr`.
- `output_path` (string, required): output GeoPackage/GeoTIFF path.
- `attribution` (list, required): at least `source`, plus optional `license`, `credit`.

Vector file fields (`type: vector_file`):
- `path` (string, required): input vector file path (e.g., GeoPackage).
- `layer` (string, optional): layer name within the GeoPackage.

Vector ArcGIS fields (`type: vector_arcgis`):
- `url` (string, required): ArcGIS REST layer URL (MapServer/FeatureServer).
- `where` (string, optional): filter clause (default `1=1`).
- `out_fields` (string, optional): field list (default `*`).
- `crs` (string, optional): request CRS (default `EPSG:4326`).
- `offline` (logical, optional): skip network fetch.
- `fixture_path` (string, optional): local vector fixture for offline mode.
- `fixture_layer` (string, optional): layer name within fixture.

Raster file fields (`type: raster_file`):
- `path` (string, required): input raster path (GeoTIFF).
- `categorical` (logical, default `false`): if TRUE, use nearest-neighbor resampling.
- `resample` (string, optional): `near`, `bilinear`, or `cubic` (overrides `categorical`).
- `units` (string, optional): units for extracted values (e.g., `m`).

Raster ArcGIS fields (`type: raster_arcgis`):
- `url` (string, required): ArcGIS REST export URL (MapServer/export).
- `crs` (string, optional): export CRS (default `EPSG:3857`).
- `format` (string, optional): image format (default `png`).
- `width`/`height` (integer, optional): export pixel dimensions (default 2048).
- `dpi` (integer, optional): export DPI (default 96).
- `layers` (list, optional): layer IDs/names to show.
- `layers_mode` (string, optional): `show`/`hide`/`include`/`exclude` (default `show`).
- `band` (integer, optional): select a single band from multiband imagery.
- `offline` (logical, optional): skip network fetch.
- `fixture_path` (string, optional): local raster fixture used when offline or fetch fails.
- `categorical` (logical, default `false`): if TRUE, use nearest-neighbor resampling.
- `resample` (string, optional): `near`, `bilinear`, or `cubic` (overrides `categorical`).
- `units` (string, optional): units for extracted values (e.g., `m`).

Raster WCS fields (`type: raster_wcs`):
- `url` (string, required): WCS endpoint URL (GetCapabilities URL base).
- `coverage` (string, required): coverage identifier (e.g., `1` for GA DEM 1s).
- `version` (string, optional): WCS version (default `1.0.0`).
- `crs` (string, optional): request CRS (default `EPSG:4326`).
- `format` (string, optional): output format (default `GeoTIFF`).
- `resolution` (string/number, optional): grid resolution in CRS units (e.g., `1s` for 1 arc-second).
- `width`/`height` (integer, optional): explicit pixel dimensions (overrides `resolution`).
- `max_dim` (integer, optional): cap on computed width/height (default 4096).
- `fallback` (list, optional): fallback raster if WCS fails (e.g., `type: raster_geodata`, `resolution: 3s`).
- `offline` (logical, optional): skip network fetch.
- `fixture_path` (string, optional): local raster fixture used when offline.
- `categorical` (logical, default `false`): if TRUE, use nearest-neighbor resampling.
- `resample` (string, optional): `near`, `bilinear`, or `cubic` (overrides `categorical`).
- `units` (string, optional): units for extracted values (e.g., `m`).

Raster geodata fields (`type: raster_geodata`):
- `resolution` (string, optional): `3s` (default) or `30s` (arc-second resolution).
- `geodata_path` (string, optional): cache directory for downloaded tiles.
- `offline` (logical, optional): skip network fetch.
- `fixture_path` (string, optional): local raster fixture used when offline.
- `categorical` (logical, default `false`): if TRUE, use nearest-neighbor resampling.
- `resample` (string, optional): `near`, `bilinear`, or `cubic` (overrides `categorical`).
- `units` (string, optional): units for extracted values (e.g., `m`).

Derived slope (`type: derived_slope`):
- `source_id` (string, required): raster layer ID (DEM).
- `units` (string, optional): `degrees` (default) or `radians`.

Derived indices (`type: derived_ndvi`, `type: derived_nbr`):
- `source_id` (string, required): multiband raster layer ID.
- `bands` (list, required): band mapping.
  - NDVI: `red`, `nir` band numbers.
  - NBR: `nir`, `swir2` band numbers.

Resampling policy:
- Categorical rasters use `near` (nearest neighbor).
- Continuous rasters default to `bilinear`.

Ordering note:
- Derived layers must appear *after* their `source_id` in `analysis_layers`.

Network access:
- Remote imagery/vector fetches are disabled unless `LOCALMAP_ALLOW_NETWORK=1` is set.
- When network is disabled, imagery uses placeholders; ArcGIS vectors/rasters require a `fixture_path`.

Cache invalidation:
- Delete `data/cache/` to force a refetch, or set a new `cache_dir` in the layer config.
- For analysis layers, bump `analysis_cache_version` in `R/analysis_layers.R` if the cache key logic changes.

### `data.dem_variant`

Optional convenience switch for DEM sources used by analysis layers with IDs ending in `_dem`.
If set, it overrides the DEM layer configuration with a known source definition.

Supported values:
- `ga_1s` (default): Geoscience Australia DEM SRTM 1 Second 2024 (WCS).
- `ga_1s_hydro`: Geoscience Australia DEM SRTM 1 Second Hydro Enforced 2024 (WCS).
- `srtm_3s`: geodata SRTM 3 arc-second (~90 m).
- `srtm_30s`: geodata SRTM 30 arc-second (~1 km).
- `elvis_2m`: user-supplied ELVIS 2 m DEM (requires `data.dem_variant_path`).

Related keys:
- `data.dem_variant_path` (string, required for `elvis_2m`): path to the local DEM file.
- `data.dem_variant_attribution` (list, optional): overrides default attribution for `elvis_2m`.

### `data.attributes`

Controls site attribute extraction outputs.

- `enabled` (logical, default `true`): enable extraction and table outputs.
- `output_long` (string, optional): path for the canonical long table (parquet).
- `output_wide` (string, optional): path for the convenience wide CSV.

### `data.overview_map`

- `output_path` (string, optional): output PNG path.
- `width`/`height` (numeric, inches): figure size.
- `dpi` (numeric): output resolution.
- `match_aspect` (logical, default `true`): adjust width/height to match AOI aspect ratio.
- `base_layer_id` (string, optional): layer ID to use as basemap.
- `overlays` (list, optional): overlay layers with `id` and `opacity`.
- `show_labels` (logical, default `false`): draw site labels.
- `label_field` (string, default `site`): site label column.
- `label_size` (numeric): label size.
- `point_colour`/`point_size`: site marker styling.
- `aoi_colour`/`coverage_colour`: outline and fill styling.
- `scale_bar_location`/`north_arrow_location`: positions for cartographic annotations.

### `data.panel_figure`

- `paths` (list): panel image paths.
- `order` (list, optional): ordering patterns for panel filenames.
- `columns`/`rows` (integer): panel grid layout.
- `output_path` (string): PNG output path.
- `output_pdf` (string, optional): PDF output path.
- `gap_px` (integer, optional): padding between panels.
- `labels` (list, optional): label values + style (see camera-sites stack config).
