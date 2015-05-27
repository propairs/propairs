#!/usr/bin/env bash


usage()
{
cat << EOF
usage: $0 [-i <PATH>] -o <PATH> [-t <0|1>]

This script generates the ProPairs dataset

OPTIONS:
   -h           show this message
   -i <PATH>    path to directoy containing this script
   -o <PATH>    path to output directory
   -t <0|1>     0: full search; 1: test search (default)
EOF
exit 1;
}

error() {
   line="$1"
   message="$2"
   if [ "$message" != "" ]; then
      printf "error: %s (line %s)\n" "$message" "$line"
   elif [ "${g_message}" != "" ]; then
      printf "error while %s (line %s)\n" "${g_message}" "$line"
   else
      printf "error (line %s)\n" "$line"
   fi
   exit 1
}
trap 'error ${LINENO}' ERR
declare g_message=""



#-- parse arguments -----------

declare PPROOT=
declare OUTPUT=
declare TESTSET=1
while getopts ":t:p:o:i:" o; do
    case "${o}" in
        t)
            TESTSET=${OPTARG}
            ;;
        o)
            OUTPUT=${OPTARG}
            ;;
        i)
            PPROOT=${OPTARG}
            ;;            
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))



#-- check arguments -----------

printf "OUTPUT:       %s\n" "$OUTPUT"
printf "TESTSET:      %s\n" "$TESTSET"
printf "PPROOT:       %s\n" "$PPROOT"
printf "PROPAIRSROOT: %s\n" "$PROPAIRSROOT"

# set PROPAIRSROOT if defined by argument
if [ "${PPROOT}" != "" ]; then
   export PROPAIRSROOT=${PPROOT}
fi

# test OUTPUT directory
mkdir -p "${OUTPUT}"
if ! cd "${OUTPUT}"; then
   printf "error: unable to change directory to ${OUTPUT}.\n\n"
   usage
fi

# test PROPAIRSROOT directory
if [ ! -e "${PROPAIRSROOT}"/start.sh ]; then
   printf "error: start.sh is not found in directory PROPAIRSROOT(\"${PROPAIRSROOT}\"). Maybe the path is not absolute.\n\n"
   usage
fi



#-- set variables -----------

g_message="setting variables"
export PYTHONPATH=`find ${PROPAIRSROOT}/biopython/ -name "site-packages" -type d`

if [ ! -d "${PYTHONPATH}" ]; then
   printf "error: PYTHONPATH=$PYTHONPATH not found\n"
   printf "       Did you run make?\n"
   exit 1
fi

# TODO: merge_bio_folder.py has high memory requirements
#       if we lower them, we can use more cores per default
NUMCPU=`cat /proc/cpuinfo | grep "^processor" | wc -l`
NUMCPU=$(( NUMCPU / 4 ))
if [ $NUMCPU -lt 1 ]; then
   NUMCPU=1
fi

export PDBDATADIR=${OUTPUT}/pdb_dst/



#-- define helper functions -----------

g_message="defining helper functions"
get_dir_hash() {
   # get ms5sum of md5sum of all files
   # TODO: WARNING might change when files have moved
   find "$1" -type f -exec md5sum {} \; | md5sum
}

#-- get pdb files -----------

g_message="getting PDB files"
if [ "${TESTSET}" != "" ]; then
   rsync -av --delete --progress --port=33444 \
   --include-from="$PROPAIRSROOT/testdata/pdb_DB4set.txt" --include="*/" --exclude="*" \
   rsync.wwpdb.org::ftp_data/structures/divided/pdb/ ./pdb
else 
   rsync -av --delete --progress --port=33444 \
   rsync.wwpdb.org::ftp_data/structures/divided/pdb/ ./pdb
fi
get_dir_hash ./pdb > ./pdb.md5

if [ "${TESTSET}" != "" ]; then
   rsync -av --delete --progress --port=33444 \
   --include-from="$PROPAIRSROOT/testdata/pdbbio_DB4set.txt" --include="*/" --exclude="*" \
   rsync.wwpdb.org::ftp/data/biounit/coordinates/divided/ ./pdb_bio/
else
   rsync -av --delete --progress --port=33444 \
   rsync.wwpdb.org::ftp/data/biounit/coordinates/divided/ ./pdb_bio/
fi
get_dir_hash ./pdb_bio > ./pdb_bio.md5



#-- prepare pdb files -----------

g_message="preparing PDB files"
# check if something changed
rebuild_pdb=0
if [ ! -e ./pdb.md5_old ] || ! diff -q ./pdb.md5 ./pdb.md5_old > /dev/null ; then
   rebuild_pdb=1
fi
if [ ! -e ./pdb_bio.md5_old ] || ! diff -q ./pdb_bio.md5 ./pdb_bio.md5_old > /dev/null ; then
   rebuild_pdb=1
fi
# rebuild data, if input changed
echo "rebuild:" ${rebuild_pdb}
if [ ${rebuild_pdb} -eq 1 ]; then
   # remove old data
   rm -Rf pdb_bio_merged
   rm -Rf pdb_dst
   # create data
   mkdir -p pdb_bio_merged
   mkdir -p pdb_dst
   python $PROPAIRSROOT/pdb-merge-bio/merge_bio_folder.py --numthreads ${NUMCPU}
   ${PROPAIRSROOT}/bin/pdbbio_merge_model.sh pdb pdb_bio_merged/ pdb_dst
   # store md5sums for next call
   cp ./pdb.md5     ./pdb.md5_old
   cp ./pdb_bio.md5 ./pdb_bio.md5_old
fi 



#-- generate set -----------

declare TESTARGS=
if [ "${TESTSET}" != "" ]; then
   TESTARGS="-p test"
fi

${PROPAIRSROOT}/bin/run_db.sh -f $TESTARGS

