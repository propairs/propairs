#!/bin/bash

source ${PROPAIRSROOT}/config/tables.def


_DEBUG=0

function log () {
   if [[ $_DEBUG -eq 1 ]]; then
      echo "$@"
   fi
}


function get_bound {
   PDBCODE=$1

   QUERY=$(
   cat << EOF
select c.pdb,c.c1,c.c2 from ${TNAMECON} c where TRUE
and c.intsize > 10
and c.p='${PDBCODE}'
-- only first biounit
and substr(c.pdb, 5, 1) = '1'
-- B1 and B2 not in same grp (do not allow similar sequence) 
and (c.c1,c.c2) not in (select d.c,d.grp from ${TNAMEGRP} d where d.pdb=c.pdb)
and (c.c2,c.c1) not in (select d.c,d.grp from ${TNAMEGRP} d where d.pdb=c.pdb)
and (c.pdb,c.c1) in 
( SELECT grp.pdb,grp.c from ${TNAMEGRP} grp where grp.pdb=c.pdb
  AND ( FALSE
     OR (grp.pdb,grp.grp) in 
     ( select a.pdb1,a.c1 from ${TNAMESIM} a where TRUE
	     and a.pdb1=c.pdb 
	     and a.sid > 0.8
	     and ( FALSE
		     or a.c1 in (SELECT g.grp from ${TNAMEGRP} g where g.pdb=c.pdb and g.c=grp.grp)
	     )
	     and (a.pdb2) not in
	     (	select b.pdb2 from ${TNAMESIM} b where TRUE
		     and b.pdb1=c.pdb 
		     and b.sid > 0.5
		     and ( FALSE
			     or b.c1 in (SELECT g.grp from ${TNAMEGRP} g where g.pdb=c.pdb and g.c=c.c2)
		     )
	     )
	     and (a.pdb2) not in
	     (	select b.pdb1 from ${TNAMESIM} b where TRUE
		     and b.pdb2=c.pdb 
		     and b.sid > 0.5
		     and ( FALSE
			     or b.c2 in (SELECT g.grp from ${TNAMEGRP} g where g.pdb=c.pdb and g.c=c.c2)
		     )
	     )
	  ) 
     OR (grp.pdb,grp.grp) in 
     ( select a.pdb2,a.c2 from ${TNAMESIM} a where TRUE
	     and a.pdb2=c.pdb 
	     and a.sid > 0.8
	     and ( FALSE
		     or a.c2 in (SELECT g.grp from ${TNAMEGRP} g where g.pdb=c.pdb and g.c=grp.grp)
	     )
	     and (a.pdb1) not in
	     (	select b.pdb2 from ${TNAMESIM} b where TRUE
		     and b.pdb1=c.pdb 
		     and b.sid > 0.5
		     and ( FALSE
			     or b.c1 in (SELECT g.grp from ${TNAMEGRP} g where g.pdb=c.pdb and g.c=c.c2)
		     )
	     )
	     and (a.pdb1) not in
	     (	select b.pdb1 from ${TNAMESIM} b where TRUE
		     and b.pdb2=c.pdb 
		     and b.sid > 0.5
		     and ( FALSE
			     or b.c2 in (SELECT g.grp from ${TNAMEGRP} g where g.pdb=c.pdb and g.c=c.c2)
		     )
	     )
	  )
  )
);
EOF
   )
   psql -d ppidb1 -U ppiuser -c "${QUERY}" -t -A -F ',' -R ';' -q
}


