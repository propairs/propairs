#!/bin/bash

source ${PROPAIRSROOT}/config/global.conf
source ${PROPAIRSROOT}/config/columns_def.sh


DEBUG=0
HEADONLY=0

INPUT=$1
INPUTCLUS=$2
OUTPUT=$3

#------------------------------------------------------------------------------

# check settings

if [ ! -e "${INPUT}" ]; then
    echo "input does not exist"
    exit 1
fi

if [ ! -e "${INPUTCLUS}" ]; then
    echo "input 3_clustered does not exist"
    exit 1
fi


if [ ! -d "${PDBDATADIR}" ]; then
    echo "PDBDATADIR ("${PDBDATADIR}") not found"
    exit 1
fi

if [ ! -d "${XTALDIR}" ]; then
    echo "XTALDIR ("${XTALDIR}") not found"
    exit 1
fi

if [ ! -e "${PYMOLBIN}" ]; then
    echo "PYMOLBIN ("${PYMOLBIN}") not found"
    exit 1
fi


#------------------------------------------------------------------------------

function parseUCofactors() {
   if [ "$1" == "-" ]; then
      printf "[\"-\"]"
      return
   fi
   LISTU1=""
   while read -d ';' COFPAIR; do
   if [ "${COFPAIR}" == "" ]; then
      continue
   fi
   IFS=',' read -ra FIELDS <<< "${COFPAIR}"
   # has match ?
   if [ "${FIELDS[0]}" != "" -a "${FIELDS[1]}" != "" ]; then
      LISTU1+="\""`echo ${FIELDS[1]#?} | sed "s/^[^(]*(\(.*\))/\1/"`"\","
   fi
   done < <(echo  $1)
   # format as json array
   BLA=`printf "%s" "$LISTU1" | tr "," "\n" | sort | uniq | tr "\n" ","`
   BLA="${BLA%?}"
   printf "[%s]" "$BLA"
}

#------------------------------------------------------------------------------

function parseBCofactors() {
   if [ "$1" == "-" ]; then
      printf "[\"-\"]"
      return
   fi
   LISTB1=""
   while read -d ';' COFPAIR; do
   if [ "${COFPAIR}" == "" ]; then
      continue
   fi
   IFS=',' read -ra FIELDS <<< "${COFPAIR}"
   # has match ?
   if [ "${FIELDS[0]}" != "" ]; then
      LISTB1+="\""`echo ${FIELDS[0]#?} | sed "s/^[^(]*(\(.*\))/\1/"`"\","
   fi
   done < <(echo  $1)
   # format as json array
   BLA=`printf "%s" "$LISTB1" | tr "," "\n" | sort | uniq | tr "\n" ","`
   BLA="${BLA%?}"
   printf "[%s]" "$BLA"
}

#------------------------------------------------------------------------------

function cofdetailB() {
   if [ "$1" == "-" ]; then
      printf "[\"-\"]"
      return
   fi
   LISTB1=""
   while read -d ';' COFPAIR; do
      if [ "${COFPAIR}" == "" ]; then
         continue
      fi
      IFS=',' read -ra FIELDS <<< "${COFPAIR}"
      # has match ?
      if [ "${FIELDS[0]}" != "" -a "${FIELDS[1]}" != "" ]; then
         #LISTB1+="\""`echo ${FIELDS[0]#?} | sed "s/^[^(]*(\(.*\))/\1/"`"\","
         IFS=' ' read -ra BCOF <<< $(echo "${FIELDS[0]}" | tr ":" " " | tr "(" " " | tr ")" " ")
         LISTB1+=" \"${BCOF[2]} (${BCOF[0]}:${BCOF[1]})\","
      fi
   done < <(echo  $1)
   # format as json array
   LISTB1="${LISTB1%?}"
   printf "[%s]" "$LISTB1"
}

# unbound cofactors
function cofdetailB2() {
   if [ "$1" == "-" ]; then
      printf "[\"-\"]"
      return
   fi
   LISTB1=""
   while read -d ';' COFPAIR; do
      if [ "${COFPAIR}" == "" ]; then
         continue
      fi
      IFS=',' read -ra FIELDS <<< "${COFPAIR}"
      # is unmatched ?
      if [ "${FIELDS[0]}" != "" -a "${FIELDS[1]}" == "" ]; then
         #LISTB1+="\""`echo ${FIELDS[0]#?} | sed "s/^[^(]*(\(.*\))/\1/"`"\","
         IFS=' ' read -ra BCOF <<< $(echo "${FIELDS[0]}" | tr ":" " " | tr "(" " " | tr ")" " ")
         LISTB1+=" \"${BCOF[2]} (${BCOF[0]}:${BCOF[1]})\","
      fi
   done < <(echo  $1)
   # format as json array
   LISTB1="${LISTB1%?}"
   printf "[%s]" "$LISTB1"
}

