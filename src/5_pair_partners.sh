pair_partners() (
  set -ETeuo pipefail

  declare -r sqlite_db=${pp_tmp_prefix}/lpp.db

  dst_file=${pp_out_prefix}_paired
  # already done?
  [ -f ${dst_file} ] && { printf "using existing pairings \n" | pplog 0 ; return 0; } || true
  
  mkdir -p ${pp_tmp_prefix}

  printf "preparing database\n" | pplog 0
  cat ${pp_in_clustered} | sed "s/\ \+/ /g" > ${pp_tmp_prefix}/import.ssv
  query=$(
  cat << EOI
drop table if exists ppl;
.separator " "
.import ${pp_tmp_prefix}/import.ssv ppl
-- split cofactors into rows conatining 1 bound and 1 unbound each
CREATE INDEX ppl_unbound ON ppl(seedpb, cbi1, cbi2);
CREATE INDEX ppl_seedidx ON ppl(seedidx);
drop table if exists coflist;
create table coflist (
  seedidx text
  , cofb text
  , cofu text
);
WITH w_split(seedidx, word, str) AS (
    SELECT seedidx,'', cof||';' from ppl
    UNION ALL SELECT
    seedidx,
    substr(str, 0, instr(str, ';')),
    substr(str, instr(str, ';')+1)
    FROM w_split WHERE str!=''
),
w_coflist as (
SELECT 
seedidx 
, substr(word, 0, instr(word, ',')) as cofb
, substr(word, instr(word, ',')+1) as cofu
FROM w_split WHERE word!='' order by seedidx
)
insert into coflist select * from w_coflist;
CREATE INDEX coflist_seedidx_cofb_cofu ON coflist(seedidx,cofb,cofu);
CREATE INDEX coflist_seedidx_cofu_cofb ON coflist(seedidx,cofu,cofb);
EOI
)
  echo "${query}" | sqlite3 -bail -csv ${sqlite_db}


  query=$(
  cat << EOI 
select distinct(CLUSID) from ppl order by cast(CLUSID as int);
EOI
)

  clus_ids=( $(echo "${query}" | sqlite3 -bail -csv ${sqlite_db} ) )


  printf "generating pairs for %s interface clusters\n" "${#clus_ids[@]}" | pplog 0
  get_cluster_candidates() {
    local clus_id=$1
    local query=$(
    # get complex with max interface Ca atoms (ica1*ica2)
    # get complex with min interfacing chains     
    # get complex with min gaps within interface
    # get complex with min number of additional chains
    # get complex with min. distance to medoid
    # sort by complex and interface chain ids
    cat << EOI
.separator " "
select SEEDIDX, SEEDPB, CBI1, CBI2 from ppl 
where clusid = '${clus_id}'
order by 
  cast(BNUMI1CA as int) * cast(BNUMI2CA as int) desc
, cast(BNUMICHAINS as int)
, cast(BNUMGAPS as int)
, cast(BNUMNONICHAINS as int)
, cast(CLUSMEDDIST as float)
, cast(SEEDPB as int)
, cast(CBI1 as int)
, cast(CBI2 as int)
;
EOI
)
    echo "${query}" | sqlite3 -bail -csv ${sqlite_db}
  }

  get_unbound_candidates() {
    local seedpb=$1
    local cbi1=$2
    local cbi2=$3
    # get structure with min. number of chains - but fully covering B2 chains
    # get structure with min. number of gaps
    # get structure with max. interface coverage (residues)
    # get structure with min. number of additional cofactors within interface  
    # get structure with min. IRMSD
    local query=$(
  cat << EOI
.separator " "
select seedidx from ppl 
where seedpb = '${seedpb}'
  and cbi1 = '${cbi1}'
  and cbi2 = '${cbi2}'
order by 
  cast(UNUMXCHAINS as int) desc
, cast(UNUMGAPS as int)
, cast(UALIGNEDIRATIO as float)
, cast(UNUMUNMATCHEDCOF as int)
, cast(UIRMSD as float)
;
EOI
)
    echo "${query}" | sqlite3 -bail -csv ${sqlite_db}
  }

  get_row_by_seedidx() {
    local seedidx=$1
    local query=$(
  cat << EOI
.separator " "
select * from ppl 
where seedidx = '${seedidx}'
;
EOI
)
    echo "${query}" | sqlite3 -bail -csv ${sqlite_db}
  }

  compatible_cofactors() {
    local seedidx1=$1
    local seedidx2=$2
    # look for bad stuff
    local query=$(
    cat << EOI
.separator " "
with 
c1 as (
	select * from coflist where
	seedidx = '${seedidx1}'
),
c2 as (
	select * from coflist where
	seedidx = '${seedidx2}'
)
-- find mismatched cofactors
select * from c1
left outer join c2 on c1.cofb = c2.cofb
-- we care only about cofs that are found in the b interface
where c1.cofb != '' and (
  (c1.cofu != '' and c2.cofu != '') or -- assigned to none = bad
  (c1.cofu  = '' and c2.cofu  = '')    -- assigned to both = bad
)
;
EOI
)
    local res="$(echo "${query}" | sqlite3 -bail -csv ${sqlite_db})"
    # return true if we didn't find incompatible data
    [ -z "${res}" ]
  }

  num_paired=0
  num_single=0

  #init output (prepare for space-separated)
  #head -n 1 ${pp_in_clustered} | sed "s/\ \+/ /g" > ${pp_tmp_prefix}/paired
  > ${pp_tmp_prefix}/paired
  # ${clus_ids[@]}
  for clustid in ${clus_ids[@]}; do
    printf "pairing cluster ${clustid}...\n" | pplog 1
    cands="$( get_cluster_candidates ${clustid} )"
    [ ! -z "${cands}" ] ||  { printf "error: cands\n" | pplog 0; exit 1; }
    # try to pair
    pair=()
    while [ "${#pair[@]}" -eq 0 ] && read seedpb cbi1 cbi2; do
      # get unboud 1 candidates
      u1cands="$( get_unbound_candidates $seedpb $cbi1 $cbi2 )"
      # get unboud 2 candidates
      u2cands="$( get_unbound_candidates $seedpb $cbi2 $cbi1 )"
      while [ "${#pair[@]}" -eq 0 ] && read seedidx1; do
        while [ "${#pair[@]}" -eq 0 ] && read seedidx2; do
          # no partner?
          [ ! -z "${seedidx2}" ] || continue
          if compatible_cofactors $seedidx1 $seedidx2; then
            pair=( $seedidx1 $seedidx2 )
          fi
        done < <( echo "${u2cands}" )
      done < <( echo "${u1cands}" )
      printf "  ${clustid}: found %d matchtes for $seedpb $cbi1 $cbi2\n" "${#pair[@]}" | pplog 1
    done < <( echo "${cands}" | cut -d " " -f 2- | uniq ) # skip seedidx - we'll use it below
    # if no solution is found, use first candidate - only one unbound
    case "${#pair[@]}" in
      0)
        # get unpaired 
        #get_row_by_seedidx $( echo "${cands}" | head -n 1 | cut -f 1 -d " " ) >> ${pp_tmp_prefix}/paired
        echo "${cands}" | head -n 1 | cut -f 1 -d " " >> ${pp_tmp_prefix}/paired
        let "num_single+=1"
        ;;
      2)
        # get pair
        #for seedidx in ${pair[@]}; do
        #  get_row_by_seedidx "${seedidx}" >> ${pp_tmp_prefix}/paired
        #done
        printf "%s %s\n" ${pair[0]} ${pair[1]} >> ${pp_tmp_prefix}/paired
        let "num_paired+=1"
        ;;
      *)
        echo printf "error: pair=${#pair[@]}\n" | pplog 0
        exit 1
    esac
    # echo >> ${pp_tmp_prefix}/paired
  done
  printf "pairs=%d single=%d (sum=%d)\n" $num_paired $num_single $((num_paired+num_single)) | pplog 0
  printf "pairing of binding partners done\n" | pplog 0

  mv ${pp_tmp_prefix}/paired ${dst_file}
)

pair_partners
unset pair_partners
