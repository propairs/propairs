#!/bin/bash

source ${PROPAIRSROOT}/config/columns_def.sh


### check options
usage()
{
cat << EOF
usage: $0 options <aligned> 

OPTIONS:
   -h      Show this message
   -l      List columns
   -c      column index
   -n      colum name
   -s      skip header
EOF
}


list() 
{
   printf "listing columns of \"${INPUT}\"\n"
   read -a cols < <( head -n 1 ${INPUT} )
   for i in "${!cols[@]}"; do 
      printf "%d  %s\n" "$((i + 1))" "${cols[$i]}"
   done
}

declare SHOWLIST=0
declare COLUMN=
declare SKIP=0
declare NAME=""

while getopts "hlc:n:s" OPTION
do
     case $OPTION in
         h)
             usage
             exit 0
             ;;                      
         l)
             SHOWLIST=1
             ;;
         s)
             SKIP=1
             ;;
         n)
             NAME="${OPTARG}"
             ;;             
         c)
             COLUMN="${OPTARG}"
             ;;                  
     esac
done
shift $(( OPTIND-1 ))


INPUT="$1"


# no input file 
if [ "$INPUT" == "" ]; then
   usage
   exit 1
fi
# no options provided
if [ "$SHOWLIST" == "0" -a "$COLUMN" == "" -a "$NAME" == "" ]; then
   usage
   exit 1
fi


if [ "$SHOWLIST" != "0" ]; then 
   list
   exit 0
fi

if [ "$NAME" != "" ]; then
   COLUMN=`list "$INPUT" | grep $NAME'$' | awk '{print $1}'`
fi 

if [ "$COLUMN" == "" ]; then
   exit 0
fi


tail -n +$(( SKIP + 1 )) "$INPUT" | awk \
    -v col=${COLUMN} \
   '{print $col}'



