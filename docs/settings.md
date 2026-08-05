# Simplified settings workflow

The settings interface is the primary real-data route. It overlays a concise
project description onto a complete base profile, writes the resolved run
configuration, and runs the standard `{targets}` pipeline.

`settings.example.yaml` is real-data only. Before using it, the configured
input directory must contain `site.csv` with `site`, `lat`, and `lon` columns.
`obs.csv` and `op.csv` are optional. These input files are not included in the
checkout.

After `make bootstrap`, the checkout wrapper loads the source package and runs
the example settings path:

```sh
Rscript scripts/run_project.R settings.example.yaml
```

For a copied settings file, pass that path to the same wrapper. If `localmap`
has been installed as an R package, the equivalent public API route is:

```r
localmap::run_settings("settings.example.yaml")
```

## Input tables

- `site.csv` is required. Existing `count`/`obs` and `rd` columns are used when
  present.
- `obs.csv` is optional. When site counts are absent, records are aggregated by
  site; a `count` column is summed when present, otherwise rows are counted.
- `op.csv` is optional. When `rd` is absent, numeric operational-day values are
  summed by site.

Set `obs_file` or `op_file` to an empty string when the optional file is absent.
Input coordinates are latitude/longitude in EPSG:4326.

## Field resolution

- `project`: output identity. If omitted, it resolves from the input-directory
  basename, then falls back to `project`.
- `base_profile`: full configuration to overlay; defaults to `jc`.
- `input_dir`: input-table directory; defaults to `data/raw/<project>`.
- `site_file`: required-site filename; defaults to `site.csv`.
- `obs_file` and `op_file`: optional filenames; each defaults to its conventional
  name unless explicitly set to an empty string.
- `central_site`: focal map site; defaults to the first site when the input is
  readable.
- `aoi`: optional `mode`, `buffer_km`, `size_km`, and `rotation_deg` overrides.
- `camera_sites.bbox_half_km`: optional camera-map half-width in kilometres.
- `layers.include`: imagery keys `orthophoto`, `tasveg`, `topography`, `roads`,
  and `localities`.
- `analysis_layers.include`: analysis keys `dem`, `slope`, `canopy_height`,
  `ndvi`, `nbr`, `climate`, `tasveg`, `tasveg_class`, `fire`, `geology`,
  `land_tenure`, `reserve_estate`, and `soil_ph`.
- `products`: optional target selector. Choose `attributes`, `atlas`, `figure`,
  or any subset; `all` is the default and selects all three product groups.
- `large_downloads.allow`: optional explicit large-download gate.
- `outputs.dir`: run output root; defaults to `outputs/<project>`.

Dependency resolution is automatic: `slope` includes `dem`; `ndvi` or `nbr`
includes `multiband`; `tasveg` includes `tasveg_class`. Unspecified values retain
the selected base profile's behavior. See the
[configuration reference](config_reference.md) for that complete schema.

## Resolution and outputs

`run_settings()` reads either a top-level `settings` mapping or a direct mapping,
resolves the base profile with `cfg_read()`, applies the settings, and rewrites
profile output paths beneath the configured output directory. It writes
`outputs/<project>/run_config.yaml` (or `<outputs.dir>/run_config.yaml`), runs the
selected product targets with that generated configuration, restores the caller's
relevant environment variables, and returns the run-config path. When `products`
is omitted, the runner selects `all`. An explicit non-empty `targets` argument
remains an advanced override. The selected products are recorded in the generated
run config and run-manifest provenance.

Review maps, tables, layer sidecars, `provenance/attribution.md`, and
`provenance/run_manifest.yml` together. The [output guide](output_schema_v1.md)
explains interpretation; the [layer guide](layers_guide.md) distinguishes live
imagery, cache hits, fixtures, and placeholders.
