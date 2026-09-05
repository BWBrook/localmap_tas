# LocalMap Tas successor handover

Snapshot: 2026-09-05, prepared for a fresh project thread.

This is a compact bootstrap note, not a substitute for the live repository.
Start with `AGENTS.md`, inspect Git state, and prefer current code, tests, and
settings over dated plans or logs.

## Immediate state

- Repository: `/Users/bwbrook/git/localmap_tas`
- Implementation baseline before this handover commit: `main` at `c13c246`
  (`agent: feat(attributes): add buffered raster summaries`).
- Closeout published the 27 previously local commits plus this handover to
  `origin/main`, leaving the LocalMap repository clean with only `main` locally
  and remotely. Verify the live state rather than assuming this snapshot still
  holds.
- Do not fetch, pull, push, or otherwise alter the remote state without Barry's
  explicit approval. Do not discard or rewrite the 27-commit local history.
- The last approved implementation tranche is closed. The project is at a
  clean scientific decision boundary; no next feature is implicitly approved.

## What the product is

`localmap` is a Tasmania-first R package and `{targets}` workflow for ecologists
who need repeatable local spatial products. A user supplies sites, an AOI, and
selected spatial layers; the workflow produces maps and/or site-attribute
tables with provenance. It is settings-first, offline-capable, and deliberately
not a general GIS or interactive web-mapping application.

The core product promise is one legible route from settings to inspectable
outputs. Network and large-download access are explicit opt-ins. Offline
fixtures and imagery placeholders must remain visibly distinct from live data.

After `make bootstrap`, the current copyable routes are:

```sh
# Full deterministic JC demonstration.
LOCALMAP_ALLOW_NETWORK=0 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 \
  R_CONFIG_ACTIVE=jc_ci TARGETS_PROFILE=ci make pipeline

# Exact-point attributes for the 13 packaged JC sites.
LOCALMAP_ALLOW_NETWORK=0 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 \
  Rscript scripts/run_project.R settings.attributes-jc.yaml

# Continuous-raster summaries within one 100 m radius per JC site.
LOCALMAP_ALLOW_NETWORK=0 LOCALMAP_ALLOW_LARGE_DOWNLOADS=0 \
  Rscript scripts/run_project.R settings.attributes-buffered-jc.yaml
```

`settings.example.yaml` is the real-data template. It requires a user-supplied
`site.csv`; `obs.csv` and `op.csv` are optional. See `README.md` and
`docs/settings.md` for the supported interface.

## What the recent programme accomplished

1. **Made settings runs product-selective.** `products` can select
   `attributes`, `atlas`, `figure`, or `all`, and validation follows the chosen
   product. The inactive raw/input-manifest branch, its public API, the static
   output-schema-v1 machinery, and the orphan camera-panel target were removed.
   Current `{targets}` file tracking, run/layer provenance, attribution, and
   artefact review remain the evidence contract.
2. **Proved the exact-point attributes journey** (`380cad6`). The real settings
   entry point runs offline across all 13 packaged JC sites with DEM and
   TASVEG-class fixtures while excluding imagery, distances, occurrence, ALA,
   atlas, and figure work.
3. **Fixed the wide table's user contract** (`021a9ae`). The convenience CSV is
   selected-only: unselected attribute families do not appear as empty padding,
   but a selected attribute remains visible even when all of its values are
   genuinely `NA`. The canonical long Parquet contract was unchanged.
4. **Added continuous-raster buffering** (`c13c246`). One optional run-wide
   `attributes.radius_m` gives circular, overlap-area-weighted means and
   full-buffer valid-data fractions. Omitted or zero radius preserves exact
   point extraction.

## Scientific and product invariants

- Treat a buffer radius as the spatial support of a site covariate. It is not a
  camera-effort model, a GPS-error model, or a claim that deployments are
  interchangeable.
- Exact-point extraction is the default and must remain backward compatible.
- A positive radius currently supports continuous rasters only. Categorical
  rasters, vectors, and distance layers fail with actionable errors; do not
  silently coerce them into a statistic.
- Buffered means use raster-cell overlap area. Valid fraction is valid raster
  area divided by the complete circular-buffer area, so true NODATA and source
  edges reduce coverage.
