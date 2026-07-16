#!/usr/bin/env Rscript

if (!requireNamespace("pkgdown", quietly = TRUE)) {
  install.packages("pkgdown")
}

config <- yaml::read_yaml("_pkgdown.yml")
internal_sections <- vapply(
  config$reference,
  function(section) identical(tolower(section$title), "internal"),
  logical(1)
)
if (!identical(sum(internal_sections), 1L)) {
  stop("Pkgdown requires one internal suppression section.", call. = FALSE)
}
reference <- config$reference[!internal_sections]
group_sizes <- vapply(reference, function(section) length(section$contents), integer(1))
public_topics <- unname(unlist(lapply(reference, `[[`, "contents"), use.names = FALSE))

if (!identical(group_sizes, c(2L, 4L, 3L, 4L, 4L))) {
  stop("Public reference groups must contain 2, 4, 3, 4, and 4 topics.", call. = FALSE)
}
if (length(public_topics) != 17L || anyDuplicated(public_topics)) {
  stop("Public reference topics must contain exactly 17 unique names.", call. = FALSE)
}

namespace <- parse(file = "NAMESPACE")
exports <- vapply(
  Filter(function(expr) is.call(expr) && identical(expr[[1L]], quote(export)), namespace),
  function(expr) as.character(expr[[2L]]),
  character(1)
)
if (!identical(sort(public_topics), sort(exports))) {
  stop("Pkgdown topics must match the package exports exactly.", call. = FALSE)
}

pkg <- pkgdown::as_pkgdown(".")
topic_rows <- match(public_topics, pkg$topics$name)
if (anyNA(topic_rows)) {
  stop("Every public export must map to a documented pkgdown topic.", call. = FALSE)
}
public_reference_files <- basename(pkg$topics$file_out[topic_rows])
private_reference_files <- setdiff(basename(pkg$topics$file_out), public_reference_files)

pkgdown::clean_site(pkg, quiet = TRUE, force = TRUE)
pkgdown::init_site(pkg)
pkgdown::build_home(pkg, preview = FALSE, quiet = FALSE)

agents_page <- file.path(pkg$dst_path, "AGENTS.html")
if (file.exists(agents_page) && !file.remove(agents_page)) {
  stop("Could not remove the generated AGENTS page.", call. = FALSE)
}

pkgdown::build_reference(
  pkg,
  lazy = FALSE,
  examples = TRUE,
  preview = FALSE,
  devel = TRUE,
  topics = public_topics
)

disable_private_reference_links <- function(path) {
  document <- xml2::read_html(path)
  links <- xml2::xml_find_all(document, "//a[@href]")
  hrefs <- xml2::xml_attr(links, "href")
  targets <- basename(sub("[?#].*$", "", hrefs))
  private <- !is.na(targets) & targets %in% private_reference_files
  if (!any(private)) return(0L)

  for (link in links[private]) {
    attributes <- xml2::xml_attrs(link)
    xml2::xml_set_name(link, "span")
    xml2::xml_set_attrs(link, attributes[names(attributes) != "href"])
  }
  xml2::write_html(document, path)
  sum(private)
}

private_links_removed <- sum(vapply(
  file.path(pkg$dst_path, "reference", public_reference_files),
  disable_private_reference_links,
  integer(1)
))

pkgdown::build_articles_index(pkg)
for (article in pkg$vignettes$name) {
  pkgdown::build_article(
    article,
    pkg = pkg,
    lazy = FALSE,
    new_process = FALSE,
    quiet = FALSE
  )
}
pkgdown::build_tutorials(pkg, preview = FALSE)
pkgdown::build_news(pkg, preview = FALSE)
pkgdown::build_redirects(pkg)
pkgdown::build_search(pkg)

html_files <- sort(list.files(
  pkg$dst_path,
  pattern = "[.]html$",
  recursive = TRUE,
  full.names = TRUE
))
site_paths <- substring(html_files, nchar(pkg$dst_path) + 2L)
site_paths <- gsub("\\\\", "/", site_paths)

sitemap <- xml2::xml_new_root("urlset")
xml2::xml_set_attr(sitemap, "xmlns", "http://www.sitemaps.org/schemas/sitemap/0.9")
for (site_path in site_paths) {
  url <- xml2::xml_add_child(sitemap, "url")
  xml2::xml_add_child(url, "loc", paste0("/", site_path))
}
xml2::write_xml(sitemap, file.path(pkg$dst_path, "sitemap.xml"), options = "format")

actual_reference_files <- sort(list.files(
  file.path(pkg$dst_path, "reference"),
  pattern = "[.]html$"
))
expected_reference_files <- sort(c("index.html", public_reference_files))
if (!identical(actual_reference_files, expected_reference_files)) {
  stop("Generated reference pages do not match the public topic contract.", call. = FALSE)
}
if (file.exists(agents_page)) {
  stop("AGENTS.html must not remain in the public site.", call. = FALSE)
}

collect_search_paths <- function(value) {
  if (!is.list(value)) return(character())
  current <- if (!is.null(value$path) && is.character(value$path)) value$path else character()
  c(current, unlist(lapply(value, collect_search_paths), use.names = FALSE))
}

search <- jsonlite::read_json(file.path(pkg$dst_path, "search.json"), simplifyVector = FALSE)
search_paths <- unique(collect_search_paths(search))
sitemap_doc <- xml2::read_xml(file.path(pkg$dst_path, "sitemap.xml"))
sitemap_paths <- xml2::xml_text(xml2::xml_find_all(
  sitemap_doc,
  "//*[local-name()='loc']"
))

assert_public_paths <- function(paths, source) {
  if (any(grepl("AGENTS[.]html", paths, ignore.case = TRUE))) {
    stop(source, " exposes AGENTS.html.", call. = FALSE)
  }
  reference_paths <- paths[grepl("/reference/[^/]+[.]html$", paths)]
  reference_files <- unique(basename(reference_paths))
  unexpected <- setdiff(reference_files, c("index.html", public_reference_files))
  if (length(unexpected)) {
    stop(source, " exposes non-public reference topics: ", paste(unexpected, collapse = ", "), call. = FALSE)
  }
}

assert_public_paths(search_paths, "search.json")
assert_public_paths(sitemap_paths, "sitemap.xml")

cat("Finished building public pkgdown site\n")
cat("Reference groups: ", paste(group_sizes, collapse = ","), "\n", sep = "")
cat("Reference topics: ", length(public_reference_files), "\n", sep = "")
cat("Private reference links disabled: ", private_links_removed, "\n", sep = "")
cat("HTML pages: ", length(html_files), "\n", sep = "")
