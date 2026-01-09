# Layer registry guide

This guide describes how to add imagery layers via `data.layers` in `config/config.yaml`.

## 1) Define a layer

Each layer entry must include:
- `id`: unique ID used by maps and panels.
- `type`: `wms`, `arcgis_export`, or `file`.
- `attribution`: list with at least `source` (and optionally `license`, `credit`).

### WMS example
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
      output_path: "outputs/layers/tasveg_wms.png"
      offline: true
      attribution:
        source: "The LIST"
        license: "CC BY 4.0"
        credit: "TASVEG"
```

### ArcGIS export example
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
      output_path: "outputs/layers/topography_arcgis.png"
      offline: true
      attribution:
        source: "The LIST"
        license: "CC BY 4.0"
        credit: "Topography"
```

### File example
```yaml
data:
  layers:
    - id: "local_raster"
      type: "file"
      path: "inst/extdata/local_raster.png"
      output_path: "outputs/layers/local_raster.png"
      attribution:
        source: "Local raster"
```

## 2) Use layers in maps

Overview maps can reference layer IDs:

```yaml
data:
  overview_map:
    base_layer_id: "tasveg_wms"
    overlays:
      - id: "topography_arcgis"
        opacity: 0.35
```

## 3) Provenance and caching

- Each imagery output writes a sidecar `.yml` provenance file with request metadata.
- Cached imagery is stored under `data/cache/` with deterministic keys.
- Use `offline: true` to force placeholder imagery (CI-safe).
