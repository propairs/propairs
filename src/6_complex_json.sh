source ${PPROOT}/src/6_helpers.sh

_cofdetailB() {
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
      if [ "${FIELDS[0]}" != "" -a "${FIELDS[1]-}" != "" ]; then
         #LISTB1+="\""`echo ${FIELDS[0]#?} | sed "s/^[^(]*(\(.*\))/\1/"`"\","
         IFS=' ' read -ra BCOF <<< $(echo "${FIELDS[0]}" | tr ":" " " | tr "(" " " | tr ")" " ")
         LISTB1+=" \"${BCOF[2]} (${BCOF[0]}:${BCOF[1]})\","
      fi
   done < <(echo  $1)
   # format as json array
   LISTB1="${LISTB1%?}"
   printf "[%s]" "$LISTB1"
}

#-------------------------------------------------------------------------------

# unbound cofactors
_cofdetailB2() {
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
      if [ "${FIELDS[0]}" != "" -a "${FIELDS[1]-}" == "" ]; then
         #LISTB1+="\""`echo ${FIELDS[0]#?} | sed "s/^[^(]*(\(.*\))/\1/"`"\","
         IFS=' ' read -ra BCOF <<< $(echo "${FIELDS[0]}" | tr ":" " " | tr "(" " " | tr ")" " ")
         LISTB1+=" \"${BCOF[2]} (${BCOF[0]}:${BCOF[1]})\","
      fi
   done < <(echo  $1)
   # format as json array
   LISTB1="${LISTB1%?}"
   printf "[%s]" "$LISTB1"
}

#-------------------------------------------------------------------------------

