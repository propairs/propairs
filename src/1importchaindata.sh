#!/usr/bin/env bash

set -ETeuo pipefail

source ${PROPAIRSROOT}/config/global.conf
source ${PROPAIRSROOT}/config/tables_def.sh


declare -r sqlite_db=$1
INPCON=`readlink -e "$2"`
INPGRP=`readlink -e "$3"`
INPSIM=`readlink -e "$4"`


function doquery {
   printf "executing ... " >&2
   echo "$1" | sqlite3 ${sqlite_db} && echo "OK" >&2
}

QUERY=$(
cat << EOF
-- ret rid of old stuff
DROP TABLE IF EXISTS ${TNAMECON};
-- create
CREATE TABLE ${TNAMECON} (
    pdb character varying(5) NOT NULL,
    c1 character(1) NOT NULL,
    c2 character(1) NOT NULL,
    intsize integer NOT NULL
);
-- import
.mode csv
.separator ' '
.import ${INPCON} ${TNAMECON}

-- derive
ALTER TABLE ${TNAMECON} ADD COLUMN p VARCHAR(4);
UPDATE ${TNAMECON} SET p = SUBSTR(pdb, 1, 4);

-- index
CREATE INDEX ${TNAMECON}_pdb_idx ON ${TNAMECON}(pdb);
CREATE INDEX ${TNAMECON}_p_idx ON ${TNAMECON}(p);
CREATE INDEX ${TNAMECON}_intsize_idx ON ${TNAMECON}(intsize);
CREATE INDEX ${TNAMECON}_c1_idx ON ${TNAMECON}(c1);
CREATE INDEX ${TNAMECON}_c2_idx ON ${TNAMECON}(c2);
EOF
)

doquery "${QUERY}"
if [ $? -ne 0 ]; then
   exit 1
fi

QUERY=$(
cat << EOF
-- ret rid of old stuff
DROP TABLE IF EXISTS ${TNAMEGRP};
-- create
CREATE TABLE ${TNAMEGRP} (
    pdb character varying(5) NOT NULL,
    c character(1) NOT NULL,
    grp character(1) NOT NULL
);
-- import
.mode csv
.separator ' '
.import ${INPGRP} ${TNAMEGRP}

-- derive
ALTER TABLE ${TNAMEGRP} ADD COLUMN p VARCHAR(4);
UPDATE ${TNAMEGRP} SET p = SUBSTR(pdb, 1, 4);

-- index
CREATE INDEX ${TNAMEGRP}_pdb_idx ON ${TNAMEGRP}(pdb);
CREATE INDEX ${TNAMEGRP}_grp_idx ON ${TNAMEGRP}(grp);
CREATE INDEX ${TNAMEGRP}_p_idx ON ${TNAMEGRP}(p);
CREATE INDEX ${TNAMEGRP}_c_idx ON ${TNAMEGRP}(c);
EOF
)

doquery "${QUERY}"
if [ $? -ne 0 ]; then
   exit 1
fi

QUERY=$(
cat << EOF
-- ret rid of old stuff
DROP TABLE IF EXISTS ${TNAMESIM};
-- create
CREATE TABLE ${TNAMESIM} (
    pdb1 character varying(5) NOT NULL,
    c1 character(1) NOT NULL,
    pdb2 character varying(5) NOT NULL,
    c2 character(1) NOT NULL,
    sid numeric(8,6) NOT NULL
);
-- import
.mode csv
.separator ' '
.import ${INPSIM} ${TNAMESIM}


-- derive
ALTER TABLE ${TNAMESIM} ADD COLUMN p1 VARCHAR(4);
UPDATE ${TNAMESIM} SET p1 = SUBSTR(pdb1, 1, 4);
ALTER TABLE ${TNAMESIM} ADD COLUMN p2 VARCHAR(4);
UPDATE ${TNAMESIM} SET p2 = SUBSTR(pdb2, 1, 4);

-- index
CREATE INDEX ${TNAMESIM}_pdb1_idx ON ${TNAMESIM}(pdb1);
CREATE INDEX ${TNAMESIM}_pdb2_idx ON ${TNAMESIM}(pdb2);
CREATE INDEX ${TNAMESIM}_p1_idx ON ${TNAMESIM}(p1);
CREATE INDEX ${TNAMESIM}_p2_idx ON ${TNAMESIM}(p2);
CREATE INDEX ${TNAMESIM}_c1_idx ON ${TNAMESIM}(c1);
CREATE INDEX ${TNAMESIM}_c2_idx ON ${TNAMESIM}(c2);
CREATE INDEX ${TNAMESIM}_sid_idx ON ${TNAMESIM}(sid);
EOF
)

doquery "${QUERY}"
if [ $? -ne 0 ]; then
   exit 1
fi
