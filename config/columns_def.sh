### seed

SEEDIDX=1
SEEDPB=2   # (bound) primary protein complex / potential docking complex
SEEDCB1=3  # (bound) primary pair / has to have a counterpart in the unbound structure (SEEDCU1)
SEEDCB2=4  # (bound) primary pair / is not allowed to have a counterpart in the unbound structure
SEEDPU=5   # (unbound) secondary protein / potential unbound structure matching SEEDCB1
SEEDCU1=6  # (unbound) potential unbound counterpart of SEEDCB1

### alignment status

STATUS=7   # status of interface partitioning / valid seed? (error / ok)

### bound

CBI1=8             # interface chains of the binding partner involving the CCsub
CBI2=9             # interface chains of the complementary part

BNUMICHAINS=10     # number of interface chains (#CBI1+#CBI2)
BNUMGAPS=11        # number of gaps at residues of both interfaces
BNUMI1GAPS=12      # number of gaps at residues of interface CBI1
BNUMI2GAPS=13      # number of gaps at residues of interface CBI2

BNUMI1CA=14        # number of CA atoms of interface CBI1
BNUMI2CA=15        # number of CA atoms of interface CBI2

BNUMNONICHAINS=16  # number of non-interface chains (#CB1+#CB2X)
BNUMCOF=17         # number of cofactors found in interface

CB1=18             # binding partner involving the CCsub (aligned with CU1)
CB2X=19            # complementary part (not aligned, but connected to SEEDCB2)

### unbound

UNUMCHAINS=20        # number of chains from SEEDPU aligned to SEEDPC (#CU1)
UNUMGAPS=21          # number fo gaps found at residues in the interface region of CU1
UNUMXCHAINS=22       # number of additional chains (#CU1-#CB1)
UALIGNEDIRATIO=23    # fraction of CB1:CB2 interface residues relocated in CU1
UNUMMATCHEDCOF=24    # number of cofactors in SEEDPU matched with in SEEDPB
UNUMUNMATCHEDCOF=25  # number of cofactors in SEEDPU not matched to any in SEEDPB
UIRMSD=26            # interface RMSD of CU1 superimposed to CB1
UNUMCLASHES=27       # number of C-alpha clashes of CU1 with CB2X

CU1=28               # chains of SEEDPU matched with CB1 + appended chains (use only first #CB1 chains for alignment)

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

