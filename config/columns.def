### seed

SEEDIDX=1
SEEDPB=2   # PC complex to start from (bound)
SEEDCB1=3  # CB1 seed chain (bound)
SEEDCB2=4  # CB2 seed chain (bound)
SEEDPU=5   # PU potential structure matching CB1 (unbound)
SEEDCU1=6  # CU1 seed chain (unbound)

### alignment status

STATUS=7   # status of unbound alignment / interface partitioning (error / ok)

### bound

CBI1=8             # CB1 interface chains
CBI2=9             # CB2 interface chains

BNUMICHAINS=10     # number of interface chains (#BI1+#BI2)
BNUMGAPS=11        # number of gaps at residues of both interfaces
BNUMI1GAPS=12      # number of gaps at interface1 residues
BNUMI2GAPS=13      # number of gaps at interface2 residues

BNUMI1CA=14        # number of CA atoms of interface 1
BNUMI2CA=15        # number of CA atoms of interface 2

BNUMNONICHAINS=16  # number of non-interface chains (#CB1+#CB2)
BNUMCOF=17         # number of cofactors found in interface

CB1=18             # CB1 chains (aligned with CU1)
CB2X=19            # CB2 chains (not aligned, but connected to seed CB2)

### unbound

UNUMCHAINS=20        # number of chains from PU aligned to B1 (#CU1)
UNUMGAPS=21          # number fo gaps found at CU1 "interface" residues
UNUMXCHAINS=22       # number of additional chains (#CU1-#CB1)
UALIGNEDIRATIO=23    # fraction of B1:B2 interface residues relocated in CU1
UNUMMATCHEDCOF=24    # number of cofactors in PU matched with in PB
UNUMUNMATCHEDCOF=25  # number of cofactors in PU not matched to any in PB
UIRMSD=26            # interface RMSD of CU1 superimposed to CB1
UNUMCLASHES=27       # number of C-alpha clashes of CU1 with CB2

CU1=28               # chains of PU matched with CB1 + appended chains (use only first #CB1 chains for alignment)

ROT1=29              # transformation matrix to superimpose CU1 to CB1 - begin
ROT2=30
ROT3=31
ROT4=32
ROT5=33
ROT6=34
ROT7=35
ROT8=36
ROT9=37
ROT10=38
ROT11=39
ROT12=40             # transformation matrix to superimpose CU1 to CB1 - end

### cofactor

COF=41  # CBI1-cofactors ";"-separated and (if found) their CU1 matching ","-separated 
        #(i.e. ";cofB1_1,cofU1_1;cofB1_2,;cofB3_1,cofU2_1;"...)

### cluster

CLUSID=42       # cluster ID of CBI1:CBI2 interface
CLUSMEMID=43    # member id within cluster
CLUSMEDDIST=44  # distance to medoid of cluster

NUMCOLS=45

TABLEHEADER="SEEDIDX  SEEDPB  SEEDCB1  SEEDCB2  SEEDPU  SEEDCU1  STATUS  CBI1  CBI2  BNUMICHAINS  BNUMGAPS BNUMI1GAPS BNUMI2GAPS BNUMI1CA BNUMI2CA BNUMNONICHAINS  BNUMCOF  CB1     CB2X    UNUMCHAINS  UNUMGAPS  UNUMXCHAINS  UALIGNEDIRATIO  UNUMMATCHEDCOF  UNUMUNMATCHEDCOF  UIRMSD  UNUMCLASHES  CU1           ROT1   ROT2   ROT3   ROT4   ROT5   ROT6   ROT7   ROT8   ROT9   ROT10    ROT11    ROT12    COF CLUSID CLUSMEMID CLUSMEDDIST"

