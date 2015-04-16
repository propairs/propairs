BIOPYTHON_VERSION=1.16

all: biopython
	$(MAKE) -C xtal

biopython_src:
	wget -O biopython.tar.gz http://biopython.org/DIST/biopython-$(BIOPYTHON_VERSION).tar.gz && \
	tar xzf biopython.tar.gz && $(RM) biopython.tar.gz && mv biopython-$(BIOPYTHON_VERSION) biopython_src

biopython: biopython_src
	cd biopython_src && pwd && \
	python setup.py build && \
	python setup.py install --prefix=../biopython

clean:
	$(RM) -R biopython
	$(MAKE) -C xtal clean



distclean: clean
	$(MAKE) -C xtal distclean
	$(RM) -R biopython_src
	

