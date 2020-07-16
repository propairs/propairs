# calculating chain-similarities within and between all PDB structures

_call_xtal() {
  local -r op=$1
  dst_fn=${pp_out_prefix}_${op}
  # already done?
  [ -f ${dst_fn} ] && { printf "using existing ${op} file\n" | pplog 0 ; return 0; } || true
  { 
    ${PPROOT}/xtal/src/xtalcompseqid/xtalcompseqid \
      ${op} \
      ${pp_in_pdb} \
      ${pp_in_pdbcodes} \
      ${pp_tmp_prefix}/chunk_status_${op}.txt \
      >> ${pp_tmp_prefix}/${op}
  } 2>&1 | pplog 1
  mv ${pp_tmp_prefix}/${op} ${dst_fn}
}

calc_sim() {
  mkdir -p ${pp_tmp_prefix}
  _call_xtal grp
  _call_xtal con
  _call_xtal sim
}

calc_sim

unset calc_sim
unset _call_xtal