function cofdetailI() {
   if [ "$1" == "-" ]; then
      printf "[\"-\"]"
      return
   fi
   LISTB1=""
   while read -d ';' COFPAIR; do
      if [ "${COFPAIR}" == "" ]; then
         continue
      fi
      IFS=',' read -ra FIELDS <<< "${COFPAIR}"
      # has match ?
      if [ "${FIELDS[0]}" != "" ]; then
         #LISTB1+="\""`echo ${FIELDS[0]#?} | sed "s/^[^(]*(\(.*\))/\1/"`"\","
         IFS=' ' read -ra BCOF <<< $(echo "${FIELDS[0]}" | tr ":" " " | tr "(" " " | tr ")" " ")
         LISTB1+=" \"${BCOF[2]} (${BCOF[0]}:${BCOF[1]})\","
      fi
   done < <(echo  $1)
   # format as json array
   LISTB1="${LISTB1%?}"
   printf "%s" "$LISTB1"
}

function cofdetailU() {
   if [ "$1" == "-" ]; then
      printf "[\"-\"]"
      return
   fi
   LISTB1=""
   while read -d ';' COFPAIR; do
      if [ "${COFPAIR}" == "" ]; then
         continue
      fi
      IFS=',' read -ra FIELDS <<< "${COFPAIR}"
      # has match ?
      if [ "${FIELDS[0]}" != "" -a "${FIELDS[1]}" != "" ]; then
         #LISTB1+="\""`echo ${FIELDS[0]#?} | sed "s/^[^(]*(\(.*\))/\1/"`"\","
         IFS=' ' read -ra BCOF <<< $(echo "${FIELDS[1]}" | tr ":" " " | tr "(" " " | tr ")" " ")
         LISTB1+=" \"${BCOF[2]} (${BCOF[0]}:${BCOF[1]})\","
      fi
   done < <(echo  $1)
   # format as json array
   LISTB1="${LISTB1%?}"
   printf "[%s]" "$LISTB1"
}

#------------------------------------------------------------------------------

function getHeader() {
  if [ "$1" == "-" ]; then
    echo "-"
    return;
  fi
  head -n 1 $PDBDATADIR/$1.pdb | cut -c 11-50 | sed "s/\  */ /g" | sed "s/\"/\\\\\"/g";
}

function getTitle() {
  if [ "$1" == "-" ]; then
    echo "-"
    return;
  fi
   grep "^TITLE" $PDBDATADIR/$1.pdb | sed "s/^.\{10\}//" | tr -d "\n" | sed "s/\  */ /g" | sed "s/\"/\\\\\"/g"; printf "\n"
}

function getCompound() {
  if [ "$1" == "-" ]; then
    echo "-"
    return;
  fi
   grep "^COMPND" $PDBDATADIR/$1.pdb | sed "s/^.\{10\}//" | tr -d "\n" | sed "s/\  */ /g" | sed "s/\"/\\\\\"/g"; printf "\n"
}

