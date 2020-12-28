# postprocessing of PDB bio files to obtain bio units

clean_bio() {
  set -ETeuo pipefail
  dst_dir=${pp_out_prefix}_pdbbio
  # already done?
  [ -d ${dst_dir} ] && { printf "using existing, cleaned PDB bio directory\n" | pplog 0 ; return 0; } || true

  mkdir -p ${pp_tmp_prefix}/pdb_bio_merged
  echo "cleaning bio with ${OMP_NUM_THREADS} CPUs and ${CFG_MAXMEM_KB} kB memory"
  python3 ${PPROOT}/pdb-merge-bio/merge_bio_folder.py \
    --numthreads ${OMP_NUM_THREADS} \
    --maxmem $((CFG_MAXMEM_KB / OMP_NUM_THREADS )) \
    --src ${pp_in_pdbbio} \
    --dst ${pp_tmp_prefix}/pdb_bio_merged \
    2>&1 | pplog 1

  mv ${pp_tmp_prefix}/pdb_bio_merged ${dst_dir}
  [ -d ${dst_dir} ] || { printf "error: pdb directory not created\n"; exit 1; }
}

clean_bio

unset clean_bio
