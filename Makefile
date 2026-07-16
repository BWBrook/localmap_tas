RSCRIPT = Rscript

.PHONY: help bootstrap bootstrap-qa actionlint lint test pipeline docs site check

help:
	@echo "Common tasks:"
	@echo "  make bootstrap   # restore renv and refresh package docs"
	@echo "  make bootstrap-qa # install Suggests-based QA tools in the QA cache lib"
	@echo "  make actionlint  # lint GitHub Actions workflows"
	@echo "  make lint        # run lint checks (requires bootstrap-qa)"
	@echo "  make test        # run unit tests"
	@echo "  make pipeline    # run targets pipeline"
	@echo "  make docs        # render docs/ with Quarto"
	@echo "  make site        # build the pkgdown reference site"
	@echo "  make check       # run R CMD check (requires bootstrap-qa)"

bootstrap:
	@$(RSCRIPT) scripts/bootstrap.R

bootstrap-qa:
	@$(RSCRIPT) -e "source('dependencies.R'); check_system_requirements(); if (!requireNamespace('renv', quietly=TRUE)) install.packages('renv'); restore_project_library()" \
	        -e "source('dependencies.R'); install_project_qa_dependencies()"

actionlint:
	@if ! command -v actionlint >/dev/null 2>&1; then \
		echo "actionlint is not installed. Install it first, then rerun make actionlint."; \
		exit 1; \
	fi
	@actionlint .github/workflows/ci.yaml

lint:
	@$(RSCRIPT) -e "source('dependencies.R'); with_qa_library({ if (!requireNamespace('lintr', quietly=TRUE)) stop('lintr is not installed. Run make bootstrap-qa first.'); l <- lintr::lint_package(); if (length(l) > 0) { print(l); quit(status = 1) } })"

test:
	@$(RSCRIPT) -e "devtools::test(reporter='summary', stop_on_failure=TRUE)"

pipeline:
	@$(RSCRIPT) -e "targets::tar_make()"

docs:
	@quarto render docs/

check:
	@$(RSCRIPT) -e "source('dependencies.R'); with_qa_library({ if (!requireNamespace('rcmdcheck', quietly=TRUE)) stop('rcmdcheck is not installed. Run make bootstrap-qa first.'); rcmdcheck::rcmdcheck(args = c('--no-manual'), error_on = 'warning') })"

site:
	@$(RSCRIPT) -e "if (requireNamespace('pkgdown', quietly=TRUE)) pkgdown::build_site(preview = FALSE) else install.packages('pkgdown'); pkgdown::build_site(preview = FALSE)"
