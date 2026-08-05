testthat::test_that("output manifest helper maps profiles to the correct manifest", {
  testthat::expect_equal(
    localmap:::output_manifest_file_for_profile("demo"),
    "inst/extdata/output_manifest_demo.csv"
  )
  testthat::expect_equal(
    localmap:::output_manifest_file_for_profile("tas_canonical"),
    "inst/extdata/output_manifest_tas_canonical.csv"
  )
  testthat::expect_equal(
    localmap:::output_manifest_file_for_profile("jc"),
    "inst/extdata/output_manifest_v1.csv"
  )
})

testthat::test_that("tasveg class helpers derive stable ids and lookup paths", {
  testthat::expect_equal(
    localmap:::resolve_tasveg_class_id("demo", c(demo_tasveg_class = "x")),
    "demo_tasveg_class"
  )
  testthat::expect_equal(
    localmap:::resolve_tasveg_class_id("jc", c(other = "x")),
    "jc_tasveg_class"
  )
  testthat::expect_equal(
    localmap:::tasveg_class_lookup_path(
      output_dir = "outputs/demo",
      class_id = "demo_tasveg_class",
      vector_path = NULL
    ),
    file.path("outputs/demo", "analysis", "vector", "demo_tasveg_class_lookup.csv")
  )
})

testthat::test_that("output schema helper returns required demo outputs", {
  ctx <- list(
    species_map = "outputs/demo/maps/species_occurrences.png",
    camera_sites_map = "outputs/demo/maps/camera_sites.png",
    camera_sites_tile = "outputs/demo/tiles/camera_sites_tile.png",
    aoi_debug_plot = "outputs/demo/maps/aoi_debug.png",
    coverage_summary = "outputs/demo/tables/coverage_summary.csv",
    site_attributes_long_file = "outputs/demo/tables/site_attributes_long.parquet",
    site_attributes_wide_file = "outputs/demo/tables/site_attributes_wide.csv",
    layer_output_paths = c(
      tasveg_wms = "outputs/demo/layers/tasveg_wms.png",
      topography_arcgis = "outputs/demo/layers/topography_arcgis.png"
    ),
    layer_provenance_paths = c(
      tasveg_wms = "outputs/demo/layers/tasveg_wms.png.yml",
      topography_arcgis = "outputs/demo/layers/topography_arcgis.png.yml"
    ),
    overview_map = "outputs/demo/maps/overview_map.png",
    panel_figure_png = "outputs/demo/maps/panel_figure.png",
    panel_figure_pdf = "outputs/demo/maps/panel_figure.pdf",
    analysis_layer_paths = c(demo_bio1 = "outputs/demo/analysis/raster/demo_bio1.tif"),
    analysis_layer_provenance_paths = c(
      demo_bio1 = "outputs/demo/analysis/raster/demo_bio1.tif.yml"
    ),
    analysis_layer_preview_paths = c(
      demo_bio1 = "outputs/demo/analysis/raster/demo_bio1.png"
    ),
    analysis_provenance = "outputs/demo/provenance/analysis_layers.csv",
    attribution_report = "outputs/demo/provenance/attribution.md",
    run_manifest = "outputs/demo/provenance/run_manifest.yml"
  )

  outputs <- localmap:::build_output_schema_expected_outputs("demo", ctx)

  testthat::expect_true(all(c(
    "species_map",
    "camera_sites_map",
    "overview_map",
    "panel_figure_png",
    "run_manifest"
  ) %in% names(outputs)))
  testthat::expect_equal(outputs$species_map, ctx$species_map)
  testthat::expect_equal(outputs$wms_layer, ctx$layer_output_paths[["tasveg_wms"]])
})
