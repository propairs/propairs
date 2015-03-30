#!/bin/bash
# Argument = -c

source ${PROPAIRSROOT}/config/columns.def





usage()
{
cat << EOF
usage: $0 [-c] <aligned>

This script checks an "unbound aligned file" if it contains test cases.

OPTIONS:
   -h      Show this message
   -c      only collect rows from aligned matching testset
   -t      only ignore "corrected"
EOF
}

COLLECT=0
IGNOREALL=1
while getopts “hct” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         c)
             COLLECT=1
             shift
             ;;
         t)
             IGNOREALL=0
             shift
             ;;             
         ?)
             usage
             exit
             ;;
     esac
done



TESTSET=$1
ALIGNED=$2

TMPRES=`mktemp`

ERR_U1CHAINS=" error_U_chains"
ERR_BCHAINS=" error_B_chains"
ERR_B1CHAINS=" error_B1_chains"
ERR_B2CHAINS=" error_B2_chains"
ERR_BUCHAINS=" error_B&U_chains"
ERR_B1CAND=" error_B1cand"
ERR_U1CAND=" error_U1cand"
ERR_CHAINMATCH=" error_chainmatch"
ERR_SEED=" error_seed"

function is_subset {
  SET=$1
  SUB=$2
  i=0; while [ $i -lt ${#SUB} ] ; do 
    if [[ "$SET" != *${SUB:$i:1}* ]]; then
      printf "error"
      return 0
    fi
    i=$((i+1)) ; 
  done
  printf "ok"
  return 1
}


function check_chain_subsets {
  local MB1=$1
  local MCB1=$2
  local MB2=$3
  local MCB2=$4
  local MU1=$5
  local MCU1=$6
  
  local R1=`is_subset $MB1 $MCB1`
  local R2=`is_subset $MB2 $MCB2`
  local R3=`is_subset $MU1 $MCU1`
    
  ERR=0
  if [ "$R1" != "ok" ]; then ERR=$((ERR + 1)); fi
  if [ "$R2" != "ok" ]; then ERR=$((ERR + 2)); fi
  if [ "$R3" != "ok" ]; then ERR=$((ERR + 4)); fi
  
  if [ "$ERR" -eq 0 ]; then
     printf "ok"
  elif [ "$ERR" -eq 1 ]; then
     printf "${ERR_B1CHAINS}"  
  elif [ "$ERR" -eq 2 ]; then
     printf "${ERR_B2CHAINS}"  
  elif [ "$ERR" -eq 4 ]; then
     printf "${ERR_U1CHAINS}"  
  elif [ "$ERR" -eq 5 ]; then
     printf "${ERR_BCHAINS}"                 
  else
     printf "${ERR_BUCHAINS}"                    
  fi
}



function check_inc {
  MPB=$2
  MCB1=$3
  MCB2=$4
  MPU=$5
  MCU1=$6
  RES=$(tail -n +2 $1 | grep -v error | grep "${MPB}" | while read LINE; do
#    echo "$LINE" | while read LINE; do
      cols=( `echo $LINE` )
      PB=${cols[$SEEDPB-1]}
      PU=${cols[$SEEDPU-1]}
      B1=${cols[$CB1-1]}
      B2=${cols[$CB2X-1]}
      U1=${cols[$CU1-1]}
      if [ "$MPB" != "${PB:0:4}" ]; then 
        continue;  
      fi    
      if [ "$MPU" != "${PU:0:4}" ]; then 
        continue;  
      fi  
      RES=`check_chain_subsets $B1 $MCB1 $B2 $MCB2  $U1 $MCU1`     
      if [ "$COLLECT" == 1 ]; then
         if [ "${RES}" == "ok" ]; then
            printf "%s %s\n" "$LINE" "$B1 $MCB1 $B2 $MCB2  $U1 $MCU1"
         fi
      else
         printf "%s(%s)\n" "$RES" "${cols[$SEEDIDX-1]}" #"$LINE"
      fi
 #   done;   
  done)
  
  if [ "$COLLECT" == 1 ]; then
     if [ `printf "%s\n" "$RES" | grep -v error | wc -w` -gt 0 ]; then
        printf "%s\n" "`echo "$RES" | grep -v error`"
     fi
     return
  fi
  
  # see if RES contains good results
  if [ `printf "%s\n" "$RES" | grep -v error | wc -w` -gt 0 ]; then 
      # filter out errors - only use first line
      RES=`printf "%s\n" "$RES" | grep -v error | head -n 1`; 
  elif [ `printf "%s\n" "$RES" | grep "${ERR_U1CHAINS}" | wc -w` -gt 0 ]; then 
      # only use first line
      RES=`printf "%s\n" "$RES" | grep "${ERR_U1CHAINS}" | head -n 1`; 
  elif [ `printf "%s\n" "$RES" | grep "${ERR_B1CHAINS}" | wc -w` -gt 0 ]; then 
      # only use first line
      RES=`printf "%s\n" "$RES" | grep "${ERR_B1CHAINS}" | head -n 1`; 
  elif [ `printf "%s\n" "$RES" | grep "${ERR_BUCHAINS}" | wc -w` -gt 0 ]; then 
      # use first line
      RES=`printf "%s\n" "$RES" | grep "${ERR_BUCHAINS}" | head -n 1`; 
  fi
  
  # try to find res in cand list
  if [ `printf "%s" "$RES" | wc -w` -eq 0 ]; then
      TMP=`cat $1 | grep "${MPB}.*${MPU}" | head -n 1`
      if [ `printf "%s" "$TMP" | wc -w` -gt 0 ]; then
         RES=${ERR_CHAINMATCH}"("`echo $TMP | awk '{print $1}'`")"
      fi
  fi
  
  # try to find U1 in cand list
  if [ `printf "%s" "$RES" | wc -w` -eq 0 ]; then
      TMP=`cat $1 | grep "^.*\ .*${MPU}"`
      if [ `printf "%s" "$TMP" | wc -w` -eq 0 ]; then
         RES=`printf "%s" "${ERR_U1CAND}"`
      fi
  fi 
  
  # try to find B1 in cand list
  if [ `printf "%s" "$RES" | wc -w` -eq 0 ]; then
      TMP=`cat $1 | grep "^${MPB}"`
      if [ `printf "%s" "$TMP" | wc -w` -eq 0 ]; then
         RES=`printf "%s" "${ERR_B1CAND}"`
      fi
  fi
  
  if [ `printf "%s" "$RES" | wc -w` -eq 0 ]; then
      RES=`printf "%s" "${ERR_SEED}"`
  fi
  
  printf "%s" "$RES"
}

declare FILTER="Ignore"
if [ "$IGNOREALL" == 0 ]; then
   FILTER="Ignore_corrected\|Ignore_Antibody_2"
fi


cat ${TESTSET} | sed "s/Ignore_Antibody_1/Antibody/" | grep -v ${FILTER} | sort | while read MPB MCB1 MCB2 MPU MCU1 MO; do
  #echo "   ------------"   $MPB $MCB1 $MPU $MCU1 "------------"    
  if [ "$COLLECT" == 1 ]; then
     check_inc ${ALIGNED} $MPB $MCB1 $MCB2 $MPU $MCU1 # | head -n 1
  else 
     printf "%-25s %s %-4s %-4s %s %-4s    %s\n" "`check_inc ${ALIGNED} $MPB $MCB1 $MCB2 $MPU $MCU1`" "${MPB}" "${MCB1}" "${MCB2}" "${MPU}" "${MCU1}" "${MO}"
  fi
done | tee ${TMPRES}

# summary
if [ "$COLLECT" != 1 ]; then
   printf "\n"
   printf "SUMMARY ok   : %d\n" `cat ${TMPRES} | grep "^ok" | wc -l`
   printf "SUMMARY error: %d\n" `cat ${TMPRES} | grep "error" | wc -l`
   printf "SUMMARY total: %d\n" `cat ${TMPRES} | wc -l`
fi

rm -f ${TMPRES}



