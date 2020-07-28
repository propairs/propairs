function find_seeds() (

set -ETeuo pipefail

export sqlite_db=${pp_tmp_prefix}/chaininf.db
export TNAMECON=chaincon
export TNAMEGRP=chaingrp
export TNAMESIM=chainsim

function get_bound {
   PDBCODE=$1

   QUERY=$(
   cat << EOF
PRAGMA cache_size = -$((CFG_MAXMEM_KB / OMP_NUM_THREADS));
.separator "," ";"
select c.pdb,c.c1,c.c2 from ${TNAMECON} c where 1
and c.p='${PDBCODE}'
and c.intsize > 10
-- only first biounit
and substr(c.pdb, 5, 1) = '1'
-- B1 and B2 not in same grp (do not allow similar sequence) 
and (c.c1,c.c2) not in (select d.c,d.grp from ${TNAMEGRP} d where d.pdb=c.pdb)
and (c.c2,c.c1) not in (select d.c,d.grp from ${TNAMEGRP} d where d.pdb=c.pdb)
and (c.pdb,c.c1) in 
( SELECT grp.pdb,grp.c from ${TNAMEGRP} grp where grp.pdb=c.pdb
  AND ( 0
     OR (grp.pdb,grp.grp) in 
     ( select a.pdb1,a.c1 from ${TNAMESIM} a where 1
	     and a.pdb1=c.pdb 
	     and a.sid > 0.8
	     and ( 0
		     or a.c1 in (SELECT g.grp from ${TNAMEGRP} g where g.pdb=c.pdb and g.c=grp.grp)
	     )
	     and (a.pdb2) not in
	     (	select b.pdb2 from ${TNAMESIM} b where 1
		     and b.pdb1=c.pdb 
		     and b.sid > 0.5
		     and ( 0
			     or b.c1 in (SELECT g.grp from ${TNAMEGRP} g where g.pdb=c.pdb and g.c=c.c2)
		     )
	     )
	     and (a.pdb2) not in
	     (	select b.pdb1 from ${TNAMESIM} b where 1
		     and b.pdb2=c.pdb 
		     and b.sid > 0.5
		     and ( 0
			     or b.c2 in (SELECT g.grp from ${TNAMEGRP} g where g.pdb=c.pdb and g.c=c.c2)
		     )
	     )
	  ) 
     OR (grp.pdb,grp.grp) in 
     ( select a.pdb2,a.c2 from ${TNAMESIM} a where 1
	     and a.pdb2=c.pdb 
	     and a.sid > 0.8
	     and ( 0
		     or a.c2 in (SELECT g.grp from ${TNAMEGRP} g where g.pdb=c.pdb and g.c=grp.grp)
	     )
	     and (a.pdb1) not in
	     (	select b.pdb2 from ${TNAMESIM} b where 1
		     and b.pdb1=c.pdb 
		     and b.sid > 0.5
		     and ( 0
			     or b.c1 in (SELECT g.grp from ${TNAMEGRP} g where g.pdb=c.pdb and g.c=c.c2)
		     )
	     )
	     and (a.pdb1) not in
	     (	select b.pdb1 from ${TNAMESIM} b where 1
		     and b.pdb2=c.pdb 
		     and b.sid > 0.5
		     and ( 0
			     or b.c2 in (SELECT g.grp from ${TNAMEGRP} g where g.pdb=c.pdb and g.c=c.c2)
		     )
	     )
	  )
  )
);
EOF
   )
	 echo "${QUERY}" | sqlite3 ${sqlite_db}
}


function get_unbound {
   PDBCODE=$1
   CHAININ=$2
   CHAINEX=$3

   QUERY=$(
   cat << EOF
PRAGMA cache_size = -$((CFG_MAXMEM_KB / OMP_NUM_THREADS));
.separator "," ";"
SELECT c.pdb,c.c FROM ${TNAMEGRP} c WHERE 1
AND ( 0
  OR (c.pdb,c.grp) IN 
  (
    -- chain must be similar to query chain
	  SELECT a.pdb2,a.c2 FROM ${TNAMESIM} a WHERE 1
	  AND a.pdb1='${PDBCODE}'
	  AND a.sid > 0.8
	  AND NOT a.p2=a.p1	
	  AND ( 0
		  or a.c1 in (SELECT g.grp FROM ${TNAMEGRP} g WHERE g.pdb='${PDBCODE}' AND g.c='${CHAININ}')
	  )
    -- other chain is not allowed to be similar to something within pdb2 - use pX instead of pdbX to avoid wrong biocells
	  AND (a.p2) NOT IN
	  (	SELECT b.p2 FROM ${TNAMESIM} b WHERE 1
		  AND b.pdb1='${PDBCODE}'
		  AND b.sid > 0.5
		  AND NOT b.p2=b.p1
		  AND ( 0
			  or b.c1 in (SELECT g.grp FROM ${TNAMEGRP} g WHERE g.pdb='${PDBCODE}' AND g.c='${CHAINEX}')
		  )
	  )
    -- something within pdb2 is not allowed to be similar to other chain - use pX instead of pdbX to avoid wrong biocells
	  AND (a.p2) NOT IN
	  (	SELECT b.p1 FROM ${TNAMESIM} b WHERE 1
		  AND b.pdb2='${PDBCODE}'
		  AND b.sid > 0.5
		  AND NOT b.p2=b.p1
		  AND ( 0
			  or b.c2 in (SELECT g.grp FROM ${TNAMEGRP} g WHERE g.pdb='${PDBCODE}' AND g.c='${CHAINEX}')
		  )
	  )
  )	  
  OR (c.pdb,c.grp) IN 
  (
    -- chain must be similar to query chain
	  SELECT a.pdb1,a.c1 FROM ${TNAMESIM} a WHERE 1
	  AND a.pdb2='${PDBCODE}'
	  AND a.sid > 0.8
	  AND NOT a.p1=a.p2	
	  AND ( 0
		  or a.c2 in (SELECT g.grp FROM ${TNAMEGRP} g WHERE g.pdb='${PDBCODE}' AND g.c='${CHAININ}')
	  )
    -- other chain is not allowed to be similar to something within pdb2 - use pX instead of pdbX to avoid wrong biocells
	  AND (a.p1) NOT IN
	  (	SELECT b.p2 FROM ${TNAMESIM} b WHERE 1
		  AND b.pdb1='${PDBCODE}'
		  AND b.sid > 0.5
		  AND NOT b.p2=b.p1
		  AND ( 0
			  or b.c1 in (SELECT g.grp FROM ${TNAMEGRP} g WHERE g.pdb='${PDBCODE}' AND g.c='${CHAINEX}')
		  )
	  )
    -- something within pdb2 is not allowed to be similar to other chain - use pX instead of pdbX to avoid wrong biocells
	  AND (a.p1) NOT IN
	  (	SELECT b.p1 FROM ${TNAMESIM} b WHERE 1
		  AND b.pdb2='${PDBCODE}'
		  AND b.sid > 0.5
		  AND NOT b.p2=b.p1
		  AND ( 0
			  or b.c2 in (SELECT g.grp FROM ${TNAMEGRP} g WHERE g.pdb='${PDBCODE}' AND g.c='${CHAINEX}')
		  )
	  )  
  )	  
)
ORDER BY c.pdb,c.c -- LIMIT 1
EOF
   )
	 echo "${QUERY}" | sqlite3 ${sqlite_db}
}

function get_pdbids {
   QUERY=$(
   cat << EOF
.separator "," ";"
SELECT DISTINCT
  ${TNAMECON}.p
FROM 
  ${TNAMECON}
ORDER BY p;
EOF
   )
	 echo "${QUERY}" | sqlite3 ${sqlite_db}
}

function find_cand() {
	PDBCODE=$1
	PDBCODE=`echo ${PDBCODE} | tr [:upper:] [:lower:]`
	# log "`printf "++++++++++ %s ++++++++++\n" ${PDBCODE}`"
	RES=`get_bound ${PDBCODE}`
	# log ">> get_bound $RES"
	
	
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
		# log "`printf "%s %c %c -- \n" "${PDB}" "${CHAININ}" "${CHAINEX}"`"
		# unbound
		URES=`get_unbound "${PDB}" "${CHAININ}" "${CHAINEX}"`
		# log ">> get_unbound $URES"
		
			IFS=$';'
			for UROW in $URES
			do
			printf "%s,%c:%c %s\n" "${PDB}" "${CHAININ}" "${CHAINEX}" "$UROW"
			done
			unset IFS
	done
	unset IFS
}


function find_seeds_split() {
	set -ETeuo pipefail
	local -r chunk_file_in=$1
	local -r chunk_file_out=${chunk_file_in/pdbcodes/seeds}
	# done ?
	[ -f ${chunk_file_out} ] && return 0 || true
	{
		while read pdb_code; do 
			find_cand ${pdb_code}
		done < ${chunk_file_in}
 	} | tr ':' ' '  | tr ',' ' ' > ${chunk_file_out}_tmp
	mv ${chunk_file_out}_tmp ${chunk_file_out}
	printf "completed seed ${chunk_file_out}\n"
}

dst_fn=${pp_out_prefix}_seeds
[ -f ${dst_fn} ] && { printf "using existing seeds\n" | pplog 0 ; return 0; } || true

printf "calculating seeds...\n" | pplog 0


get_pdbids | tr ";" "\n" > ${pp_tmp_prefix}/exp_pdbcodes
num_pdbs=$( cat ${pp_tmp_prefix}/exp_pdbcodes | wc -l )

# split into at least 4 on smaller data sets
chunk_size=$(( num_pdbs/4 < 100 ? num_pdbs/4+1 : 100 ))

split -l ${chunk_size} -d ${pp_tmp_prefix}/exp_pdbcodes ${pp_tmp_prefix}/exp_split_pdbcodes
chunks=$(find ${pp_tmp_prefix} -regex ".*exp_split_pdbcodes[^_]*" | sort )
printf "calculating seeds with %s CPUs and %s chunks\n" $OMP_NUM_THREADS "$( echo "$chunks" | wc -l )" | pplog 0

export -f find_cand
export -f get_bound
export -f get_unbound
export -f find_seeds_split
parallel \
	-j ${OMP_NUM_THREADS} \
	find_seeds_split {} ::: $chunks | pplog 1

# merge and format table
printf "merging seeds...\n" | pplog 0
find ${pp_tmp_prefix} -regex ".*exp_split_seeds[^_]*" \
	| xargs cat | sort | cat -n | format_table 5 > ${pp_tmp_prefix}/exp_seeds
mv ${pp_tmp_prefix}/exp_seeds ${dst_fn}

)


find_seeds
unset find_seeds
