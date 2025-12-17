# localmap_tas — Product brief

## Summary

localmap_tas is a reproducible workflow for generating **publication-quality local maps of field sites in Tasmania**. Users specify a target location (centroid), map extent, site coordinates, and desired GIS layers (from The List and other sources). The workflow fetches and caches spatial layers, renders polished map panels, and can optionally extract per-site attributes from selected layers.

## Target users

- Ecologists and conservation biologists
- Land managers and practitioners
- Students learning reproducible GIS workflows in R

## Primary user outcomes

1. **Fast, repeatable figure generation** for manuscripts and reports:
   - A site overview map (basemap + site points + optional coverage polygon)
   - Multi-panel figures showing key covariates (e.g., vegetation, elevation, slope, canopy)

2. **Traceable provenance**:
   - Every layer used in a figure is recorded (source, request params, CRS, date)
   - Cached artefacts are reused across runs

3. **Optional site enrichment**:
   - Extract raster/vector attributes at site points and write a tidy table

## Core workflow (UX)

1. Edit `config/config.yaml`:
   - site points input (CSV / GeoPackage)
   - centroid + bounding box size (and optional rotation)
   - list of layers/panels to render
2. Run a single command:
   - `targets::tar_make()` (or `make pipeline`)
3. Collect outputs from `outputs/`:
   - `outputs/maps/` (single maps + panels)
   - `outputs/tables/` (optional extracted attributes)
   - `outputs/provenance/` (metadata)

## Non-goals

- Interactive web maps or a Shiny app (not in v1.0 scope)
- A full general-purpose GIS replacement
- Global-scale mapping; the default assumptions are Tasmania-centric

## Constraints & assumptions

- R 4.5.2+
- Reproducibility: `renv` is the source of truth for the environment
- Orchestration: `{targets}` is the canonical workflow runner
- Spatial stack: `sf` and `terra` for geometry/raster operations; plotting via `ggplot2` (with optional extensions)
- Primary data source: Land Tasmania “The List” open data services and downloads
- The workflow must degrade gracefully when offline (placeholders + warnings)

## Definition of “publication quality”

- Consistent framing and CRS across panels
- Scale bars and north arrows where appropriate
- Configurable labels, fonts, and panel layout
- Outputs at 300+ DPI suitable for manuscript figures
