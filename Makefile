BASEDIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

BIOPYTHON_VERSION=1.65

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

.PHONY: pyenv
pyenv:
	python3 -m virtualenv env

.PHONY: pydeps
pydeps: pyenv
	bash -c "\
		source env/bin/activate \
	    && pip3 install numpy\
			&& pip3 install biopython==1.77\
	"

.PHONY: run_example
run_example: all pydeps
	mkdir -p $(BASEDIR)/ppdata
	$(BASEDIR)/bin/pp_env $(BASEDIR)/ppdata
