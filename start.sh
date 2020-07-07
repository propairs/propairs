#!/usr/bin/env bash

set -ETeuo pipefail

declare -r PROPAIRSROOT; PROPAIRSROOT="$( cd "$( dirname $0 )/." && pwd )"

usage()
{
cat << EOF
usage: $0 -o <PATH> [-t <0|1>]

This script generates the ProPairs dataset

OPTIONS:
   -h           show this message
   -o <PATH>    path to output directory
   -t <0|1>     0: full search; 1: test search (default)
   -v           enable debug output
   -s <DATE>    set date for PDB snapshot
   -l           get list of valid dates to be used as snapshot
EOF
exit 1;
}

# logging function - needs tailing newline!
pplog() {
   if [ $1 -le ${g_loglevel} ]; then
      IFS="\n"
      cat | while read line; do 
         echo "$(date)" "$line" | tee -a "${g_logfile}"
      done
      unset IFS
   else
      cat > /dev/null
   fi
}
declare g_loglevel=0
declare g_logfile=/tmp/log

error() {
   line="$1"
   message="$2"
   if [ "$message" != "" ]; then
      printf "error: %s (line %s)\n" "$message" "$line" | pplog 0
   elif [ "${g_statusmessage}" != "" ]; then
      printf "error while %s (line %s)\n" "${g_statusmessage}" "$line" | pplog 0
   else
      printf "error (line %s)\n" "$line" | pplog 0
   fi
   exit 1
}
trap 'error ${LINENO}' ERR
declare g_statusmessage=""

get_PDB_snapshot_list() {
   snlist="$(wget ftp://snapshots.rcsb.org/ 2>/dev/null -O - | grep -o '/snapshots.rcsb.org:21/[0-9]*/' | tr "/" " " | awk '{print $2}')"
   declare -a sna=( $snlist )
   printf "found %d snapshots:\n" ${#sna[@]}
   for i in ${!sna[@]}; do
      printf "   %2d: %s\n" $i ${sna[$i]}
   done
}

#-- parse arguments -----------

declare PPROOT=
declare OUTPUT=
declare SNAPSHOT=
declare TESTSET=1
while getopts "t:p:o:s:lv" o; do
    case "${o}" in
        t)
            TESTSET=${OPTARG}
            ;;
        o)
            OUTPUT=${OPTARG}
            ;;
        l)
            get_PDB_snapshot_list
            exit 0
            ;;
        s)
            SNAPSHOT=${OPTARG}
            ;;
        v)
            g_loglevel=1
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))



#-- check arguments -----------

: "${PROPAIRSROOT:=$PPROOT}"

pplog 1 << EOI
OUTPUT:       $OUTPUT
TESTSET:      $TESTSET
SNAPSHOT:     $SNAPSHOT
EOI

# set PROPAIRSROOT if defined by argument
export PROPAIRSROOT

# test OUTPUT directory
mkdir -p "${OUTPUT}"
if ! cd "${OUTPUT}"; then
   printf "error: unable to change directory to ${OUTPUT}.\n\n"
   usage
fi

# test PROPAIRSROOT directory
if [ ! -e "${PROPAIRSROOT}"/start.sh ]; then
   printf "error: start.sh is not found in directory PROPAIRSROOT(\"${PROPAIRSROOT}\"). Maybe the path is not absolute.\n\n"
   usage
fi

if [ "${SNAPSHOT}" != "" ]; then
   LIST="$( get_PDB_snapshot_list )"
   if ! echo "$LIST" | grep -o "${SNAPSHOT}" > /dev/null; then
      printf "error: unable to find snapshot \"${SNAPSHOT}\". Check internet connection and this list of available snapshots:\n\n"
      echo "$LIST"
      exit 1;
   fi
fi


#-- set variables -----------

g_statusmessage="setting variables"
echo ${g_statusmessage} | pplog 0
export PYTHONPATH=`find ${PROPAIRSROOT}/biopython/ -name "site-packages" -type d`

if [ ! -d "${PYTHONPATH}" ]; then
   error ${LINENO} "error: Biopython not found in PYTHONPATH=$PYTHONPATH - Did you run make?"
fi


