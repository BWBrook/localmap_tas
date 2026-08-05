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
    cue = targets::tar_cue(mode = "always"),
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
    output_dir,
    {
      output_cfg <- cfg$data$outputs
      if (!is.null(output_cfg$output_dir) && nzchar(output_cfg$output_dir)) {
        output_cfg$output_dir
      } else {
        "outputs"
      }
    },
    description = "Base output directory for this run."
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
    {
      legend_paths <- layer_outputs$legend_path
      legend_paths <- legend_paths[!is.na(legend_paths) & nzchar(legend_paths)]
      if (exists("tasveg_class_legend", inherits = FALSE)) {
        legend_paths <- unique(c(legend_paths, tasveg_class_legend))
      }
      legend_paths[!is.na(legend_paths) & nzchar(legend_paths)]
    },
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
      render_tasveg_class_outputs(
        cfg = cfg,
        analysis_layer_paths = analysis_layer_paths,
        layer_legend_paths = layer_legend_paths,
        output_dir = output_dir
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
    flatten_lookup_paths(analysis_attribute_lookups),
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
      output_path = file.path(output_dir, "provenance", "analysis_layers.csv")
    ),
    format = "file",
    description = "Combined provenance table for imagery and analysis layers."
  ),
  targets::tar_target(
    attribution_report,
    write_attribution_report(
      layers = layer_outputs,
      analysis_layers = analysis_layers,
      output_path = file.path(output_dir, "provenance", "attribution.md")
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
      output_path = file.path(output_dir, "provenance", "run_manifest.yml")
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
      output_path = file.path(output_dir, "maps", "aoi_debug.png")
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
    output_manifest_file_for_profile(localmap_active_profile(cfg)),
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
      profile <- localmap_active_profile(cfg)
      expected_outputs <- build_output_schema_expected_outputs(
        profile,
        list(
          species_map = species_map,
          camera_sites_map = camera_sites_map,
          camera_sites_panel = camera_sites_panel,
          camera_sites_tile = camera_sites_tile,
          aoi_debug_plot = aoi_debug_plot,
          coverage_summary = coverage_summary,
          layer_output_paths = layer_output_paths,
          layer_provenance_paths = layer_provenance_paths,
          analysis_layer_paths = analysis_layer_paths,
          analysis_layer_provenance_paths = analysis_layer_provenance_paths,
          analysis_layer_preview_paths = analysis_layer_preview_paths,
          overview_map = overview_map,
          panel_figure_png = panel_figure_png,
          panel_figure_pdf = panel_figure_pdf,
          tasveg_class_legend = tasveg_class_legend,
          tasveg_class_lookup = tasveg_class_lookup,
          analysis_attribute_lookups = analysis_attribute_lookups,
          site_attributes_long_file = site_attributes_long_file,
          site_attributes_wide_file = site_attributes_wide_file,
          analysis_provenance = analysis_provenance,
          attribution_report = attribution_report,
          run_manifest = run_manifest
        )
      )
      validate_output_manifest(manifest = output_manifest, expected_outputs = expected_outputs)
    },
    description = "Validated output schema manifest (v1) for produced artefacts."
  )
)
