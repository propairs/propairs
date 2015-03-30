#!/bin/bash

usage() {
   echo "Usage: `basename $0` PDB_DIR PDB_BIO_DIR OUT_DIR"
   echo "prepare PDBs for ProPairs"
}

EXPECTED_ARGS=3
if [ $# -ne $EXPECTED_ARGS ]
then
  usage
  exit 1
fi

DIRPDB="$1"
DIRPDBBIOMERGED="$2"
DIRPDBDST="$3"

FIRST_MODEL_ONLY=1

if [ ! -e "$DIRPDB" ] | [  ! -d "$DIRPDB" ]; then
   echo "error PDB_DIR"
   usage
   exit 1
fi
if [ ! -e "$DIRPDBBIOMERGED" ] | [  ! -d "$DIRPDBBIOMERGED" ]; then
   echo "error PDB_BIO_DIR"
   usage
   exit 1
fi
if [ ! -e "$DIRPDBDST" ] | [  ! -d "$DIRPDBDST" ]; then
   echo "error OUT_DIR"
   usage
   exit 1
fi



mkdir -p ${DIRPDBDST}

TMPDIR=`mktemp -d`
TMPLIST=${TMPDIR}/pdbcodes.txt


function get_model_ids_z {
   INP="$1"
   gunzip -c "$1" | grep "^MODEL" | awk '{print $2}'
}


function extract_model_only_z {
   PDB="$1"
   ID="$2"
   gunzip -c "$PDB" | awk "/ENDMDL/{flag=0}flag;/MODEL[ ]*${ID}[^0-9]/{flag=1}"
}


function extract_header_only_z {
   PDB="$1"
   gunzip -c "$PDB" | awk '/^MODEL|^ATOM/ {flag=1} !flag {print}'
}


#extract model x of pdb
function extract_model_z {
   extract_header_only_z "$1"
   extract_model_only_z "$1" "$2"
}


# convert a number to a lowercase char
function getChar {
   X=$(( $1 + 96 ))
   if [ $X -lt 97 -o $X -gt 122 ]; then
      printf "z"
   else
      printf \\$(printf '%03o' "$X")
   fi 
}


function merge_pdb5 {
   PDBCODE=$1
   MODEL=$2

   SUBDIR=`echo $PDBCODE | sed "s/^.\(..\).*/\1/g"`

   # check if pdb exists   
   PDBFILEO=${DIRPDB}/${SUBDIR}/pdb${PDBCODE}.ent.gz
   if [ ! -e ${PDBFILEO} ]; then
       return 1
   fi

   # check if merged pdb exits
   PDBFILEM=${DIRPDBBIOMERGED}/${SUBDIR}/${PDBCODE}.pdb${MODEL}
   if [ ! -e ${PDBFILEM} ]; then
       return 1
   fi

   # new name
   PDBFILED=${DIRPDBDST}/${PDBCODE}${MODEL}.pdb

   # merge pdb - header and resolution (if provided)
   gunzip -c ${PDBFILEO} | grep "^HEADER\|^REMARK   2 RESOLUTION" | sed "s/XXXX/${PDBCODE}/g" > ${PDBFILED}

   # merge pdb merged
   cat ${PDBFILEM} >> ${PDBFILED}
   
   return 0;
}


# get all current 4-letter PDB codes
PFIX="pdb"
SFIX=".ent.gz"
find ${DIRPDB} -name "${PFIX}????${SFIX}" -exec basename {} ${SFIX} \; | sed "s/^${PFIX}//" > ${TMPLIST}

# use bio PDB XXXX[0-9] if available + original PDBs header
# use PDB otherwise
while read PDBCODE; do
   # 2-letter subdir x12x
   SUBDIR=${PDBCODE:1:2}
   
   FOUND=0
   # check if biounit is available
   for BIOUNIT in 1 2 3 4 5 6 7 8 9; do 
      if [ -e ${DIRPDBBIOMERGED}/${SUBDIR}/${PDBCODE}.pdb${BIOUNIT} ]; then
         FOUND=1
         break;
      fi
   done
   
   printf "PDB %s has bio: %d" "${PDBCODE}" "${FOUND}" 
     
   if [ $FOUND -eq 1 ]; then 
      # merge bio PDB
      for BIOUNIT in 1 2 3 4 5 6 7 8 9; do 
         merge_pdb5 ${PDBCODE} ${BIOUNIT}
      done
   else  
      # use orginal PDB
      INP=${DIRPDB}/${SUBDIR}/${PFIX}${PDBCODE}${SFIX}
      MODELIDS=`get_model_ids_z "${INP}"`
      if [ `echo ${MODELIDS} | wc -w` -eq 0 ]; then
         # copy when there are no models
         gunzip -c ${INP} > ${DIRPDBDST}/${PDBCODE}0.pdb
      else
         # split up models to different files 
         for M in $MODELIDS; do
            DST=${PDBCODE}`getChar $M`.pdb
            extract_model_z $INP $M > ${DIRPDBDST}/${DST}
            if [ ${FIRST_MODEL_ONLY} -eq 1 ]; then
               break;
            fi
         done
         printf "   %d models" "`echo ${MODELIDS} | wc -w`"
      fi
   fi
   printf "\n"
done < ${TMPLIST}

rm -R ${TMPDIR}


