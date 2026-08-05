#' Validate output schema manifest
#'
#' Ensures the output manifest contains required fields and verifies that
#' declared output files exist on disk when expected outputs are supplied.
#'
#' @param manifest A tibble/data.frame with output metadata.
#' @param expected_outputs Optional named list mapping output_id to file path.
#' @return The manifest as a tibble (invisibly) after validation.
#' @export

validate_output_manifest <- function(manifest,
                                     expected_outputs = NULL) {
  checkmate::assert_data_frame(manifest, min.rows = 1L)
  required <- c("output_id", "type", "path")
  checkmate::assert_names(names(manifest), must.include = required)

  if (!is.null(expected_outputs)) {
    checkmate::assert_list(expected_outputs, any.missing = FALSE)
    for (id in names(expected_outputs)) {
      path <- expected_outputs[[id]]
      if (!is.null(path) && nzchar(path) && file.exists(path)) {
        manifest_rows <- manifest[manifest$output_id == id, , drop = FALSE]
        if (nrow(manifest_rows) == 0L) {
          rlang::abort(
            sprintf("Output manifest missing output_id '%s'.", id),
            class = "output_manifest_missing_id"
          )
        }
        for (declared in manifest_rows$path) {
          if (!file.exists(declared)) {
            rlang::abort(
              sprintf("Declared output missing on disk: %s", declared),
              class = "output_manifest_missing_file"
            )
          }
        }
      }
    }
  }

  tibble::as_tibble(manifest)
}
