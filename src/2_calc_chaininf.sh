# calculating chain-similarities within and between all PDB structures

_call_xtal() {
  local -r op=$1
  dst_fn=${pp_tmp_prefix}/chaininf_${op}
  # already done?
  [ -f ${dst_fn} ] && { printf "using existing ${op} file\n" | pplog 0 ; return 0; } || true
  { 
    ${PPROOT}/xtal/src/xtalcompseqid/xtalcompseqid \
      ${op} \
      ${pp_in_pdb} \
      ${pp_in_pdbcodes} \
      ${pp_tmp_prefix}/chunk_status_${op} \
      >> ${dst_fn}_tmp
  } 2>&1 | pplog 1
  mv ${dst_fn}_tmp ${dst_fn}
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