# Generate small analysis fixtures for JC example (vector + raster)
# Run from repo root: Rscript scripts/generate_analysis_fixtures.R

suppressPackageStartupMessages({
  library(sf)
  library(terra)
  library(readr)
})

set.seed(123)

jc_sites <- read_csv("data/raw/jc_camera_study/site.csv", show_col_types = FALSE)

# Build a simple bounding box around sites in EPSG:4326
bbox <- st_bbox(c(
  xmin = min(jc_sites$lon) - 0.002,
  xmax = max(jc_sites$lon) + 0.002,
  ymin = min(jc_sites$lat) - 0.002,
  ymax = max(jc_sites$lat) + 0.002
), crs = 4326)

# Vector fixture: two polygons with habitat labels
poly_left <- st_polygon(list(rbind(
  c(bbox["xmin"], bbox["ymin"]),
  c(mean(c(bbox["xmin"], bbox["xmax"])), bbox["ymin"]),
  c(mean(c(bbox["xmin"], bbox["xmax"])), bbox["ymax"]),
  c(bbox["xmin"], bbox["ymax"]),
  c(bbox["xmin"], bbox["ymin"])
)))
poly_right <- st_polygon(list(rbind(
  c(mean(c(bbox["xmin"], bbox["xmax"])), bbox["ymin"]),
  c(bbox["xmax"], bbox["ymin"]),
  c(bbox["xmax"], bbox["ymax"]),
  c(mean(c(bbox["xmin"], bbox["xmax"])), bbox["ymax"]),
  c(mean(c(bbox["xmin"], bbox["xmax"])), bbox["ymin"])
)))

vector_sf <- st_sf(
  habitat = c("forest", "grassland"),
  zone = c("west", "east"),
  geometry = st_sfc(poly_left, poly_right, crs = 4326)
)

vector_path <- "inst/extdata/jc_habitats.gpkg"
if (file.exists(vector_path)) file.remove(vector_path)

st_write(vector_sf, vector_path, layer = "habitats", quiet = TRUE)

# Raster fixtures
# DEM: gradient surface
r <- rast(nrows = 60, ncols = 60, xmin = bbox["xmin"], xmax = bbox["xmax"],
          ymin = bbox["ymin"], ymax = bbox["ymax"], crs = "EPSG:4326")

values(r) <- as.vector(outer(seq(1, 60), seq(1, 60), function(x, y) x + y))

writeRaster(r, "inst/extdata/jc_dem.tif", overwrite = TRUE)

# Multiband raster: red, nir, swir2
r1 <- r
values(r1) <- values(r) / max(values(r))
r2 <- r
values(r2) <- pmin(1, values(r1) * 1.2 + rnorm(ncell(r1), 0, 0.02))
r3 <- r
values(r3) <- pmin(1, values(r1) * 0.8 + rnorm(ncell(r1), 0, 0.02))

multi <- c(r1, r2, r3)
names(multi) <- c("red", "nir", "swir2")
writeRaster(multi, "inst/extdata/jc_multiband.tif", overwrite = TRUE)

message("Fixtures written to inst/extdata/")
