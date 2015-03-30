all: biopython
	$(MAKE) -C xtal

biopython-1.65:
	wget -O biopython.tar.gz http://biopython.org/DIST/biopython-1.65.tar.gz && \
	tar xzf biopython.tar.gz && $(RM) biopython.tar.gz

biopython: biopython-1.65
	cd biopyth* && pwd && \
	python setup.py build && \
	python setup.py install --prefix=../biopython

clean:
	$(RM) -R biopython-1.65 biopython
	$(MAKE) -C xtal clean



distclean: clean
	$(MAKE) -C xtal distclean
