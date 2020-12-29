#!/usr/bin/env bash

set -ETeuo pipefail

cmd=$1
shift

source ${PPROOT}/src/6_paired_json.sh
source ${PPROOT}/src/6_complex_json.sh
source ${PPROOT}/src/6_set_plaintext.sh

case "$cmd" in 
  "paired_json")
    write_paired_json $*
    ;;
  "complex_json")
    write_complex_json $*
    ;;
  "set_plaintext")
    write_set_plaintext $*
    ;;
  *)
    echo "error: cmd arg \"${cmd}\""
    exit 1
esac