export PDBDATADIR=${OUTPUT}/pdb_dst/



#-- define helper functions -----------

g_statusmessage="defining helper functions"
echo ${g_statusmessage} | pplog 0
get_dir_hash() {
   # get ms5sum of md5sum of all files
   # TODO: WARNING might change when files have moved
   find "$1" -type f -exec md5sum {} \; | md5sum
}



#-- get pdb files -----------
PDBSNAP_HOST=snapshotrsync.rcsb.org
PDBSNAP_PORT=8730
PDBSNAP_HOST=pdbjsnap.protein.osaka-u.ac.jp
PDBSNAP_PORT=873


if [ "$SNAPSHOT" == "" ]; then
   # use current PDB
   g_statusmessage="getting PDB files"
   echo ${g_statusmessage}"..." | pplog 0
   if [ "${TESTSET}" != "0" ]; then
      rsync -av --delete --progress --port=33444 \
      --include-from="$PROPAIRSROOT/testdata/pdb_DB4set.txt" --include="*/" --exclude="*" \
      rsync.wwpdb.org::ftp_data/structures/divided/pdb/ ./pdb | pplog 1
   else
      rsync -av --delete --progress --port=33444 \
      rsync.wwpdb.org::ftp_data/structures/divided/pdb/ ./pdb | pplog 1
   fi
   get_dir_hash ./pdb > ./pdb.md5

   if [ "${TESTSET}" != "0" ]; then
      rsync -av --delete --progress --port=33444 \
      --include-from="$PROPAIRSROOT/testdata/pdbbio_DB4set.txt" --include="*/" --exclude="*" \
      rsync.wwpdb.org::ftp/data/biounit/coordinates/divided/ ./pdb_bio/ | pplog 1
   else
      rsync -av --delete --progress --port=33444 \
      rsync.wwpdb.org::ftp/data/biounit/coordinates/divided/ ./pdb_bio/ | pplog 1
   fi
   get_dir_hash ./pdb_bio > ./pdb_bio.md5
else # use PDB snapshot
   g_statusmessage="getting PDB files for snapshot ${SNAPSHOT}"
   echo ${g_statusmessage}"..." | pplog 0
   # remove any symlinks
   find -type l -exec rm {} \;
   if [ "${TESTSET}" != "0" ]; then
      rsync -av --delete --progress --port=${PDBSNAP_PORT} \
      --include-from="$PROPAIRSROOT/testdata/pdb_DB4set.txt" --include="*/" --exclude="*" \
      ${PDBSNAP_HOST}::${SNAPSHOT}/pub/pdb/data/structures/divided/pdb/ ./pdb | pplog 1
   else
      rsync -av --delete --progress --port=${PDBSNAP_PORT} \
      ${PDBSNAP_HOST}::${SNAPSHOT}/pub/pdb/data/structures/divided/pdb/ ./pdb | pplog 1
   fi
   # fix PDB filenames for old snapshots
   find pdb -name "*.Z" -exec bash -c 'ln -s -f $(pwd)/{} $(pwd)/$(echo {} | sed "s/.Z$/.gz/")' \;
   get_dir_hash ./pdb > ./pdb.md5

   if [ "${TESTSET}" != "0" ]; then
      rsync -av --delete --progress --port=${PDBSNAP_PORT} \
      --include-from="$PROPAIRSROOT/testdata/pdbbio_DB4set.txt" --include="*/" --exclude="*" \
      ${PDBSNAP_HOST}::${SNAPSHOT}/pub/pdb/data/biounit/coordinates/divided/ ./pdb_bio/ | pplog 1
   else
      rsync -av --delete --progress --port=${PDBSNAP_PORT} \
      ${PDBSNAP_HOST}::${SNAPSHOT}/pub/pdb/data/biounit/coordinates/divided/ ./pdb_bio/ | pplog 1
   fi
   get_dir_hash ./pdb_bio > ./pdb_bio.md5
fi


#-- prepare pdb files -----------

g_statusmessage="preparing PDB files"
echo ${g_statusmessage}"..." | pplog 0
# check if something changed
rebuild_pdb=0
if [ ! -e ./pdb.md5_old ] || ! diff -q ./pdb.md5 ./pdb.md5_old > /dev/null ; then
   rebuild_pdb=1
