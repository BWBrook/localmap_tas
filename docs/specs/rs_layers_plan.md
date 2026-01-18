# RS layers expansion plan (CHM, fire, soils, geology/tenure, climate normals)

## Purpose
Add ecologically relevant remote-sensing (RS) layers and derived site attributes for the JC and TAS canonical profiles, with staged verification and reproducibility safeguards.

## Scope
**Priority layers**
1. Canopy height (CHM, meters)
2. Fire attributes (FIRESENS, FLAMMAB)
3. Soil pH (0–15 cm)
4. Geology + land tenure + reserve estate
5. Climate normals (baseline climatologies; bioclim variables)

## Data sources (authoritative)
- **Canopy height (CHM 2 m)**: LIST Tree Canopy Height Model (LiDAR-derived, 2 m) with Raster services; statewide coverage where LiDAR exists. Source metadata page: LIST Tree Canopy Height Model. citeturn2search0
- **Fire attributes (FIRESENS, FLAMMAB)**: LIST TASVEG 4.0 Fire Attributes (MapServer layer 91; includes FLAMMAB, FIRESENS, VEGCODE/VEG_GROUP). citeturn1search1
- **Soil pH**: LIST/DPIPWE soil pH (0–15 cm) 30 m raster. citeturn0search0
- **Geology**: Mineral Resources Tasmania GeologyLIST MapServer. citeturn2search1
- **Land tenure**: LIST OpenDataWFS Land Tenure layer. citeturn0search2
- **Reserve estate**: Tasmanian Reserve Estate Spatial Layer (NRE). citeturn1search2
- **Climate normals**: WorldClim 2.x (bioclim variables; 30 arc‑sec). citeturn0search3turn1search3

## Configuration & toggles
- Add a **global toggle** for large downloads, default **ON** in `default`/`jc`/`tas_canonical` but **OFF** in `ci`.
  - Example: `data.large_downloads.allow: true`
  - If disabled and the CHM dataset is not present, emit a warning and skip CHM with a clear message.
  - Always log the choice in provenance sidecars.

## Staged implementation with checkpoints

### Stage 1 — Canopy Height (CHM)
**Work items**
- Add CHM layer to `analysis_layers` (JC + TAS) as `raster_arcgis` (if service exists) or `raster_file` backed by a cached download.
- Implement a **download-once cache** if using a full-file source; crop to AOI for analysis.
- Add `canopy_height_m` attribute to `site_attributes` (mean/median at site point).
- Add preview PNGs to `outputs/analysis/*/raster/` and (optionally) map overlay in `outputs/maps`.

**Verification**
- Run `targets::tar_make()` for CHM targets only.
- Check CHM preview shows plausible meter-scale variation.
- Confirm CHM values at known sites are non‑NA where LiDAR coverage exists.
- Add 3–6 bullet notes to `docs/AGENT_NOTES.md` (sanity check).

### Stage 2 — Fire attributes (FIRESENS/FLAMMAB)
**Work items**
- Add TASVEG Fire Attributes vector layer to `analysis_layers` (MapServer/91).
- Add `firesens` and `flammab` columns in `site_attributes`.
- Add WMS overlay map for fire classes with legend.

**Verification**
- Generate preview map and check legend only shows AOI classes.
- Confirm categorical values in tables are non‑empty for JC.

### Stage 3 — Soil pH
**Work items**
- Add soil pH raster (0–15 cm) to `analysis_layers`.
- Add `soil_ph` attribute for each site.
- Add preview PNG + map panel.

**Verification**
- Check `soil_ph` values are within 0–14 range.
- Confirm spatial pattern not obviously misaligned with AOI.

### Stage 4 — Geology + land tenure + reserve estate
**Work items**
- Add geology polygon layer; extract `geology_unit` (code or description).
- Add land tenure layer; extract `tenure_class`.
- Add reserve estate layer; extract `reserve_class` or `reserve_status`.
- Add optional overlay maps (toggleable).

**Verification**
- Check overlays align with orthophoto/roads.
- Confirm table columns populated (or NA if outside coverage).

### Stage 5 — Climate normals
**Work items**
- Add WorldClim bioclim raster(s) (Bio1, Bio12; possibly Bio4/Bio15 for seasonality).
- Add `bio1_mean_temp_c`, `bio12_annual_precip_mm`, etc. to `site_attributes`.
- Add preview PNGs for at least 1–2 bioclim variables.

**Verification**
- Check values are within plausible climate ranges for Tasmania.
- Confirm rasters align with AOI.

## Artefact review (required)
For each stage:
1. Build artefacts (targets).
2. Visual sanity check (alignment, scale bar, graticules).
3. Log interpretation in `docs/AGENT_NOTES.md`.
4. Iterate if anything looks off.

## Documentation updates
- `docs/output_schema_v1.md` + `inst/extdata/output_manifest_*.csv`
- `docs/config_reference.md`
- `docs/decisions.md` for any non‑trivial choice (e.g., WorldClim vs. BoM).

## Acceptance checklist
- All new layers fetchable with clear warnings on offline/disabled state.
- Tables contain required columns with consistent naming in JC/TAS.
- CI remains green (lint/tests/RCMD check).
- Outputs reviewed and logged.
