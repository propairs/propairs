PDBSNAP_HOST=snapshotrsync.rcsb.org
PDBSNAP_PORT=8730
PDBSNAP_HOST=pdbjsnap.protein.osaka-u.ac.jp
PDBSNAP_PORT=873

fn_testset=${PROPAIRSROOT}"/testdata/pdbbio_DB4set.txt"
out_prefix="./0a_dlpdb_"

_get_dir_hash() {
   # get ms5sum of md5sum of all files
   # TODO: WARNING might change when files have moved
   find "$1" -type f -exec md5sum {} \; | md5sum
}


# status file: "<snapshot> <testset>"
#  example: "20170101 1"
#  If status file does not match. Delete and run rsync.


_write_status() {
  echo "${SNAPSHOT} ${TESTSET}" > ${out_prefix}_status
}

_cmp_status() {
  [ -f ${out_prefix}_status ] || return 1
  status=( $( cat ${out_prefix}_status ) )
  [ "${status[0]}" == "${SNAPSHOT}" ] || return 1
  [ "${status[1]}" == "${TESTSET}" ]  || return 1
  return 0
}

download_pdbs() {
  _cmp_status && return 0 || true
  rm -rf ${out_prefix}_status
  if [ "$SNAPSHOT" == "latest" ]; then
    # use current PDB
    g_statusmessage="getting PDB files"
    echo ${g_statusmessage}"..." | pplog 0
    if [ "${TESTSET}" != "0" ]; then
        rsync -av --delete --progress --port=33444 \
        --include-from="$PROPAIRSROOT/testdata/pdb_DB4set.txt" --include="*/" --exclude="*" \
        rsync.wwpdb.org::ftp_data/structures/divided/pdb/ ./pdb | pplog 1
    else
        rsync -av --delete --progress --port=33444 \
        rsync.wwpdb.org::ftp_data/structures/divided/pdb/ ./pdb | pplog 1
    fi
    _get_dir_hash ./pdb > ./pdb.md5

    if [ "${TESTSET}" != "0" ]; then
        rsync -av --delete --progress --port=33444 \
        --include-from="$PROPAIRSROOT/testdata/pdbbio_DB4set.txt" --include="*/" --exclude="*" \
        rsync.wwpdb.org::ftp/data/biounit/coordinates/divided/ ./pdb_bio/ | pplog 1
    else
        rsync -av --delete --progress --port=33444 \
        rsync.wwpdb.org::ftp/data/biounit/coordinates/divided/ ./pdb_bio/ | pplog 1
    fi
    _get_dir_hash ./pdb_bio > ./pdb_bio.md5
  else # use PDB snapshot
    g_statusmessage="getting PDB files for snapshot ${SNAPSHOT}"
    echo ${g_statusmessage}"..." | pplog 0
    # remove any symlinks
    find -type l -exec rm {} \;
    if [ "${TESTSET}" != "0" ]; then
        rsync -av --delete --progress --port=${PDBSNAP_PORT} \
        --include-from="$PROPAIRSROOT/testdata/pdb_DB4set.txt" --include="*/" --exclude="*" \
        ${PDBSNAP_HOST}::${SNAPSHOT}/pub/pdb/data/structures/divided/pdb/ ./pdb | pplog 1
    else
        rsync -av --delete --progress --port=${PDBSNAP_PORT} \
        ${PDBSNAP_HOST}::${SNAPSHOT}/pub/pdb/data/structures/divided/pdb/ ./pdb | pplog 1
    fi
    # fix PDB filenames for old snapshots
    find pdb -name "*.Z" -exec bash -c 'ln -s -f $(pwd)/{} $(pwd)/$(echo {} | sed "s/.Z$/.gz/")' \;
    _get_dir_hash ./pdb > ./pdb.md5

    if [ "${TESTSET}" != "0" ]; then
        rsync -av --delete --progress --port=${PDBSNAP_PORT} \
        --include-from=${fn_testset} --include="*/" --exclude="*" \
        ${PDBSNAP_HOST}::${SNAPSHOT}/pub/pdb/data/biounit/coordinates/divided/ ./pdb_bio/ | pplog 1
    else
        rsync -av --delete --progress --port=${PDBSNAP_PORT} \
        ${PDBSNAP_HOST}::${SNAPSHOT}/pub/pdb/data/biounit/coordinates/divided/ ./pdb_bio/ | pplog 1
    fi
    _get_dir_hash ./pdb_bio > ./pdb_bio.md5
  fi
  _write_status
}


download_pdbs