fi
if [ ! -e ./pdb_bio.md5_old ] || ! diff -q ./pdb_bio.md5 ./pdb_bio.md5_old > /dev/null ; then
   rebuild_pdb=1
fi
# rebuild data, if input changed
if [ ${rebuild_pdb} -eq 1 ]; then
   # remove old data
   rm -Rf pdb_bio_merged
   rm -Rf pdb_dst
   # create data
   mkdir -p pdb_bio_merged
   mkdir -p pdb_dst
   # TODO: merge_bio_folder.py has high memory requirements
   #       if we lower them, we can use more cores per default
   NUMCPU=`cat /proc/cpuinfo | grep "^processor" | wc -l`
   if [ $NUMCPU -lt 1 ]; then
      NUMCPU=1
   fi
   MEMKB=$(cat /proc/meminfo | grep ^MemTotal | awk '{print $2}' )
   echo "Using ${NUMCPU} CPUs and ${MEMKB} kB memory" | pplog 0
   python $PROPAIRSROOT/pdb-merge-bio/merge_bio_folder.py --numthreads ${NUMCPU} --maxmem ${MEMKB} 2>&1 | pplog 1
   ${PROPAIRSROOT}/bin/0pdbbio_merge_model.sh pdb pdb_bio_merged/ pdb_dst | pplog 1
   # store md5sums for next call
   cp ./pdb.md5     ./pdb.md5_old
   cp ./pdb_bio.md5 ./pdb_bio.md5_old
else
   echo "   nothing changed - using previous data" | pplog 0
fi 



#-- init propairs vars -----------


g_statusmessage="initializing propairs variables"
echo ${g_statusmessage}"..." | pplog 0
declare SUFFIX=
PDBSET=
FULL=1
DATE=$(date +%y%m%d)
if [ "$SNAPSHOT" != "" ]; then
   DATE=$SNAPSHOT
fi
if [ "${TESTSET}" != "0" ]; then
	SUFFIX="test"
fi
NAME="run"${DATE}${SUFFIX}"_"
# return to initial directory
#trap "{ cd - ; exit 255; }" SIGINT
# create output dir
TMPDIR=./
TMPDIR2=./
mkdir -p ${TMPDIR2}/${NAME}/
TMPDIR2=${TMPDIR2}/${NAME}/
# define stuff
PDBDIR=${PDBDATADIR}
PREFIX=${TMPDIR}/${NAME}
g_logfile=${PREFIX}"log"
rm -f ${g_logfile}
PDBCODES=${PREFIX}"0a_pdbcodes"
TABGRPTMP=${TMPDIR2}"0b_chaingrp"
TABCONTMP=${TMPDIR2}"0c_chaincon"
TABSIMTMP=${TMPDIR2}"0d_chainsim"
TABGRP=${PREFIX}"0b_chaingrp"
TABCON=${PREFIX}"0c_chaincon"
TABSIM=${PREFIX}"0d_chainsim"
DBIMP=${PREFIX}"0e_dbimport"
CAND=${PREFIX}"1_cand"
ALIGNED=${PREFIX}"2_aligned"
CLUSTERED=${PREFIX}"3_clustered"
MERGED=${PREFIX}"4_merged"
WWWDATA=${PREFIX}"5_wwwdata"
# enable core dumps 
ulimit -c unlimited
source ${PROPAIRSROOT}/config/global.conf


#------------------------------------------------------------------------------

function formatTable {
   source ${PROPAIRSROOT}/config/columns_def.sh
   local MTABLEFILE=$1
   local MNUMCOLS=$2
   
   local MTMPFILE=`mktemp`
   cp ${MTABLEFILE} ${MTMPFILE}
   (
      echo $TABLEHEADER | awk -v numcols=${MNUMCOLS} '{ for (x=1; x<=numcols; x++) {  printf "%s ", $x }; printf "\n" }';
      cat ${MTMPFILE} | sort -n
   ) | column -t > ${MTABLEFILE}
   rm -f ${MTMPFILE}
}

#------------------------------------------------------------------------------

