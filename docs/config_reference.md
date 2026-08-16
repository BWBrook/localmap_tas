# Config reference (schema v2)

This document describes the configuration schema used by `config/config.yaml`.
The active profile is selected via `R_CONFIG_ACTIVE` (default: `default`).

Most real-data users should begin with the concise
[settings workflow](settings.md), which resolves a small project overlay against
one of these profiles. Use this reference when selecting a base profile or when
the settings interface does not expose the required advanced field. This guide
describes existing configuration semantics; it does not create a second run
interface.

## Schema version

- `schema_version` (integer, required): current schema version. Must be `2`.

## Top-level keys (profile root)

- `data_dir` (string, default: `"data"`): root folder for runtime data.
- `db_path` (string, default: `"data/interim/local.duckdb"`): optional local DB path.
- `sample_frac` (numeric, default: `1.0`): optional sampling fraction for large datasets.
- `data` (list, required): workflow inputs and map settings.
- `ala` (list, required for `figure`/`all` products): ALA / galah configuration.

## `data`

Required:
- `aoi` (list, required): area of interest definition.
- `species_requests` (string, required for `figure`/`all` products): species query CSV path (e.g., `metadata/species_requests.csv`).
- JC profile uses `metadata/species_requests_jc.csv` (species codes from `obs.csv`).
- `occurrence` (list, required for `figure`/`all` products): occurrence settings.
- `camera_sites` (list): camera-site settings.
- `coverage` (list, optional): coverage polygon settings.
- `layers` (list, optional): registry of imagery layers (WMS/ArcGIS/file).
- `analysis_layers` (list, optional): analysis-grade vector/raster layers and derived products.
- `distance_layers` (list, optional): vector layers used to compute distance-to features.
- `overview_map` (list, optional): overview map rendering settings.
- `panel_figure` (list, optional): multi-panel figure assembly settings.

For settings-generated runs, `data$outputs$products` defaults to `all` when it is
omitted. `attributes` and `atlas` selections can omit the occurrence-dependent
`species_requests`, `occurrence`, and top-level `ala` configuration; `figure`
and `all` selections require them. AOI, camera-site, layer, attribute/map, and
provenance validation still applies to every selection. The run-level
`run_manifest` records the selected products, resolved config, and layer
sources, parameters, and paths; review it with layer sidecars, attribution, and
the actual product artefacts. It does not certify that product outputs completed.

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

### `data.distance_layers`

Optional vector layers used to derive `distance_to_*` attributes in site tables.

Each entry supports:
- `id` (string): internal layer identifier.
- `distance_to` (string): label used in output columns (e.g., `road`, `locality`).
- `type` (string): should be `vector_arcgis`.
- `url` (string): ArcGIS REST layer URL (ending in `/MapServer/<layer_id>`).
- `crs` (string, default: `"EPSG:4326"`): query CRS.
- `out_fields` (string, default: `"OBJECTID"`): minimal fields to request.
- `fixture_path`/`fixture_layer` (optional): offline fixture for CI.
- `offline` (logical, default: `false`): force fixture usage.
- `attribution` (list): attribution metadata (at least `source`).

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

- `site_path` (string, required): path to `site.csv` (lat/lon).
- `obs_path` (string, optional): path to `obs.csv` (site + datetime + optional `count`).
- `op_path` (string, optional): path to `op.csv` (operational days by site, wide format).
- `output_path` (string, optional): derived output CSV (defaults to `data/interim/jc_camera_sites.csv`).

Derived fields:
- `obs`: total observed individuals per site (from `site.csv` `count`/`obs`, else sum of
  `obs.csv$count` if present; otherwise row count).
- `rd`: number of operational days per site (from `site.csv` `rd`, else summed `op.csv` values).

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
- `legend` (list, optional): legend display settings (including `alpha` for transparency).

### `data.camera_sites.stack`

