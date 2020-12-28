MAKEFLAGS += --warn-undefined-variables 

pdbcode_splits_in  = $(wildcard ${pp_tmp_prefix}/exp_split_pdbcodes*)
pdbcode_splits_out = $(subst pdbcodes,seeds,$(pdbcode_splits_in))

all: $(pdbcode_splits_out)

$(pdbcode_splits_out): ${pp_tmp_prefix}/exp_split_seeds%: ${pp_tmp_prefix}/exp_split_pdbcodes%
	bash $(PPROOT)/src/2_find_seeds_split.sh $^
