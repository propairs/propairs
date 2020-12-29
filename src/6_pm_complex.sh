#!/usr/bin/env bash

set -ETeuo pipefail

PDBPATH=

#PMARGS="-W 100 -H 400"

### check options
usage()
{
cat << EOF
usage: $0 options <clustered>

OPTIONS:
   -h            Show this message
   -d            Data is shown in debug mode 
   -f <path>     Set filename for png output
   -r            Write rotated iamges
   -w <width>    Set width for png output
   -v <path>     Set filename for VRML output (not supported yet)
   -o <path>     Write out PDBs
   -p <path>     PDB input dir
EOF
}

declare PNGWIDTH="400"
declare PNGROTATE="False"
declare OUTPREFIX=""
declare DEBUG="False"
declare PDBOUT=""
declare HEADLESS=0
declare WRLOUT=""

while getopts “hf:w:rdo:v:p:” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         f)
             OUTPREFIX="${OPTARG}"
             ;;
         w)
             PNGWIDTH="${OPTARG}"
             ;;
         r)
             PNGROTATE="True"
             ;;
         d)
             DEBUG="True"
             ;;
         o)
             PDBOUT="${OPTARG}"
             ;;                   
         p)
             PDBPATH="${OPTARG}"
             ;;                   
         v)
             WRLOUT="${OPTARG}"
             ;;                  
     esac
done
shift $(( OPTIND-1 ))

# check args
[ -d "${PDBPATH}" ] || { printf "error: PDBPATH=\"${PDBPATH}\" (-p) \n"; exit 1; }


# run pymol in headless mode?
if [ "$PDBOUT" != "" ]; then
   HEADLESS=1
fi
if [ "$OUTPREFIX" != "" ]; then
   HEADLESS=1
fi


