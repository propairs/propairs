BASEDIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

BIOPYTHON_VERSION=1.77

all: 3rdparty
	$(MAKE) -C xtal

.PHONY: prepare_offline
prepare_offline:
	$(MAKE) -C 3rdparty download

.PHONY: 3rdparty
3rdparty:
	$(MAKE) -C 3rdparty all

clean:
	$(MAKE) -C xtal clean

.PHONY: distclean
distclean: clean
	$(MAKE) -C xtal distclean
	$(MAKE) -C 3rdparty clean

env/bin/activate:
	pip3 install virtualenv
	python3 -m virtualenv env

.PHONY: pydeps
pydeps: env/bin/activate
	bash -c "\
		source env/bin/activate \
	    && pip3 install numpy\
			&& pip3 install biopython==$(BIOPYTHON_VERSION)\
	"

.PHONY: run_example
run_example: all pydeps
	mkdir -p $(BASEDIR)/ppdata
	$(BASEDIR)/bin/pp_env $(BASEDIR)/ppdata