- Resolve acquisition extent before extraction. Buffered runs require an
  unrotated auto AOI and raise its margin to at least `radius_m / 1000`; internal
  clipping must never masquerade as missing source coverage.
- Preserve selected missingness in the wide table while excluding unselected
  families. Keep the long table canonical and the wide table convenient.
- Analysis defaults to `EPSG:28355`; imagery defaults to `EPSG:3857`.
- Preserve explicit network gates, deterministic caching, attribution, and
  provenance. Passing tests does not replace inspecting generated spatial
  artefacts and tables.

## Evidence already obtained

- The exact offline route produced 39 unique long rows and a 13-row wide table
  with `site_id`, `lat`, `lon`, `dem`, `tasveg_class`, `rd`, and `obs`.
  An identical rerun skipped downstream work and preserved generated hashes.
- The 100 m buffered DEM route produced 26 long rows and 13 wide rows with
  `dem_mean_r100m` and `dem_valid_fraction_r100m`. An independent `terra`/`sf`
  oracle agreed at numerical precision; a synthetic edge/NODATA case gave the
  expected 0.25 coverage, and zero valid support gave `NA` mean plus zero
  coverage. Its identical rerun preserved all eight artefact hashes.
- These were offline fixture demonstrations, not validation of current live
  services or release imagery. The commands were not rerun merely to create
  this handover note.

The concise evidence ledger is at the top of `docs/AGENT_NOTES.md`; the public
contract is in `README.md`, `docs/settings.md`, and `docs/config_reference.md`.

## Where to head next

The next material question is **categorical buffering**. Barry has explicitly
endorsed buffering as useful for tree-to-tree movement and multiple cameras
representing a general site, but categorical semantics were intentionally left
for discussion before implementation.

The decision is whether a buffered categorical raster should expose a dominant
class plus its area share, the full class-area composition, or both. My
recommended starting position, not yet approved, is:

- keep full class-area proportions in the canonical long output because they
  preserve ecological heterogeneity and permit later modelling choices; and
- derive dominant class plus dominant share only as a compact convenience
  representation, without exploding the default wide table into a universal
  class catalogue.

Discuss that contract with Barry before coding. In particular, settle treatment
of NODATA, ties, class labels/codes, minimum reportable shares, and whether
fractions are relative to the full buffer or only valid categorical area.

If approved, the smallest coherent next tranche is one offline categorical
fixture through the real settings entry point, with an independent area oracle,
edge/NODATA and tie cases, provenance, selected-only output behavior, an
identical-rerun check, and direct table inspection. Do not add multiple radii,
per-layer radii, extra continuous statistics, vector summaries, distance
reinterpretation, or camera/deployment schemas unless Barry expands the scope.

## How to work here

- Use [`$twilight-laboratory`](/Users/bwbrook/.codex/skills/twilight-laboratory/SKILL.md)
  for substantive multi-stage work. Recover live state, name the scientific
  decision and gold stamp, execute routine work autonomously, and spend Barry's
  attention only at consequential scientific, scope, compute, publication, or
  authority boundaries.
- Use [`$kill-your-darlings`](/Users/bwbrook/.codex/skills/kill-your-darlings/SKILL.md)
  to keep one current end-to-end route, make every abstraction and check earn
  its maintenance cost, and remove obsolete companions when behavior is
  retired. Preserve scientific validity, reproducibility, source integrity,
  and irreversible-operation safety.
- Work directly in this repository. The old Chief of Staff, Goal Composer,
  named `cartographer` agent, mandatory goal packets, and delegate-and-stop
  cadence are historical machinery, not the current control plane.
- Use current native tools and bounded helpers only when they materially help.
  Inspect diffs, artefacts, and evidence yourself before accepting delegated or
  cached claims.
- Apply one focused review and one material repair pass, then stop when further
  work is mainly polish and cannot change the scientific or product decision.

## Stale-history warning

`docs/roadmap.md` is useful historical context but is not reconciled with the
later WP-027 closeout and August simplification. It still marks old release work
unchecked and describes output-schema machinery that has since been removed.
Do not execute its first unchecked item or resurrect deleted compatibility
surfaces unless Barry explicitly asks to revive that roadmap. Historical logs
and plans are evidence of past decisions, not standing authorization for new
work.
