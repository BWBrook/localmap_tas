WP-018a Analysis layer previews (2026-01-10)

Command:
  R_CONFIG_ACTIVE=jc TARGETS_PROFILE=ci Rscript -e 'targets::tar_make(names = c("analysis_layer_preview_files"))'

Artefacts:
  jc_habitats.png
  jc_dem.png
  jc_multiband.png
  jc_slope.png
  jc_ndvi.png
  jc_nbr.png
  (JC profile)
