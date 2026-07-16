# localmap_tas product brief

## Product posture

`localmap` is a settings-first R package and reproducible `{targets}` workflow
for configured Tasmanian field-site mapping. Users provide site coordinates,
choose an AOI and spatial layers, and receive manuscript-ready maps, optional
site attributes, and provenance that records sources and processing context.

The product is Tasmania-centric rather than a general-purpose GIS or an
interactive web-mapping application. Its primary users are ecologists,
conservation practitioners, land managers, and students who need repeatable
local spatial products.

## Primary outcomes

1. Consistently framed overview, camera-site, occurrence, and multi-panel maps.
2. Optional long and wide site-attribute tables derived from configured raster
   and vector layers.
3. Cached acquisitions, attribution, and run manifests that make outputs
   reviewable and reproducible.
4. Explicit offline degradation: imagery placeholders carry warnings and
   provenance rather than silently representing live data.

The product has exactly two workflows: the deterministic offline JC
demonstration and the real-data settings workflow; the checkout wrapper and
installed-package API are invocation contexts for that same real-data workflow.

## Deterministic demonstration route

The repository demonstration is the two-step offline JC profile:

```sh
make bootstrap
LOCALMAP_ALLOW_NETWORK=0 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci make pipeline
```

`jc_ci` uses packaged occurrence and camera-site fixtures, offline WMS/ArcGIS
placeholders, and disabled topographic tiles. It does not promise
`outputs/jc/maps/species_topo.png`. The route demonstrates pipeline assembly and
artifact contracts, not successful live imagery acquisition.

## Real-data settings route

`settings.example.yaml` is real-data only. Before running it, `site.csv` must
exist in the configured input directory with `site`, `lat`, and `lon` columns;
`obs.csv` and `op.csv` are optional.

After `make bootstrap`, the checkout invocation context loads the source package:

```sh
Rscript scripts/run_project.R settings.example.yaml
```

After `localmap` has been installed as an R package, the equivalent public API
invocation context is:

```r
localmap::run_settings("settings.example.yaml")
```

The authoritative field and resolution rules are in
[Simplified settings workflow](settings.md). Advanced profile semantics remain
in [Config reference](config_reference.md).

## Constraints

- R 4.6.x with the project `renv` lockfile as the dependency source of truth.
- `{targets}` is the canonical pipeline runner; `sf` and `terra` provide the
  spatial stack.
- Land Tasmania LIST services and configured local/remote sources require
  source-specific attribution and licensing review.
- Network and large-download access must be explicit. Offline placeholders and
  fixtures must remain distinguishable from fetched live data.

Publication quality means coherent AOI framing and CRS, legible annotations,
consistent panel layout, appropriate resolution, and provenance that supports
scientific interpretation. Visual review remains required after technical
tests pass.
