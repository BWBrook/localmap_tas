# Workflow

This is the authoritative run, validation, and artifact-review workflow for
contributors and automation.

## 1. Choose a supported route

### Deterministic JC demonstration

From a clean checkout, run:

```sh
make bootstrap
LOCALMAP_ALLOW_NETWORK=0 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci make pipeline
```

`jc_ci` uses packaged occurrence and camera-site fixtures, offline WMS/ArcGIS
placeholders, and disabled topographic tiles. It does not promise
`outputs/jc/maps/species_topo.png`. Use this route for repeatable pipeline and
artifact-contract evidence, not as proof that live map services work.

### Real-data settings

Use the [settings guide](settings.md) for the primary real-data route.
`settings.example.yaml` is real-data only: its configured input directory must
contain `site.csv` with `site`, `lat`, and `lon`; `obs.csv` and `op.csv` are
optional. After `make bootstrap`, the source checkout entry point is:

```sh
Rscript scripts/run_project.R settings.example.yaml
```

After `localmap` has been installed as an R package, the equivalent API route is:

```r
localmap::run_settings("settings.example.yaml")
```

Both routes delegate to the public settings API, write the resolved run config
under the project output directory, and run the same target graph.

## 2. Implement incrementally

1. Keep the active roadmap scope and costly design decisions current.
2. Keep `_targets.R` thin and place reusable logic in focused package functions.
3. Add or update tests before behavior changes; preserve deterministic fixtures.
4. Update user documentation and the Unreleased changelog when contracts change.
5. Keep runtime data in `data/` and generated products in `outputs/`; never use
   generated HTML or output artifacts as source files.

## 3. Validate technically

Use the repository commands rather than softer ad hoc substitutes:

```sh
make bootstrap-qa
make actionlint
make lint
LOCALMAP_ALLOW_NETWORK=0 make test
make docs
make site
make check
git diff --check
```

`make test` is decisive and returns nonzero on a failure. Network-dependent
tests stay gated by default. An established offline warning or network skip is
not permission to accept a new warning, skip, or failure.

## 4. Review artifacts as scientific results

After every output-affecting change:

1. Generate overview, occurrence/camera, and panel maps; site-attribute tables;
   layer sidecars; attribution; and run-manifest products relevant to the run.
2. Confirm all site points lie within the AOI and that base layers, overlays,
   graticules, labels, scale bars, north arrows, legends, and panel extents are
   coherent.
3. Check dimensions and resolution against the intended use, and compare table
   row/column content with the configured sites and layers.
4. Read provenance before interpreting pixels or values. In particular,
   distinguish live acquisition and cache hits from `offline_fixture`,
   `offline_placeholder`, or other placeholder status.
5. Record what the artifacts show, anything suspicious, and any required
   iteration in the work package that owns the change.
6. Fix, rerun, and reinspect until the products are coherent. Passing tests alone
   is not artifact acceptance.

See the [Layer registry guide](layers_guide.md) for provenance interpretation,
and assess each selected product through the artefact-review steps above.

## 5. Reproducibility and acquisition rules

- `renv.lock` is authoritative; never hand-edit it.
- Avoid hidden state and resolve project paths consistently.
- Cache remote layers deterministically. Network or source failures must warn or
  fail explicitly and must never silently produce a misleading map.
- Network fetches require `LOCALMAP_ALLOW_NETWORK=1`. Large downloads require
  `LOCALMAP_ALLOW_LARGE_DOWNLOADS=1` and compatible configuration.
- Offline imagery may use visible placeholders. Offline ArcGIS vector/raster
  analysis requires configured fixtures or an actionable failure.
- Fixture-backed sidecars retain `offline_fixture`; ordinary cached inputs use
  `cache_hit`. Placeholder status must remain visible in provenance.
- Containers use `scripts/bootstrap_container.R` and mount real datasets rather
  than baking them into images.

On macOS, install `gdal`, `geos`, `proj`, `udunits`, and `apache-arrow` through
Homebrew before the first restore. The bootstrap scripts preflight this stack.

## 6. Stop and escalate

Stop when required credentials/data are unavailable, a consequential design fork
is ambiguous, a validation/render/link gate fails, warnings or skips exceed the
accepted baseline, or repeated attempts cannot resolve a problem. Preserve the
evidence and ask one succinct question rather than broadening scope.
