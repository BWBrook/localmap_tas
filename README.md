# localmap_tas: Reproducible local mapping for Tasmania

`localmap` is an R package and `{targets}` workflow for configured Tasmanian
field-site mapping. It turns site coordinates, an area of interest, and selected
spatial layers into publication-ready maps, site-attribute tables, and explicit
provenance.

## Deterministic JC demonstration

From a clean checkout, restore the project environment and run the offline JC
profile:

```sh
make bootstrap
LOCALMAP_ALLOW_NETWORK=0 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci make pipeline
```

`jc_ci` uses packaged occurrence and camera-site fixtures, offline WMS/ArcGIS
placeholders, and disabled topographic tiles. It does not promise
`outputs/jc/maps/species_topo.png`, and its placeholder imagery is not evidence
of a successful live service request.

The deterministic route produces non-empty evidence including:

- maps under `outputs/jc/maps/`, including species occurrences, overview,
  camera sites, and PNG/PDF panel figures;
- `coverage_summary.csv`, long Parquet attributes, and wide CSV attributes under
  `outputs/jc/tables/`;
- offline `tasveg_wms.png` and `topography_arcgis.png` placeholders under
  `outputs/jc/layers/`; and
- attribution and run-manifest records under `outputs/jc/provenance/`.

## Offline attributes settings route

`settings.attributes-jc.yaml` is a concise exact-point extraction example for
the 13 packaged JC camera sites. It selects the continuous JC DEM and
categorical TASVEG class fixtures, with imagery and distance layers disabled:

```sh
LOCALMAP_ALLOW_NETWORK=0 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 Rscript scripts/run_project.R settings.attributes-jc.yaml
```

Only the attributes product and shared provenance/attribution targets run.
Review the long Parquet and wide CSV tables under
`outputs/jc_attributes_offline/tables/` with their records under
`outputs/jc_attributes_offline/provenance/`. The wide CSV contains only mapped
attributes represented in the long table, followed by available site metadata.

For area summaries, `settings.attributes-buffered-jc.yaml` is a separate
offline DEM-only example using one 100 m circular buffer per site in the
configured metric analysis CRS:

```sh
LOCALMAP_ALLOW_NETWORK=0 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 Rscript scripts/run_project.R settings.attributes-buffered-jc.yaml
```

Its wide table under `outputs/jc_attributes_buffered_r100m/tables/` contains
`dem_mean_r100m` and `dem_valid_fraction_r100m`. Coverage is valid DEM area
divided by the complete circular buffer area, so raster edges and NODATA reduce
the fraction. Buffered extraction rejects categorical, vector, and distance
sources. It also requires an unrotated auto AOI and raises the resolved AOI
margin to at least the extraction radius so internal clipping cannot masquerade
as missing raster coverage. Omit `attributes.radius_m` or set it to zero for
exact-point behavior.

## Real-data settings route

`settings.example.yaml` is a real-data-only template. Before running it,
`site.csv` must exist in the configured input directory with `site`, `lat`, and
`lon` columns. `obs.csv` and `op.csv` are optional. These input files are not
included in the checkout.

After `make bootstrap`, the checkout route loads the source package before
running the settings workflow:

```sh
Rscript scripts/run_project.R settings.example.yaml
```

When `localmap` has been installed as an R package, the public API route is:

```r
localmap::run_settings("settings.example.yaml")
```

Both routes resolve the selected base profile, write
`outputs/<project>/run_config.yaml`, and run the standard pipeline. See the
[settings guide](https://github.com/BWBrook/localmap_tas/blob/main/docs/settings.md)
for field resolution, product selection (`attributes`, `atlas`, `figure`, or
`all`, which is the default), and input requirements, the
[configuration reference](https://github.com/BWBrook/localmap_tas/blob/main/docs/config_reference.md)
for the full profile schema, and the
[layer guide](https://github.com/BWBrook/localmap_tas/blob/main/docs/layers_guide.md)
before using live or local spatial sources.

## Outputs and interpretation

Outputs are written under `outputs/<profile>/` or the configured project output
directory and are ignored by Git. Review the selected maps and tables together
with layer provenance sidecars, the attribution report, and the run manifest.
Follow the artefact-review steps in
[Workflow](https://github.com/BWBrook/localmap_tas/blob/main/docs/workflow.md)
before interpreting a map or extracted value.

## Contributors

The supported commands and review order are in
[Development Notes](https://github.com/BWBrook/localmap_tas/blob/main/docs/DEVELOPMENT.qmd).
The mandatory implementation and artifact-review process is in
[Workflow](https://github.com/BWBrook/localmap_tas/blob/main/docs/workflow.md);
architecture and scope remain maintained in `docs/architecture.md` and
`docs/roadmap.md`.

On macOS, the spatial/runtime prerequisites are:

```sh
brew install gdal geos proj udunits apache-arrow
```

Common gates are `make test`, `make lint`, `make docs`, `make site`, and
`make check`. Run `make bootstrap-qa` before lint or package checks.

## License

MIT (see `LICENSE`).
