testthat::test_that("provenance outputs capture layer metadata", {
  layers <- tibble::tibble(
    id = "imagery1",
    type = "wms",
    path = "outputs/jc/layers/imagery1.png",
    provenance_path = "outputs/jc/layers/imagery1.png.yml",
    cache_path = "data/cache/imagery1.png",
    attribution_source = "Imagery Source",
    attribution_license = "CC BY",
    attribution_credit = "Imagery Credit"
  )
  analysis_layers <- tibble::tibble(
    id = "analysis1",
    type = "raster_file",
    path = "outputs/jc/analysis/raster/analysis1.tif",
    provenance_path = "outputs/jc/analysis/raster/analysis1.tif.yml",
    cache_path = "data/cache/analysis1.tif",
    source_id = NA_character_,
    attribution_source = "Analysis Source",
    attribution_license = "CC BY",
    attribution_credit = "Analysis Credit"
  )

  prov_path <- tempfile(fileext = ".csv")
  attr_path <- tempfile(fileext = ".md")
  cfg_path <- tempfile(fileext = ".yml")
  manifest_path <- tempfile(fileext = ".csv")
  run_path <- tempfile(fileext = ".yml")
  writeLines("schema_version: 2", cfg_path)
  writeLines("output_id,type,path", manifest_path)

  prov_out <- localmap:::build_layer_provenance(
    layers = layers,
    analysis_layers = analysis_layers,
    output_path = prov_path
  )
  testthat::expect_true(file.exists(prov_out))
  prov_tbl <- utils::read.csv(prov_out)
  testthat::expect_true(all(c("imagery1", "analysis1") %in% prov_tbl$layer_id))

  attr_out <- localmap:::write_attribution_report(
    layers = layers,
    analysis_layers = analysis_layers,
    output_path = attr_path
  )
  testthat::expect_true(file.exists(attr_out))
  attr_lines <- readLines(attr_out)
  testthat::expect_true(any(grepl("imagery1", attr_lines)))
  testthat::expect_true(any(grepl("analysis1", attr_lines)))

  run_out <- localmap:::write_run_manifest(
    cfg = list(schema_version = 2),
    cfg_file = cfg_path,
    layer_registry = list(list(
      id = "imagery1",
      type = "wms",
      url = "http://example",
      attribution = list(source = "Imagery Source")
    )),
    layer_outputs = layers,
    analysis_layers_cfg = list(list(
      id = "analysis1",
      type = "raster_file",
      path = "analysis1.tif",
      attribution = list(source = "Analysis Source")
    )),
    analysis_layers = analysis_layers,
    output_manifest_file = manifest_path,
    output_path = run_path
  )
  testthat::expect_true(file.exists(run_out))
  run_lines <- readLines(run_out)
  testthat::expect_true(any(grepl("layers.imagery.imagery1", run_lines)))
  testthat::expect_true(any(grepl("layers.analysis.analysis1", run_lines)))
})

testthat::test_that("imagery provenance includes required machine-readable keys", {
  prov_path <- tempfile(fileext = ".yml")
  localmap:::imagery_write_provenance(
    prov_path,
    list(
      status = "offline_placeholder",
      output_path = "outputs/demo/maps/species_occurrences.png",
      params = list(width = 64, height = 64)
    )
  )

  lines <- readLines(prov_path)
  testthat::expect_true(any(grepl("^status: offline_placeholder$", lines)))
  testthat::expect_true(any(grepl(
    "^output_path: outputs/demo/maps/species_occurrences.png$",
    lines
  )))
  testthat::expect_true(any(grepl("^params.width: 64$", lines)))
  testthat::expect_true(any(grepl("^params.height: 64$", lines)))
  testthat::expect_true(any(grepl("^timestamp:", lines)))
})
