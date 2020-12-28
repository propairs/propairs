merge_models() (
  set -ETeuo pipefail
  
  dst_dir=${pp_out_prefix}_pdb
  # already done?
  [ -d ${dst_dir} ] && { printf "using existing, analysis-ready PDB directory\n" | pplog 0 ; return 0; } || true
  # check input
  [  ! -d "$pp_in_pdb" ] && { printf "error: pp_in_pdb\n" | pplog 0 ; return 1; }
  [  ! -d "$pp_in_pdbbio" ] && { printf "error: pp_in_pdbbio\n" | pplog 0; return 1; }
  
  mkdir -p ${pp_tmp_prefix}

  # get all current 4-letter PDB codes
  PFIX="pdb"
  SFIX=".ent.gz"

  # do we have pdbcodes?
  if [ ! -f ${pp_tmp_prefix}/pdbcodes ]; then
    printf "writing pdb codes\n" | pplog 0
    find ${pp_in_pdb} -name "${PFIX}????${SFIX}" -exec basename {} ${SFIX} \; | sed "s/^${PFIX}//" \
      > ${pp_tmp_prefix}/pdbcodes
  fi
  # make chunks
  if [ ! -f ${pp_tmp_prefix}/pdbcodes_split_done ]; then
    # todo: split into at least 4 on smaller data sets
    # chunk_size=$(( num_pdbcodes/4 < 400 ? num_pdbcodes/4 : 400 ))
    split -l 400 -d ${pp_tmp_prefix}/pdbcodes ${pp_tmp_prefix}/pdbcodes_split
    chunks=$(find ${pp_tmp_prefix} -regex ".*pdbcodes_split[^_]*" | sort )
    printf "merging pdb files with %s CPUs and %s chunks\n" $OMP_NUM_THREADS "$( echo "$chunks" | wc -l )" | pplog 0
    touch ${pp_tmp_prefix}/pdbcodes_split_done
  fi

  export PPROOT
  export pp_tmp_prefix
  export pp_in_pdb
  export pp_in_pdbbio
  make -j ${OMP_NUM_THREADS} -f ${PPROOT}/src/1_merge_models.mk | pplog 1  2>&1 | pplog 2

  mv ${pp_tmp_prefix}/pdb ${pp_out_prefix}_pdb
  rm -f ${pp_tmp_prefix}/*_done
)

merge_models
unset merge_models