- `panels` (list, optional): explicit panel entries (same format as `data.panel_figure`).
- `paths` (character vector): explicit input PNGs.
- `glob` (character vector): glob patterns.
- `input_dir` (character vector): directories to scan.
- `pattern` (string): file name regex.
- `order` (character vector): preferred ordering patterns.
- `columns`/`rows` (integer): panel layout.
- `gap_px` (numeric): gap between panels.
- `normalize_sizes` (logical, optional): resize panels to a common size before stacking.
- `size_mode` (string, optional): `"min"` or `"max"` target dimensions when normalizing.
- `target_width_px`/`target_height_px` (integer, optional): explicit panel size for resizing.
- `legend_defaults` (list, optional): default legend overlay settings for panels.
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
The `jc` profile represents the Judbury camera-study configuration and expects
its configured real inputs unless settings override them.
The `jc_ci` profile inherits `jc` but uses packaged occurrence and camera-site
fixtures, forces WMS/ArcGIS imagery to offline placeholders, and disables
topographic tiles. It is the deterministic checkout profile and does not produce
or promise `outputs/jc/maps/species_topo.png`.
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
- `legend_path` (string, optional): output path for a fetched legend graphic.
- `legend` (list, optional): legend fetch settings (`show`, `format`, `graphic_width`, `graphic_height`, `source`).
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
  `raster_arcgis`, `raster_wcs`, `raster_geodata`, `raster_remote`,
  `derived_slope`, `derived_ndvi`, `derived_nbr`.
- `output_path` (string, required): output GeoPackage/GeoTIFF path.
- `attribution` (list, required): at least `source`, plus optional `license`, `credit`.
- `skip_attributes` (logical, optional): if TRUE, omit this layer from site-attribute extraction.

Vector file fields (`type: vector_file`):
- `path` (string, required): input vector file path (e.g., GeoPackage).
- `layer` (string, optional): layer name within the GeoPackage.

Vector ArcGIS fields (`type: vector_arcgis`):
- `url` (string, required): ArcGIS REST layer URL (MapServer/FeatureServer).
- `where` (string, optional): filter clause (default `1=1`).
- `out_fields` (string, optional): field list (default `*`).
- `attribute_fields` (list, optional): restrict extracted attributes to these fields.
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
- `geodata_type` (string, optional): `elevation` (default), `soil_world`, or `worldclim`.
- `geodata_var` (string, optional): dataset variable (e.g., `phh2o` for SoilGrids, `bio` for WorldClim).
- `geodata_depth` (numeric, optional): SoilGrids depth in cm (e.g., 15 for 0–15 cm).
- `geodata_stat` (string, optional): SoilGrids statistic (`mean`, `uncertainty`, etc.).
- `geodata_res` (numeric, optional): WorldClim resolution in minutes (e.g., `0.5` for 30 arc‑sec).
- `geodata_version` (string, optional): WorldClim version (default `2.1`).
- `band` (string/integer, optional): band name/number to select from multiband outputs.
- `scale` (numeric, optional): scale factor applied after download (e.g., `0.1` for BIO1).
- `offset` (numeric, optional): additive offset applied after scaling.
- `resolution` (string, optional): for elevation only; `3s` (default) or `30s` (arc-second resolution).
- `geodata_path` (string, optional): cache directory for downloaded tiles.
- `offline` (logical, optional): skip network fetch.
- `fixture_path` (string, optional): local raster fixture used when offline.
- `categorical` (logical, default `false`): if TRUE, use nearest-neighbor resampling.
- `resample` (string, optional): `near`, `bilinear`, or `cubic` (overrides `categorical`).
- `units` (string, optional): units for extracted values (e.g., `m`).

Raster remote fields (`type: raster_remote`):
- `download_url` (string, required): URL to a downloadable raster archive or file.
- `download_dir` (string, optional): cache directory for downloaded archives.
- `download_path` (string, optional): explicit archive filename (overrides basename of URL).
- `download_size_mb` (numeric, optional): expected download size; triggers re-download if smaller.
- `download_zip` (logical, optional): treat download as zip (auto-detected by extension).
- `extract_dir` (string, optional): extraction directory (defaults to `download_dir`).
- `extract_pattern` (string, optional): regex to locate the extracted raster (default `\\.tif$`).
- `extract_file` (string, optional): explicit extracted filename relative to `extract_dir`.
- `extract_path` (string, optional): full path to extracted raster file.
- `large_download` (logical, optional): mark as large download (gated by `data.large_downloads.allow`).

