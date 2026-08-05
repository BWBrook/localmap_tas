# Internal helpers that keep `_targets.R` declarative.

localmap_active_profile <- function(cfg = NULL,
                                    default = Sys.getenv("R_CONFIG_ACTIVE", "default")) {
  profile <- NULL
  if (!is.null(cfg)) {
    profile <- attr(cfg, "config")
  }
  if (is.null(profile) || !nzchar(profile)) {
    profile <- default
  }
  profile
}

named_path_lookup <- function(values, key) {
  if (is.null(values) || is.null(key) || !nzchar(key)) {
    return("")
  }
  if (!key %in% names(values)) {
    return("")
  }
  values[[key]]
}

find_layer_cfg <- function(layers_cfg, id) {
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

resolve_tasveg_class_id <- function(profile, analysis_layer_paths) {
  class_id <- NULL
  layer_ids <- names(analysis_layer_paths)
  if (!is.null(layer_ids)) {
    matches <- layer_ids[grepl("tasveg_class", layer_ids)]
    if (length(matches) > 0L) {
      class_id <- matches[[1]]
    }
  }

  if (!is.null(class_id) && nzchar(class_id)) {
    return(class_id)
  }

  if (profile %in% c("tas_canonical", "tas_canonical_ci")) {
    return("tasveg_class_vector")
  }
  if (identical(profile, "demo")) {
    return("demo_tasveg_class")
  }
  "jc_tasveg_class"
}

tasveg_class_lookup_path <- function(output_dir, class_id, vector_path = NULL) {
  if (!is.null(vector_path) && nzchar(vector_path)) {
    return(sub("\\.gpkg$", "_lookup.csv", vector_path))
  }

  prefix <- if (grepl("^demo", class_id)) {
    "demo"
  } else if (grepl("^jc", class_id)) {
    "jc"
  } else if (grepl("^tas", class_id)) {
    "tas"
  } else {
    "site"
  }

  file.path(
    output_dir,
    "analysis",
    "vector",
    paste0(prefix, "_tasveg_class_lookup.csv")
  )
}

render_tasveg_class_outputs <- function(cfg,
                                        analysis_layer_paths,
                                        layer_legend_paths,
                                        output_dir) {
  profile <- localmap_active_profile(cfg)
  class_id <- resolve_tasveg_class_id(profile, analysis_layer_paths)
  layer_cfg <- find_layer_cfg(cfg$data$analysis_layers, class_id)
  vector_path <- named_path_lookup(analysis_layer_paths, class_id)
  legend_path <- named_path_lookup(layer_legend_paths, "tasveg_class_wms")
  if (is.null(legend_path) || !nzchar(legend_path)) {
    legend_path <- file.path(output_dir, "layers", "tasveg_class_wms_legend.png")
  }
  lookup_path <- tasveg_class_lookup_path(output_dir, class_id, vector_path)

  render_tasveg_class_legend(
    vector_path = vector_path,
    legend_path = legend_path,
    lookup_path = lookup_path,
    layer_url = layer_cfg$url %||% "",
    offline = isTRUE(layer_cfg$offline)
  )
}

flatten_lookup_paths <- function(lookup_paths) {
  if (is.null(lookup_paths)) {
    lookup_paths <- character()
  } else {
    lookup_paths <- unname(unlist(lookup_paths, use.names = FALSE))
  }
  lookup_paths[!is.na(lookup_paths) & nzchar(lookup_paths)]
}

output_manifest_file_for_profile <- function(profile) {
  if (profile %in% c("tas_canonical", "tas_canonical_ci")) {
    return("inst/extdata/output_manifest_tas_canonical.csv")
  }
  if (identical(profile, "demo")) {
    return("inst/extdata/output_manifest_demo.csv")
  }
  "inst/extdata/output_manifest_v1.csv"
}

build_output_schema_expected_outputs <- function(profile, ctx) {
  if (profile %in% c("tas_canonical", "tas_canonical_ci")) {
    return(list(
      species_map = ctx$species_map,
      camera_sites_map = ctx$camera_sites_map,
      camera_sites_panel = ctx$camera_sites_panel,
      camera_sites_tile = ctx$camera_sites_tile,
      aoi_debug_plot = ctx$aoi_debug_plot,
      coverage_summary = ctx$coverage_summary,
      wms_layer = named_path_lookup(ctx$layer_output_paths, "tasveg_wms"),
      wms_layer_provenance = named_path_lookup(ctx$layer_provenance_paths, "tasveg_wms"),
      tasveg_class_wms_layer = named_path_lookup(ctx$layer_output_paths, "tasveg_class_wms"),
      tasveg_class_wms_layer_provenance = named_path_lookup(
        ctx$layer_provenance_paths,
        "tasveg_class_wms"
      ),
      tasveg_class_wms_legend = ctx$tasveg_class_legend,
      arcgis_layer = named_path_lookup(ctx$layer_output_paths, "orthophoto_arcgis"),
      arcgis_layer_provenance = named_path_lookup(
        ctx$layer_provenance_paths,
        "orthophoto_arcgis"
      ),
      topography_arcgis_layer = named_path_lookup(ctx$layer_output_paths, "topography_arcgis"),
      topography_arcgis_layer_provenance = named_path_lookup(
        ctx$layer_provenance_paths,
        "topography_arcgis"
      ),
      fire_attributes_arcgis_layer = named_path_lookup(
        ctx$layer_output_paths,
        "fire_attributes_arcgis"
      ),
      fire_attributes_arcgis_layer_provenance = named_path_lookup(
        ctx$layer_provenance_paths,
        "fire_attributes_arcgis"
      ),
      soil_ph_wms_layer = named_path_lookup(ctx$layer_output_paths, "soil_ph_wms"),
      soil_ph_wms_layer_provenance = named_path_lookup(
        ctx$layer_provenance_paths,
        "soil_ph_wms"
      ),
      overview_map = ctx$overview_map,
      panel_figure_png = ctx$panel_figure_png,
      panel_figure_pdf = ctx$panel_figure_pdf,
      vector_tasveg = named_path_lookup(ctx$analysis_layer_paths, "tasveg_vector"),
      vector_tasveg_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "tasveg_vector"
      ),
      vector_tasveg_class = named_path_lookup(ctx$analysis_layer_paths, "tasveg_class_vector"),
      vector_tasveg_class_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "tasveg_class_vector"
      ),
      vector_fire_attributes = named_path_lookup(ctx$analysis_layer_paths, "tas_fire_attributes"),
      vector_fire_attributes_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "tas_fire_attributes"
      ),
      vector_geology = named_path_lookup(ctx$analysis_layer_paths, "tas_geology"),
      vector_geology_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "tas_geology"
      ),
      vector_land_tenure = named_path_lookup(ctx$analysis_layer_paths, "tas_land_tenure"),
      vector_land_tenure_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "tas_land_tenure"
      ),
      vector_reserve_estate = named_path_lookup(ctx$analysis_layer_paths, "tas_reserve_estate"),
      vector_reserve_estate_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "tas_reserve_estate"
      ),
      raster_dem = named_path_lookup(ctx$analysis_layer_paths, "tas_dem"),
      raster_dem_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "tas_dem"
      ),
      raster_slope = named_path_lookup(ctx$analysis_layer_paths, "tas_slope"),
      raster_slope_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "tas_slope"
      ),
      raster_chm = named_path_lookup(ctx$analysis_layer_paths, "tas_chm"),
      raster_chm_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "tas_chm"
      ),
      raster_soil_ph = named_path_lookup(ctx$analysis_layer_paths, "tas_soil_ph"),
      raster_soil_ph_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "tas_soil_ph"
      ),
      raster_bio1 = named_path_lookup(ctx$analysis_layer_paths, "tas_bio1"),
      raster_bio1_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "tas_bio1"
      ),
      raster_bio12 = named_path_lookup(ctx$analysis_layer_paths, "tas_bio12"),
      raster_bio12_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "tas_bio12"
      ),
      vector_tasveg_preview = named_path_lookup(
        ctx$analysis_layer_preview_paths,
        "tasveg_vector"
      ),
      vector_tasveg_class_preview = named_path_lookup(
        ctx$analysis_layer_preview_paths,
        "tasveg_class_vector"
      ),
      tasveg_class_lookup = ctx$tasveg_class_lookup,
      tasveg_group_lookup = ctx$analysis_attribute_lookups$tasveg_group_lookup,
      geology_lookup = ctx$analysis_attribute_lookups$geology_lookup,
      land_tenure_lookup = ctx$analysis_attribute_lookups$land_tenure_lookup,
      reserve_estate_lookup = ctx$analysis_attribute_lookups$reserve_estate_lookup,
      vector_fire_attributes_preview = named_path_lookup(
        ctx$analysis_layer_preview_paths,
        "tas_fire_attributes"
      ),
      vector_geology_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "tas_geology"),
      vector_land_tenure_preview = named_path_lookup(
        ctx$analysis_layer_preview_paths,
        "tas_land_tenure"
      ),
      vector_reserve_estate_preview = named_path_lookup(
        ctx$analysis_layer_preview_paths,
        "tas_reserve_estate"
      ),
      raster_dem_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "tas_dem"),
      raster_slope_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "tas_slope"),
      raster_chm_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "tas_chm"),
      raster_soil_ph_preview = named_path_lookup(
        ctx$analysis_layer_preview_paths,
        "tas_soil_ph"
      ),
      raster_bio1_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "tas_bio1"),
      raster_bio12_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "tas_bio12"),
      site_attributes_long = ctx$site_attributes_long_file,
      site_attributes_wide = ctx$site_attributes_wide_file,
      analysis_provenance = ctx$analysis_provenance,
      attribution_report = ctx$attribution_report,
      run_manifest = ctx$run_manifest
    ))
  }

  if (identical(profile, "demo")) {
    return(list(
      species_map = ctx$species_map,
      camera_sites_map = ctx$camera_sites_map,
      camera_sites_panel = ctx$camera_sites_panel,
      camera_sites_tile = ctx$camera_sites_tile,
      aoi_debug_plot = ctx$aoi_debug_plot,
      coverage_summary = ctx$coverage_summary,
      site_attributes_long = ctx$site_attributes_long_file,
      site_attributes_wide = ctx$site_attributes_wide_file,
      wms_layer = named_path_lookup(ctx$layer_output_paths, "tasveg_wms"),
      wms_layer_provenance = named_path_lookup(ctx$layer_provenance_paths, "tasveg_wms"),
      arcgis_layer = named_path_lookup(ctx$layer_output_paths, "topography_arcgis"),
      arcgis_layer_provenance = named_path_lookup(
        ctx$layer_provenance_paths,
        "topography_arcgis"
      ),
      overview_map = ctx$overview_map,
      panel_figure_png = ctx$panel_figure_png,
      panel_figure_pdf = ctx$panel_figure_pdf,
      fire_attributes_arcgis_layer = named_path_lookup(
        ctx$layer_output_paths,
        "fire_attributes_arcgis"
      ),
      fire_attributes_arcgis_layer_provenance = named_path_lookup(
        ctx$layer_provenance_paths,
        "fire_attributes_arcgis"
      ),
      soil_ph_wms_layer = named_path_lookup(ctx$layer_output_paths, "soil_ph_wms"),
      soil_ph_wms_layer_provenance = named_path_lookup(
        ctx$layer_provenance_paths,
        "soil_ph_wms"
      ),
      vector_fire_attributes = named_path_lookup(
        ctx$analysis_layer_paths,
        "demo_fire_attributes"
      ),
      vector_fire_attributes_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "demo_fire_attributes"
      ),
      vector_fire_attributes_preview = named_path_lookup(
        ctx$analysis_layer_preview_paths,
        "demo_fire_attributes"
      ),
      vector_geology = named_path_lookup(ctx$analysis_layer_paths, "demo_geology"),
      vector_geology_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "demo_geology"
      ),
      vector_geology_preview = named_path_lookup(
        ctx$analysis_layer_preview_paths,
        "demo_geology"
      ),
      vector_land_tenure = named_path_lookup(ctx$analysis_layer_paths, "demo_land_tenure"),
      vector_land_tenure_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "demo_land_tenure"
      ),
      vector_land_tenure_preview = named_path_lookup(
        ctx$analysis_layer_preview_paths,
        "demo_land_tenure"
      ),
      vector_reserve_estate = named_path_lookup(
        ctx$analysis_layer_paths,
        "demo_reserve_estate"
      ),
      vector_reserve_estate_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "demo_reserve_estate"
      ),
      vector_reserve_estate_preview = named_path_lookup(
        ctx$analysis_layer_preview_paths,
        "demo_reserve_estate"
      ),
      raster_chm = named_path_lookup(ctx$analysis_layer_paths, "demo_chm"),
      raster_chm_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "demo_chm"
      ),
      raster_chm_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "demo_chm"),
      raster_soil_ph = named_path_lookup(ctx$analysis_layer_paths, "demo_soil_ph"),
      raster_soil_ph_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "demo_soil_ph"
      ),
      raster_soil_ph_preview = named_path_lookup(
        ctx$analysis_layer_preview_paths,
        "demo_soil_ph"
      ),
      raster_bio1 = named_path_lookup(ctx$analysis_layer_paths, "demo_bio1"),
      raster_bio1_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "demo_bio1"
      ),
      raster_bio1_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "demo_bio1"),
      raster_bio12 = named_path_lookup(ctx$analysis_layer_paths, "demo_bio12"),
      raster_bio12_provenance = named_path_lookup(
        ctx$analysis_layer_provenance_paths,
        "demo_bio12"
      ),
      raster_bio12_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "demo_bio12"),
      analysis_provenance = ctx$analysis_provenance,
      attribution_report = ctx$attribution_report,
      run_manifest = ctx$run_manifest
    ))
  }

  list(
    species_map = ctx$species_map,
    camera_sites_map = ctx$camera_sites_map,
    camera_sites_panel = ctx$camera_sites_panel,
    camera_sites_tile = ctx$camera_sites_tile,
    aoi_debug_plot = ctx$aoi_debug_plot,
    coverage_summary = ctx$coverage_summary,
    wms_layer = named_path_lookup(ctx$layer_output_paths, "tasveg_wms"),
    wms_layer_provenance = named_path_lookup(ctx$layer_provenance_paths, "tasveg_wms"),
    tasveg_class_wms_layer = named_path_lookup(ctx$layer_output_paths, "tasveg_class_wms"),
    tasveg_class_wms_layer_provenance = named_path_lookup(
      ctx$layer_provenance_paths,
      "tasveg_class_wms"
    ),
    tasveg_class_wms_legend = ctx$tasveg_class_legend,
    arcgis_layer = named_path_lookup(ctx$layer_output_paths, "topography_arcgis"),
    arcgis_layer_provenance = named_path_lookup(
      ctx$layer_provenance_paths,
      "topography_arcgis"
    ),
    orthophoto_arcgis_layer = named_path_lookup(ctx$layer_output_paths, "orthophoto_arcgis"),
    orthophoto_arcgis_layer_provenance = named_path_lookup(
      ctx$layer_provenance_paths,
      "orthophoto_arcgis"
    ),
    roads_wms_layer = named_path_lookup(ctx$layer_output_paths, "roads_wms"),
    roads_wms_layer_provenance = named_path_lookup(
      ctx$layer_provenance_paths,
      "roads_wms"
    ),
    localities_wms_layer = named_path_lookup(ctx$layer_output_paths, "localities_wms"),
    localities_wms_layer_provenance = named_path_lookup(
      ctx$layer_provenance_paths,
      "localities_wms"
    ),
    fire_attributes_arcgis_layer = named_path_lookup(
      ctx$layer_output_paths,
      "fire_attributes_arcgis"
    ),
    fire_attributes_arcgis_layer_provenance = named_path_lookup(
      ctx$layer_provenance_paths,
      "fire_attributes_arcgis"
    ),
    soil_ph_wms_layer = named_path_lookup(ctx$layer_output_paths, "soil_ph_wms"),
    soil_ph_wms_layer_provenance = named_path_lookup(
      ctx$layer_provenance_paths,
      "soil_ph_wms"
    ),
    overview_map = ctx$overview_map,
    panel_figure_png = ctx$panel_figure_png,
    panel_figure_pdf = ctx$panel_figure_pdf,
    vector_tasveg = named_path_lookup(ctx$analysis_layer_paths, "jc_tasveg"),
    vector_tasveg_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_tasveg"
    ),
    vector_tasveg_class = named_path_lookup(ctx$analysis_layer_paths, "jc_tasveg_class"),
    vector_tasveg_class_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_tasveg_class"
    ),
    vector_fire_attributes = named_path_lookup(ctx$analysis_layer_paths, "jc_fire_attributes"),
    vector_fire_attributes_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_fire_attributes"
    ),
    vector_geology = named_path_lookup(ctx$analysis_layer_paths, "jc_geology"),
    vector_geology_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_geology"
    ),
    vector_land_tenure = named_path_lookup(ctx$analysis_layer_paths, "jc_land_tenure"),
    vector_land_tenure_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_land_tenure"
    ),
    vector_reserve_estate = named_path_lookup(ctx$analysis_layer_paths, "jc_reserve_estate"),
    vector_reserve_estate_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_reserve_estate"
    ),
    raster_dem = named_path_lookup(ctx$analysis_layer_paths, "jc_dem"),
    raster_dem_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_dem"
    ),
    raster_multiband = named_path_lookup(ctx$analysis_layer_paths, "jc_multiband"),
    raster_multiband_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_multiband"
    ),
    raster_slope = named_path_lookup(ctx$analysis_layer_paths, "jc_slope"),
    raster_slope_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_slope"
    ),
    raster_ndvi = named_path_lookup(ctx$analysis_layer_paths, "jc_ndvi"),
    raster_ndvi_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_ndvi"
    ),
    raster_nbr = named_path_lookup(ctx$analysis_layer_paths, "jc_nbr"),
    raster_nbr_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_nbr"
    ),
    raster_chm = named_path_lookup(ctx$analysis_layer_paths, "jc_chm"),
    raster_chm_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_chm"
    ),
    raster_soil_ph = named_path_lookup(ctx$analysis_layer_paths, "jc_soil_ph"),
    raster_soil_ph_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_soil_ph"
    ),
    raster_bio1 = named_path_lookup(ctx$analysis_layer_paths, "jc_bio1"),
    raster_bio1_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_bio1"
    ),
    raster_bio12 = named_path_lookup(ctx$analysis_layer_paths, "jc_bio12"),
    raster_bio12_provenance = named_path_lookup(
      ctx$analysis_layer_provenance_paths,
      "jc_bio12"
    ),
    vector_tasveg_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "jc_tasveg"),
    vector_tasveg_class_preview = named_path_lookup(
      ctx$analysis_layer_preview_paths,
      "jc_tasveg_class"
    ),
    tasveg_class_lookup = ctx$tasveg_class_lookup,
    tasveg_group_lookup = ctx$analysis_attribute_lookups$tasveg_group_lookup,
    geology_lookup = ctx$analysis_attribute_lookups$geology_lookup,
    land_tenure_lookup = ctx$analysis_attribute_lookups$land_tenure_lookup,
    reserve_estate_lookup = ctx$analysis_attribute_lookups$reserve_estate_lookup,
    vector_fire_attributes_preview = named_path_lookup(
      ctx$analysis_layer_preview_paths,
      "jc_fire_attributes"
    ),
    vector_geology_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "jc_geology"),
    vector_land_tenure_preview = named_path_lookup(
      ctx$analysis_layer_preview_paths,
      "jc_land_tenure"
    ),
    vector_reserve_estate_preview = named_path_lookup(
      ctx$analysis_layer_preview_paths,
      "jc_reserve_estate"
    ),
    raster_dem_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "jc_dem"),
    raster_multiband_preview = named_path_lookup(
      ctx$analysis_layer_preview_paths,
      "jc_multiband"
    ),
    raster_slope_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "jc_slope"),
    raster_ndvi_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "jc_ndvi"),
    raster_nbr_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "jc_nbr"),
    raster_chm_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "jc_chm"),
    raster_soil_ph_preview = named_path_lookup(
      ctx$analysis_layer_preview_paths,
      "jc_soil_ph"
    ),
    raster_bio1_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "jc_bio1"),
    raster_bio12_preview = named_path_lookup(ctx$analysis_layer_preview_paths, "jc_bio12"),
    site_attributes_long = ctx$site_attributes_long_file,
    site_attributes_wide = ctx$site_attributes_wide_file,
    analysis_provenance = ctx$analysis_provenance,
    attribution_report = ctx$attribution_report,
    run_manifest = ctx$run_manifest
  )
}
