# WP-014 Log — Vector acquisition v1

Date: 2026-01-09

## Summary
- Added AOI-clipped vector acquisition with cached GeoPackage output and provenance sidecar.
- JC habitat fixture serves as the default offline-safe vector source.

## Artefacts
- Canonical run folder: `outputs/canonical_runs/WP-014_2026-01-09_vector-acquisition/`
  - `jc_habitats.gpkg`
  - `jc_habitats.gpkg.yml`

## Sanity checks
- Vector bbox matches AOI bbox in EPSG:28355; geometries fall entirely within AOI.
- Fixture attributes `habitat` and `zone` are preserved after clipping.
- `sf::st_intersection` emits the expected “attribute variables are assumed to be spatially constant” warning.

## Notes
- The fixture provides deterministic offline behaviour; swap to ArcGIS vectors when network sources are needed.