Derived slope (`type: derived_slope`):
- `source_id` (string, required): raster layer ID (DEM).
- `units` (string, optional): `degrees` (default) or `radians`.

Derived indices (`type: derived_ndvi`, `type: derived_nbr`):
- `source_id` (string, required): multiband raster layer ID.
- `bands` (list, required): band mapping (numbers or band-name strings; lists of candidates are allowed).
  - NDVI: `red`, `nir`.
  - NBR: `nir`, `swir2`.

Resampling policy:
- Categorical rasters use `near` (nearest neighbor).
- Continuous rasters default to `bilinear`.

Ordering note:
- Derived layers must appear *after* their `source_id` in `analysis_layers`.

Network access:
- Remote imagery/vector fetches are disabled unless `LOCALMAP_ALLOW_NETWORK=1` is set.
- When network is disabled, imagery uses placeholders; ArcGIS vectors/rasters require a `fixture_path`.
- Large raster downloads are gated by `LOCALMAP_ALLOW_LARGE_DOWNLOADS` (set automatically from config).

Cache invalidation:
- Delete `data/cache/` to force a refetch, or set a new `cache_dir` in the layer config.
- For analysis layers, bump `analysis_cache_version` in `R/analysis_layers.R` if the cache key logic changes.

### `data.large_downloads`

Controls whether large, one-off raster downloads (e.g., statewide CHM) are allowed.

- `allow` (logical, default `true`): when `false`, any analysis layer marked
  `large_download: true` is skipped unless a cached file already exists.

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
- `radius_m` (number, default `0`): one non-negative run-wide extraction radius
  in metres. Omitted or zero uses exact points. A positive value creates metric
  circular buffers and supports continuous raster layers only; categorical
  rasters, vectors, and distance layers are rejected during configuration
  validation with their source names.
- `output_long` (string, optional): path for the canonical long table (parquet).
- `output_wide` (string, optional): path for the convenience wide CSV.

For positive radii, each raster band produces an overlap-area-weighted mean and
a valid-data fraction. The fraction denominator is the full circular buffer,
so raster edges and NODATA reduce coverage; zero valid support gives an `NA`
mean and zero coverage. Statistic and radius are encoded in the long attribute
name and mapped wide column, for example `value_mean_r100m` and
`dem_mean_r100m`. The resolved run config and run manifest record both the
radius and the derived `exact_point` or `buffered` extraction mode.
Buffered extraction requires unrotated auto AOI mode. During resolution,
`buffer_km` (when explicit) or `min_buffer_km` is raised to at least
`radius_m / 1000`; a smaller `max_buffer_km` is raised as well. The effective
margin remains visible in the resolved run config and prevents AOI clipping
from being counted as source-edge or NODATA coverage loss.

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
- `point_colour`/`point_size`/`point_shape`: site marker styling.
- `aoi_colour`/`coverage_colour`: outline and fill styling.
- `scale_bar_location`/`north_arrow_location`: positions for cartographic annotations.

### `data.panel_figure`

- `panels` (list, optional): explicit panel entries. Each entry can include:
  - `path` (string): PNG path to include.
  - `label` (string, optional): panel label (e.g., `a)`).
  - `legend_path` (string, optional): legend PNG to overlay inside the panel.
  - `legend_alpha`/`legend_position`/`legend_width_fraction`/`legend_margin_fraction`
    (optional): legend overlay controls (defaults from `legend_defaults`).
- `paths` (list): panel image paths (legacy fallback when `panels` not provided).
- `order` (list, optional): ordering patterns for panel filenames.
- `columns`/`rows` (integer): panel grid layout.
- `output_path` (string): PNG output path.
- `output_pdf` (string, optional): PDF output path.
- `gap_px` (integer, optional): padding between panels.
- `normalize_sizes` (logical, optional): resize panels to a common size before stacking.
- `size_mode` (string, optional): `"min"` or `"max"` target dimensions when normalizing.
- `target_width_px`/`target_height_px` (integer, optional): explicit panel size for resizing.
- `legend_defaults` (list, optional): default overlay settings (`alpha`, `position`,
  `width_fraction`, `margin_fraction`) for panel legends.
- `labels` (list, optional): label values + style (see camera-sites stack config).