_cofdetailI() {
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

#-------------------------------------------------------------------------------

_cofdetailU() {
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
      if [ "${FIELDS[0]}" != "" -a "${FIELDS[1]-}" != "" ]; then
         #LISTB1+="\""`echo ${FIELDS[0]#?} | sed "s/^[^(]*(\(.*\))/\1/"`"\","
         IFS=' ' read -ra BCOF <<< $(echo "${FIELDS[1]}" | tr ":" " " | tr "(" " " | tr ")" " ")
         LISTB1+=" \"${BCOF[2]} (${BCOF[0]}:${BCOF[1]})\","
      fi
   done < <(echo  $1)
   # format as json array
   LISTB1="${LISTB1%?}"
   printf "[%s]" "$LISTB1"
}

#-------------------------------------------------------------------------------

_writeJsonData() {
  set -ETeuo pipefail
  local INPUTCLUS=$1
  local dn_pdbs=$2
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
  read -a cols1 < <(grep "^${INDEX1} " ${INPUTCLUS} | head -n 1 )
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
  RB1COFD="`_cofdetailB ${RB1COF}`"
  RB2COFD="`_cofdetailB2 ${RB1COF}`"
  RU1P=${cols1[$SEEDPU-1]}
  RU1C=${cols1[$CU1-1]}
  RU1CI=${RU1C:0:${#RBIC1}}
  RU1COF=${cols1[$COF-1]}
  RU1IGAPS=${cols1[$UNUMGAPS-1]}
  RU1IRMSD=${cols1[$UIRMSD-1]}
  RU1SIM=${cols1[$UALIGNEDIRATIO-1]}
  RCLUSID=${cols1[$CLUSID-1]}
  if [ "$INDEX2" != "" ]; then
    read -a cols2 < <(grep "^${INDEX2} " ${INPUTCLUS} | head -n 1 )
    RBC2=${cols2[$CB1-1]}
    RBCI2=${cols2[$CBI1-1]}
    RB2COF=${cols2[$COF-1]}
    RU2P=${cols2[$SEEDPU-1]}
    RU2C=${cols2[$CU1-1]}
    RU2CI=${RU2C:0:${#RBIC2}}
    RU2COF=${cols2[$COF-1]}
    RB2COFD="`_cofdetailB ${RB2COF}`"
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
    \"btype\" : \"`getHeader ${RBP} ${dn_pdbs}`\",
    \"btitle\" : \"`getTitle ${RBP} ${dn_pdbs}`\",
    \"bcompound\" : \"`getCompound ${RBP} ${dn_pdbs}`\",
    \"bcof\": \"`_cofdetailI ${RB1COF} | tr -d '\"'`\",
    \"b1cof\": ${RB1COFD},
    \"b2cof\": ${RB2COFD},
    \"b1gaps\": \"$RB1GAPS\",
    \"b2gaps\": \"$RB2GAPS\",
    \"b1ca\": \"$RB1CA\",
    \"b2ca\": \"$RB2CA\",
    \"u1p\": \"$RU1P\",
    \"u1c\": \"$RU1C\",
    \"u1ci\": \"$RU1CI\",
    \"u1type\": \"`getHeader ${RU1P} ${dn_pdbs}`\",
    \"u1title\" : \"`getTitle ${RU1P} ${dn_pdbs}`\",
    \"u1compound\": \"`getCompound ${RU1P} ${dn_pdbs}`\",
    \"u1sim\" : \"${RU1SIM}\",
    \"u1irmsd\" : \"${RU1IRMSD}\",
    \"u1gaps\" : \"${RU1IGAPS}\",
    \"u1cof\" : `_cofdetailU ${RU1COF}`,
    \"u2p\": \"$RU2P\",
    \"u2c\": \"$RU2C\",
    \"u2ci\": \"$RU2CI\",
    \"u2type\": \"`getHeader ${RU2P} ${dn_pdbs}`\",
    \"u2title\" : \"`getTitle ${RU2P} ${dn_pdbs}`\",
    \"u2compound\": \"`getCompound ${RU2P} ${dn_pdbs}`\",
    \"u2sim\" : \"${RU2SIM}\",
    \"u2irmsd\" : \"${RU2IRMSD}\",
    \"u2gaps\" : \"${RU2IGAPS}\",
    \"u2cof\" : `_cofdetailU ${RU2COF}`,
    \"hasu2\" : \"${RHASU2}\",
    \"cluster\" : \"TODO\",
"
    #\"cluster\" : \"`${PROPAIRSROOT}/bin/4mergepartners.sh -m ${RCLUSID} ${INPUTCLUS} | tr -d '"' | sed 's/$/\\\n/g' | tr -d '\n'`\",
  echo " \"aln1\" :"
  ${PPROOT}/xtal/src/xtalcompunbound/xtalcompunbound -debug=true $dn_pdbs/${cols1[$SEEDPB-1]}.pdb ${cols1[$SEEDCB1-1]} ${cols1[$SEEDCB2-1]} $dn_pdbs/${cols1[$SEEDPU-1]}.pdb ${cols1[$SEEDCU1-1]} 2>&1 | grep intaln | sed "s/.*intaln//"

  if [ "$index2" != "" ]; then
    echo ",\"aln2\" :"
    ${PPROOT}/xtal/src/xtalcompunbound/xtalcompunbound -debug=true $dn_pdbs/${cols2[$SEEDPB-1]}.pdb ${cols2[$SEEDCB1-1]} ${cols2[$SEEDCB2-1]} $dn_pdbs/${cols2[$SEEDPU-1]}.pdb ${cols2[$SEEDCU1-1]} 2>&1 | grep intaln | sed "s/.*intaln//"
   fi
  echo "}"
}

#-------------------------------------------------------------------------------

write_complex_json() {
  set -ETeuo pipefail
  source ${PPROOT}/config/columns_def.sh
  local pair=$1
  local fn_in_clustered=$2
  local dn_in_pdbs=$3
  local dn_out_detail=$4
  local dn_out_pdb=$5
  IFS="_"
  read -a sidx < <(echo "$pair")
  unset IFS
  index1=${sidx[0]}
  index2=${sidx[1]-}
  echo "writing pp-complex info for $index1"
  # write json details
  _writeJsonData ${fn_in_clustered} ${dn_in_pdbs} "$index1" "$index2" > ${dn_out_detail}/complex.json
  # write pdb and images
  args=`${PPROOT}/src/6_select_aligned.sh ${fn_in_clustered} ${index1} ${index2}`
  ${PPROOT}/src/6_pm_complex.sh -p ${dn_in_pdbs} -o ${dn_out_pdb}/${index1} -w 800 -f ${dn_out_detail}/img $args
  # compress pdb files with gz
  find ${dn_out_pdb}/ -name "${index1}_*.pdb" -exec gzip {} \;
  # convert pngs to webp
  find ${dn_out_detail}/ -name 'img_*_01.png' -exec mogrify -format webp -strip -interlace Plane -quality 95  {} \;
  # create preview 
  convert -rotate -0 -resize x40 -gravity Center -crop 20x20+0+0 -strip  ${dn_out_detail}/img_p0011_01.png ${dn_out_detail}/preview.png
  # remove pymol png images
  find ${dn_out_detail}/ -name 'img_*_01.png' -exec rm {} \;
}