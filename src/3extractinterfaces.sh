#!/bin/bash

source ${PROPAIRSROOT}/config/columns_def.sh


# how to handle interruptions?
trap "echo 'received trap signal'; exit" SIGHUP SIGINT SIGTERM

# check arguments
EXPECTED_ARGS=1
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: `basename $0` {INPUT}"
  exit 1
fi
INPUT=$1

# check I/O files
if [ ! -e ${INPUT} ]; then
    echo "input does not exist"
    exit 1
fi

# convert
# > 123 1a2k1 A D 1jb21 B  ... AB D
# to
# > 124 1a2k1 AB D
function prepare_data() {
  INPUT=$1
  TMPFILE=`mktemp`
  
    
   tail -n +2 ${INPUT} | grep -v error | awk -v seedpb=$SEEDPB -v bi1=$CBI1 -v bi2=$CBI2 '{printf "%s %s %s\n", $seedpb, $bi1, $bi2 }' | while read PB B1 B2; do
    if [[ "$B1" < "$B2" ]]; then
      printf "%s %s %s\n" $PB $B1 $B2 >> ${TMPFILE}
    else 
      printf "%s %s %s\n" $PB $B2 $B1 >> ${TMPFILE}
    fi
  done
  
  cat ${TMPFILE} | sort -u
  rm -f ${TMPFILE}
}

prepare_data ${INPUT} ${OUTPUT}

