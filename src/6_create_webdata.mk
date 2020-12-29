MAKEFLAGS += --warn-undefined-variables 

xtal_cof_ignorelist := cof_ignorelist.txt
xtal_cof_groups := cof_groups.txt

# put a _ behind first element. => "234_534", "345_", ...
pairs != cat $(pp_in_paired) | sed "s/^\([0-9]\+\)\ */\1_/"
# get id for first binding partner (split each pair at "_")
pairs1 := $(foreach x,$(pairs), $(firstword $(subst _, ,$x)))

dst_complex_info := $(patsubst %,$(pp_out_prefix)/info/%,$(pairs1))
dst_complex_pdb  := $(patsubst %,$(pp_out_prefix)/info/%,$(pairs1))

all: set_plaintext $(pp_out_prefix)/propairs_set_nonredundant_paired.json $(dst_complex_info)
	

.PHONY: out_dir
out_dir:
	mkdir -p $(pp_out_prefix)/pdb
	mkdir -p $(pp_out_prefix)/info

.PHONY: tmp_dir
tmp_dir:
	mkdir -p $(pp_tmp_prefix)

$(pp_out_prefix)/info/%: $(pp_tmp_prefix)/$(xtal_cof_groups) $(pp_tmp_prefix)/$(xtal_cof_ignorelist)  | out_dir
	$(RM) -r $@_tmp
	mkdir -p $@_tmp
	XTAL_COF_GROUPS=$(pp_tmp_prefix)/$(xtal_cof_groups) \
		XTAL_COF_IGNORELIST=$(pp_tmp_prefix)/$(xtal_cof_ignorelist) \
		bash $(PPROOT)/src/6_www_helper.sh complex_json $(filter $*_%, $(pairs)) $(pp_in_clustered) $(pp_in_pdb) $@_tmp/ $(pp_out_prefix)/pdb
	mv $@_tmp $@

$(pp_tmp_prefix)/$(xtal_cof_ignorelist): | tmp_dir
	cp ${PPROOT}/config/cof_ignorelist.txt $@

$(pp_tmp_prefix)/$(xtal_cof_groups): | tmp_dir
	cp ${PPROOT}/config/cof_groups.txt $@

$(pp_out_prefix)/propairs_set_nonredundant_paired.json: | out_dir
	bash $(PPROOT)/src/6_www_helper.sh paired_json $(pp_in_paired) $(pp_in_clustered) $(pp_in_pdb) > $@_tmp
	mv $@_tmp $@

.PHONY: set_plaintext
set_plaintext: $(pp_out_prefix)/propairs_set_large_unpaired.txt.gz $(pp_out_prefix)/propairs_set_nonredundant_paired.txt.gz

$(pp_out_prefix)/propairs_set_%.txt.gz: | out_dir
	bash $(PPROOT)/src/6_www_helper.sh set_plaintext $* $(pp_in_paired) $(pp_in_clustered) $@_tmp
	mv $@_tmp $@
