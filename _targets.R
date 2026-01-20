## localmap {targets} pipeline

targets::tar_option_set(
  seed = 1L,
  packages = character(0) # we use explicit namespace qualifiers within functions
)

# Source helpers
targets::tar_source("R")

list(
  # Configuration
  targets::tar_target(
    cfg_file,
    {
      override <- Sys.getenv("LOCALMAP_CONFIG_PATH", "")
      if (nzchar(override)) {
        override
      } else {
        here::here("config", "config.yaml")
      }
    },
    format = "file",
    description = "Path to the YAML configuration file (tracked for changes)."
  ),
  targets::tar_target(
    config_profile,
    Sys.getenv("R_CONFIG_ACTIVE", "default"),
    cue = targets::tar_cue(mode = "always"),
    description = "Active config profile (tracked for changes)."
  ),
  targets::tar_target(
    cfg,
    cfg_read(profile = config_profile, config_path = cfg_file),
    description = "Project configuration (paths, compute flags)."
  ),

  targets::tar_target(
    ala_config,
    if (isTRUE(cfg$ala$use_fixture)) cfg$ala else ala_configure(cfg$ala),
    description = "Configured galah options for ALA access."
  ),

  targets::tar_target(
    species_requests,
    read_species_requests(cfg$data$species_requests),
    description = "Species queries supplied via CSV (common and scientific names)."
  ),

  targets::tar_target(
    species_taxa,
    if (isTRUE(cfg$ala$use_fixture)) {
      ala_fixture_taxa(species_requests)
    } else {
      ala_resolve_species(species_requests)
    },
    description = "Resolved species metadata from the Atlas of Living Australia."
  ),

  targets::tar_target(
    species_occurrences,
    if (isTRUE(cfg$ala$use_fixture)) {
      ala_fixture_occurrences(
        taxa = species_taxa,
        fixture_path = cfg$ala$fixture_occurrences,
        min_year = cfg$data$occurrence$min_year,
        min_lat = cfg$data$occurrence$min_lat,
        state_province = cfg$data$occurrence$state_province
      )
    } else {
      ala_fetch_occurrences(
        taxa = species_taxa,
        min_year = cfg$data$occurrence$min_year,
        boundary = cfg$data$occurrence$boundary,
        boundary_simplify = cfg$data$occurrence$boundary_simplify,
        columns = cfg$data$occurrence$fields,
        min_lat = cfg$data$occurrence$min_lat,
        state_province = cfg$data$occurrence$state_province,
        config = ala_config
      )
    },
    description = "Occurrence records retrieved from the Atlas of Living Australia."
  ),

  targets::tar_target(
    species_map,
    map_species_occurrences(
      occurrences = species_occurrences,
      mapping_settings = cfg$data$occurrence$map,
      aoi = aoi
    ),
    format = "file",
    description = "Static map visualising species occurrences within the configured bounding box."
  ),

  targets::tar_target(
    topo_tile_map,
    generate_topo_tile_map(
      occurrences = species_occurrences,
      mapping_settings = cfg$data$occurrence$map,
      aoi = aoi
    ),
    format = "file",
    description = "Tile-based occurrence map using slippy tiles (OpenTopoMap by default)."
  ),

  targets::tar_target(
    camera_sites_file,
    resolve_camera_sites_file(cfg$data$camera_sites),
    format = "file",
    description = "Camera site effort CSV defined or derived from configuration."
  ),
  targets::tar_target(
    camera_sites_data,
    read_camera_sites(camera_sites_file),
    description = "Camera site metrics including effort and observations."
  ),
  targets::tar_target(
    aoi,
    build_aoi_from_config(
      aoi_cfg = cfg$data$aoi,
      sites = camera_sites_data
    ),
    description = "AOI polygon and derived bounding boxes."
  ),
  targets::tar_target(
    coverage_zone,
    build_coverage_zone(
      sites = camera_sites_data,
      coverage_cfg = cfg$data$coverage,
      analysis_crs = aoi$crs
    ),
    description = "Coverage zone polygon derived from site points."
  ),
  targets::tar_target(
    coverage_summary,
    write_coverage_summary(
      coverage = coverage_zone,
      output_path = if (is.null(cfg$data$coverage)) NULL else cfg$data$coverage$summary_path
    ),
    format = "file",
    description = "Coverage zone summary table (area and metadata)."
  ),
  targets::tar_target(
    layer_registry,
    validate_layer_registry(cfg$data$layers),
    description = "Validated registry of imagery layers."
  ),
  targets::tar_target(
    layer_outputs,
    fetch_layer_registry(layer_registry, aoi = aoi),
    description = "Imagery layers fetched from registry."
  ),
  targets::tar_target(
    layer_output_paths,
    stats::setNames(layer_outputs$path, layer_outputs$id),
    description = "Named vector of layer output paths."
  ),
  targets::tar_target(
    layer_provenance_paths,
    stats::setNames(layer_outputs$provenance_path, layer_outputs$id),
    description = "Named vector of layer provenance paths."
  ),
  targets::tar_target(
    layer_legend_paths,
    stats::setNames(layer_outputs$legend_path, layer_outputs$id),
    description = "Named vector of layer legend paths."
  ),
  targets::tar_target(
    layer_files,
    layer_outputs$path,
    format = "file",
    description = "Layer imagery files from the registry."
  ),
  targets::tar_target(
    layer_provenance_files,
    layer_outputs$provenance_path,
    format = "file",
    description = "Layer provenance sidecars."
  ),
  targets::tar_target(
    layer_legend_files,
    layer_outputs$legend_path[!is.na(layer_outputs$legend_path)],
    format = "file",
    description = "Layer legend files from the registry."
  ),
  targets::tar_target(
    analysis_layers,
    {
      if (!nzchar(Sys.getenv("LOCALMAP_ALLOW_LARGE_DOWNLOADS", ""))) {
        allow_large <- isTRUE(cfg$data$large_downloads$allow)
        Sys.setenv(
          LOCALMAP_ALLOW_LARGE_DOWNLOADS = if (allow_large) "1" else "0"
        )
      }
      fetch_analysis_layers(cfg$data$analysis_layers, aoi = aoi)
    },
    description = "Analysis-grade vector/raster layers clipped to AOI."
  ),
  targets::tar_target(
    analysis_layer_paths,
    stats::setNames(analysis_layers$path, analysis_layers$id),
    description = "Named vector of analysis layer output paths."
  ),
  targets::tar_target(
    analysis_layer_provenance_paths,
    stats::setNames(analysis_layers$provenance_path, analysis_layers$id),
    description = "Named vector of analysis layer provenance paths."
  ),
  targets::tar_target(
    analysis_layer_files,
    analysis_layers$path,
    format = "file",
    description = "Analysis layer outputs (GeoPackage/GeoTIFF)."
  ),
  targets::tar_target(
    analysis_layer_provenance_files,
    analysis_layers$provenance_path,
    format = "file",
    description = "Analysis layer provenance sidecars."
  ),
  targets::tar_target(
    analysis_layer_previews,
    render_analysis_layer_previews(
      analysis_layers,
      aoi = aoi,
      sites = camera_sites_data
    ),
    description = "Quick-look PNG previews for analysis layers."
  ),
  targets::tar_target(
    analysis_layer_preview_paths,
    stats::setNames(analysis_layer_previews$path, analysis_layer_previews$id),
    description = "Named vector of analysis layer preview PNG paths."
  ),
  targets::tar_target(
    analysis_layer_preview_files,
    analysis_layer_previews$path,
    format = "file",
    description = "Analysis layer preview PNGs."
  ),
  targets::tar_target(
    tasveg_class_outputs,
    {
      analysis_layer_files
      profile <- attr(cfg, "config")
      if (is.null(profile) || !nzchar(profile)) {
        profile <- Sys.getenv("R_CONFIG_ACTIVE", "default")
      }
      class_id <- if (profile %in% c("tas_canonical", "tas_canonical_ci")) {
        "tasveg_class_vector"
      } else if (profile %in% c("demo")) {
        "demo_tasveg_class"
      } else {
        "jc_tasveg_class"
      }
      safe_lookup <- function(values, key) {
        if (is.null(values) || is.null(key) || !nzchar(key)) {
          return("")
        }
        if (!key %in% names(values)) {
          return("")
        }
        values[[key]]
      }
      find_cfg_layer <- function(layers_cfg, id) {
        if (is.null(layers_cfg)) {
          return(NULL)
        }
        for (layer in layers_cfg) {
          if (!is.null(layer$id) && identical(layer$id, id)) {
            return(layer)
          }
        }
        NULL
      }
      layer_cfg <- find_cfg_layer(cfg$data$analysis_layers, class_id)
      vector_path <- safe_lookup(analysis_layer_paths, class_id)
      legend_path <- safe_lookup(layer_legend_paths, "tasveg_class_wms")
      profile_dir <- if (profile %in% c("tas_canonical", "tas_canonical_ci")) {
        "tas"
      } else if (profile %in% c("demo")) {
        "demo"
      } else {
        "jc"
      }
      if (is.null(legend_path) || !nzchar(legend_path)) {
        legend_path <- file.path("outputs", "layers", profile_dir, "tasveg_class_wms_legend.png")
      }
      lookup_path <- NULL
      if (!is.null(vector_path) && nzchar(vector_path)) {
        lookup_path <- sub("\\.gpkg$", "_lookup.csv", vector_path)
      } else {
        prefix <- if (identical(profile_dir, "tas")) {
          "tas"
        } else if (identical(profile_dir, "demo")) {
          "demo"
        } else {
          "jc"
        }
        lookup_path <- file.path(
          "outputs",
          "analysis",
          profile_dir,
          "vector",
          paste0(prefix, "_tasveg_class_lookup.csv")
        )
      }
      render_tasveg_class_legend(
        vector_path = vector_path,
        legend_path = legend_path,
        lookup_path = lookup_path,
        layer_url = layer_cfg$url %||% "",
        offline = isTRUE(layer_cfg$offline)
      )
    },
    description = "Custom TASVEG class legend + lookup for AOI classes."
  ),
  targets::tar_target(
    tasveg_class_legend,
    tasveg_class_outputs$legend_path,
    format = "file",
    description = "TASVEG class legend PNG (AOI classes only)."
  ),
  targets::tar_target(
    tasveg_class_lookup,
    tasveg_class_outputs$lookup_path,
    format = "file",
    description = "TASVEG class lookup CSV (code to label)."
  ),
  targets::tar_target(
    analysis_attribute_lookups,
    render_attribute_lookups(analysis_layers),
    description = "Lookup tables for coded vector attributes."
  ),
  targets::tar_target(
    analysis_attribute_lookup_files,
    {
      lookup_paths <- analysis_attribute_lookups
      if (is.null(lookup_paths)) {
        lookup_paths <- character()
      } else {
        lookup_paths <- unname(unlist(lookup_paths, use.names = FALSE))
      }
      lookup_paths <- lookup_paths[!is.na(lookup_paths) & nzchar(lookup_paths)]
      lookup_paths
    },
    format = "file",
    description = "Attribute lookup CSVs (vector code to label)."
  ),
  targets::tar_target(
    site_attributes_long,
    {
      attributes_cfg <- cfg$data$attributes
      enabled <- is.null(attributes_cfg$enabled) || isTRUE(attributes_cfg$enabled)
      if (isTRUE(enabled)) {
        build_site_attributes_long(
          sites = camera_sites_data,
          analysis_layers = analysis_layers,
          aoi = aoi,
          analysis_crs = cfg$data$aoi$crs,
          distance_layers = cfg$data$distance_layers
        )
      } else {
        empty_site_attributes()
      }
    },
    description = "Canonical long table of site attributes (raster + vector)."
  ),
  targets::tar_target(
    site_attributes_long_file,
    {
      attributes_cfg <- cfg$data$attributes
      output_path <- NULL
      if (!is.null(attributes_cfg$output_long)) {
        output_path <- attributes_cfg$output_long
      }
      write_site_attributes_long(site_attributes_long, output_path = output_path)
    },
    format = "file",
    description = "Parquet output for site attributes (long)."
  ),
  targets::tar_target(
    site_attributes_wide_file,
    {
      attributes_cfg <- cfg$data$attributes
      output_path <- NULL
      if (!is.null(attributes_cfg$output_wide)) {
        output_path <- attributes_cfg$output_wide
      }
      write_site_attributes_wide(
        site_attributes_long,
        sites = camera_sites_data,
        output_path = output_path
      )
    },
    format = "file",
    description = "Convenience CSV output for site attributes (wide)."
  ),
  targets::tar_target(
    analysis_provenance,
    build_layer_provenance(
      layers = layer_outputs,
      analysis_layers = analysis_layers,
      output_path = "outputs/provenance/analysis_layers.csv"
    ),
    format = "file",
    description = "Combined provenance table for imagery and analysis layers."
  ),
  targets::tar_target(
    attribution_report,
    write_attribution_report(
      layers = layer_outputs,
      analysis_layers = analysis_layers,
      output_path = "outputs/provenance/attribution.md"
    ),
    format = "file",
    description = "Human-readable layer attribution report."
  ),
  targets::tar_target(
    run_manifest,
    write_run_manifest(
      cfg = cfg,
      cfg_file = cfg_file,
      layer_registry = layer_registry,
      layer_outputs = layer_outputs,
      analysis_layers_cfg = cfg$data$analysis_layers,
      analysis_layers = analysis_layers,
      output_manifest_file = output_manifest_file,
      output_path = "outputs/provenance/run_manifest.yml"
    ),
    format = "file",
    description = "Machine-readable run manifest with layer metadata."
  ),
  targets::tar_target(
    camera_sites_context,
    prepare_camera_site_context(
      sites = camera_sites_data,
      central_site = cfg$data$camera_sites$central_site,
      half_width_km = cfg$data$camera_sites$bbox_half_km,
      basemap_cfg = cfg$data$camera_sites$basemap
    ),
    description = "Prepared spatial context (bounding box, filtered sites) for mapping camera deployments."
  ),
  targets::tar_target(
    aoi_debug_plot,
    render_aoi_debug_plot(
      aoi = aoi,
      sites = camera_sites_data,
      output_path = NULL
    ),
    format = "file",
    description = "Debug plot showing the configured AOI bounding box and camera sites."
  ),
  targets::tar_target(
    camera_sites_tile,
    fetch_camera_wms_tile(
      bbox_3857 = camera_sites_context$bbox_3857,
      provider_cfg = cfg$data$camera_sites$basemap
    ),
    format = "file",
    description = "Basemap tile fetched from the configured WMS provider for camera sites."
  ),
  targets::tar_target(
    camera_sites_map,
    render_camera_sites_map(
      context = camera_sites_context,
      tile_path = camera_sites_tile,
      map_cfg = cfg$data$camera_sites$map
    ),
    format = "file",
    description = "Camera site map with effort-scaled symbols and observation highlighting."
  ),
  targets::tar_target(
    overview_map,
    render_overview_map(
      aoi = aoi,
      sites = camera_sites_data,
      coverage = coverage_zone,
      layers = layer_outputs,
      map_cfg = cfg$data$overview_map
    ),
    format = "file",
    description = "Overview map with AOI, sites, and optional coverage polygon."
  ),
  targets::tar_target(
    camera_sites_panel,
    camera_sites_stack_maps(
      stack_cfg = cfg$data$camera_sites$stack,
      prerequisites = list(camera_sites_map, species_map)
    ),
    format = "file",
    description = "Vertically stacked panel of camera site maps."
  ),
  targets::tar_target(
    panel_figure,
    assemble_panel_figure(
      panel_cfg = cfg$data$panel_figure,
      prerequisites = list(overview_map, species_map, camera_sites_map, topo_tile_map)
    ),
    description = "Multi-panel figure assembly (PNG + PDF)."
  ),
  targets::tar_target(
    panel_figure_png,
    panel_figure$png,
    format = "file",
    description = "Multi-panel figure PNG output."
  ),
  targets::tar_target(
    panel_figure_pdf,
    panel_figure$pdf,
    format = "file",
    description = "Multi-panel figure PDF output."
  ),

  targets::tar_target(
    output_manifest_file,
    {
      profile <- attr(cfg, "config")
      if (is.null(profile) || !nzchar(profile)) {
        profile <- Sys.getenv("R_CONFIG_ACTIVE", "default")
      }
      if (profile %in% c("tas_canonical", "tas_canonical_ci")) {
        "inst/extdata/output_manifest_tas_canonical.csv"
      } else if (profile %in% c("demo")) {
        "inst/extdata/output_manifest_demo.csv"
      } else {
        "inst/extdata/output_manifest_v1.csv"
      }
    },
    format = "file",
    description = "Output schema manifest (v1) file."
  ),

  targets::tar_target(
    output_manifest,
    readr::read_csv(output_manifest_file, show_col_types = FALSE, num_threads = 1),
    description = "Output schema manifest (v1) defining expected outputs."
  ),

  targets::tar_target(
    output_schema_v1,
    {
      profile <- attr(cfg, "config")
      if (is.null(profile) || !nzchar(profile)) {
        profile <- Sys.getenv("R_CONFIG_ACTIVE", "default")
      }
      safe_lookup <- function(values, key) {
        if (is.null(values) || is.null(key) || !nzchar(key)) {
          return("")
        }
        if (!key %in% names(values)) {
          return("")
        }
        values[[key]]
      }
      expected_outputs <- if (profile %in% c("tas_canonical", "tas_canonical_ci")) {
        list(
          species_map = species_map,
          camera_sites_map = camera_sites_map,
          camera_sites_panel = camera_sites_panel,
          camera_sites_tile = camera_sites_tile,
          aoi_debug_plot = aoi_debug_plot,
          coverage_summary = coverage_summary,
          wms_layer = safe_lookup(layer_output_paths, "tasveg_wms"),
          wms_layer_provenance = safe_lookup(layer_provenance_paths, "tasveg_wms"),
          tasveg_class_wms_layer = safe_lookup(layer_output_paths, "tasveg_class_wms"),
          tasveg_class_wms_layer_provenance = safe_lookup(layer_provenance_paths, "tasveg_class_wms"),
          tasveg_class_wms_legend = tasveg_class_legend,
          arcgis_layer = safe_lookup(layer_output_paths, "orthophoto_arcgis"),
          arcgis_layer_provenance = safe_lookup(layer_provenance_paths, "orthophoto_arcgis"),
          topography_arcgis_layer = safe_lookup(layer_output_paths, "topography_arcgis"),
          topography_arcgis_layer_provenance = safe_lookup(layer_provenance_paths, "topography_arcgis"),
          fire_attributes_arcgis_layer = safe_lookup(layer_output_paths, "fire_attributes_arcgis"),
          fire_attributes_arcgis_layer_provenance = safe_lookup(
            layer_provenance_paths,
            "fire_attributes_arcgis"
          ),
          soil_ph_wms_layer = safe_lookup(layer_output_paths, "soil_ph_wms"),
          soil_ph_wms_layer_provenance = safe_lookup(layer_provenance_paths, "soil_ph_wms"),
          overview_map = overview_map,
          panel_figure_png = panel_figure_png,
          panel_figure_pdf = panel_figure_pdf,
          vector_tasveg = safe_lookup(analysis_layer_paths, "tasveg_vector"),
          vector_tasveg_provenance = safe_lookup(analysis_layer_provenance_paths, "tasveg_vector"),
          vector_tasveg_class = safe_lookup(analysis_layer_paths, "tasveg_class_vector"),
          vector_tasveg_class_provenance = safe_lookup(
            analysis_layer_provenance_paths,
            "tasveg_class_vector"
          ),
          vector_fire_attributes = safe_lookup(analysis_layer_paths, "tas_fire_attributes"),
          vector_fire_attributes_provenance = safe_lookup(
            analysis_layer_provenance_paths,
            "tas_fire_attributes"
          ),
          vector_geology = safe_lookup(analysis_layer_paths, "tas_geology"),
          vector_geology_provenance = safe_lookup(analysis_layer_provenance_paths, "tas_geology"),
          vector_land_tenure = safe_lookup(analysis_layer_paths, "tas_land_tenure"),
          vector_land_tenure_provenance = safe_lookup(
            analysis_layer_provenance_paths,
            "tas_land_tenure"
          ),
          vector_reserve_estate = safe_lookup(analysis_layer_paths, "tas_reserve_estate"),
          vector_reserve_estate_provenance = safe_lookup(
            analysis_layer_provenance_paths,
            "tas_reserve_estate"
          ),
          raster_dem = safe_lookup(analysis_layer_paths, "tas_dem"),
          raster_dem_provenance = safe_lookup(analysis_layer_provenance_paths, "tas_dem"),
          raster_slope = safe_lookup(analysis_layer_paths, "tas_slope"),
          raster_slope_provenance = safe_lookup(analysis_layer_provenance_paths, "tas_slope"),
          raster_chm = safe_lookup(analysis_layer_paths, "tas_chm"),
          raster_chm_provenance = safe_lookup(analysis_layer_provenance_paths, "tas_chm"),
          raster_soil_ph = safe_lookup(analysis_layer_paths, "tas_soil_ph"),
          raster_soil_ph_provenance = safe_lookup(
            analysis_layer_provenance_paths,
            "tas_soil_ph"
          ),
          raster_bio1 = safe_lookup(analysis_layer_paths, "tas_bio1"),
          raster_bio1_provenance = safe_lookup(analysis_layer_provenance_paths, "tas_bio1"),
          raster_bio12 = safe_lookup(analysis_layer_paths, "tas_bio12"),
          raster_bio12_provenance = safe_lookup(analysis_layer_provenance_paths, "tas_bio12"),
          vector_tasveg_preview = safe_lookup(analysis_layer_preview_paths, "tasveg_vector"),
          vector_tasveg_class_preview = safe_lookup(
            analysis_layer_preview_paths,
            "tasveg_class_vector"
          ),
          tasveg_class_lookup = tasveg_class_lookup,
          tasveg_group_lookup = analysis_attribute_lookups$tasveg_group_lookup,
          geology_lookup = analysis_attribute_lookups$geology_lookup,
          land_tenure_lookup = analysis_attribute_lookups$land_tenure_lookup,
          reserve_estate_lookup = analysis_attribute_lookups$reserve_estate_lookup,
          vector_fire_attributes_preview = safe_lookup(
            analysis_layer_preview_paths,
            "tas_fire_attributes"
          ),
          vector_geology_preview = safe_lookup(analysis_layer_preview_paths, "tas_geology"),
          vector_land_tenure_preview = safe_lookup(
            analysis_layer_preview_paths,
            "tas_land_tenure"
          ),
          vector_reserve_estate_preview = safe_lookup(
            analysis_layer_preview_paths,
            "tas_reserve_estate"
          ),
          raster_dem_preview = safe_lookup(analysis_layer_preview_paths, "tas_dem"),
          raster_slope_preview = safe_lookup(analysis_layer_preview_paths, "tas_slope"),
          raster_chm_preview = safe_lookup(analysis_layer_preview_paths, "tas_chm"),
          raster_soil_ph_preview = safe_lookup(analysis_layer_preview_paths, "tas_soil_ph"),
          raster_bio1_preview = safe_lookup(analysis_layer_preview_paths, "tas_bio1"),
          raster_bio12_preview = safe_lookup(analysis_layer_preview_paths, "tas_bio12"),
          site_attributes_long = site_attributes_long_file,
          site_attributes_wide = site_attributes_wide_file,
          analysis_provenance = analysis_provenance,
          attribution_report = attribution_report,
          run_manifest = run_manifest
        )
      } else {
        list(
          species_map = species_map,
          camera_sites_map = camera_sites_map,
          camera_sites_panel = camera_sites_panel,
          camera_sites_tile = camera_sites_tile,
          aoi_debug_plot = aoi_debug_plot,
          coverage_summary = coverage_summary,
          wms_layer = safe_lookup(layer_output_paths, "tasveg_wms"),
          wms_layer_provenance = safe_lookup(layer_provenance_paths, "tasveg_wms"),
          tasveg_class_wms_layer = safe_lookup(layer_output_paths, "tasveg_class_wms"),
          tasveg_class_wms_layer_provenance = safe_lookup(layer_provenance_paths, "tasveg_class_wms"),
          tasveg_class_wms_legend = tasveg_class_legend,
          arcgis_layer = safe_lookup(layer_output_paths, "topography_arcgis"),
          arcgis_layer_provenance = safe_lookup(layer_provenance_paths, "topography_arcgis"),
          orthophoto_arcgis_layer = safe_lookup(layer_output_paths, "orthophoto_arcgis"),
          orthophoto_arcgis_layer_provenance = safe_lookup(layer_provenance_paths, "orthophoto_arcgis"),
          roads_wms_layer = safe_lookup(layer_output_paths, "roads_wms"),
          roads_wms_layer_provenance = safe_lookup(layer_provenance_paths, "roads_wms"),
          localities_wms_layer = safe_lookup(layer_output_paths, "localities_wms"),
          localities_wms_layer_provenance = safe_lookup(layer_provenance_paths, "localities_wms"),
          fire_attributes_arcgis_layer = safe_lookup(layer_output_paths, "fire_attributes_arcgis"),
          fire_attributes_arcgis_layer_provenance = safe_lookup(
            layer_provenance_paths,
            "fire_attributes_arcgis"
          ),
          soil_ph_wms_layer = safe_lookup(layer_output_paths, "soil_ph_wms"),
          soil_ph_wms_layer_provenance = safe_lookup(layer_provenance_paths, "soil_ph_wms"),
          overview_map = overview_map,
          panel_figure_png = panel_figure_png,
          panel_figure_pdf = panel_figure_pdf,
          vector_tasveg = safe_lookup(analysis_layer_paths, "jc_tasveg"),
          vector_tasveg_provenance = safe_lookup(analysis_layer_provenance_paths, "jc_tasveg"),
          vector_tasveg_class = safe_lookup(analysis_layer_paths, "jc_tasveg_class"),
          vector_tasveg_class_provenance = safe_lookup(
            analysis_layer_provenance_paths,
            "jc_tasveg_class"
          ),
          vector_fire_attributes = safe_lookup(analysis_layer_paths, "jc_fire_attributes"),
          vector_fire_attributes_provenance = safe_lookup(
            analysis_layer_provenance_paths,
            "jc_fire_attributes"
          ),
          vector_geology = safe_lookup(analysis_layer_paths, "jc_geology"),
          vector_geology_provenance = safe_lookup(analysis_layer_provenance_paths, "jc_geology"),
          vector_land_tenure = safe_lookup(analysis_layer_paths, "jc_land_tenure"),
          vector_land_tenure_provenance = safe_lookup(
            analysis_layer_provenance_paths,
            "jc_land_tenure"
          ),
          vector_reserve_estate = safe_lookup(analysis_layer_paths, "jc_reserve_estate"),
          vector_reserve_estate_provenance = safe_lookup(
            analysis_layer_provenance_paths,
            "jc_reserve_estate"
          ),
          raster_dem = safe_lookup(analysis_layer_paths, "jc_dem"),
          raster_dem_provenance = safe_lookup(analysis_layer_provenance_paths, "jc_dem"),
          raster_multiband = safe_lookup(analysis_layer_paths, "jc_multiband"),
          raster_multiband_provenance = safe_lookup(analysis_layer_provenance_paths, "jc_multiband"),
          raster_slope = safe_lookup(analysis_layer_paths, "jc_slope"),
          raster_slope_provenance = safe_lookup(analysis_layer_provenance_paths, "jc_slope"),
          raster_ndvi = safe_lookup(analysis_layer_paths, "jc_ndvi"),
          raster_ndvi_provenance = safe_lookup(analysis_layer_provenance_paths, "jc_ndvi"),
          raster_nbr = safe_lookup(analysis_layer_paths, "jc_nbr"),
          raster_nbr_provenance = safe_lookup(analysis_layer_provenance_paths, "jc_nbr"),
          raster_chm = safe_lookup(analysis_layer_paths, "jc_chm"),
          raster_chm_provenance = safe_lookup(analysis_layer_provenance_paths, "jc_chm"),
          raster_soil_ph = safe_lookup(analysis_layer_paths, "jc_soil_ph"),
          raster_soil_ph_provenance = safe_lookup(
            analysis_layer_provenance_paths,
            "jc_soil_ph"
          ),
          raster_bio1 = safe_lookup(analysis_layer_paths, "jc_bio1"),
          raster_bio1_provenance = safe_lookup(analysis_layer_provenance_paths, "jc_bio1"),
          raster_bio12 = safe_lookup(analysis_layer_paths, "jc_bio12"),
          raster_bio12_provenance = safe_lookup(analysis_layer_provenance_paths, "jc_bio12"),
          vector_tasveg_preview = safe_lookup(analysis_layer_preview_paths, "jc_tasveg"),
          vector_tasveg_class_preview = safe_lookup(
            analysis_layer_preview_paths,
            "jc_tasveg_class"
          ),
          tasveg_class_lookup = tasveg_class_lookup,
          tasveg_group_lookup = analysis_attribute_lookups$tasveg_group_lookup,
          geology_lookup = analysis_attribute_lookups$geology_lookup,
          land_tenure_lookup = analysis_attribute_lookups$land_tenure_lookup,
          reserve_estate_lookup = analysis_attribute_lookups$reserve_estate_lookup,
          vector_fire_attributes_preview = safe_lookup(
            analysis_layer_preview_paths,
            "jc_fire_attributes"
          ),
          vector_geology_preview = safe_lookup(analysis_layer_preview_paths, "jc_geology"),
          vector_land_tenure_preview = safe_lookup(
            analysis_layer_preview_paths,
            "jc_land_tenure"
          ),
          vector_reserve_estate_preview = safe_lookup(
            analysis_layer_preview_paths,
            "jc_reserve_estate"
          ),
          raster_dem_preview = safe_lookup(analysis_layer_preview_paths, "jc_dem"),
          raster_multiband_preview = safe_lookup(analysis_layer_preview_paths, "jc_multiband"),
          raster_slope_preview = safe_lookup(analysis_layer_preview_paths, "jc_slope"),
          raster_ndvi_preview = safe_lookup(analysis_layer_preview_paths, "jc_ndvi"),
          raster_nbr_preview = safe_lookup(analysis_layer_preview_paths, "jc_nbr"),
          raster_chm_preview = safe_lookup(analysis_layer_preview_paths, "jc_chm"),
          raster_soil_ph_preview = safe_lookup(analysis_layer_preview_paths, "jc_soil_ph"),
          raster_bio1_preview = safe_lookup(analysis_layer_preview_paths, "jc_bio1"),
          raster_bio12_preview = safe_lookup(analysis_layer_preview_paths, "jc_bio12"),
          site_attributes_long = site_attributes_long_file,
          site_attributes_wide = site_attributes_wide_file,
          analysis_provenance = analysis_provenance,
          attribution_report = attribution_report,
          run_manifest = run_manifest
        )
      }
      validate_output_manifest(manifest = output_manifest, expected_outputs = expected_outputs)
    },
    description = "Validated output schema manifest (v1) for produced artefacts."
  ),


  # Manifest of input files
  targets::tar_target(
    raw_manifest,
    read_manifest(cfg$data$manifest),
    description = "CSV manifest of input files."
  ),

  # Track file dependencies declared in the manifest (vector of paths)
  targets::tar_target(
    input_files,
    raw_manifest$abs_path,
    format = "file",
    description = "File paths declared in the manifest (tracked as file deps)."
  ),

  # Lightweight preview of input CSVs (row/column counts)
  targets::tar_target(
    data_preview,
    preview_manifest(raw_manifest, n_max = 100L),
    description = "Per-file preview (n_rows, n_cols) for CSV inputs."
  ),

  # Combine CSV inputs when columns align across files
  targets::tar_target(
    combined_data,
    combine_manifest_csvs(raw_manifest),
    description = "Combined tibble of CSV inputs using common columns."
  ),

  # Example summary derived from the manifest
  targets::tar_target(
    manifest_summary,
    {
      dplyr::summarise(
        raw_manifest,
        n_rows = dplyr::n(),
        n_files = dplyr::n_distinct(abs_path)
      )
    },
    description = "Simple summary of the manifest contents."
  ),

  # Report rendering: render to same directory as source file
  targets::tar_target(
    report,
    {
      qmd <- "reports/paper.qmd"
      out_dir <- dirname(qmd)
      # Render with Quarto if available; otherwise write a simple placeholder HTML
      quarto_path <- tryCatch(quarto::quarto_path(), error = function(e) "")
      has_quarto <- isTRUE(requireNamespace("quarto", quietly = TRUE)) &&
        is.character(quarto_path) && length(quarto_path) == 1L &&
        nzchar(quarto_path) && !is.na(quarto_path)
      base <- tools::file_path_sans_ext(basename(qmd))
      html <- file.path(out_dir, paste0(base, ".html"))
      ok <- FALSE
      if (has_quarto) {
        ok <- isTRUE(tryCatch({
          quarto::quarto_render(input = qmd, quiet = TRUE)
          file.exists(html)
        }, error = function(e) FALSE))
      }
      if (!ok) {
        writeLines("<html><body><p>Report placeholder (Quarto not available or render failed).</p></body></html>", html)
      }
      html
    },
    format = "file",
    description = "Rendered Quarto report artifact."
  )
)
