function _get_pdbids() {
  local QUERY=$(
  cat << EOF
.separator "," ";"
SELECT DISTINCT
  ${TNAMECON}.p
FROM 
  ${TNAMECON}
ORDER BY p;
EOF
  )
  echo "${QUERY}" | sqlite3 ${sqlite_db}
}


function find_seeds() (
  set -ETeuo pipefail

  export sqlite_db=${pp_tmp_prefix}/chaininf.db
  export TNAMECON=chaincon
  export TNAMEGRP=chaingrp
  export TNAMESIM=chainsim

  dst_fn=${pp_out_prefix}_seeds
  [ -f ${dst_fn} ] && { printf "using existing seeds\n" | pplog 0 ; return 0; } || true

  printf "calculating seeds...\n" | pplog 0

  if [ ! -e ${pp_tmp_prefix}/exp_pdbcodes ]; then
    _get_pdbids | tr ";" "\n" > ${pp_tmp_prefix}/exp_pdbcodes_tmp
    num_pdbs=$( cat ${pp_tmp_prefix}/exp_pdbcodes_tmp | wc -l )

    # split into at least 4 on smaller data sets
    chunk_size=$(( num_pdbs/4 < 100 ? num_pdbs/4+1 : 100 ))
    split -l ${chunk_size} -d ${pp_tmp_prefix}/exp_pdbcodes_tmp ${pp_tmp_prefix}/exp_split_pdbcodes
    mv ${pp_tmp_prefix}/exp_pdbcodes_tmp ${pp_tmp_prefix}/exp_pdbcodes
  fi

  chunks=$(find ${pp_tmp_prefix} -regex ".*exp_split_pdbcodes[^_]*" | sort )
  printf "calculating seeds with %s CPUs and %s chunks\n" $OMP_NUM_THREADS "$( echo "$chunks" | wc -l )" | pplog 0

  export PPROOT
  export pp_tmp_prefix
  make -j ${OMP_NUM_THREADS} -f ${PPROOT}/src/2_find_seeds.mk | pplog 1

  # merge and format table
  printf "merging seeds...\n" | pplog 0
  find ${pp_tmp_prefix} -regex ".*exp_split_seeds[^_]*" \
    | xargs cat | sort | cat -n | format_table 5 > ${pp_tmp_prefix}/exp_seeds
  mv ${pp_tmp_prefix}/exp_seeds ${dst_fn}
)


find_seeds
unset find_seeds
unset _get_pdbids