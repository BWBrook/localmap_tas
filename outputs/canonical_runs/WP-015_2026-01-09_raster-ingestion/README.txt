WP-015 Raster ingestion v1 (2026-01-09)

Command:
  R_CONFIG_ACTIVE=jc TARGETS_PROFILE=ci Rscript -e 'targets::tar_make(names = c("analysis_layer_files","analysis_layer_provenance_files"))'

Artefacts:
  jc_dem.tif
  jc_dem.tif.yml
  (JC profile)
