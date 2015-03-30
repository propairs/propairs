#!/bin/bash

source ${PROPAIRSROOT}/config/columns.def


# how to handle interruptions?
trap "echo 'received trap signal'; exit" SIGHUP SIGINT SIGTERM

# check arguments
EXPECTED_ARGS=3
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: `basename $0` {INPUT} {CLUSTER} {OUTPUT}"
  exit 1
fi
INPUT=$1
CLUSTER=$2
OUTPUT=$3

# check I/O files
if [ ! -e ${INPUT} ]; then
    echo "INPUT does not exist"
    exit 1
fi
# check I/O files
if [ ! -e ${CLUSTER} ]; then
    echo "CLUSTER does not exist"
    exit 1
fi


# find cluster ids and nr of a pdb
function getClusterInfo {
   CLFILE=$1
   PDB=$2
   CB1=$3
   CB2=$4
   PDB=`echo $PDB | tr [:upper:] [:lower:]`
   #printf "______ %s %s\n" "${PDB} ${CB1} ${CB2}" >&2
   # get 1798 from "2b3t1 A B       1798 0"
   cat $CLFILE | grep "^${PDB} ${CB1} ${CB2} " | sed "s/^......[^ ]*\ [^ ]*\ *\([^ ]*\ .*\)/\1/"
}


# convert
# > 1azz1 D B 1ifg1 A  1  1.33    D    B    A    D    B 
# > 1azz1 B D       3 0
# to
# > 1azz1 D B 1ifg1 A  1  1.33    D    B    A    D    B 3 0
function merge_data() {
  INPUT=$1
  CLUSTER=$2
  OUTPUT=$3
  TMP=`mktemp`
  tail -n +2 ${INPUT} | grep -v error | awk -v seedpb=$SEEDPB -v bi1=$CBI1 -v bi2=$CBI2 '{printf "%s %s %s\n", $seedpb, $bi1, $bi2 }' | while read PB B1 B2 _; do
    if [[ "$B1" < "$B2" ]]; then
      printf "%s\n" "`getClusterInfo ${CLUSTER} $PB $B1 $B2`" >> ${TMP}
    else 
      printf "%s\n" "`getClusterInfo ${CLUSTER} $PB $B2 $B1`" >> ${TMP}
    fi
  done 
  
  paste <(tail -n +2 ${INPUT} | grep -v error) ${TMP} > ${OUTPUT}
  rm -f ${TMP}
}

merge_data ${INPUT} ${CLUSTER} ${OUTPUT}

