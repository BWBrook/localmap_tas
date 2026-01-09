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
