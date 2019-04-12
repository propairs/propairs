#!/usr/bin/env bash

# start database
PSQLVER=$( cd /usr/lib/postgresql && ls | tail -n 1 )
PSQLBINDIR=/usr/lib/postgresql/${PSQLVER}/bin/

if [ -d "$PSQLBINDIR" ]; then
  export PATH=$PSQLBINDIR:$PATH
fi

DATADIR=/data/psql/

export LC_ALL=C

#  if database dir not found, create and init
if [ ! -d "${DATADIR}" ]; then
  mkdir ${DATADIR}
  pg_ctl initdb -D ${DATADIR}
  sed -i "s+.*unix_socket_directories.*+unix_socket_directories = '\/data\/psql'+" ${DATADIR}/postgresql.conf
  pg_ctl start -D ${DATADIR} -l ${DATADIR}/log.txt
  # wait until started
  for i in {1..10}; do
    if pg_isready -h localhost -p 5432; then break; fi
    echo "sleep... $(date)"
    sleep 5
  done
  createuser -s ppiuser  -h localhost -p 5432
  createdb -O ppiuser ppidb1  -h localhost -p 5432
else
  pg_ctl start -D ${DATADIR} -l ${DATADIR}/log.txt
fi

export PGHOST=localhost
export PGPORT=5432

# run propairs
$PROPAIRSROOT/start.sh -i $PROPAIRSROOT -o /data $*

