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

BNUMI1CA=14        # number of C-alpha atoms of interface CBI1
BNUMI2CA=15        # number of C-alpha atoms of interface CBI2

BNUMNONICHAINS=16  # number of non-interface chains (#CB1+#CB2X)
BNUMCOF=17         # number of cofactors found in interface
BNUMS2BONDS=18     # number of disulfide bonds found in interface

CB1=19             # binding partner involving the CCsub (aligned with CU1)
CB2X=20            # complementary part (not aligned, but connected to SEEDCB2)

### unbound

UNUMCHAINS=21        # number of chains from SEEDPU aligned to SEEDPC (#CU1)
UNUMGAPS=22          # number fo gaps found at residues in the interface region of CU1
UNUMXCHAINS=23       # number of additional chains (#CU1-#CB1)
UALIGNEDIRATIO=24    # fraction of CB1:CB2 interface residues relocated in CU1
UNUMMATCHEDCOF=25    # number of cofactors in SEEDPU matched with in SEEDPB
UNUMUNMATCHEDCOF=26  # number of cofactors in SEEDPU not matched to any in SEEDPB
UIRMSD=27            # interface RMSD of CU1 superimposed to CB1
UNUMCLASHES=28       # number of C-alpha clashes of CU1 with CB2X

CU1=29               # chains of SEEDPU matched with CB1 + appended chains 
                     #          (use only first #CB1 chains for alignment)

ROT1=30              # transformation matrix to superimpose CU1 to CB1 - begin
ROT2=31
ROT3=32
ROT4=33
ROT5=34
ROT6=35
ROT7=36
ROT8=37
ROT9=38
ROT10=39
ROT11=41
ROT12=42             # transformation matrix to superimpose CU1 to CB1 - end

### cofactor

COF=42 # A ";"-separated list of cofactor that are found in the interface of 
       #     CBI1:CBI2 (XXX,) or in the interface region of CU1 (,XXX).
       #     Assignments of bound-unbound are denoted ","-separated (XXX,XXX).
       #
       #  Example: ";D:304(FAD),B:304(FAD);D:99(FES),;,B:305(NAP);"
       #  "D:304(FAD),B:304(FAD)" - FAD (Flavin adenine dinucleotide) is 
       #                            found in the interface of CB1:CB2 and 
       #                            is assigned to FAD in the unbound structure
       #             "D:99(FES)," - FES ([Fe2S2] cluster) is found in the 
       #                            interface of CB1:CB2 and is not assigned
       #            ",B:305(NAP)" - NAP (NADP) is found in the interface region
       #                            of the unbound structure and is not assigned

### cluster

CLUSID=43       # cluster ID of CBI1:CBI2 interface
CLUSMEMID=44    # member id within cluster
CLUSMEDDIST=45  # distance to medoid of cluster

NUMCOLS=46

TABLEHEADER="SEEDIDX  SEEDPB  SEEDCB1  SEEDCB2  SEEDPU  SEEDCU1  STATUS  CBI1  CBI2  BNUMICHAINS  BNUMGAPS BNUMI1GAPS BNUMI2GAPS BNUMI1CA BNUMI2CA BNUMNONICHAINS  BNUMCOF  BNUMS2BONDS  CB1     CB2X    UNUMCHAINS  UNUMGAPS  UNUMXCHAINS  UALIGNEDIRATIO  UNUMMATCHEDCOF  UNUMUNMATCHEDCOF  UIRMSD  UNUMCLASHES  CU1           ROT1   ROT2   ROT3   ROT4   ROT5   ROT6   ROT7   ROT8   ROT9   ROT10    ROT11    ROT12    COF CLUSID CLUSMEMID CLUSMEDDIST"