function 1findcandidates {
   local MOUTFILE=$1
   local MLOGFILE=$2
   local MPDBSET=$3
   local MCAND=$4   

   if [ "${MPDBSET}" != "" -a ! -e "${MPDBSET}" ]; then
      printf "file \"%s\" not found\n" "${MPDBSET}" >&2
      return 1
   fi
   # find seeds
   ${PROPAIRSROOT}/bin/1findcandidates.sh "${MPDBSET}" 2> ${MLOGFILE} | tr ':' ' '  | tr ',' ' ' | cat -n > ${MOUTFILE}
   # check for errors
   if [ $? -ne 0 ]; then
      return 1
   fi
   if [ `cat ${MOUTFILE} | wc -w` -eq 0 ]; then
      return 1
   fi
   # format output
   source ${PROPAIRSROOT}/config/columns_def.sh
   formatTable ${MOUTFILE} ${SEEDCU1}
   # print info
   printf "  %s seeds generated\n" "`tail -n +2 ${MOUTFILE} | wc -l`" | pplog 1
}

#------------------------------------------------------------------------------

function 2alignunbound {
   local MOUTFILE=$1
   local MLOGFILE=$2
   local MPDBDIR=$3
   local MCAND=$4
   
   # prepare cofactor stuff
   cp ${PROPAIRSROOT}/config/cof_ignorelist.txt /tmp/
   cp ${PROPAIRSROOT}/config/cof_groups.txt /tmp/
   
   # align
   ${XTALDIR}/src/xtalcompunbound/xtalcompunbound ${MPDBDIR} ${MCAND} 2> ${MLOGFILE} > ${MOUTFILE} || return 1
   # format output
   source ${PROPAIRSROOT}/config/columns_def.sh
   formatTable ${MOUTFILE} ${ROT12}
   # print info
   printf "   %s seeds checked\n" "`tail -n +2 ${MOUTFILE} | wc -l`" | pplog 0
   printf "   %s valid alignments\n" "`tail -n +2 ${MOUTFILE} | grep -v error | wc -l`" | pplog 0
}

#------------------------------------------------------------------------------

function 3clusterinterfaces {
   local MOUTFILE=$1
   local MLOGFILE=$2
   local MPDBDIR=$3
   local MALIGNED=$4
   
   MLOGFILEGZ=${PREFIX}"supp_3cluster_log.gz"
   
   # cluster
   ${PROPAIRSROOT}/bin/3extractinterfaces.sh ${MALIGNED} > ${MLOGFILE}_interfaces && \
   ${XTALDIR}/src/xtaluniquecomp/xtaluniquecomp ${MPDBDIR} ${MLOGFILE}_interfaces 2> ${MLOGFILE} > ${MLOGFILE}_cluster && \
   ${PROPAIRSROOT}/bin/3assignclusters.sh ${MALIGNED} ${MLOGFILE}_cluster ${MOUTFILE} > /dev/null
   if [ `cat ${MOUTFILE} | wc -w` -eq 0 ]; then
      return 1
   fi
   source ${PROPAIRSROOT}/config/columns_def.sh
   formatTable ${MOUTFILE} ${CLUSMEDDIST}
   
   # write out interface score vs. sequence ID
   cat ${MLOGFILE} | grep "^intsc" | gzip - > ${MLOGFILE}_intscore.gz
   cat ${MLOGFILE} | gzip > ${MLOGFILEGZ}
   printf "   %s unique interfaces\n" "`cat ${MLOGFILE}_interfaces | wc -l`"  | pplog 0
   printf "   %s interface clusters\n" "`cat  ${MLOGFILE}_cluster | grep "^cl cluster" | wc -l`"  | pplog 0
   printf "   %s alignments assigned to clusters\n" "`tail -n +2 ${MOUTFILE} | wc -l`"  | pplog 0
   
}

#------------------------------------------------------------------------------

