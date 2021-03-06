#!/bin/bash
# Argument = -c

usage()
{
cat << EOF
usage: $0 options <clustered>

This script tries to find the best two unbound structures for each complex.

OPTIONS:
   -h         Show this message
   -c         ignore cofactor when pairing unbound
   -i         merge by (cluster + PDB-ID) instead of cluster
   -m <cid>   get all cluster members belonging to this clusterid
   -s         statistic how many paired unbound structures with cofactors have multiple candidates
EOF
}

declare IGNORE_COF=
declare USE_INTERFACE=
declare KEY_CLUSTID=
declare STAT_MUL_PAIRED=


while getopts “hcism:” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         c)
             IGNORE_COF=1
             ;;
         i)
             USE_INTERFACE=1
             ;;             
         m)
             KEY_CLUSTID="${OPTARG}"
             ;;
         s)
             STAT_MUL_PAIRED=1
             ;;             
         ?)
             usage
             exit
             ;;
     esac
done

shift $(( OPTIND-1 ))


#PS4='$(date "+%s.%N ($LINENO) + ")'

source ${PROPAIRSROOT}/config/columns_def.sh
source ${PROPAIRSROOT}/config/global.conf


function getU1cand {
   local LIST=$1
   local TPB=$2
   local TB1=$3
   local TB2=$4
   
#   cat $LIST | while read LINE; do
#   local cols=( `echo $LINE` )
#   if [ "${cols[$SEEDPB-1]}" = $TPB -a "${cols[$CBI1-1]}" = $TB1 -a "${cols[$CBI2-1]}" = $TB2 ]; then
#      echo "$LINE"
#   fi
#   done
   awk \
   -v seedpb=${SEEDPB} \
   -v tpb=${TPB} \
   -v cbi1=${CBI1} \
   -v tb1=${TB1} \
   -v cbi2=${CBI2} \
   -v tb2=${TB2} \
   '$seedpb==tpb&&$cbi1==tb1&&$cbi2==tb2{print $0}' "$LIST"
}


# has cofactor?
# STAT_MUL_PAIRED?
# 


NUM_MUL_PAIRED=0
rm -f /tmp/numpaired

