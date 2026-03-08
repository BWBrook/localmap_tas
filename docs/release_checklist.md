# Release checklist

This checklist must be satisfied before tagging a release.

## 1) Versioning and changelog
- [ ] `DESCRIPTION` version bumped (SemVer)
- [ ] `docs/CHANGELOG.md` updated (Keep a Changelog), with release date
- [ ] `CITATION.cff` version updated and repository URL is correct

## 2) Licensing and attribution
- [ ] LICENSE is MIT and consistent with DESCRIPTION
- [ ] README contains attribution guidance for The List / other sources (as applicable)
- [ ] Layer provenance includes attribution fields where configured

## 3) Quality gates
- [ ] `make bootstrap-qa` completed
- [ ] `make actionlint` passes
- [ ] `make lint` passes (or exceptions documented)
- [ ] `make test` passes
- [ ] `R_CONFIG_ACTIVE=demo TARGETS_PROFILE=ci Rscript -e 'targets::tar_make()'` passes
- [ ] `make check` passes (no ERRORs)

## 4) Artefact verification
- [ ] Overview map(s) generated and visually inspected
- [ ] Multi-panel figure generated and visually inspected
- [ ] Optional attribute extraction (if enabled) verified on demo or example
- [ ] Provenance outputs generated and checked for completeness

## 5) Release artefacts
- [ ] Source tarball built (`.tar.gz`)
- [ ] Example outputs packaged (e.g., `outputs/examples/` zipped)
- [ ] Release notes prepared from changelog

## 6) Tagging
- [ ] Git tag created for the version
- [ ] Working tree clean, all changes committed
