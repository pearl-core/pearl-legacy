.PHONY: clean clean-test clean-pyc clean-build docs help
.DEFAULT_GOAL := help

define BROWSER_PYSCRIPT
import os, webbrowser, sys

try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

CONDA_EXE = ~/miniconda3/condabin/conda
CONDA_ENV_DIR = $(shell cat ${HOME}/.conda/environments.txt | grep envs/pearl)
CONDA_ENV_BIN = $(CONDA_ENV_DIR)/bin/wrappers/conda

PYTHON = $(CONDA_ENV_BIN)/python
PYTEST = $(PYTHON) -m pytest
PIP = $(PYTHON) -m pip

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: clean-build clean-pyc clean-test ## remove all build, test, coverage and Python artifacts

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

lint: ## check style with flake8
	flake8 src tests

test: ## run tests quickly with the default Python
	$(PYTEST)

test-all: ## run tests on every Python version with tox
	tox

coverage: ## check code coverage quickly with the default Python
	coverage run --source pearllib -m pytest
	coverage report -m
	coverage html
	$(BROWSER) htmlcov/index.html

docs: ## generate Sphinx HTML documentation, including API docs
	rm -f docs/pearl.rst
	rm -f docs/modules.rst
	sphinx-apidoc -o docs/ pearl
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(BROWSER) docs/_build/html/index.html

servedocs: docs ## compile the docs watching for changes
	watchmedo shell-command -p '*.rst' -c '$(MAKE) -C docs html' -R -D .

release: dist ## package and upload a release
	twine upload dist/*

dist: clean ## builds source and wheel package
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist

PYTHON_VERSION ?= 3.5
conda-init: ## init the environment
	rm -rf ~/miniconda3
	./integ-tests/install-conda.sh
	$(CONDA_EXE) update --yes conda
	$(CONDA_EXE) create --yes -n pearl python=$(PYTHON_VERSION)
	$(CONDA_EXE) install --yes -n pearl -c conda-forge conda-wrappers

create-wrappers: ## create wrapper executables to be accessible outside the environment activation
	$(CONDA_ENV_DIR)/bin/create-wrappers -t conda -b $(CONDA_ENV_DIR)/bin -d $(CONDA_ENV_DIR)/bin/wrappers/ --conda-env-dir $(CONDA_ENV_DIR)

init: ## installs stable dependencies
	$(PIP) install -r requirements-dev.txt

upgrade: ## upgrades all dependencies
	$(PIP) install --upgrade -r requirements-dev.in
	$(PIP) freeze >> requirements-dev.txt

install: clean ## install the package to the active Python's site-packages
	$(PIP) install -e .