function 4mergepartners {
   local MOUTFILE=$1
   local MLOGFILE=$2
   local MCLUSFILE=$3

   ${PROPAIRSROOT}/bin/4mergepartners.sh ${MCLUSFILE} > ${MOUTFILE} 2> ${MLOGFILE}
   if [ `cat ${MOUTFILE} | wc -w` -eq 0 ]; then
      return 1
   fi 
   # calc number of separators
   S=`tail -n +2  ${MOUTFILE} | grep '^$' | wc -l`
   # calc number of non-empty lines
   C=`tail -n +2  ${MOUTFILE} | grep  -v '^$' | wc -l`
   UNPAIRED=$(( S*2  - C )) 
   PAIRED=$(( S - UNPAIRED )) 
   printf "   %s complexes with one aligned unbound\n" "$UNPAIRED" | pplog 0
   printf "   %s complexes with two aligned unbound\n" "$PAIRED" | pplog 0
   # write out pairings that do not match because of cofactors
   ${PROPAIRSROOT}/bin/4mergepartners.sh -c ${MCLUSFILE} | grep -v " ok " | uniq > ${PREFIX}"supp_unmatchedCof"
}

#------------------------------------------------------------------------------

5wwwraw() {
   local setname="$1"
   local wwwname="$2"
   (
      cd www
      read -d "" html << EOI   
      <h2>Dataset - $setname</h2><ul><li><b><a href="data/data${setname}/raw/${setname}.zip">large ProPairs set</a></b></li>no redundancy removed - but contains clustering information<li><b><a href="data/data${setname}/raw/${setname}_nonredundant.zip">small ProPairs set</a></b></li>redundancy removed; contains only representative complexes and unbound structures</ul>   
EOI
      cat rawdata.html_tmpl | sed "s+{{RAWDATA}}+$html+g" > rawdata.html
   )
}


#------------------------------------------------------------------------------


# full search (starts from pdb files) 
if [ "${FULL}" -eq 1 ]; then

   if [ ! -e ${PDBCODES}_done ]; then
      g_statusmessage="getting PDB codes"
      echo ${g_statusmessage}"..." | pplog 0
      rm -f ${TABSIM}_done
      find  ${PDBDIR} -name '*.pdb' -exec basename {} .pdb \; | sort > ${PDBCODES} && \
      [ -s ${PDBCODES} ] && \
      touch ${PDBCODES}_done
   fi


   if [ ! -e ${PDBCODES}_done ]; then
      error ${LINENO} "missing ${PDBCODES}"
   fi
   if [ ! -e ${TABSIM}_done ]; then
      rm -f ${DBIMP}_done
      INP=${TMPDIR2}/chainsim_pdblist.txt
      # use subset?
      if [ "${PDBSET}" == "" ]; then
         cat ${PDBCODES} > ${INP}
      else
         cat ${PDBCODES} | grep -f ${PDBSET} > ${INP}
      fi
      
      # run 
      g_statusmessage="calculating chain similarities"
      echo ${g_statusmessage}"..." | pplog 0
      ${XTALDIR}/src/xtalcompseqid/xtalcompseqid grp ${PDBDIR} ${INP} > ${TABGRPTMP} 2> ${TMPDIR2}/chainsim_grp_log.txt && \
      ${XTALDIR}/src/xtalcompseqid/xtalcompseqid con ${PDBDIR} ${INP} > ${TABCONTMP} 2> ${TMPDIR2}/chainsim_con_log.txt && \
      ${XTALDIR}/src/xtalcompseqid/xtalcompseqid sim ${PDBDIR} ${INP} > ${TABSIMTMP} 2> ${TMPDIR2}/chainsim_sim_log.txt && \
      cp ${TABGRPTMP} ${TABGRP} && \
      cp ${TABCONTMP} ${TABCON} && \
      cp ${TABSIMTMP} ${TABSIM} && \
      touch ${TABSIM}_done      
   fi

   if [ ! -e ${TABSIM}_done ]; then
      error ${LINENO} "missing ${TABSIM}"
   fi
   if [ ! -e ${DBIMP}_done ]; then
      g_statusmessage="importing to database"
      echo ${g_statusmessage}"..." | pplog 0
      rm -f ${CAND}_done
      ${PROPAIRSROOT}/bin/1importchaindata.sh ${TABCON} ${TABGRP} ${TABSIM} 2> ${TMPDIR2}/0import_log && \
      touch ${DBIMP}_done
   fi
   if [ ! -e ${DBIMP}_done ]; then
      error ${LINENO} "missing ${DBIMP}"
   fi