### check number of arguments
MIN_EXPECTED_ARGS_1=18
MIN_EXPECTED_ARGS_2=$((MIN_EXPECTED_ARGS_1 * 2 - 3))
if [ $# -ne ${MIN_EXPECTED_ARGS_1} ] && [ $# -ne ${MIN_EXPECTED_ARGS_2} ]
then
  echo "Usage: `basename $0` pB cB1 cB2 pU1 cU1 U1cof U1RotMat1 ... RotMat12 [pU2 cU2 U2cof U2RotMat1 ... U2RotMat12]"
  echo "got <"$*">"$# "$1"
  exit 1
fi
HAS_U2="False"
if [ $# -eq ${MIN_EXPECTED_ARGS_2} ]; then
   HAS_U2="True"
fi

### parse and prepare input
PB=${1}
CB1=${2}
CB2=${3}
PU1=${4}
CU1=${5}
U1COF=${6}
U1ROT1=${7}
U1ROT2=${8}
U1ROT3=${9}
U1ROT4=${10}
U1ROT5=${11}
U1ROT6=${12}
U1ROT7=${13}
U1ROT8=${14}
U1ROT9=${15}
U1ROT10=${16}
U1ROT11=${17}
U1ROT12=${18}
LISTBALL=""
LISTB1=""
LISTB2=""
LISTU1=""
while read -d ';' COFPAIR; do
  if [ "${COFPAIR}" == "" ]; then
    continue
  fi
  IFS=',' read -ra FIELDS <<< "${COFPAIR}"  
  # has match ?
  if [ "${FIELDS[1]-}" == "" ]; then
    LISTB2+=",(""'"`echo ${FIELDS[0]:0:1}`"'"`echo ${FIELDS[0]#?} | sed "s/^:\([^(]*\)(.*/:'\1'/" | tr ":" ","`")"
  elif [ "${FIELDS[0]}" != "" -a "${FIELDS[1]}" != "" ]; then
    LISTB1+=",(""'"`echo ${FIELDS[0]:0:1}`"'"`echo ${FIELDS[0]#?} | sed "s/^:\([^(]*\)(.*/:'\1'/" | tr ":" ","`")"
    LISTU1+=",(""'"`echo ${FIELDS[1]:0:1}`"'"`echo ${FIELDS[1]#?} | sed "s/^:\([^(]*\)(.*/:'\1'/" | tr ":" ","`")"
  else 
    :
  fi
  # add bound confactor - no matter what
  if [ "${FIELDS[0]}" != "" ]; then
     LISTBALL+=",(""'"`echo ${FIELDS[0]:0:1}`"'"`echo ${FIELDS[0]#?} | sed "s/^:\([^(]*\)(.*/:'\1'/" | tr ":" ","`")"
  fi
  
done < <(echo  ${U1COF})
LISTBALL="${LISTBALL#?}"
LISTB1="${LISTB1#?}"
LISTB2="${LISTB2#?}"
LISTU1="${LISTU1#?}"
LISTBALL="["${LISTBALL}"]"
LISTB1="["${LISTB1}"]"
LISTB2="["${LISTB2}"]"
LISTU1="["${LISTU1}"]"
U1ROTMATRIX="[${U1ROT1}, ${U1ROT2}, ${U1ROT3}, ${U1ROT10}, ${U1ROT4}, ${U1ROT5}, ${U1ROT6}, ${U1ROT11}, ${U1ROT7}, ${U1ROT8}, ${U1ROT9}, ${U1ROT12}, 0, 0, 0, 1]"


### read stuff for 2nd unbound, if provided
LISTU2="[]"
U2ROTMATRIX="[]"
  if [ ${HAS_U2} == "True" ]; then
  PU2=${19}
  CU2=${20}
  U2COF=${21}
  U2ROT1=${22}
  U2ROT2=${23}
  U2ROT3=${24}
  U2ROT4=${25}
  U2ROT5=${26}
  U2ROT6=${27}
  U2ROT7=${28}
  U2ROT8=${29}
  U2ROT9=${30}
  U2ROT10=${31}
  U2ROT11=${32}
  U2ROT12=${33}
  LISTB2=""
  LISTU2=""
  while read -d ';' COFPAIR; do
    if [ "${COFPAIR}" == "" ]; then
      continue
    fi
    IFS=',' read -ra FIELDS <<< "${COFPAIR}"  
    # has match ?
    if [ "${FIELDS[1]-}" == "" ]; then
      :
    elif [ "${FIELDS[0]}" != "" -a "${FIELDS[1]}" != "" ]; then
      LISTB2+=",(""'"`echo ${FIELDS[0]:0:1}`"'"`echo ${FIELDS[0]#?} | sed "s/^:\([^(]*\)(.*/:'\1'/" | tr ":" ","`")"
      LISTU2+=",(""'"`echo ${FIELDS[1]:0:1}`"'"`echo ${FIELDS[1]#?} | sed "s/^:\([^(]*\)(.*/:'\1'/" | tr ":" ","`")"
    else
      :
    fi
  done < <(echo  ${U2COF})
  LISTB2="${LISTB2#?}"
  LISTU2="${LISTU2#?}"
  LISTB2="["${LISTB2}"]"
  LISTU2="["${LISTU2}"]"
  U2ROTMATRIX="[${U2ROT1}, ${U2ROT2}, ${U2ROT3}, ${U2ROT10}, ${U2ROT4}, ${U2ROT5}, ${U2ROT6}, ${U2ROT11}, ${U2ROT7}, ${U2ROT8}, ${U2ROT9}, ${U2ROT12}, 0, 0, 0, 1]"
fi

### show stuff used by pymol
echo ${PB}     # b PDB
echo ${CB1}    # b1 chains
echo ${CB2}    # b2 chains
echo ${PU1}    # u1 PDB
echo ${PU2-}    # u2 PDB
echo ${CU1}    # u1 chains
echo ${CU2-}    # u2 chains
echo "COFAll" ${LISTBALL} # all cofactors
echo "COFB1 " ${LISTB1}   # b1 cofactors
echo "COFB2 " ${LISTB2}   # b2 cofactors
echo "COFU1 " ${LISTU1}   # u1 cofactors
echo "COFU2 " ${LISTU2}   # u2 cofactors
echo ${U1ROTMATRIX} 
echo ${U2ROTMATRIX}


### create and fill temporary script file for pymol
# TMPFILE=`mktemp`

### U1 stuff
pmscript=$(
cat << EOF

#### input
ppdbdir = "${PDBPATH}/"
ppdbidB = "${PB}"
ppdbidU1 = "${PU1}"
ppdbidU2 = "${PU2-}"
pchainsB1 = "${CB1}"
pchainsB2 = "${CB2}"
pchainsU1 = "${CU1}"
pchainsU2 = "${CU2-}"
pcofactorBa = ${LISTBALL}
pcofactorB1 = ${LISTB1}
pcofactorB2 = ${LISTB2}
pcofactorU1 = ${LISTU1}
pcofactorU2 = ${LISTU2}
pu1rot=${U1ROTMATRIX}
pu2rot=${U2ROTMATRIX}

cfgHasU2 = ${HAS_U2}
cfgCofIgnorelist = "${PPROOT}/config/cof_ignorelist.txt"
cfgCofIntThres = 5.5
cfgCofB1b2IntThres = 10.0
cfgPngPrefix = "${OUTPREFIX}"
cfgImgWidth = ${PNGWIDTH}
cfgImgRotate = ${PNGROTATE}
cfgPdbPrefix = "${PDBOUT}"
cfgVrmlPrefix = "${WRLOUT}"

bpdb="bpdb"
u1pdb="u1pdb"
u2pdb="u2pdb"


cmd.do("run ${PPROOT}/src/6_pm_complex.py")
EOF
)

### set pymol path

if [ "${PYMOLBIN-}" == "" ]; then
   PYMOLBIN=$(which pymol)
fi

### run pymol
if [ "${HEADLESS}" == "0" ]; then
  ${PYMOLBIN} -u <(echo "${pmscript}")
else
  ${PYMOLBIN} -qcu <(echo "${pmscript}")
fi





