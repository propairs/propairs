modules := $(modules) \
	gnuparallel

LIBVER_gnuparallel := 20200622

.PHONY: gnuparallel_download
gnuparallel_download: download/parallel-${LIBVER_gnuparallel}.tar.bz2

.PHONY: gnuparallel_build
gnuparallel_build: gnuparallel/bin/parallel

.PHONY: gnuparallel_clean
gnuparallel_clean:
	$(RM) -r gnuparallel
	$(RM) -r gnuparallel_build

.PHONY: gnuparallel_dlclean
gnuparallel_dlclean:
	$(RM) download/parallel-${LIBVER_gnuparallel}.tar.bz2

download/parallel-${LIBVER_gnuparallel}.tar.bz2:
	mkdir -p download/
	cd download && wget https://ftp.gnu.org/gnu/parallel/parallel-${LIBVER_gnuparallel}.tar.bz2

gnuparallel/bin/parallel: download/parallel-${LIBVER_gnuparallel}.tar.bz2
	mkdir -p gnuparallel_build \
		&& cd gnuparallel_build \
		&& tar xf ../download/parallel-${LIBVER_gnuparallel}.tar.bz2 \
		&& cd parallel-$(LIBVER_gnuparallel) \
		&& ./configure --prefix=$(BASEDIR)/gnuparallel
	$(MAKE) -C gnuparallel_build/parallel-$(LIBVER_gnuparallel)
	$(MAKE) -C gnuparallel_build/parallel-$(LIBVER_gnuparallel) install
	$(RM) -r gnuparallel_build
