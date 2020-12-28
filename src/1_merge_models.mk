MAKEFLAGS += --warn-undefined-variables 

pdbcode_splits = $(wildcard ${pp_tmp_prefix}/pdbcodes_split*)
pdbcode_splits_done = $(patsubst %,%_done, $(pdbcode_splits))

all: $(pdbcode_splits_done)

$(pdbcode_splits_done): %_done: % | pdb_dir
	pp_in_pdbbio=$(pp_in_pdbbio) \
	pp_in_pdb=$(pp_in_pdb) \
		bash $(PPROOT)/src/1_merge_models_split.sh $^
	touch $@


.PHONY: pdb_dir
pdb_dir:
	mkdir -p ${pp_tmp_prefix}/pdb