# Layer registry guide

This guide covers imagery selection, attribution, offline behavior, and
interpretation for `data.layers` in `config/config.yaml`. Analysis-grade vector
and raster inputs use `data.analysis_layers`; their complete fields are in the
[configuration reference](config_reference.md).

## Choose a layer role

- Use `wms` or `arcgis_export` for rendered contextual imagery. These products
  can become visible placeholders when network access is unavailable.
- Use `file` for a local image whose origin and licensing are already known.
- Use `data.analysis_layers` when pixels or vector features feed site-attribute
  extraction. Configure an offline fixture where supported; do not treat an
  imagery placeholder as analysis data.

Every imagery entry needs a unique `id`, a `type`, and `attribution` containing
at least `source`. Add `license` and `credit` whenever the provider supplies
them. Confirm that the source scale, CRS, currency, resolution, and licence fit
the intended scientific interpretation before selecting it.

## WMS example

```yaml
data:
  layers:
    - id: "tasveg_wms"
      type: "wms"
      url: "https://services.thelist.tas.gov.au/arcgis/services/Public/NaturalEnvironment/MapServer/WMSServer"
      layers:
        - "TASVEG_4.0_Groups55513"
      styles: ""
      crs: "EPSG:3857"
      format: "image/png"
      width: 1600
      height: 1600
      dpi: 96
      output_path: "outputs/jc/layers/tasveg_wms.png"
      offline: true
      attribution:
        source: "The LIST"
        license: "CC BY 4.0"
        credit: "TASVEG"
```

## ArcGIS export example

```yaml
data:
  layers:
    - id: "topography_arcgis"
      type: "arcgis_export"
      url: "https://services.thelist.tas.gov.au/arcgis/rest/services/Public/TopographyAndRelief/MapServer/export"
      crs: "EPSG:3857"
      format: "png"
      width: 1600
      height: 1600
      dpi: 96
      output_path: "outputs/jc/layers/topography_arcgis.png"
      offline: true
      attribution:
        source: "The LIST"
        license: "CC BY 4.0"
        credit: "Topography"
```

## Local-file example

```yaml
data:
  layers:
    - id: "local_raster"
      type: "file"
      path: "inst/extdata/local_raster.png"
      output_path: "outputs/jc/layers/local_raster.png"
      attribution:
        source: "Local raster"
```

## Use layers in maps

Overview maps reference layer IDs rather than repeating source definitions:

```yaml
data:
  overview_map:
    base_layer_id: "tasveg_wms"
    overlays:
      - id: "topography_arcgis"
        opacity: 0.35
```

Check overlay CRS/alignment, opacity, labels, and whether the provider's useful
scale matches the AOI. A successfully composed panel is not by itself evidence
that every source was acquired live.

## Provenance, cache, and placeholders

- Imagery outputs have `.yml` sidecars with request and status metadata. Cached
  imagery lives under `data/cache/` with deterministic keys.
- `offline: true` or `LOCALMAP_ALLOW_NETWORK=0` forces an imagery placeholder
  where that source supports graceful offline behavior. Expected warnings make
  this substitution explicit.
- `status: offline_placeholder` means the PNG is layout evidence only, not
  fetched imagery and not a basis for ecological interpretation.
- `status: cache_hit` means an existing acquired cache entry was reused; inspect
  its request/provenance rather than assuming freshness.
- `status: offline_fixture` identifies packaged/local analysis evidence used in
  place of a remote source. It is deterministic demonstration evidence, not a
  live-service check.
- Attribution remains required for configured sources even when a placeholder
  is rendered, because the final live workflow is designed around that source.

Review layer sidecars together with `provenance/attribution.md` and
`provenance/run_manifest.yml`, then inspect the selected maps and tables under
the [workflow](workflow.md) artefact-review cycle.
