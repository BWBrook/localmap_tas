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

## Real-data settings route

`settings.example.yaml` is a real-data-only template. Before running it,
`site.csv` must exist in the configured input directory with `site`, `lat`, and
`lon` columns. `obs.csv` and `op.csv` are optional.

```r
localmap::run_settings("settings.example.yaml")
```

The command resolves the selected base profile, writes
`outputs/<project>/run_config.yaml`, and runs the standard pipeline. The shell
wrapper provides the same route:

```sh
Rscript scripts/run_project.R settings.example.yaml
```

See the [settings guide](../quarto/settings.html) for field resolution and input
requirements, the [configuration reference](../quarto/config_reference.html)
for the full profile schema, and the [layer guide](../quarto/layers_guide.html)
before using live or local spatial sources.

## Outputs and interpretation

Outputs are written under `outputs/<profile>/` or the configured project output
directory and are ignored by Git. Read
[the output schema](../quarto/output_schema_v1.html) alongside provenance
sidecars and the attribution report before interpreting a map or extracted
value.

## Contributors

The supported commands and review order are in
[Development Notes](../quarto/DEVELOPMENT.html). The mandatory implementation
and artifact-review process is in [Workflow](../quarto/workflow.html);
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
