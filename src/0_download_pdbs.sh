# download PDB files and PDB bio files

_download_pdb() {
  fn_testset=${PPROOT}/testdata/pdb_DB4set.txt
  dst_dir=${pp_out_prefix}_pdb

  # already done?
  [ -d ${dst_dir} ] && { printf "using pre-downloaded PDB directory\n" | pplog 0 ; return 0; } || true

  find -type l -exec rm {} \;
  echo "PDB syncing..." | pplog 0
  if [ "$CFG_SNAPSHOT" == "latest" ]; then
    # use current PDB
    if [ "${CFG_TESTSET}" != "0" ]; then
      rsync -av --delete --progress --port=33444 \
        --include-from=${fn_testset} --include="*/" --exclude="*" \
        rsync.wwpdb.org::ftp_data/structures/divided/pdb/ ./pdb | pplog 1
    else
      rsync -av --delete --progress --port=33444 \
        rsync.wwpdb.org::ftp_data/structures/divided/pdb/ ./pdb | pplog 1
    fi
  else
    if [ "${CFG_TESTSET}" != "0" ]; then
      rsync -av --delete --progress --port=${PDBSNAP_PORT} \
        --include-from=${fn_testset} --include="*/" --exclude="*" \
        ${PDBSNAP_HOST}::${CFG_SNAPSHOT}/pub/pdb/data/structures/divided/pdb/ ./pdb | pplog 1
    else
      rsync -av --delete --progress --port=${PDBSNAP_PORT} \
        ${PDBSNAP_HOST}::${CFG_SNAPSHOT}/pub/pdb/data/structures/divided/pdb/ ./pdb | pplog 1
    fi
    printf "PDB sync fixing filenames...\n" | pplog 0
    find ./pdb -name "*.Z" | while read pdbz; do 
      ln -s ${pdbz##*/} ${pdbz/ent.Z/ent.gz}
    done
  fi
  printf "PDB sync complete (num.pdbs=%s)\n" "$(find -L ./pdb -type f -name "*.gz" | wc -l)" | pplog 0
  mv ./pdb ${dst_dir}
  [ -d ${dst_dir} ] || { printf "error: pdb directory not created\n"; exit 1; }
}

_download_pdbbio() {  
  fn_testsetbio=${PPROOT}/testdata/pdbbio_DB4set.txt
  dst_dir=${pp_out_prefix}_pdbbio

  # already done?
  [ -d ${dst_dir} ] && { printf "using pre-downloaded PDB-bio directory\n" | pplog 0 ; return 0; } || true

  find -type l -exec rm {} \;
  echo "PDB bio syncing..." | pplog 0
  if [ "$CFG_SNAPSHOT" == "latest" ]; then
    if [ "${CFG_TESTSET}" != "0" ]; then
        rsync -av --delete --progress --port=33444 \
        --include-from=${fn_testsetbio} --include="*/" --exclude="*" \
        rsync.wwpdb.org::ftp/data/biounit/coordinates/divided/ ./pdb_bio/ | pplog 1
    else
        rsync -av --delete --progress --port=33444 \
        rsync.wwpdb.org::ftp/data/biounit/coordinates/divided/ ./pdb_bio/ | pplog 1
    fi
  else 
    if [ "${CFG_TESTSET}" != "0" ]; then
        rsync -av --delete --progress --port=${PDBSNAP_PORT} \
        --include-from=${fn_testsetbio} --include="*/" --exclude="*" \
        ${PDBSNAP_HOST}::${CFG_SNAPSHOT}/pub/pdb/data/biounit/coordinates/divided/ ./pdb_bio/ | pplog 1
    else
        rsync -av --delete --progress --port=${PDBSNAP_PORT} \
        ${PDBSNAP_HOST}::${CFG_SNAPSHOT}/pub/pdb/data/biounit/coordinates/divided/ ./pdb_bio/ | pplog 1
    fi
  fi
  printf "PDB bio sync complete (num.pdbs=%s)\n" "$(find ./pdb_bio -type f -name "*.gz" | wc -l)" | pplog 0
  mv ./pdb_bio ${dst_dir}
  [ -d ${dst_dir} ] || { printf "error: pdb bio directory not created\n"; exit 1; }
}

download_pdbs() {
  PDBSNAP_HOST=snapshotrsync.rcsb.org
  PDBSNAP_PORT=8730
  # PDBSNAP_HOST=pdbjsnap.protein.osaka-u.ac.jp
  # PDBSNAP_PORT=873
  mkdir -p ${pp_tmp_prefix}
  cd ${pp_tmp_prefix}
  _download_pdb
  _download_pdbbio
}



download_pdbs

unset download_pdbs
unset _get_dir_hash
unset _download_pdb
unset _download_pdbbio
