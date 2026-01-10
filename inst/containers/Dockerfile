FROM rocker/r2u:jammy

# Install system libraries needed for geospatial work and other common R extensions.
RUN apt-get update && apt-get install -y --no-install-recommends \
    gdal-bin libgdal-dev libgeos-dev libproj-dev libudunits2-dev \
    cmake git pandoc libfontconfig1-dev libfreetype6-dev libgit2-dev \
    libglpk-dev libx11-dev libharfbuzz-dev libfribidi-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /project
COPY . /project

# Bootstrap dependencies (restore if renv.lock exists, otherwise init + snapshot)
RUN R -q -e "source('scripts/bootstrap_container.R')"

# Default command: run the full pipeline
CMD ["R", "-q", "-e", "targets::tar_make()"]
