# AGENTS.md — localmap_tas (Codex CLI Engineer)

This file defines how you (the Codex CLI agent) must operate **inside this repository**.
If a global agent policy conflicts with this file, **this file wins** for this repo.

## 1) Mission

Deliver a reproducible, publication-quality **local mapping workflow for Tasmania**:
- Users define a site (points + extent) and a set of GIS layers (LIST and others).
- The system fetches/caches layers, renders maps/panels, and (optionally) extracts site attributes.
- The workflow is automated via `{targets}` and reproducible via `renv`.

You own implementation. The PI (ChatGPT) owns requirements, architecture, and acceptance criteria.

## 2) Non-negotiables

- **No silent failures.** If a layer cannot be fetched, emit a clear warning and either:
  - render a placeholder (for imagery outputs), or
  - fail with an actionable error if the output would be misleading.
- **Reproducibility first.** Changes must keep the project runnable on a clean clone.
- **Local git only.** You may create local commits. Do not push/fetch/pull remotes unless explicitly approved.
- **Do not hand-edit `renv.lock`.** Use `renv` tooling.
- **No large data committed.** Small demo fixtures belong in `inst/extdata/`. Everything else is runtime data and must be ignored.

## 3) Required repo documents (keep updated)

- `docs/product_brief.md` — what we are building
- `docs/architecture.md` — system design
- `docs/roadmap.md` — milestones and backlog
- `docs/decisions.md` — irreversible or costly decisions
- `docs/workflow.md` — how you must work
- `docs/release_checklist.md` — pre-tag checks
- `docs/questions_for_human.md` — only if blocked after multiple attempts
- `docs/AGENT_NOTES.md` — running lab notebook of what changed and why
- `docs/CHANGELOG.md` — Keep a Changelog style

## 4) Working style

### 4.1 Autonomy
Default to acting without asking the human. Only escalate via `docs/questions_for_human.md` when:
- you are blocked by missing credentials / tokens / data,
- there is an irreversible fork with unclear trade-offs,
- repeated attempts fail and you have exhausted reasonable alternatives.

### 4.2 Logging discipline
For each substantial work session:
- Append a dated entry to `docs/AGENT_NOTES.md`:
  - what you changed,
  - what artefacts you generated/inspected,
  - what remains.

If you make a major design choice, add it to `docs/decisions.md`.

### 4.3 Commit discipline
Commit frequently with Conventional Commits, prefixing automated commits with `agent:`.
Examples:
- `agent: feat(site-maps): add WMS panel workflow`
- `agent: fix(pkg): correct LICENSE and Rbuildignore`

## 5) Artefact Review Cycle (mandatory)

You must treat generated artefacts (maps, tables, caches) like scientific results: inspect them, interpret them, iterate.

For every milestone and for any change that affects outputs:

1. **Build artefacts**
   - Run the relevant pipeline targets to generate:
     - map PNGs/PDFs,
     - panel figures,
     - extracted attribute tables,
     - provenance metadata.
2. **Sanity (domain checks)**
   - Confirm spatial sanity:
     - site points fall within the bounding box,
     - graticules/scale bars are plausible,
     - overlays align with basemap (no obvious offsets),
     - legends are present/absent as configured.
3. **Interpretation (write it down)**
   - Add 3–6 bullets to `docs/AGENT_NOTES.md` describing:
     - what the outputs show,
     - what looks wrong/suspicious,
     - what you will change next.
4. **Iteration**
   - Fix issues, re-run, and repeat until coherent.

“Tests pass” is not sufficient if maps are obviously wrong.

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
