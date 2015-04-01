#!/usr/bin/env bash

usage()
{
cat << EOF
usage: $0 -i <PATH> -o <PATH> [-t <0|1>]

This script generates the ProPairs dataset

OPTIONS:
   -h           show this message
   -i <PATH>    path to directoy containing this script
   -o <PATH>    path to output directory
   -t <0|1>     0: full search; 1: test search (default)
EOF
exit 1;
}


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


#-- get pdb files -----------


if [ ! -e ./pdb_done ]; then
rm -f pdb_bio_done
   if [ "${TESTSET}" != "" ]; then
      rsync -av --delete --progress --port=33444 \
      --include-from="$PROPAIRSROOT/testdata/pdb_DB4set.txt" --include="*/" --exclude="*" \
      rsync.wwpdb.org::ftp_data/structures/divided/pdb/ ./pdb && \
      touch pdb_done
   else 
      rsync -av --delete --progress --port=33444 \
      rsync.wwpdb.org::ftp_data/structures/divided/pdb/ ./pdb && \
      touch pdb_done
   fi
fi

if [ -e pdb_done -a ! -e ./pdb_bio_done ]; then
rm -f pdb_bio_merged_done
   if [ "${TESTSET}" != "" ]; then
      rsync -av --delete --progress --port=33444 \
      --include-from="$PROPAIRSROOT/testdata/pdbbio_DB4set.txt" --include="*/" --exclude="*" \
      rsync.wwpdb.org::ftp/data/biounit/coordinates/divided/ ./pdb_bio/ && \
      touch pdb_bio_done
   else
      rsync -av --delete --progress --port=33444 \
      rsync.wwpdb.org::ftp/data/biounit/coordinates/divided/ ./pdb_bio/ && \
      touch pdb_bio_done   
   fi
fi


#-- prepare pdb files -----------

if [ -e pdb_bio_done -a ! -e pdb_bio_merged_done ]; then
rm -f pdb_dst
mkdir -p pdb_bio_merged
python $PROPAIRSROOT/pdb-merge-bio/merge_bio_folder.py --numthreads ${NUMCPU} && \
touch pdb_bio_merged_done
fi

if [ -e pdb_bio_merged_done -a ! -e pdb_dst_done ]; then
mkdir -p pdb_dst
${PROPAIRSROOT}/bin/pdbbio_merge_model.sh pdb pdb_bio_merged/ pdb_dst/ && \
touch pdb_dst_done
fi

#-- generate set -----------

if [ -e pdb_dst_done ]; then
   ${PROPAIRSROOT}/bin/run_db.sh -f
fi

