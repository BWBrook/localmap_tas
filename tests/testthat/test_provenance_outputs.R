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
  run_path <- tempfile(fileext = ".yml")
  writeLines("schema_version: 2", cfg_path)

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
    cfg = list(
      schema_version = 2,
      data = list(
        outputs = list(
          products = "attributes",
          settings_path = "settings.attributes-jc.yaml"
        ),
        camera_sites = list(jc = list(site_path = "inst/extdata/sites.csv")),
        attributes = list(
          output_long = "outputs/attributes.parquet",
          output_wide = "outputs/attributes.csv"
        )
      )
    ),
    cfg_file = cfg_path,
    layer_registry = list(list(
      id = "imagery1",
      type = "wms",
      url = "http://example",
      layers = "LIST",
      crs = "EPSG:3857",
      width = 512,
      height = 512,
      format = "image/png",
      attribution = list(source = "Imagery Source")
    )),
    layer_outputs = layers,
    analysis_layers_cfg = list(list(
      id = "analysis1",
      type = "raster_file",
      path = "analysis1.tif",
      crs = "EPSG:28355",
      categorical = FALSE,
      bands = 1,
      units = "m",
      attribution = list(source = "Analysis Source")
    )),
    analysis_layers = analysis_layers,
    output_path = run_path
  )
  testthat::expect_true(file.exists(run_out))
  run_lines <- readLines(run_out)
  testthat::expect_true(any(grepl("run.products: attributes", run_lines)))
  testthat::expect_true(any(grepl(
    "run.settings_path: settings.attributes-jc.yaml",
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl("config.schema_version: 2", run_lines)))
  testthat::expect_true(any(grepl(
    sprintf("config.path: %s", cfg_path),
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    sprintf("config.hash: %s", unname(tools::md5sum(cfg_path))),
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "layers.imagery.imagery1.source: http://example",
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "layers.imagery.imagery1.params.layers: LIST",
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "layers.imagery.imagery1.output_path: outputs/jc/layers/imagery1.png",
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "layers.imagery.imagery1.provenance_path: outputs/jc/layers/imagery1.png.yml",
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "layers.imagery.imagery1.cache_path: data/cache/imagery1.png",
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "layers.imagery.imagery1.attribution.source: Imagery Source",
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "layers.analysis.analysis1.source: analysis1.tif",
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "layers.analysis.analysis1.params.crs: EPSG:28355",
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "attributes.site_input_path: inst/extdata/sites.csv",
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "attributes.configured_long_path: outputs/attributes.parquet",
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "attributes.configured_wide_path: outputs/attributes.csv",
    run_lines,
    fixed = TRUE
  )))
  testthat::expect_false(any(grepl("^output_schema(?:\\.|:)", run_lines, perl = TRUE)))

  atlas_path <- tempfile(fileext = ".yml")
  localmap:::write_run_manifest(
    cfg = list(
      schema_version = 2,
      data = list(
        outputs = list(products = "atlas"),
        camera_sites = list(jc = list(site_path = "inst/extdata/sites.csv")),
        attributes = list(
          output_long = "outputs/attributes.parquet",
          output_wide = "outputs/attributes.csv"
        )
      )
    ),
    cfg_file = cfg_path,
    layer_registry = list(),
    layer_outputs = NULL,
    analysis_layers_cfg = list(),
    analysis_layers = NULL,
    output_path = atlas_path
  )
  testthat::expect_false(any(grepl(
    "^attributes(?:\\.|:)",
    readLines(atlas_path),
    perl = TRUE
  )))
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
