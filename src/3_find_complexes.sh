find_complexes() (
  set -ETeuo pipefail

  dst_file=${pp_out_prefix}_complexes
  # already done?
  [ -f ${dst_file} ] && { printf "using existing interface partitions \n" | pplog 0 ; return 0; } || true
  printf "calculating interface partitions (+unbound alignments)\n" | pplog 0              

  mkdir -p ${pp_tmp_prefix}

  export XTAL_COF_IGNORELIST=${pp_tmp_prefix}/cof_ignorelist.txt
  export XTAL_COF_GROUPS=${pp_tmp_prefix}/cof_groups.txt
  cp ${PPROOT}/config/cof_ignorelist.txt ${XTAL_COF_IGNORELIST}
  cp ${PPROOT}/config/cof_groups.txt ${XTAL_COF_GROUPS}

  # align
  {
    ${PPROOT}/xtal/src/xtalcompunbound/xtalcompunbound ${pp_in_pdb}/ ${pp_in_seeds} ${pp_tmp_prefix}/chunk_status >> ${pp_tmp_prefix}/complexes_tmp
  } 2>&1 | pplog 1

  # format output
  cat ${pp_tmp_prefix}/complexes_tmp | sort | uniq | format_table 41 > ${pp_tmp_prefix}/complexes

  num_total=$( tail -n +2 ${pp_tmp_prefix}/complexes | wc -l )
  num_valid=$( tail -n +2 ${pp_tmp_prefix}/complexes | grep -v error | wc -l ) 
  printf "found %s valid interface-unbound pairs from %s seeds\n" "$num_valid" "$num_total" | pplog 0
  mv ${pp_tmp_prefix}/complexes ${dst_file}
)


find_complexes

unset find_complexes