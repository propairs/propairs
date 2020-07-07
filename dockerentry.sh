#!/usr/bin/env bash

set -ETeuo pipefail

# run propairs
$PROPAIRSROOT/start.sh -o /data $*
