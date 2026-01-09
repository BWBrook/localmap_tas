WP-018 Provenance + attribution outputs v1 (2026-01-09)

Command:
  R_CONFIG_ACTIVE=jc TARGETS_PROFILE=ci Rscript -e 'targets::tar_make(names = c("analysis_provenance","attribution_report","run_manifest"))'

Artefacts:
  analysis_layers.csv
  attribution.md
  run_manifest.yml
  (JC profile)
