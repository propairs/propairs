#set -ETeuo pipefail
PPROOT=/home/fkrull/workspace/propairs

pp_inp_clustered=/home/fkrull/workspace/bup_ppdata_200708/run200707test_3_clustered

pp_tmp_prefix=/tmp/pp


mkdir -p ${pp_tmp_prefix}

cat ${pp_inp_clustered} | sed "s/\ \+/ /g" > ${pp_tmp_prefix}/import.ssv

query=$(
  cat << EOI
drop table if exists ppl;
.separator " "
.import /tmp/bla.tab ppl
EOI
)

echo "${query}" | sqlite3 --bail ${pp_tmp_prefix}/lpp.db


query=$(
  cat << EOI
  select count(*) from ppl 
EOI
)

echo "${query}" | sqlite3 --bail ${pp_tmp_prefix}/lpp.db

exit 0












source ${PPROOT}/config/columns_def.sh

cluster_ids=$(
#tail -n +2 ${pp_inp_clustered} | awk -v clusid=43 '{printf "%s\n", $clusid}' | sort -n | uniq
tail -n +2 ${pp_inp_clustered} | while read line; do
  toks=( echo $line )
  echo ${toks[ CLUSID ]}
done | sort -n -u
)

echo "$cluster_ids"