function mergeU1U2 {
   local LU1=$1
   local LU2=$2
   
   while read LINE; do
      local cols=( `echo ${LINE}` )
      local BU1LIGS=()
      local BU1LIGA=()
      #echo ++ "${cols[$COF-1]}" 1>&2

      #for statistics
      local HAS_COF=0
      local CURR_MERGED="${cols[$CLUSID-1]}"
      local LAST_MERGED=

      IFS=';' read -ra FIELDS <<< "${cols[$COF-1]}"
      for TLIG in "${FIELDS[@]}"; do
         IFS=',' read -ra FIELDS <<< "$TLIG"
         if [ "${FIELDS[0]}" != "" ]; then
            BU1LIGS+=("${FIELDS[0]}")
            HAS_COF=1
            if [ "${FIELDS[1]}" != "" ]; then
               BU1LIGA+=("1")
            else
               BU1LIGA+=("0")            
            fi         
         fi
      done
      #for TLIG in "${BU1LIGA[@]}"; do
      #   echo .. $TLIG 1>&2
      #done
      
      while read LINEU2; do
         local cols=( `echo ${LINEU2}` )
         local BU2LIGS=()
         local BU2LIGA=()
         #echo ++ "${cols[$COF-1]}" 1>&2

         IFS=';' read -ra FIELDS <<< "${cols[$COF-1]}"
         for TLIG in "${FIELDS[@]}"; do
            IFS=',' read -ra FIELDS <<< "$TLIG"
            if [ "${FIELDS[0]}" != "" ]; then
               BU2LIGS+=("${FIELDS[0]}")
               if [ "${FIELDS[1]}" != "" ]; then
                  BU2LIGA+=("1")
               else
                  BU2LIGA+=("0")
               fi            
            fi
         done
         
         if [ ${#BU2LIGA[@]} -ne ${#BU1LIGA[@]} ]; then
            continue
         fi
         
         local count=${#BU2LIGA[@]}
         local index=0
         local FOUND=1
         while [ "$index" -lt "$count" ]; do
             #echo -e "index: $index\tvalue: ${array[$index]}"
             if [ ${BU1LIGA[$index]} -eq 1 -a ${BU2LIGA[$index]} -eq 1 ]; then
               FOUND=0
               break
             fi
             if [ ${BU1LIGA[$index]} -eq 0 -a ${BU2LIGA[$index]} -eq 0 ]; then
               FOUND=0
               break
             fi             
             let "index++"
         done
         
         if [ $FOUND -eq 1 ]; then
            if [ "${STAT_MUL_PAIRED}" == "1" ] && [ "${HAS_COF}" == "1" ]; then
               if [ "${CURR_MERGED}" != "${LAST_MERGED}" ]; then
                  # use output but wait for another match
                  LAST_MERGED=${CURR_MERGED}
                  echo "${LINE}" 
                  echo "${LINEU2}"                  
                  continue
               else 
                  # count and break
                  echo ${CURR_MERGED} >> /tmp/numpaired
                  return     
               fi
            else
               # default mode: use output -> finished for this complex
               echo "${LINE}" 
               echo "${LINEU2}"
               return
            fi
         fi
      done < <(cat $LU2)
   done < <(cat $LU1)
   
}


function getClusterCandidates() {
   local MINP="$1"
   local MCLUSID="$2"
   awk -v clusid=${CLUSID} -v clustid=${MCLUSID} '$clusid==clustid{print $0}' "${MINP}"
}

# sort bound by representativity
function sortClusterCandidates() {
   local MINP="$1"
   
   # add combined intCa and remove it later
   
   # get max interface Ca atoms
   # get complex with min interfacing chains     
   # get complex with min gaps within interface
   # get complex with min number of additional chains
   # get complex with min. distance to medoid
   
   cat ${MINP} | \
   awk -v ica1=${BNUMI1CA} -v ica2=${BNUMI2CA} '$ica2 != "" { printf "%s", $0; printf " %s\n", $ica1*$ica2; }' | \
   sort \
   -k${NUMCOLS},${NUMCOLS}rn \
   -k${BNUMICHAINS},${BNUMICHAINS}n \
   -k${BNUMGAPS},${BNUMGAPS}n \
   -k${BNUMNONICHAINS},${BNUMNONICHAINS}n \
   -k${CLUSMEDDIST},${CLUSMEDDIST}n \
   -k${SEEDPB},${SEEDPB} \
   -k${CBI1},${CBI1} \
   -k${CBI2},${CBI2} \
   | sed "s/[0-9]*$//"
}



INPUT=$1


# get cluster for given ID
if [ "${KEY_CLUSTID}" != "" ]; then
   source ${PROPAIRSROOT}/config/columns_def.sh
   source ${PROPAIRSROOT}/bin/helper.sh
   TMPFILE1=`mktemp`_tmpfile1
   TMPFILE2=`mktemp`_tmpfile2
   TMPFILE3=`mktemp`_tmpfile3
   
   head -n 1 ${INPUT} > ${TMPFILE1}
   
   # sort .. and order interface chains by alphabet
   sortClusterCandidates <(getClusterCandidates ${INPUT} ${KEY_CLUSTID} | awk -v cbi1=${CBI1} -v cbi2=${CBI2} '$cbi2>$cbi1 {t=$cbi1; $cbi1=$cbi2; $cbi2=t} {print $0}') >> ${TMPFILE1}
   
   # select relevant fields
   paste -d " " \
    <(${PROPAIRSROOT}/bin/getCol.sh -c ${SEEDPB} ${TMPFILE1}) \
    <(${PROPAIRSROOT}/bin/getCol.sh -c ${CBI1} ${TMPFILE1}) \
    <(${PROPAIRSROOT}/bin/getCol.sh -c ${CBI2} ${TMPFILE1}) \
    <(${PROPAIRSROOT}/bin/getCol.sh -c ${CLUSMEDDIST} ${TMPFILE1}) \
     | uniq | column -t > ${TMPFILE3}
   
   # add derived field
   echo "TYPE" > ${TMPFILE2}
   getHeader "`${PROPAIRSROOT}/bin/getCol.sh -c 1 ${TMPFILE3} | tail -n +2`" >> ${TMPFILE2}
     
   # put together  
   echo "COMPLEX B1 B2   MEDOID_DIST TYPE"
   paste -d " " <(tail -n +2 ${TMPFILE3}) <(tail -n +2 ${TMPFILE2}) | sort -n -k 4,4 | uniq
     
   rm -f ${TMPFILE1}
   rm -f ${TMPFILE2}
   rm -f ${TMPFILE3}
   exit 0
fi





TMPINPMERGED=`mktemp`_inpmerged
TMPINPCLUSTERS=`mktemp`_inpclusters
TMPFILE=`mktemp`_tmpfile
TMPCLUSCAND=`mktemp`_cluscand
TMPUCAND=`mktemp`_ucand
TMPU1CAND=`mktemp`_u1cand
TMPU2CAND=`mktemp`_u2cand


# use interfaces (avoids discarding redundant interfaces)
if [ "$USE_INTERFACE" == 1 ]; then
   head -n 1 $1 > ${TMPINPMERGED}
   tail -n +2 $1 | awk \
      -v seedpb=$SEEDPB \
      -v cbi1=$CBI1 \
      -v cbi2=$CBI2 \
      -v clusid=$CLUSID \
   '{$clusid=$clusid$seedpb; print $0}' | column -t >> ${TMPINPMERGED}
else 
   cp $1 ${TMPINPMERGED}
fi 




# get all cluster ids
head -n 1 ${TMPINPMERGED}
tail -n +2 ${TMPINPMERGED} | awk -v clusid=$CLUSID '{printf "%s\n", $clusid}' | sort -n | uniq > $TMPINPCLUSTERS



while read CLUSTID; do
   

   echo
   # select all members of cluster
   rm -f $TMPCOMPCAND
   rm -f $TMPUCAND
   rm -f $TMPCLUSCAND
   
#   tail -n +2 $1 | while read MLINE; do
#      cols=( `echo ${MLINE}` )
#      if [ "${cols[$CLUSID-1]}" = "$CLUSTID" ]; then
#         echo "${MLINE}" >> $TMPCLUSCAND
#      fi
#   done
   #awk -v clusid=${CLUSID} -v clustid=${CLUSTID} '$clusid==clustid{print $0}' "${TMPINPMERGED}" > $TMPCLUSCAND
   getClusterCandidates ${TMPINPMERGED} ${CLUSTID} > $TMPCLUSCAND
   
   
   # sort bound by representativity
   cp ${TMPCLUSCAND} ${TMPFILE}
   # get complex with max interfacing chains     
   # get complex with min gaps within interface
   # get complex with min number of additional chains
   # get complex with min. distance to medoid
   #cat ${TMPFILE} | sort -k${BNUMICHAINS},${BNUMICHAINS}rn -k${BNUMGAPS},${BNUMGAPS}n -k${BNUMNONICHAINS},${BNUMNONICHAINS}n -k${CLUSMEDDIST},${CLUSMEDDIST}n > $TMPCLUSCAND
   sortClusterCandidates ${TMPFILE} > $TMPCLUSCAND



   
   # sort unbound by representativity
   # get structure with min. number of chains - but fully covering B2 chains
   # get structure with min. number of gaps
   # get structure with max. interface coverage (residues)
   # get structure with min. number of additional cofactors within interface  
   # get structure with min. IRMSD
   cat $TMPCLUSCAND | sort -k${UNUMXCHAINS},${UNUMXCHAINS}n -k${UNUMGAPS},${UNUMGAPS}n -k${UALIGNEDIRATIO},${UALIGNEDIRATIO}rn -k${UNUMUNMATCHEDCOF},${UNUMUNMATCHEDCOF}n -k${UIRMSD},${UIRMSD}n > $TMPUCAND

   
   
   # try complexes until one solution is found
   FOUND=0
   LASTSEEDPB=
   LASTCBI1=
   LASTCBI2=
   while read GLINE; do
      cols=( `echo $GLINE` )
      
      rm -f ${TMPU1CAND}
      rm -f ${TMPU2CAND}
      
      # skip, if we have tried this interface before
      if [ "${cols[$SEEDPB-1]}" ==  "${LASTSEEDPB}" -a "${cols[$CBI1-1]}" ==  "${LASTCBI1}" -a "${cols[$CBI2-1]}" ==  "${LASTCBI2}" ]; then
         continue;
      fi
      LASTSEEDPB="${cols[$SEEDPB-1]}"
      LASTCBI1="${cols[$CBI1-1]}" 
      LASTCBI2="${cols[$CBI2-1]}"
      
      getU1cand $TMPUCAND ${cols[$SEEDPB-1]} ${cols[$CBI1-1]} ${cols[$CBI2-1]} > ${TMPU1CAND}
      getU1cand $TMPUCAND ${cols[$SEEDPB-1]} ${cols[$CBI2-1]} ${cols[$CBI1-1]} > ${TMPU2CAND}

      if [ `cat ${TMPU1CAND} | wc -l` -eq 0 -o `cat ${TMPU2CAND} | wc -l` -eq 0 ]; then
         continue
      fi   
      
      
      # merge
      if [ "${IGNORE_COF}" == 1 ]; then
         # cofactors fo not match, report "cof" instead of "ok" but keep everything else 
         RES="`mergeU1U2 <(head -n 1 ${TMPU1CAND}) <(head -n 1 ${TMPU2CAND})`"
         if [ `echo $RES | wc -w` -eq 0 ]; then   
            RES=`head -n 1 ${TMPU1CAND}; head -n 1 ${TMPU2CAND}`
            RES=`echo "${RES}" | sed "s/ ok  / cof /"`
         fi
      else
         RES="`mergeU1U2 ${TMPU1CAND} ${TMPU2CAND}`"
      fi
      
      
      if [ `echo $RES | wc -w` -gt 0 ]; then
         echo "$RES"
         FOUND=1
         break
      fi    
   done < <(cat $TMPCLUSCAND)
   
   # if no solution is found, use first candidate - only one unbound
   if [ ${FOUND} -eq 0 ]; then
      head -n 1 $TMPCLUSCAND
   fi
done < <(cat $TMPINPCLUSTERS)

if [ "${STAT_MUL_PAIRED}" == "1" ]; then 
   NUM_MUL_PAIRED=`cat /tmp/numpaired | wc -l`
   echo NUM_MUL_PAIRED ${NUM_MUL_PAIRED} >&2   
fi


rm -f $TMPINPCLUSTERS
rm -f $TMPCOMPCAND
rm -f $TMPUCAND
rm -f $TMPFILE
rm -f ${TMPU1CAND}
rm -f ${TMPU2CAND}
rm -f ${TMPINPMERGED}
exit


