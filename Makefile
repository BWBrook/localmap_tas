.PHONY: help bootstrap bootstrap-qa lint test pipeline docs check

help:
	@echo "Common tasks:"
	@echo "  make bootstrap   # restore renv and refresh package docs"
	@echo "  make bootstrap-qa # install Suggests-based QA tools in the QA cache lib"
	@echo "  make lint        # run lint checks (requires bootstrap-qa)"
	@echo "  make test        # run unit tests"
	@echo "  make pipeline    # run targets pipeline"
	@echo "  make docs        # render docs/ with Quarto"
	@echo "  make check       # run R CMD check (requires bootstrap-qa)"

bootstrap:
	@Rscript -e "if (!requireNamespace('renv', quietly=TRUE)) install.packages('renv'); renv::restore(prompt=FALSE)" \
	        -e "if (requireNamespace('devtools', quietly=TRUE)) devtools::document()"

bootstrap-qa:
	@Rscript -e "if (!requireNamespace('renv', quietly=TRUE)) install.packages('renv'); renv::restore(prompt=FALSE)" \
	        -e "source('dependencies.R'); install_project_qa_dependencies()"

lint:
	@Rscript -e "source('dependencies.R'); with_qa_library({ if (!requireNamespace('lintr', quietly=TRUE)) stop('lintr is not installed. Run make bootstrap-qa first.'); l <- lintr::lint_package(); if (length(l) > 0) { print(l); quit(status = 1) } })"

test:
	@Rscript -e "devtools::test(reporter='summary')"

pipeline:
	@Rscript -e "targets::tar_make()"

docs:
	@quarto render docs/

check:
	@Rscript -e "source('dependencies.R'); with_qa_library({ if (!requireNamespace('rcmdcheck', quietly=TRUE)) stop('rcmdcheck is not installed. Run make bootstrap-qa first.'); rcmdcheck::rcmdcheck(args = c('--no-manual'), error_on = 'warning') })"

site:
	@Rscript -e "if (requireNamespace('pkgdown', quietly=TRUE)) pkgdown::build_site(preview = FALSE) else install.packages('pkgdown'); pkgdown::build_site(preview = FALSE)"
