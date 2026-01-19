# Attribute lookup helpers for coded site-attribute tables.

attribute_code_from_label <- function(labels,
                                      max_len = 4L,
                                      stopwords = c(
                                        "and",
                                        "of",
                                        "the",
                                        "on",
                                        "in",
                                        "for",
                                        "with",
                                        "to",
                                        "other"
                                      )) {
  labels_chr <- as.character(labels)
  stopwords <- tolower(stopwords)

  build_code <- function(label) {
    if (is.na(label) || !nzchar(label)) {
      return(NA_character_)
    }
    cleaned <- gsub("[^A-Za-z0-9 ]+", " ", label)
    words <- strsplit(cleaned, "\\s+")[[1]]
    words <- words[nzchar(words)]
    if (length(words) == 0L) {
      return(NA_character_)
    }
    keep <- !tolower(words) %in% stopwords
    if (!any(keep)) {
      keep <- rep(TRUE, length(words))
    }
    words <- words[keep]
    if (length(words) == 0L) {
      return(NA_character_)
    }
    if (length(words) == 1L) {
      code <- toupper(substr(words[[1]], 1, min(3L, nchar(words[[1]]))))
    } else {
      code <- toupper(paste0(substr(words, 1, 1), collapse = ""))
      if (nchar(code) > max_len) {
        code <- substr(code, 1, max_len)
      }
    }
    code
  }

  vapply(labels_chr, build_code, character(1))
}

write_attribute_lookup <- function(vector_path,
                                   label_field,
                                   code_field = NULL,
                                   output_path = NULL,
                                   max_len = 4L,
                                   stopwords = NULL) {
  if (is.null(output_path) || !nzchar(output_path)) {
    output_path <- sub("\\.gpkg$", "_lookup.csv", vector_path)
  }
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  if (is.null(vector_path) || !nzchar(vector_path) || !file.exists(vector_path)) {
    utils::write.csv(
      tibble::tibble(code = character(), label = character(), derived = logical()),
      output_path,
      row.names = FALSE
    )
    return(output_path)
  }

  vec <- sf::st_read(vector_path, quiet = TRUE)
  if (is.null(label_field) || !label_field %in% names(vec)) {
    utils::write.csv(
      tibble::tibble(code = character(), label = character(), derived = logical()),
      output_path,
      row.names = FALSE
    )
    return(output_path)
  }

  labels <- as.character(vec[[label_field]])
  labels <- stats::na.omit(labels)
  if (length(labels) == 0L) {
    utils::write.csv(
      tibble::tibble(code = character(), label = character(), derived = logical()),
      output_path,
      row.names = FALSE
    )
    return(output_path)
  }

  if (!is.null(code_field) && code_field %in% names(vec)) {
    codes <- as.character(vec[[code_field]])
    tbl <- tibble::tibble(
      code = codes,
      label = labels
    ) |>
      dplyr::filter(!is.na(.data$code) & nzchar(.data$code)) |>
      dplyr::group_by(.data$code) |>
      dplyr::summarise(label = dplyr::first(.data$label), .groups = "drop") |>
      dplyr::arrange(.data$code) |>
      dplyr::mutate(derived = FALSE)
  } else {
    unique_labels <- sort(unique(labels))
    codes <- attribute_code_from_label(
      unique_labels,
      max_len = max_len,
      stopwords = stopwords
    )
    codes <- make.unique(codes, sep = "")
    tbl <- tibble::tibble(
      code = codes,
      label = unique_labels,
      derived = TRUE
    )
  }

  utils::write.csv(tbl, output_path, row.names = FALSE)
  output_path
}

render_attribute_lookups <- function(analysis_layers) {
  if (is.null(analysis_layers) || !is.data.frame(analysis_layers) ||
      nrow(analysis_layers) == 0L) {
    return(list())
  }
  layer_ids <- as.character(analysis_layers$id)
  path_lookup <- stats::setNames(analysis_layers$path, layer_ids)
  base_dir <- if (length(path_lookup) > 0L) {
    dirname(path_lookup[[1]])
  } else {
    "outputs/analysis"
  }

  find_layer <- function(pattern, exclude = NULL) {
    idx <- grepl(pattern, layer_ids)
    if (!is.null(exclude)) {
      idx <- idx & !grepl(exclude, layer_ids)
    }
    if (!any(idx)) {
      return(NULL)
    }
    layer_ids[which(idx)[1]]
  }

  lookup_for <- function(layer_id,
                         label_field,
                         code_field = NULL,
                         lookup_suffix = "_lookup.csv",
                         max_len = 4L,
                         stopwords = NULL) {
    vector_path <- path_lookup[[layer_id]]
    lookup_path <- if (!is.null(vector_path) && nzchar(vector_path)) {
      sub("\\.gpkg$", lookup_suffix, vector_path)
    } else {
      file.path(base_dir, paste0(layer_id, lookup_suffix))
    }
    write_attribute_lookup(
      vector_path = vector_path,
      label_field = label_field,
      code_field = code_field,
      output_path = lookup_path,
      max_len = max_len,
      stopwords = stopwords
    )
  }

  list(
    tasveg_group_lookup = lookup_for(
      layer_id = find_layer("tasveg", exclude = "class"),
      label_field = "VEG_GROUP",
      lookup_suffix = "_group_lookup.csv",
      max_len = 4L
    ),
    geology_lookup = lookup_for(
      layer_id = find_layer("geology"),
      label_field = "description",
      code_field = "map_symb",
      lookup_suffix = "_lookup.csv",
      max_len = 4L
    ),
    land_tenure_lookup = lookup_for(
      layer_id = find_layer("land_tenure"),
      label_field = "TEN_CLASS",
      lookup_suffix = "_lookup.csv",
      max_len = 4L
    ),
    reserve_estate_lookup = lookup_for(
      layer_id = find_layer("reserve_estate"),
      label_field = "RES_CLASS",
      lookup_suffix = "_lookup.csv",
      max_len = 4L
    )
  )
}
