stable_exports <- c(
  "cfg_read",
  "run_settings",
  "ala_fetch_occurrences",
  "ala_resolve_species",
  "assemble_panel_figure",
  "build_aoi_from_config",
  "build_coverage_zone",
  "build_site_attributes_long",
  "fetch_analysis_layers",
  "map_species_occurrences",
  "read_species_requests",
  "render_overview_map",
  "validate_output_manifest"
)

experimental_exports <- c(
  "ala_configure",
  "fetch_layer_registry",
  "generate_topo_tile_map",
  "read_manifest"
)

internal_names <- c(
  "ala_default_occurrence_fields",
  "build_layer_provenance",
  "combine_manifest_csvs",
  "fetch_arcgis_imagery",
  "fetch_wms_imagery",
  "preview_manifest",
  "validate_analysis_layers",
  "validate_layer_registry",
  "write_attribution_report",
  "write_coverage_summary",
  "write_run_manifest",
  "write_site_attributes_long",
  "write_site_attributes_wide"
)

expected_exports <- sort(c(stable_exports, experimental_exports))

stable_formals <- list(
  cfg_read = c(
    profile = "Sys.getenv(\"R_CONFIG_ACTIVE\", \"default\")",
    config_path = "NULL"
  ),
  run_settings = c(
    settings_path = "<missing>",
    targets = "NULL",
    base_profile = "NULL",
    config_path = "NULL"
  ),
  ala_fetch_occurrences = c(
    taxa = "<missing>",
    min_year = "NULL",
    boundary = "NULL",
    boundary_simplify = "NULL",
    columns = "ala_default_occurrence_fields()",
    min_lat = "NULL",
    state_province = "NULL",
    fetch_fun = "NULL",
    config = "NULL"
  ),
  ala_resolve_species = c(
    species_requests = "<missing>",
    search_fun = "galah::search_taxa"
  ),
  assemble_panel_figure = c(
    panel_cfg = "<missing>",
    prerequisites = "NULL"
  ),
  build_aoi_from_config = c(
    aoi_cfg = "<missing>",
    sites = "NULL"
  ),
  build_coverage_zone = c(
    sites = "<missing>",
    coverage_cfg = "NULL",
    analysis_crs = "\"EPSG:28355\""
  ),
  build_site_attributes_long = c(
    sites = "<missing>",
    analysis_layers = "<missing>",
    aoi = "NULL",
    analysis_crs = "NULL",
    distance_layers = "NULL"
  ),
  fetch_analysis_layers = c(
    layers = "<missing>",
    aoi = "<missing>",
    cache_dir = "NULL"
  ),
  map_species_occurrences = c(
    occurrences = "<missing>",
    mapping_settings = "NULL",
    aoi = "NULL",
    output_path = "NULL"
  ),
  read_species_requests = c(
    path = "<missing>"
  ),
  render_overview_map = c(
    aoi = "<missing>",
    sites = "<missing>",
    coverage = "NULL",
    layers = "NULL",
    map_cfg = "NULL"
  ),
  validate_output_manifest = c(
    manifest = "<missing>",
    expected_outputs = "NULL"
  )
)

canonical_formals <- function(fn) {
  fn_formals <- formals(fn)
  canonical <- vapply(
    seq_along(fn_formals),
    function(index) {
      if (identical(fn_formals[[index]], quote(expr=))) {
        "<missing>"
      } else {
        deparse1(fn_formals[[index]], width.cutoff = 500L)
      }
    },
    character(1)
  )
  names(canonical) <- names(fn_formals)
  canonical
}

testthat::test_that("public exports match the exact tier contract", {
  namespace_exports <- sort(getNamespaceExports("localmap"))

  testthat::expect_length(stable_exports, 13L)
  testthat::expect_length(experimental_exports, 4L)
  testthat::expect_length(internal_names, 13L)
  testthat::expect_length(intersect(stable_exports, experimental_exports), 0L)
  testthat::expect_length(unique(c(stable_exports, experimental_exports)), 17L)
  testthat::expect_identical(namespace_exports, expected_exports)
  testthat::expect_false(any(internal_names %in% namespace_exports))
})

testthat::test_that("stable exports preserve ordered formals and default text", {
  testthat::expect_identical(names(stable_formals), stable_exports)

  for (function_name in stable_exports) {
    testthat::expect_identical(
      canonical_formals(getExportedValue("localmap", function_name)),
      stable_formals[[function_name]],
      info = function_name
    )
  }
})
