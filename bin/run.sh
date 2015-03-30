#!/bin/bash
nohup nice -n +5 ${PROPAIRSROOT}/bin/run_db.sh $* > /tmp/nohup.out 2> /tmp/nohup.err &
echo started process $!

