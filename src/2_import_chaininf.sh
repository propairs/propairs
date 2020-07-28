function import_chain_inf() (
set -ETeuo pipefail

declare -r sqlite_db=${pp_tmp_prefix}/chaininf.db
declare -r INPCON=${pp_tmp_prefix}/chaininf_con
declare -r INPGRP=${pp_tmp_prefix}/chaininf_grp
declare -r INPSIM=${pp_tmp_prefix}/chaininf_sim
declare -r TNAMECON=chaincon
declare -r TNAMEGRP=chaingrp
declare -r TNAMESIM=chainsim

query_con=$(
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

-- delete duplicates
DELETE FROM ${TNAMECON}
WHERE rowid NOT IN (
  SELECT MIN(rowid) 
  FROM ${TNAMECON}
  GROUP BY pdb,c1,c2,intsize
);

-- derive
ALTER TABLE ${TNAMECON} ADD COLUMN p VARCHAR(4);
UPDATE ${TNAMECON} SET p = SUBSTR(pdb, 1, 4);

-- index
CREATE INDEX ${TNAMECON}_pdb_idx ON ${TNAMECON}(pdb);
CREATE INDEX ${TNAMECON}_p_idx ON ${TNAMECON}(p);
CREATE INDEX ${TNAMECON}_intsize_idx ON ${TNAMECON}(intsize);
CREATE INDEX ${TNAMECON}_c1_idx ON ${TNAMECON}(c1);
CREATE INDEX ${TNAMECON}_c2_idx ON ${TNAMECON}(c2);
CREATE INDEX ${TNAMECON}_pdb_intsize_idx ON ${TNAMECON}(pdb,intsize);
EOF
)

query_grp=$(
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

-- delete duplicates
DELETE FROM ${TNAMEGRP}
WHERE rowid NOT IN (
  SELECT MIN(rowid) 
  FROM ${TNAMEGRP}
  GROUP BY pdb,c,grp
);

-- derive
ALTER TABLE ${TNAMEGRP} ADD COLUMN p VARCHAR(4);
UPDATE ${TNAMEGRP} SET p = SUBSTR(pdb, 1, 4);

-- index
CREATE INDEX ${TNAMEGRP}_pdb_idx ON ${TNAMEGRP}(pdb);
CREATE INDEX ${TNAMEGRP}_grp_idx ON ${TNAMEGRP}(grp);
CREATE INDEX ${TNAMEGRP}_p_idx ON ${TNAMEGRP}(p);
CREATE INDEX ${TNAMEGRP}_c_idx ON ${TNAMEGRP}(c);
CREATE INDEX ${TNAMEGRP}_pdb_c_idx ON ${TNAMEGRP}(pdb,c);
EOF
)

query_sim=$(
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

-- delete duplicates
DELETE FROM ${TNAMESIM}
WHERE rowid NOT IN (
  SELECT MIN(rowid) 
  FROM ${TNAMESIM}
  GROUP BY pdb1,c1,pdb2,c2,sid
);

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
CREATE INDEX ${TNAMESIM}_pdb1_sid_p2_c1_idx ON ${TNAMESIM}(pdb1,sid,p2,c1);
CREATE INDEX ${TNAMESIM}_pdb2_sid_c2_idx ON ${TNAMESIM}(pdb2,sid,c2);
EOF
)

  function doquery {
    local op=$1
    local query="$2"
    local -r cp_file=${pp_tmp_prefix}/imp_${op}_done
    if [ -f ${cp_file} ]; then
        printf "using existing ${op} chain info database entries\n" | pplog 0
        return 0;
    fi
    printf "importing ${op}\n" | pplog 0
    echo "${query}" | sqlite3 ${sqlite_db} && touch ${cp_file} | pplog 0
  }
  doquery "grp" "${query_grp}"
  doquery "con" "${query_con}"
  doquery "sim" "${query_sim}"
)

import_chain_inf
unset import_chain_inf