fi # end full search


if [ ! -e ${CAND}_done ]; then
   rm -f ${ALIGNED}_done
   g_statusmessage="generating seeds"
   echo ${g_statusmessage}"..." | pplog 0
   1findcandidates ${CAND} ${TMPDIR2}/1cand_log ${PDBSET} && \
   touch ${CAND}_done
fi


if [ ! -e ${CAND}_done ]; then
   error ${LINENO} "missing ${CAND}"
fi
if [ ! -e ${ALIGNED}_done ]; then
   g_statusmessage="calculating interface partitions / unbound alignments"
   echo ${g_statusmessage}"..." | pplog 0              
   rm -f ${CLUSTERED}_done
   2alignunbound ${ALIGNED} ${TMPDIR2}/2aligned_log "${PDBDIR}" "${CAND}" && \
   touch ${ALIGNED}_done
#   printf "  "
fi


if [ ! -e ${ALIGNED}_done ]; then
   error ${LINENO} "missing ${ALIGNED}"
fi
if [ ! -e ${CLUSTERED}_done ]; then
   g_statusmessage="clustering interfaces"
   echo ${g_statusmessage}"..." | pplog 0               
   rm -f ${MERGED}_done
   3clusterinterfaces ${CLUSTERED} ${TMPDIR2}/3cluster_log "${PDBDIR}" "${ALIGNED}" && \
   touch ${CLUSTERED}_done
fi
   
      
if [ ! -e ${CLUSTERED}_done ]; then
   error ${LINENO} "missing ${CLUSTERED}"
fi
if [ ! -e ${MERGED}_done ]; then
   g_statusmessage="generating non-redundant dataset"
   echo ${g_statusmessage}"..." | pplog 0   
   rm -f ${WWWDATA}_done
   4mergepartners ${MERGED} ${TMPDIR2}/4merge_log ${CLUSTERED} && \
   touch ${MERGED}_done
fi


if [ ! -e ${MERGED}_done ]; then
   error ${LINENO} "missing ${MERGED}"
fi
if [ ! -e ${WWWDATA}_done ]; then
   g_statusmessage="creating web data"
   echo ${g_statusmessage}"..." | pplog 0      
   WWWNAME=$( echo $NAME | sed "s/^run/data/" | tr -d "_" ) && \
   SETNAME=$( echo $NAME | sed "s/^run//" | tr -d "_" ) && \
   mkdir -p ./www && cp -r ${PROPAIRSROOT}/propairs-www/* ./www && \
   mkdir -p www/data/ && echo ${WWWNAME} >> www/data/sets.txt && \
   ${PROPAIRSROOT}/bin/5makewebdata.sh -t -n $SETNAME ${MERGED} ${CLUSTERED} www/data/${WWWNAME} > ${TMPDIR2}/5wwwdata_log && \
   5wwwraw $SETNAME www/data/${WWWNAME} && \
   echo "   Data tables created. You can start viewing the data!" | pplog 0 && \
   echo "   " | pplog 0 && \
   echo "   Open <OUTPUT_DIRECTORY>/www/database.html" | pplog 0 && \
   echo "   " | pplog 0 && \
   echo "   Creating PDB files and images..." | pplog 0 && \
   ${PROPAIRSROOT}/bin/5makewebdata.sh -p -n $SETNAME ${MERGED} ${CLUSTERED} www/data/${WWWNAME} >> ${TMPDIR2}/5wwwdata_log && \
   echo "   PDB files and front images created. Creating images of rotated structures..." | pplog 0 && \
   ${PROPAIRSROOT}/bin/5makewebdata.sh -r -n $SETNAME ${MERGED} ${CLUSTERED} www/data/${WWWNAME} >> ${TMPDIR2}/5wwwdata_log && \
   touch ${WWWDATA}_done
fi
if [ ! -e ${WWWDATA}_done ]; then
   error ${LINENO} "missing ${WWWDATA}"
fi

#------------------------------------------------------------------------------

 g_statusmessage="done"
echo ${g_statusmessage}"" | pplog 0   

