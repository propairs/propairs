#!/bin/bash
# Argument = -f -t <testfile> -p <prefix> -d <date>

#------------------------------------------------------------------------------

usage()
{
cat << EOF
usage: $0 [-f] [-p prefix] [-t pdbset] [-d date]

This script tries to find the best two unbound structures for each complex.

OPTIONS:
   -h      Show this message
   -f      start with full search, generating chain tables
   -p      prefix
   -d      date i.e. 131029
   -t      test with restriction to provided pdb codes
EOF
}

PDBSET=
FULL=0
NAME=
DATE=
while getopts "hfd:p:t:" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         f)
             FULL=1
             ;;
         d)
             DATE=$OPTARG
             ;;                                       
         p)
             NAME=$OPTARG
             ;;                          
         t)
             PDBSET=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done


#------------------------------------------------------------------------------


source ${PROPAIRSROOT}/config/global.conf

if [ "$DATE" == "" ]; then
   DATE=`date +%y%m%d`
fi
NAME="run"${DATE}${NAME}"_"



trap "{ cd - ; exit 255; }" SIGINT

TMPDIR=./
TMPDIR2=./


mkdir -p ${TMPDIR2}/${NAME}/
TMPDIR2=${TMPDIR2}/${NAME}/


PDBDIR=${PDBDATADIR}


PREFIX=${TMPDIR}/${NAME}
LOGFN=${PREFIX}"log"
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
   formatTable ${MOUTFILE} 6
   # print info
   printf "  %s seeds generated\n" "`tail -n +2 ${MOUTFILE} | wc -l`"
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
   formatTable ${MOUTFILE} 41
   # print info
   printf "  %s seeds checked\n" "`tail -n +2 ${MOUTFILE} | wc -l`"
   printf "  %s valid alignments\n" "`tail -n +2 ${MOUTFILE} | grep -v error | wc -l`"
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
   formatTable ${MOUTFILE} 44
   
   # write out interface score vs. sequence ID
   cat ${MLOGFILE} | grep "^intsc" | gzip - > ${MLOGFILE}_intscore.gz
   cat ${MLOGFILE} | gzip > ${MLOGFILEGZ}
   printf "  %s unique interfaces\n" "`cat ${MLOGFILE}_interfaces | wc -l`"
   printf "  %s interface clusters\n" "`cat  ${MLOGFILE}_cluster | grep "^cl cluster" | wc -l`"
   printf "  %s alignments assigned to clusters\n" "`tail -n +2 ${MOUTFILE} | wc -l`"
   
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
   printf "  %s complexes with one aligned unbound\n" "$UNPAIRED"
   printf "  %s complexes with two aligned unbound\n" "$PAIRED"
   # write out pairings that do not match because of cofactors
   ${PROPAIRSROOT}/bin/4mergepartners.sh -c ${MCLUSFILE} | grep -v " ok " | uniq > ${PREFIX}"supp_unmatchedCof"
}

#------------------------------------------------------------------------------

function runsearch {
   # full search (starts from pdb files) 
   if [ ${FULL} -eq 1 ]; then

      if [ ! -e ${PDBCODES}_done ]; then
         rm -f ${TABSIM}_done   
         printf "0 getting PDB codes of all files\n" && \
         printf "  " && date && \
         find  ${PDBDIR} -name '*.pdb' -exec basename {} .pdb \; | sort > ${PDBCODES} && \
         printf "  done " && date && \
         touch ${PDBCODES}_done
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
         printf "0 calculating chain similarities \n" && \
         printf "  " && date && \
         ${XTALDIR}/src/xtalcompseqid/xtalcompseqid grp ${PDBDIR} ${INP} > ${TABGRPTMP} 2> ${TMPDIR2}/chainsim_grp_log.txt && \
         ${XTALDIR}/src/xtalcompseqid/xtalcompseqid con ${PDBDIR} ${INP} > ${TABCONTMP} 2> ${TMPDIR2}/chainsim_con_log.txt && \
         ${XTALDIR}/src/xtalcompseqid/xtalcompseqid sim ${PDBDIR} ${INP} > ${TABSIMTMP} 2> ${TMPDIR2}/chainsim_sim_log.txt && \
         cp ${TABGRPTMP} ${TABGRP} && \
         cp ${TABCONTMP} ${TABCON} && \
         cp ${TABSIMTMP} ${TABSIM} && \
         printf "  done " && date && \
         touch ${TABSIM}_done      
      fi

      if [ ! -e ${TABSIM}_done ]; then
         exit 1
      fi
      if [ ! -e ${DBIMP}_done ]; then
         rm -f ${CAND}_done
         printf "0 importing to database \n" && \
         printf "  " && date && \
         ${PROPAIRSROOT}/bin/0importchaindata.sh ${TABCON} ${TABGRP} ${TABSIM} 2> ${TMPDIR2}/0import_log && \
         printf "  done " && date && \
         touch ${DBIMP}_done
      fi
      if [ ! -e ${DBIMP}_done ]; then
         exit 1
      fi
   fi # end full search


   if [ ! -e ${CAND}_done ]; then
      rm -f ${ALIGNED}_done
      printf "1 getting complex candidates\n" && \
      printf "  --" && date && \
      1findcandidates ${CAND} ${TMPDIR2}/1cand_log ${PDBSET} && \
      printf "  --done " && \
      date && \
      touch ${CAND}_done
   fi


   if [ ! -e ${CAND}_done ]; then
      exit 1
   fi
   if [ ! -e ${ALIGNED}_done ]; then
      rm -f ${CLUSTER}_done
      printf "2 aligning unbound to bound\n" && \
      printf "  --" && date && \
      2alignunbound ${ALIGNED} ${TMPDIR2}/2aligned_log "${PDBDIR}" "${CAND}" && \
      printf "  --done " && \
      date && \
      touch ${ALIGNED}_done
   #   printf "  "
   fi


   if [ ! -e ${ALIGNED}_done ]; then
      exit 1
   fi
   if [ ! -e ${CLUSTERED}_done ]; then
      rm -f ${CLUSTERED}_done
      printf "3 clustering complex interfaces\n" && \
      printf "  --" && date && \
      3clusterinterfaces ${CLUSTERED} ${TMPDIR2}/3cluster_log "${PDBDIR}" "${ALIGNED}" && \
      printf "  --done " && \
      date && \
      touch ${CLUSTERED}_done
   fi
      
         
   if [ ! -e ${CLUSTERED}_done ]; then
      exit 1
   fi   
   if [ ! -e ${MERGED}_done ]; then
      printf "4 merging interacting partners\n" && \
      printf "  --" && date && \
      4mergepartners ${MERGED} ${TMPDIR2}/4merge_log ${CLUSTERED} && \
      printf "  --done " && \
      date && \
      touch ${MERGED}_done
   fi
   
   
   if [ ! -e ${MERGED}_done ]; then
      exit 1
   fi
   if [ ! -e ${WWWDATA}_done ]; then
      printf "5 creating web data\n" && \
      printf "  --" && date && \
      WWWNAME=$( echo $NAME | sed "s/^run/data/" | tr -d "_" )
      mkdir -p www/data/ && echo ${WWWNAME} >> www/data/sets.txt && \
      ${PROPAIRSROOT}bin/makewebdata.sh ${MERGED} ${CLUSTERED} www/data/${WWWNAME} > ${TMPDIR2}/5wwwdata_log && \
      printf "  --done " && \
      date && \
      touch ${WWWDATA}_done
   fi
}

#------------------------------------------------------------------------------

# execute 
runsearch > ${LOGFN}

