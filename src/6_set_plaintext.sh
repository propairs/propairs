
# write plain set
write_set_plaintext() {
  set -ETeuo pipefail
  local settype=$1
  local fn_in_pairs=$2
  local fn_in_clustered=$3
  local fn_out_gz=$4
  case ${settype} in 
    "large")
      cat ${fn_in_clustered} | gzip > ${fn_out_gz}
      ;;
    "paired_representative")
      {
        # use fn_in_clustered but filter for pairs
        head -n 1 ${fn_in_clustered}
        while read index1 index2; do 
          grep "^${index1}[[:space:]]" ${fn_in_clustered}
          # 2nd binding partner can be missing
          [ -z "${index2-}" ] || grep "^${index2}[[:space:]]" ${fn_in_clustered}
          # sep complex by newline
          echo
        done < ${fn_in_pairs}
      } | gzip > ${fn_out_gz}
      ;;
    *)
      printf "error: settype \"${settype}\"\n" >&2
      exit 1
    ;;
  esac
}