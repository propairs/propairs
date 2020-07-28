
if [ ! -f ${pp_out_prefix}_pdbcodes ]; then
  printf "generating PDB codes...\n" | pplog 0
  mkdir -p ${pp_tmp_prefix}
  find ${pp_in_pdb} -name '*.pdb' -exec basename {} .pdb \; | sort > ${pp_tmp_prefix}/pdbcodes
  mv ${pp_tmp_prefix}/pdbcodes ${pp_out_prefix}_pdbcodes
  printf "using %s PDB codes\n" $( cat ${pp_out_prefix}_pdbcodes | wc -l ) | pplog 0
else
  printf "using existing PDB codes (n=%s)\n" $( cat ${pp_out_prefix}_pdbcodes | wc -l ) | pplog 0
fi