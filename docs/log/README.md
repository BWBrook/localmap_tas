# WP Logs (evidence records)

This folder holds one log file per Work Package (WP). Logs are mandatory evidence for PI review.

## Naming convention

- `WP-###_YYYY-MM-DD_short-slug.md`
- Example: `WP-001_2026-01-09_logging-evidence.md`

## Required sections (minimum)

- **Summary** — what changed and why.
- **Artefacts** — files produced/inspected (paths).
- **Sanity checks** — spatial/visual checks and interpretation notes.
- **Next steps** — remaining follow-ups (if any).

## Canonical run folder

Each WP must also create a canonical run folder under:

```
outputs/canonical_runs/WP-###_YYYY-MM-DD_short-slug/
```

This folder contains the artefacts referenced in the log. It is not committed, but must be included in the PI ZIP.
