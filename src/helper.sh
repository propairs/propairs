#!/bin/bash


getHeader() {
  if [ "$1" == "-" ]; then
    echo "-"
    return;
  fi
  echo "$1" | while read pdb; do
    head -n 1 $PDBDATADIR/$pdb.pdb | cut -c 11-50 | sed "s/\  */ /g" | sed "s/\"/\\\\\"/g";
  done
}


getNumRunning() {
   PROGNAME="$1"
   echo `find /proc/ -maxdepth 1 -user ${USER} -type d -exec basename {} \; 2> /dev/null | xargs ps | grep timeout | grep "${PROGNAME}" | wc -l`
}


getNumCpu() {
   # how many processes do we want to spawn=?   
   NUMCPU=`cat /proc/cpuinfo | grep "^proc" | wc -l`
   if [ "${NUMCPU}" -lt 1 ]; then
      NUMCPU=1
   fi
   echo $NUMCPU
}


waitProgSpawn() {
   PROGNAME="$1"
   NUMCPU=`getNumCpu`
   if [ "$2" != "" ]; then
      NUMCPU=$2
   fi
   NUMRUNNING=`getNumRunning "${PROGNAME}"`
   while [ ${NUMRUNNING} -ge ${NUMCPU} ]; do
      echo -ne "\b${NUMRUNNING}/${NUMCPU} used by \"${PROGNAME}\"\r"
      sleep 3
      NUMRUNNING=`getNumRunning "${PROGNAME}"`
   done
   echo -ne "\n"
   sleep 1
}


