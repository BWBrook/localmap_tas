project_root <- normalizePath(
  testthat::test_path("..", ".."),
  winslash = "/",
  mustWork = TRUE
)

read_make_target <- function(name) {
  lines <- readLines(file.path(project_root, "Makefile"), warn = FALSE)
  headers <- grep(
    "^[A-Za-z0-9_.-]+([[:space:]]+[A-Za-z0-9_.-]+)*[[:space:]]*:",
    lines
  )
  start <- which(lines == paste0(name, ":"))
  testthat::expect_identical(length(start), 1L)
  if (length(start) != 1L) return(character())

  later <- headers[headers > start]
  end <- if (length(later)) later[[1L]] - 1L else length(lines)
  lines[start:end]
}

testthat::test_that("public pkgdown build uses supported filtered components", {
  helper <- file.path(project_root, "scripts", "build_public_site.R")
  testthat::expect_true(file.exists(helper))
  if (!file.exists(helper)) return(invisible())

  code <- paste(
    vapply(parse(file = helper), deparse1, character(1), width.cutoff = 500L),
    collapse = "\n"
  )
  testthat::expect_false(grepl("pkgdown:::", code, fixed = TRUE))
  install_calls <- gregexpr('install.packages("pkgdown")', code, fixed = TRUE)[[1L]]
  build_calls <- gregexpr("pkgdown::build_reference", code, fixed = TRUE)[[1L]]
  testthat::expect_identical(sum(install_calls > 0L), 1L)
  testthat::expect_identical(sum(build_calls > 0L), 1L)
  testthat::expect_false(grepl("pkgdown::build_site", code, fixed = TRUE))
  testthat::expect_match(code, "pkgdown::build_reference", fixed = TRUE)
  testthat::expect_match(code, "topics = public_topics", fixed = TRUE)
  testthat::expect_match(code, "pkgdown::build_search", fixed = TRUE)
  testthat::expect_match(code, "jsonlite::read_json", fixed = TRUE)
  testthat::expect_match(code, "xml2::read_xml", fixed = TRUE)
  testthat::expect_match(code, "xml2::xml_set_name", fixed = TRUE)
  testthat::expect_match(code, "xml2::xml_set_attrs", fixed = TRUE)
})

testthat::test_that("site target invokes one public site build path", {
  block <- read_make_target("site")
  recipe <- block[startsWith(block, "\t")]

  testthat::expect_identical(
    recipe,
    "\t@$(RSCRIPT) scripts/build_public_site.R"
  )
})

testthat::test_that("real-data guides distinguish checkout and installed routes", {
  route_paths <- c(
    "README.md",
    "docs/product_brief.md",
    "docs/index.qmd",
    "docs/settings.md",
    "docs/PIPELINE.md",
    "docs/workflow.md",
    "vignettes/intro.Rmd"
  )
  wrapper <- "Rscript scripts/run_project.R settings.example.yaml"
  api_call <- 'localmap::run_settings("settings.example.yaml")'

  for (path in route_paths) {
    text <- paste(readLines(file.path(project_root, path), warn = FALSE), collapse = "\n")
    wrapper_at <- regexpr(wrapper, text, fixed = TRUE)[[1L]]
    api_at <- regexpr(api_call, text, fixed = TRUE)[[1L]]

    testthat::expect_true(wrapper_at > 0L, info = path)
    testthat::expect_true(api_at > wrapper_at, info = path)
    testthat::expect_match(tolower(text), "installed", fixed = TRUE, info = path)
  }
})

testthat::test_that("primary real-data guides do not claim checkout inputs exist", {
  paths <- c(
    "README.md",
    "docs/index.qmd",
    "docs/settings.md",
    "vignettes/intro.Rmd"
  )

  for (path in paths) {
    text <- paste(readLines(file.path(project_root, path), warn = FALSE), collapse = "\n")
    normalized <- gsub("[[:space:]]+", " ", tolower(text))
    testthat::expect_match(
      normalized,
      "not included in the checkout",
      fixed = TRUE,
      info = path
    )
  }
})

testthat::test_that("README navigation uses durable repository source URLs", {
  readme <- paste(
    readLines(file.path(project_root, "README.md"), warn = FALSE),
    collapse = "\n"
  )
  source_base <- "https://github.com/BWBrook/localmap_tas/blob/main/"
  expected <- paste0(
    source_base,
    c(
      "docs/settings.md",
      "docs/config_reference.md",
      "docs/layers_guide.md",
      "docs/output_schema_v1.md",
      "docs/DEVELOPMENT.qmd",
      "docs/workflow.md"
    )
  )

  testthat::expect_true(all(vapply(expected, grepl, logical(1), x = readme, fixed = TRUE)))
  testthat::expect_false(grepl("](../quarto/", readme, fixed = TRUE))
  testthat::expect_false(grepl("](../reports/", readme, fixed = TRUE))
})

testthat::test_that("pkgdown navbar carries rendered documentation navigation", {
  config <- yaml::read_yaml(file.path(project_root, "_pkgdown.yml"))
  components <- config$navbar$components
  hrefs <- vapply(components, `[[`, character(1), "href")

  testthat::expect_true("../quarto/index.html" %in% hrefs)
  testthat::expect_true("../quarto/settings.html" %in% hrefs)
  testthat::expect_true("../reports/paper.html" %in% hrefs)
})

testthat::test_that("DESCRIPTION reflects the settings-first mapping product", {
  description <- read.dcf(file.path(project_root, "DESCRIPTION"))

  testthat::expect_identical(
    unname(description[[1L, "Title"]]),
    "Settings-First Tasmanian Field-Site Mapping"
  )
  testthat::expect_match(
    unname(description[[1L, "Description"]]),
    "configured Tasmanian field sites",
    fixed = TRUE
  )
  testthat::expect_false(grepl(
    "species occurrence",
    description[[1L, "Description"]],
    ignore.case = TRUE
  ))
})

testthat::test_that("Quarto retains the mandated external output destination", {
  config <- yaml::read_yaml(file.path(project_root, "docs", "_quarto.yml"))

  testthat::expect_identical(config$project$`output-dir`, "../outputs/quarto")
  testthat::expect_length(config$project$render, 8L)
})
