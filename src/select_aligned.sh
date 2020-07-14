#!/bin/bash

# check arguments
EXPECTED_ARGS=2
if [ $# -lt $EXPECTED_ARGS ]
then
  echo "Usage: `basename $0` <input> <index1> [<index2>]"
  exit 1
fi

INPUTDATA=$1

INDEX1=$2
INDEX2=$3

# check I/O files
if [ ! -e ${INPUTDATA} ]; then
    echo "input does not exist"
    exit 1
fi

# read in column descriptions
read -a ROWNAMES < <(head -n 1 ${INPUTDATA})
for (( y=0; y<${#ROWNAMES[@]}; y++ )); do
    declare ${ROWNAMES[y]}=$((y+1))
done


if [ "${SEEDIDX}" == "" ]; then
  printf "error: table \"%s\" seems to me missing header line\n" ${INPUTDATA} >&2
  exit 1
fi


read -a cols1 < <(grep "^${INDEX1} " ${INPUTDATA} | head -n 1 )



# one or two indices?
if [ "${INDEX2}" == "" ]; then
echo \
${cols1[$SEEDPB-1]} \
${cols1[$CB1-1]} \
${cols1[$CB2X-1]} \
${cols1[$SEEDPU-1]} \
${cols1[$CU1-1]} \
${cols1[$COF-1]} \
${cols1[$ROT1-1]} \
${cols1[$ROT2-1]} \
${cols1[$ROT3-1]} \
${cols1[$ROT4-1]} \
${cols1[$ROT5-1]} \
${cols1[$ROT6-1]} \
${cols1[$ROT7-1]} \
${cols1[$ROT8-1]} \
${cols1[$ROT9-1]} \
${cols1[$ROT10-1]} \
${cols1[$ROT11-1]} \
${cols1[$ROT12-1]} 

else
read -a cols2 < <(grep "^${INDEX2} " ${INPUTDATA} | head -n 1 )
echo \
${cols1[$SEEDPB-1]} \
${cols1[$CB1-1]} \
${cols2[$CB1-1]} \
${cols1[$SEEDPU-1]} \
${cols1[$CU1-1]} \
${cols1[$COF-1]} \
${cols1[$ROT1-1]} \
${cols1[$ROT2-1]} \
${cols1[$ROT3-1]} \
${cols1[$ROT4-1]} \
${cols1[$ROT5-1]} \
${cols1[$ROT6-1]} \
${cols1[$ROT7-1]} \
${cols1[$ROT8-1]} \
${cols1[$ROT9-1]} \
${cols1[$ROT10-1]} \
${cols1[$ROT11-1]} \
${cols1[$ROT12-1]} \
${cols2[$SEEDPU-1]} \
${cols2[$CU1-1]} \
${cols2[$COF-1]} \
${cols2[$ROT1-1]} \
${cols2[$ROT2-1]} \
${cols2[$ROT3-1]} \
${cols2[$ROT4-1]} \
${cols2[$ROT5-1]} \
${cols2[$ROT6-1]} \
${cols2[$ROT7-1]} \
${cols2[$ROT8-1]} \
${cols2[$ROT9-1]} \
${cols2[$ROT10-1]} \
${cols2[$ROT11-1]} \
${cols2[$ROT12-1]}  
fi








