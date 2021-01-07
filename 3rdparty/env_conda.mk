MAKEFLAGS := -j 1

# BASEDIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

all: biopython imagemagick sif/pymol.sif
	

conda/bin/conda:
	mkdir -p conda_tmp 
	wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O conda_tmp/miniconda3.sh
	bash conda_tmp/miniconda3.sh -b -f -p conda
	$(RM) -r conda_tmp


.PHONY: biopython
biopython: conda/lib/python3.8/site-packages/biopython-1.77.dist-info/WHEEL

conda/lib/python3.8/site-packages/biopython-1.77.dist-info/WHEEL: | conda/bin/conda
	conda/bin/conda install -y -c anaconda biopython=1.77

.PHONY: imagemagick
imagemagick: conda/bin/magick

conda/bin/magick: | conda/bin/conda
	conda/bin/conda install -y -c conda-forge imagemagick

sif/pymol.sif:
	singularity pull --name sif/pymol.sif_tmp docker://pegi3s/pymol:2.3.0
	mv sif/pymol.sif_tmp sif/pymol.sif
