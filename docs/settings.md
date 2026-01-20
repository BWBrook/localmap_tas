# Simplified settings workflow

This project supports a lightweight `settings.yaml` overlay so new users do not need to edit `config/config.yaml` or understand the full `{targets}` configuration.

## Quick start

1. Copy the template:

```
cp settings.example.yaml settings.yaml
```

2. Edit `settings.yaml` (project name, input folder, and layer toggles).
3. Run the pipeline:

```
Rscript scripts/run_project.R settings.yaml
```

This writes a run-specific config to `outputs/<project>/run_config.yaml` and runs the standard targets pipeline using that configuration.

## Minimal required inputs

- `input_dir` should contain `site.csv` with at least:
  - `site`, `lat`, `lon`
- Optional:
  - `obs.csv` (for counts)
  - `op.csv` (for operational days)

If `count` and `rd` already exist in `site.csv`, they are used directly.

## Settings fields

- `project` (string): project name used for outputs (default = input folder name).
- `base_profile` (string): base config profile to start from (default = `jc`).
- `input_dir` (string): folder containing `site.csv` (plus optional `obs.csv`, `op.csv`).
- `central_site` (string, optional): focal site for maps; if omitted, uses the first site.
- `aoi` (list, optional): `mode`, `buffer_km`, `size_km`, `rotation_deg`.
- `camera_sites.bbox_half_km` (numeric, optional): map extent for camera-site map.
- `layers.include` (list): map layers to include (`orthophoto`, `tasveg`, `topography`, `roads`, `localities`).
- `analysis_layers.include` (list): analysis layers to include (`dem`, `slope`, `canopy_height`, `ndvi`, `nbr`, `climate`, `tasveg`, `tasveg_class`, `fire`, `geology`, `land_tenure`, `reserve_estate`, `soil_ph`).
- `outputs.dir` (string): output root (default = `outputs/<project>`).

## Notes

- Layers like `ndvi`/`nbr` automatically include their `multiband` dependency.
- `slope` automatically includes `dem`.
- Settings are merged with a known-good base config profile; unspecified fields keep the default behavior.
