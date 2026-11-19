# AGENTS.md — localmap_tas

These instructions apply to agents working in this repository.
If a global agent policy conflicts with this file, **this file wins** for this repo.

## 1) Mission

Deliver a reproducible, publication-quality **local mapping workflow for Tasmania**:
- Users define a site (points + extent) and a set of GIS layers (LIST and others).
- The system fetches/caches layers, renders maps/panels, and (optionally) extracts site attributes.
- The workflow is automated via `{targets}` and reproducible via `renv`.

Barry resolves consequential scientific and scope decisions. The working agent handles routine architecture and implementation within the agreed requirements.

## 2) Non-negotiables

- **No silent failures.** If a layer cannot be fetched, emit a clear warning and either:
  - render a placeholder (for imagery outputs), or
  - fail with an actionable error if the output would be misleading.
- **Reproducibility first.** Changes must keep the project runnable on a clean clone.
- **Git.** Commit and push coherent work to Barry's existing remote as needed. Fetch as needed and fast-forward only a clean checkout. Preserve unrelated work.
- **Do not hand-edit `renv.lock`.** Use `renv` tooling.
- **No large data committed.** Small demo fixtures belong in `inst/extdata/`. Everything else is runtime data and must be ignored.

## 3) Required repo documents (keep updated)

- `docs/product_brief.md` — what we are building
- `docs/architecture.md` — system design
- `docs/roadmap.md` — milestones and backlog
- `docs/decisions.md` — irreversible or costly decisions
- `docs/workflow.md` — how you must work
- `docs/release_checklist.md` — pre-tag checks
- `docs/questions_for_human.md` — durable record of material questions when useful
- `docs/AGENT_NOTES.md` — map-quality findings and handoff notes
- `docs/CHANGELOG.md` — Keep a Changelog style

## 4) Working style

### 4.1 Autonomy
Raise material questions with Barry directly and continue unaffected work. Ask when missing credentials, tokens, or data block progress, an irreversible decision has unclear trade-offs, or reasonable alternatives have failed. Use `docs/questions_for_human.md` when a durable record is useful.

### 4.2 Project records
Use `docs/AGENT_NOTES.md` to record what changed, which artefacts you generated or inspected, and what remains when it helps interpretation or handoff.

If you make a major design choice, add it to `docs/decisions.md`.

### 4.3 Commit discipline
Commit frequently with Conventional Commits, prefixing automated commits with `agent:`.
Examples:
- `agent: feat(site-maps): add WMS panel workflow`
- `agent: fix(pkg): correct LICENSE and Rbuildignore`

## 5) Artefact checks

For changes that affect outputs, run the relevant pipeline targets to generate the affected map PNGs/PDFs, panel figures, extracted attribute tables, and provenance metadata. Inspect the generated maps, tables, and caches as applicable.

Check spatial validity on representative outputs.

- site points fall within the bounding box,
- graticules/scale bars are plausible,
- overlays align with basemap (no obvious offsets),
- legends are present/absent as configured.

Fix issues and recheck affected outputs. Record material findings and unresolved map-quality issues in `docs/AGENT_NOTES.md` when they help interpretation or handoff.

## 6) Quality gates you must run before requesting a PI review

At minimum, before zipping for PI review:
- `devtools::document()` (or equivalent) produces consistent `NAMESPACE` / man pages
- unit tests pass
- lint passes (or violations triaged and documented)
- demo pipeline run completes (offline-safe)
- outputs exist under `outputs/` and have been inspected

## 7) Data & secrets policy

- Keep all runtime data under `data/` or `outputs/` (already ignored).
- Do not add secrets to the repo. If credentials are needed, use environment variables and document names in `docs/workflow.md`.
- Avoid printing sensitive local paths in logs; prefer relative paths.

## 8) Immediate hygiene fixes (first milestone)

As part of MVP work, you must:
- correct the repository license to MIT (matching project preference),
- repair `.Rbuildignore` formatting,
- ensure `AGENTS.md` is tracked (remove it from `.gitignore`),
- ensure the default/demo config runs on a clean clone.
