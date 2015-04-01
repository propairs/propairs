#!/usr/bin/env bash

# start database
/etc/init.d/postgresql start

# run propairs
$PROPAIRSROOT/start.sh -i $PROPAIRSROOT -o /data $*