function get_unbound {
   PDBCODE=$1
   CHAININ=$2
   CHAINEX=$3

   QUERY=$(
   cat << EOF
SELECT c.pdb,c.c FROM ${TNAMEGRP} c WHERE TRUE
AND ( FALSE
  OR (c.pdb,c.grp) IN 
  (
    -- chain must be similar to query chain
	  SELECT a.pdb2,a.c2 FROM ${TNAMESIM} a WHERE TRUE
	  AND a.pdb1='${PDBCODE}'
	  AND a.sid > 0.8
	  AND NOT a.p2=a.p1	
	  AND ( FALSE
		  or a.c1 in (SELECT g.grp FROM ${TNAMEGRP} g WHERE g.pdb='${PDBCODE}' AND g.c='${CHAININ}')
	  )
    -- other chain is not allowed to be similar to something within pdb2 - use pX instead of pdbX to avoid wrong biocells
	  AND (a.p2) NOT IN
	  (	SELECT b.p2 FROM ${TNAMESIM} b WHERE TRUE
		  AND b.pdb1='${PDBCODE}'
		  AND b.sid > 0.5
		  AND NOT b.p2=b.p1
		  AND ( FALSE
			  or b.c1 in (SELECT g.grp FROM ${TNAMEGRP} g WHERE g.pdb='${PDBCODE}' AND g.c='${CHAINEX}')
		  )
	  )
    -- something within pdb2 is not allowed to be similar to other chain - use pX instead of pdbX to avoid wrong biocells
	  AND (a.p2) NOT IN
	  (	SELECT b.p1 FROM ${TNAMESIM} b WHERE TRUE
		  AND b.pdb2='${PDBCODE}'
		  AND b.sid > 0.5
		  AND NOT b.p2=b.p1
		  AND ( FALSE
			  or b.c2 in (SELECT g.grp FROM ${TNAMEGRP} g WHERE g.pdb='${PDBCODE}' AND g.c='${CHAINEX}')
		  )
	  )
  )	  
  OR (c.pdb,c.grp) IN 
  (
    -- chain must be similar to query chain
	  SELECT a.pdb1,a.c1 FROM ${TNAMESIM} a WHERE TRUE
	  AND a.pdb2='${PDBCODE}'
	  AND a.sid > 0.8
	  AND NOT a.p1=a.p2	
	  AND ( FALSE
		  or a.c2 in (SELECT g.grp FROM ${TNAMEGRP} g WHERE g.pdb='${PDBCODE}' AND g.c='${CHAININ}')
	  )
    -- other chain is not allowed to be similar to something within pdb2 - use pX instead of pdbX to avoid wrong biocells
	  AND (a.p1) NOT IN
	  (	SELECT b.p2 FROM ${TNAMESIM} b WHERE TRUE
		  AND b.pdb1='${PDBCODE}'
		  AND b.sid > 0.5
		  AND NOT b.p2=b.p1
		  AND ( FALSE
			  or b.c1 in (SELECT g.grp FROM ${TNAMEGRP} g WHERE g.pdb='${PDBCODE}' AND g.c='${CHAINEX}')
		  )
	  )
    -- something within pdb2 is not allowed to be similar to other chain - use pX instead of pdbX to avoid wrong biocells
	  AND (a.p1) NOT IN
	  (	SELECT b.p1 FROM ${TNAMESIM} b WHERE TRUE
		  AND b.pdb2='${PDBCODE}'
		  AND b.sid > 0.5
		  AND NOT b.p2=b.p1
		  AND ( FALSE
			  or b.c2 in (SELECT g.grp FROM ${TNAMEGRP} g WHERE g.pdb='${PDBCODE}' AND g.c='${CHAINEX}')
		  )
	  )  
  )	  
)
ORDER BY c.pdb,c.c -- LIMIT 1
EOF
   )
   psql -d ppidb1 -U ppiuser -c "${QUERY}" -t -A -F ',' -R ';' -q
}

function get_pdbids {
   QUERY=$(
   cat << EOF
SELECT DISTINCT
  ${TNAMECON}.p
FROM 
  public.${TNAMECON}
ORDER BY p;
EOF
   )
   psql -d ppidb1 -U ppiuser -c "${QUERY}" -t -A -F ',' -R ';' -q
}  



TMPPDBLIST=`mktemp`

# how to handle interruptions?
trap "echo 'received trap signal'; rm -f $TMPPDBLIST; exit" SIGHUP SIGINT SIGTERM

INPUT=$1

# collect pdb list, if none provided
if [ ! -e "${INPUT}" ]; then
    echo "Usage: `basename $0` {INPUTPDBLIST}" >&2
    echo "input does not exist... query all PDB IDs" >&2
    get_pdbids | tr ";" "\n" > $TMPPDBLIST
    INPUT=$TMPPDBLIST
fi



function find_cand {
   PDBCODE=$1
   PDBCODE=`echo ${PDBCODE} | tr [:upper:] [:lower:]`
   log "`printf "++++++++++ %s ++++++++++\n" ${PDBCODE}`"
   RES=`get_bound ${PDBCODE}`
   log ">> get_bound $RES"
   
   
   # split lines
   IFS=$';'
   for ROW in $RES
   do
      # split fields
      IFS=',' read -ra FIELDS <<< "$ROW"
      PDB="${FIELDS[0]}"
      CHAININ="${FIELDS[1]}"
      CHAINEX="${FIELDS[2]}"
      # bound
      #log "`printf "%s %c %c -- \n" "${PDB}" "${CHAININ}" "${CHAINEX}"`"
      # unbound
      URES=`get_unbound "${PDB}" "${CHAININ}" "${CHAINEX}"`
      log ">> get_unbound $URES"
      
       IFS=$';'
       for UROW in $URES
       do
        printf "%s,%c:%c %s\n" "${PDB}" "${CHAININ}" "${CHAINEX}" "$UROW"
       done
       unset IFS
      
      unset IFS
   done
   unset IFS
}
   
   
# sequential version
while read PDBCODE; do 
   find_cand ${PDBCODE}
done < ${INPUT}



rm -f $TMPPDBLIST
 
