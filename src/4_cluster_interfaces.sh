cluster_interfalces() (
  set -ETeuo pipefail

  declare -r sqlite_db=${pp_tmp_prefix}/interface_clusters.db

  dst_file=${pp_out_prefix}_clustered
  # already done?
  [ -f ${dst_file} ] && { printf "using existing interface clusters \n" | pplog 0 ; return 0; } || true
  
  mkdir -p ${pp_tmp_prefix}

  # extrac interfaces

  if [ ! -f ${pp_tmp_prefix}/interfaces ]; then
    printf "extracting interface definitions\n" | pplog 0
    tail -n +2 ${pp_in_complexes} | grep -v error | while read idx pb cb1 cb2 pu cu1 status cbi1 cbi2 _; do
      if [[ "$cbi1" < "$cbi2" ]]; then
        printf "%s %s %s\n" $pb $cbi1 $cbi2
      else 
        printf "%s %s %s\n" $pb $cbi2 $cbi1
      fi
    done | sort -u > ${pp_tmp_prefix}/interfaces_tmp
    mv ${pp_tmp_prefix}/interfaces_tmp ${pp_tmp_prefix}/interfaces
  fi

  num_interfaces=$( wc -l < ${pp_tmp_prefix}/interfaces )

  if [  ! -f ${pp_tmp_prefix}/interface_clusters ]; then
    printf "calculating clusters for ${num_interfaces} interfaces...\n" | pplog 0
    {
      ${PPROOT}/xtal/src/xtaluniquecomp/xtaluniquecomp \
        ${pp_in_pdb} \
        ${pp_tmp_prefix}/interfaces \
        >> ${pp_tmp_prefix}/xtal_output
    } 2>&1 | pplog 1
    cat ${pp_tmp_prefix}/xtal_output | grep -v "^cl" | sed "s/\ \+/ /g" > ${pp_tmp_prefix}/interface_clusters_tmp
    mv ${pp_tmp_prefix}/interface_clusters_tmp ${pp_tmp_prefix}/interface_clusters
  fi

  num_clustered=$( wc -l < ${pp_tmp_prefix}/interface_clusters )

  [ $num_interfaces == $num_clustered ] || { printf "error: num_interfaces != num_clustered\n" | pplog 0; exit 1; }


  printf "identified %s interface clusters\n" "`cat  ${pp_tmp_prefix}/xtal_output | grep "^cl cluster" | wc -l`"  | pplog 0

query=$(
cat << EOF
-- ret rid of old stuff
DROP TABLE IF EXISTS cluster_info;
-- create
CREATE TABLE cluster_info (
    pdb         text NOT NULL,
    c1          text NOT NULL,
    c2          text NOT NULL,
    cl_id       int  NOT NULL,
    cl_mem_id   int  NOT NULL,
    cl_med_dist float not NULL
);
-- import
.mode csv
.separator ' '
.import ${pp_tmp_prefix}/interface_clusters cluster_info
EOF
)
  echo "${query}" | sqlite3 ${sqlite_db} | pplog 0

  get_clus_info() {
    local pdb=$1
    local c1=$2
    local c2=$3
    query=$(
cat << EOF 
.separator " "
select cl_id, cl_mem_id, cl_med_dist from cluster_info 
where pdb = '${pdb}'
and (
  ( c1 = '${c1}' and c2 = '${c2}' )
  or ( c2 = '${c1}' and c1 = '${c2}' )
)
EOF
) 
    echo "${query}" | sqlite3 ${sqlite_db}
  }

  printf "assigning cluster ids...\n" | pplog 0
  source ${PPROOT}/config/columns_def.sh
  tail -n +2 ${pp_in_complexes} | grep -v error | while read line; do
    tokens=(echo $line)
    echo $line $(get_clus_info ${tokens[${SEEDPB}]} ${tokens[${CBI1}]} ${tokens[${CBI2}]})
  done | format_table 44 > ${pp_tmp_prefix}/clustered

  mv ${pp_tmp_prefix}/clustered ${pp_out_prefix}_clustered
)

cluster_interfalces
unset cluster_interfalces
