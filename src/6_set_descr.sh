
# write plain set
write_set_descr() {
  set -ETeuo pipefail
  source ${PPROOT}/src/helpers.sh
  local fn_out=$1
  local set_id=$2
  local fn_set_paired=$3
  local fn_set_clustered=$4
  {
    printf "{\n"
    printf "\"title\": \"%s\"" "${set_id}"
    printf ",\n"
    printf "\"date_created\": \"%s\"" "$(date -Im)"
    printf ",\n"
    printf "\"num_interfaces\": %d" "$(tail -n +2 ${fn_set_clustered} | wc -l)"
    printf ",\n"
    printf "\"num_representative_interfaces\": %d" "$(cat ${fn_set_paired} | wc -l)"
    printf "\n"
    printf "}\n"
  } > ${fn_out}
}
