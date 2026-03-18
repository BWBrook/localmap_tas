# localmap_tas — Reproducible local mapping workflow for Tasmania

localmap_tas is an R-based workflow for generating **publication-quality maps of field sites in Tasmania**.
You configure a site (points + extent) and desired GIS layers (from The List and elsewhere), then run a reproducible pipeline to produce map figures and (optionally) site-level extracted attributes.

## What you get

- A **site overview map** (basemap + site points + annotations)
- A **multi-panel figure** (e.g., orthophoto, vegetation, elevation/slope, canopy)
- Optional **site attribute extraction** (tidy table with provenance)
- Reproducible runs via `renv` + `{targets}`

## Quickstart (local)

1. Restore the R environment:

```r
renv::restore(prompt = FALSE)
```

On macOS, install the required geospatial/runtime libraries once first:

```sh
brew install gdal geos proj udunits apache-arrow
```

2. Refresh package metadata (recommended for contributors):

```r
devtools::document()
```

3. Run the pipeline:

```r
targets::tar_make()
```

Outputs are written to `outputs/` (ignored by git).

Optional helper for non-`renv` workflows:

```r
source("dependencies.R")
install_project_dependencies()
```

QA/bootstrap for contributors who want lint and package checks:

```sh
make bootstrap-qa
make actionlint
make lint
make check
```

Optional local dataset (Judbury camera study):

```r
Sys.setenv(R_CONFIG_ACTIVE = "jc", TARGETS_PROFILE = "ci")
targets::tar_make(names = c("camera_sites_file", "camera_sites_data", "aoi", "aoi_debug_plot"))
```

## Configuration

Configuration lives in `config/config.yaml` and supports multiple profiles.
Typical configuration includes:

* site points input path (CSV/GeoPackage)
* centroid and AOI size
* layer/panel definitions
* output paths and styling

See:

* `docs/product_brief.md`
* `docs/architecture.md`
* `docs/config_reference.md`
* `docs/output_schema_v1.md`
* `docs/roadmap.md`

## Data sources and attribution

This project is designed to work with spatial data from Land Tasmania’s “The List” open data services and downloads, as well as other sources.
You are responsible for ensuring appropriate attribution and usage compliance for any layers you include in your figures.

## Development

Common tasks:

* Bootstrap QA tools: `make bootstrap-qa`
* Lint GitHub Actions workflows: `make actionlint`
* Run lint: `make lint`
* Run tests: `make test`
* Run pipeline: `make pipeline`
* Run R CMD check: `make check`

The GitHub Actions workflow provisions the system libraries required by `{units}`,
`{sf}`, and `{igraph}`, and uses `r-lib/actions/setup-pandoc@v2` so
`R CMD check` can rebuild the vignette consistently.
For local macOS development, the equivalent Homebrew prerequisites are
`gdal`, `geos`, `proj`, `udunits`, and `apache-arrow`.

See `docs/workflow.md` for the required engineering and artefact-review workflow.

## License

MIT (see LICENSE).
