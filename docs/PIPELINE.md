# Pipeline overview

Localmap uses `{targets}` to turn resolved settings or a named configuration
profile into cached spatial inputs, maps, tables, and provenance. Settings and
profiles are entry interfaces; individual targets are implementation stages,
not the onboarding route.

## Settings-first flow

```text
settings YAML
  -> run_settings()
  -> cfg_read(base profile)
  -> resolved run config under outputs/<project>/run_config.yaml
  -> cfg target
  -> AOI, sites, occurrence/camera data, and layer acquisition
  -> maps, panels, attributes, attribution, and run manifest
```

After `make bootstrap`, the source checkout route loads `localmap` before
invoking the settings API:

```sh
Rscript scripts/run_project.R settings.example.yaml
```

After the package has been installed, the equivalent public API route is:

```r
localmap::run_settings("settings.example.yaml")
```

The authoritative settings fields and input requirements are in
[Simplified settings workflow](settings.md); complete profile semantics are in
[Config reference](config_reference.md).

## Profile flow

The direct profile route begins at `cfg_read()`. Its major branches are:

- AOI and camera-site inputs feed camera maps, coverage, and overview maps.
- Species requests feed ALA resolution/acquisition or configured occurrence
  fixtures, then the occurrence map.
- Imagery and analysis-layer registries feed cached/placeholder layers,
  previews, and site-attribute extraction.
- Map products feed panel assembly.
- Declared outputs feed attribution, manifest validation, and the report
  summary.

The exact target graph remains defined in `_targets.R`; use
`targets::tar_visnetwork()` for current dependencies rather than treating this
conceptual overview as a target-name contract.

## Deterministic JC profile

From a clean checkout, use exactly:

```sh
make bootstrap
LOCALMAP_ALLOW_NETWORK=0 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci make pipeline
```

`jc_ci` inherits the JC configuration but uses packaged occurrence and
camera-site fixtures, offline WMS/ArcGIS placeholders, and disabled topographic
tiles. It does not promise `outputs/jc/maps/species_topo.png`. The placeholder
images exercise downstream composition and provenance; they do not represent
successful live service retrieval.

## Outputs and reruns

Products are grouped under `outputs/<profile>/` or the configured project output
directory. Runtime caches live under `data/cache/`; `{targets}` and deterministic
cache keys avoid unnecessary reacquisition. Delete or invalidate caches only
when the source/configuration contract requires it, then review regenerated
artifacts according to [Workflow](workflow.md).
