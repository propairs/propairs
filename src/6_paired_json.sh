

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
   if [ "${FIELDS[0]}" != "" -a "${FIELDS[1]-}" != "" ]; then
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

function _write_json_row() {
   local INPUT=$1
   local pdbdir=$2
   local i=$3
   local INDEX1=$4
   local INDEX2=$5

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
   RBNUMS2=${cols1[$BNUMS2BONDS-1]}

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
   \"bType\" : \"`getHeader ${RBP} ${pdbdir}`\",
   \"bNumCa\" : \"${RBNUMICA}\",
   \"bNumS2\" : \"${RBNUMS2}\",
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

write_paired_json() {
  source ${PPROOT}/config/columns_def.sh
  ## write JSON table
  local fn_in_pairs=$1
  local fn_in_clustered=$2
  local dn_pdbs=$3
  printf "{\n"
  i=0;
  while read line; do
    echo "write_paired_json $i ($line)" >&2
    # split rowpair to two seedidx at ","
    read -a sidx < <(echo "$line")
    unset IFS
    index1=${sidx[0]}
    index2=${sidx[1]-}
    # write table row
    _write_json_row ${fn_in_clustered} ${dn_pdbs} $i "$index1" "$index2"
    i=$((i+1))
  done < $fn_in_pairs
  printf "}\n"
}