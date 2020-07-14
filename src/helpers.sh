pplog() {
  local lvl
  lvl=$1
  readonly lvl
  local lvl_max
  lvl_max="$( [ ${CFG_VERBOSE} -eq 1 ] && echo 1 || echo 0 )"
  readonly lvl_max
  local logfn
  logfn="${OUTPUT_DIR}/log.txt"
  readonly logfn
  # print stuff to log
  IFS=$'\n'
  while read line; do
    echo $(date) $lvl "${line}" >> ${logfn}
    # check log-level and print to standard output if lower or equal
    if [ "$lvl" -le "$lvl_max" ]; then
      echo "${line}"
    fi
  done
  unset IFS
  return 0
}
export -f pplog
