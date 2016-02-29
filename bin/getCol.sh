#!/bin/bash

source ${PROPAIRSROOT}/config/columns_def.sh


### check options
usage()
{
cat << EOF
usage: $0 [options] <table> 

OPTIONS:
   -h            Show this message
   -l            List columns
   -c <cols>     comma-separated list of column indices
   -n <name>     column name
   -s            skip header
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
declare COLUMNS=
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
            IFS=',' read -ra cols <<< "${OPTARG}"       
            COLUMNS=
            for i in "${cols[@]:0:1}"; do
               COLUMNS=${COLUMNS}'$'"$i"
               echo "1" "$i"
            done
            for i in "${cols[@]:1}"; do
               COLUMNS=${COLUMNS}',''$'"$i"
            done
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
if [ "$SHOWLIST" == "0" -a "$COLUMNS" == "" -a "$NAME" == "" ]; then
   usage
   exit 1
fi


if [ "$SHOWLIST" != "0" ]; then 
   list
   exit 0
fi

if [ "$NAME" != "" ]; then
   COLUMNS='$'`list "$INPUT" | grep $NAME'$' | awk '{print $1}'`
fi 

if [ "$COLUMNS" == "" ]; then
   exit 0
fi


tail -n +$(( SKIP + 1 )) "$INPUT" | awk \
   "{print $COLUMNS}"