#------------------------------------------------------------------------------
MAX_CHAINS_LEN1=5
MAX_CHAINS_LEN2=3
function cropstr() {
   INP="$1"
   if [ ${#INP} -gt  $MAX_CHAINS_LEN1 ]; then
      printf "%s" "${INP:0:$MAX_CHAINS_LEN2}..."
      return
   fi
   printf "%s" "$INP"
}

#------------------------------------------------------------------------------

function writeJsonRow() {
   local INPUT=$1
   local i=$2
   local INDEX1=$3
   local INDEX2=$4

   # split rowpair into two seedidx at ","

   RBP="-"
   RBC1="-"
   RBC2="-"
   RBICHAINS="-"
   RBIGAPS="-"
   RBCOF="-"
   RBNUMICA="-"

   RU1P="-"
   RU1C="-"
   RU1COF="-"
   RU1IGAPS="-"
   RU1IRMSD="-"
   RU1SIM="-"

   RU2P="-"
   RU2C="-"
   RU2COF="-"
   RU2IGAPS="-"
   RU2IRMSD="-"
   RU2SIM="-"

   read -a cols1 < <(grep "^${INDEX1} " ${INPUT} | head -n 1 )
   RBP=${cols1[$SEEDPB-1]}
   RBC1=${cols1[$CB1-1]}
   RBC2=${cols1[$CB2X-1]}
   RBICHAINS=${cols1[$BNUMICHAINS-1]}
   RBIGAPS=${cols1[$BNUMGAPS-1]}
   RBCOF=${cols1[$COF-1]}
   RBNUMICA=$(( cols1[$BNUMI1CA-1] + cols1[$BNUMI2CA-1] ))

   RU1P=${cols1[$SEEDPU-1]}
   RU1C=${cols1[$CU1-1]}
   RU1COF=${cols1[$COF-1]}
   RU1IGAPS=${cols1[$UNUMGAPS-1]}
   RU1IRMSD=${cols1[$UIRMSD-1]}
   RU1SIM=${cols1[$UALIGNEDIRATIO-1]}

   if [ "$INDEX2" != "" ]; then
   read -a cols2 < <(grep "^${INDEX2} " ${INPUT} | head -n 1 )
   RBC2=${cols2[$CB1-1]}
   RU2P=${cols2[$SEEDPU-1]}
   RU2C=${cols2[$CU1-1]}
   RU2COF=${cols2[$COF-1]}
   RU2IGAPS=${cols2[$UNUMGAPS-1]}
   RU2IRMSD=${cols2[$UIRMSD-1]}
   RU2SIM=${cols2[$UALIGNEDIRATIO-1]}
   fi


   if [ $i -gt 0 ]; then
      printf " ,\"${INDEX1}\" : "
   else
      printf "  \"${INDEX1}\" : "
   fi
echo "  {
   \"bName\" : \"$RBP $RBC1:$RBC2\",
   \"bType\" : \"`getHeader ${RBP}`\",
   \"bNumCa\" : \"${RBNUMICA}\",
   \"bCof\" : `parseBCofactors ${RBCOF}`,
   \"u1Name\" : \"${RU1P} ${RU1C}\",
   \"u1Sim\" : \"${RU1SIM}\",
   \"u1Cof\" : `parseUCofactors ${RU1COF}`,
   \"u1Rmsd\" : \"${RU1IRMSD}\",
   \"u2Name\" : \"${RU2P} ${RU2C}\",
   \"u2Sim\" : \"${RU2SIM}\",
   \"u2Cof\" : `parseUCofactors ${RU2COF}`,
   \"u2Rmsd\" : \"${RU2IRMSD}\"
  }"
}

#------------------------------------------------------------------------------

function writeJsonData() {
   local INPUT=$1
   local INPUTCLUS=$2
   local INDEX1=$3
   local INDEX2=$4

   # split rowpair to two seedidx at ","

   RBP="-"
   RBC1="-"
   RBC2="-"
   RBICHAINS="-"
   RB1GAPS="-"
   RB2GAPS="-"
   RB1COF="-"
   RB2COF="-"
   RB1COFD="-"
   RB2COFD="-"
   RB1CA="-"
   RB2CA="-"
   RBIC1="-"
   RBIC2="-"

   RU1P="-"
   RU1C="-"
   RU1CI="-"
   RU1COF="-"
   RU1IGAPS="-"
   RU1IRMSD="-"
   RU1SIM="-"

   RU2P="-"
   RU2C="-"
   RU2CI="-"
   RU2COF="-"
   RU2IGAPS="-"
   RU2IRMSD="-"
   RU2SIM="-"

   RHASU2=0
   RCLUSID=0

   read -a cols1 < <(grep "^${INDEX1} " ${INPUT} | head -n 1 )
   RBP=${cols1[$SEEDPB-1]}
   RBC1=${cols1[$CB1-1]}
   RBC2=${cols1[$CB2X-1]}
   RBIC1=${cols1[$CBI1-1]}
   RBIC2=${cols1[$CBI2-1]}
   RBICHAINS=${cols1[$BNUMICHAINS-1]}
   RBIGAPS=${cols1[$BNUMGAPS-1]}
   RB1COF=${cols1[$COF-1]}
   RB1GAPS=${cols1[$BNUMI1GAPS-1]}
   RB2GAPS=${cols1[$BNUMI2GAPS-1]}
   RB1CA=${cols1[$BNUMI1CA-1]}
   RB2CA=${cols1[$BNUMI2CA-1]}
   RB1COFD="`cofdetailB ${RB1COF}`"
   RB2COFD="`cofdetailB2 ${RB1COF}`"

   RU1P=${cols1[$SEEDPU-1]}
   RU1C=${cols1[$CU1-1]}
   RU1CI=${RU1C:0:${#RBIC1}}
   RU1COF=${cols1[$COF-1]}
   RU1IGAPS=${cols1[$UNUMGAPS-1]}
   RU1IRMSD=${cols1[$UIRMSD-1]}
   RU1SIM=${cols1[$UALIGNEDIRATIO-1]}
   RCLUSID=${cols1[$CLUSID-1]}

   if [ "$INDEX2" != "" ]; then
   read -a cols2 < <(grep "^${INDEX2} " ${INPUT} | head -n 1 )
   RBC2=${cols2[$CB1-1]}
   RBCI2=${cols2[$CBI1-1]}
   RB2COF=${cols2[$COF-1]}
   RU2P=${cols2[$SEEDPU-1]}
   RU2C=${cols2[$CU1-1]}
   RU2CI=${RU2C:0:${#RBIC2}}
   RU2COF=${cols2[$COF-1]}
   RB2COFD="`cofdetailB ${RB2COF}`"
   RU2IGAPS=${cols2[$UNUMGAPS-1]}
   RU2IRMSD=${cols2[$UIRMSD-1]}
   RU2SIM=${cols2[$UALIGNEDIRATIO-1]}
   RHASU2=1
   fi




echo "{
    \"bp\": \"$RBP\",
    \"bc\": \"$RBC1:$RBC2\",
    \"b1c\": \"$RBC1\",
    \"b2c\": \"$RBC2\",
    \"b1ci\": \"$RBIC1\",
    \"b2ci\": \"$RBIC2\",
    \"btype\" : \"`getHeader ${RBP}`\",
    \"btitle\" : \"`getTitle ${RBP}`\",
    \"bcompound\" : \"`getCompound ${RBP}`\",
    \"bcof\": \"`cofdetailI ${RB1COF} | tr -d '\"'`\",
    \"b1cof\": ${RB1COFD},
    \"b2cof\": ${RB2COFD},
    \"b1gaps\": \"$RB1GAPS\",
    \"b2gaps\": \"$RB2GAPS\",
    \"b1ca\": \"$RB1CA\",
    \"b2ca\": \"$RB2CA\",
    \"u1p\": \"$RU1P\",
    \"u1c\": \"$RU1C\",
    \"u1ci\": \"$RU1CI\",
    \"u1type\": \"`getHeader ${RU1P}`\",
    \"u1title\" : \"`getTitle ${RU1P}`\",
    \"u1compound\": \"`getCompound ${RU1P}`\",
    \"u1sim\" : \"${RU1SIM}\",
    \"u1irmsd\" : \"${RU1IRMSD}\",
    \"u1gaps\" : \"${RU1IGAPS}\",
    \"u1cof\" : `cofdetailU ${RU1COF}`,
    \"u2p\": \"$RU2P\",
    \"u2c\": \"$RU2C\",
    \"u2ci\": \"$RU2CI\",
    \"u2type\": \"`getHeader ${RU2P}`\",
    \"u2title\" : \"`getTitle ${RU2P}`\",
    \"u2compound\": \"`getCompound ${RU2P}`\",
    \"u2sim\" : \"${RU2SIM}\",
    \"u2irmsd\" : \"${RU2IRMSD}\",
    \"u2gaps\" : \"${RU2IGAPS}\",
    \"u2cof\" : `cofdetailU ${RU2COF}`,
    \"hasu2\" : \"${RHASU2}\",
    \"cluster\" : \"`${PROPAIRSROOT}/bin/4mergepartners.sh -m ${RCLUSID} ${INPUTCLUS} | tr -d '"' | sed 's/$/\\\n/g' | tr -d '\n'`\",
"
   echo " \"aln1\" :"
   ${XTALDIR}/src/xtalcompunbound/xtalcompunboun -debug=true $PDBDATADIR/${cols1[$SEEDPB-1]}.pdb ${cols1[$SEEDCB1-1]} ${cols1[$SEEDCB2-1]} $PDBDATADIR/${cols1[$SEEDPU-1]}.pdb ${cols1[$SEEDCU1-1]} 2>&1 | grep intaln | sed "s/.*intaln//"


   if [ "$INDEX2" != "" ]; then
   echo ",\"aln2\" :"
   ${XTALDIR}/src/xtalcompunbound/xtalcompunbound -debug=true $PDBDATADIR/${cols2[$SEEDPB-1]}.pdb ${cols2[$SEEDCB1-1]} ${cols2[$SEEDCB2-1]} $PDBDATADIR/${cols2[$SEEDPU-1]}.pdb ${cols2[$SEEDCU1-1]} 2>&1 | grep intaln | sed "s/.*intaln//"
   fi

echo "}"
}

#------------------------------------------------------------------------------

# get list of paired/single rows:
#
# 6477,
# 19029,19124
# 12147,
# 8923,
# 12981,13108

if [ "$HEADONLY" -eq 1 ]; then
   ROWPAIRS=`awk '
   {b=0}
   prev != "" {printf "%s,%s\n", prev, $1; prev="";b=1}
   prev == "" && b==0 {prev=$1}
   ' <(tail -n +2 $INPUT | head -n 20)`
else
   ROWPAIRS=`awk '
   {b=0}
   prev != "" {printf "%s,%s\n", prev, $1; prev="";b=1}
   prev == "" && b==0 {prev=$1}
   ' <(tail -n +2 $INPUT)`
fi

## create output directories
DSTDIR="${OUTPUT}" #/`basename "${INPUT}"`"/"
printf "creating \"%s\"\n" "${DSTDIR}"
mkdir -p ${DSTDIR}
mkdir -p ${DSTDIR}/info/
mkdir -p ${DSTDIR}/pdb/
mkdir -p ${DSTDIR}/preview/

cp ${INPUT} ${DSTDIR}/

PMARGS=""
if [ "$DEBUG" == "1" ]; then
    PMARGS=" -d "
fi

## write JSON table
OUTFILE=${DSTDIR}/merged.json
printf "{\n" > $OUTFILE
i=0;
while read ROWPAIR; do
   echo "writing row $i"
   # split rowpair to two seedidx at ","
   IFS=","
   read -a SIDX < <(echo "$ROWPAIR")
   unset IFS
   INDEX1=${SIDX[0]}
   INDEX2=${SIDX[1]}
   # write table row
   writeJsonRow ${INPUT} $i $INDEX1 $INDEX2 >> $OUTFILE
   i=$((i+1))
done < <(echo "$ROWPAIRS")
printf "}\n" >> $OUTFILE

# write detail info
i=0;
while read ROWPAIR; do
   echo "writing info $i"
   # split rowpair to two seedidx at ","
   IFS=","
   read -a SIDX < <(echo "$ROWPAIR")
   unset IFS
   INDEX1=${SIDX[0]}
   INDEX2=${SIDX[1]}

   INFODIR=${DSTDIR}/info/$INDEX1
   mkdir -p $INFODIR
   i=$((i+1))
   # write json details
   writeJsonData ${INPUT} $INPUTCLUS $INDEX1 $INDEX2 > ${INFODIR}/$INDEX1.json
   # write pdb and images
   ARGS=`${PROPAIRSROOT}/bin/select_aligned.sh ${INPUT} ${INDEX1} ${INDEX2}`
   ${PROPAIRSROOT}/bin/pm_complex.sh ${PMARGS} -o ${DSTDIR}/pdb/${INDEX1} -w 400 -r -f ${INFODIR}/img $ARGS
   # full
   (
      find ${INFODIR} -name '*.png' -exec mogrify -rotate -0 -format jpg -strip -interlace Plane -quality 60 {} \;
   )
   # full first
   (
      find ${INFODIR}/ -name '*_01.png' -exec mogrify -rotate -0 -format jpg -strip -interlace Plane -quality 95  {} \;
   )
   # preview 
   convert -rotate -0 -resize x20 -gravity Center -crop 20x20+0+0 -strip  ${INFODIR}/img_p0011_01.png ${DSTDIR}/preview/${INDEX1}.jpg
   # remove pngs
   (
      find ${INFODIR}/ -name '*.png' -exec rm {} \;
   )
done < <(echo "$ROWPAIRS")


tar czf ${DSTDIR}.tar.gz ${DSTDIR}


