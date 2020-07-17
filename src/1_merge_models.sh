merge_models() (
  set -ETeuo pipefail
  
  _merge_models_par() (
    set -ETeuo pipefail

    # define stuff
    function get_model_ids_z {
      INP="$1"
      gunzip -c "$1" | grep "^MODEL" | awk '{print $2}' || echo ""
    }
    function extract_model_only_z {
      PDB="$1"
      ID="$2"
      gunzip -c "$PDB" | awk "/ENDMDL/{flag=0}flag;/MODEL[ ]*${ID}[^0-9]/{flag=1}"
    }
    function extract_header_only_z {
      PDB="$1"
      gunzip -c "$PDB" | awk '/^MODEL|^ATOM/ {flag=1} !flag {print}'
    }
    #extract model x of pdb
    function extract_model_z {
      extract_header_only_z "$1"
      extract_model_only_z "$1" "$2"
    }
    # convert a number to a lowercase char
    function getChar {
      X=$(( $1 + 96 ))
      if [ $X -lt 97 -o $X -gt 122 ]; then
          printf "z"
      else
          printf \\$(printf '%03o' "$X")
      fi 
    }
    function merge_pdb5 {
      PDBCODE=$1
      MODEL=$2
      SUBDIR=`echo $PDBCODE | sed "s/^.\(..\).*/\1/g"`
      # check if pdb exists   
      PDBFILEO=${pp_in_pdb}/${SUBDIR}/pdb${PDBCODE}.ent.gz
      if [ ! -e ${PDBFILEO} ]; then
          return 1
      fi
      # check if merged pdb exits
      PDBFILEM=${pp_in_pdbbio}/${SUBDIR}/${PDBCODE}.pdb${MODEL}
      if [ ! -e ${PDBFILEM} ]; then
          return 1
      fi
      # new name
      PDBFILED=${pp_tmp_prefix}/pdb/${PDBCODE}${MODEL}.pdb
      # merge pdb - header and resolution (if provided)
      gunzip -c ${PDBFILEO} | grep "^HEADER\|^REMARK   2 RESOLUTION" | sed "s/XXXX/${PDBCODE}/g" > ${PDBFILED}
      # merge pdb merged
      cat ${PDBFILEM} >> ${PDBFILED}
    }

    # use bio PDB XXXX[0-9] if available + original PDBs header
    # use PDB otherwise
    local fn_input_pdbs=$1
    echo $fn_input_pdbs
    # chunk already done?
    [ ! -e ${fn_input_pdbs}_done ] || return 0
    while read pdbcode; do
      # 2-letter subdir x12x
      subdir=${pdbcode:1:2}
      
      found_bio=0
      # check if any biounit is available
      for biounit_id in 1 2 3 4 5 6 7 8 9; do 
          if [ -e ${pp_in_pdbbio}/${subdir}/${pdbcode}.pdb${biounit_id} ]; then
            found_bio=1
            break;
          fi
      done
      printf "PDB %s has bio: %d" "${pdbcode}" "${found_bio}"
      if [ $found_bio -eq 1 ]; then 
          # merge bio PDB
          for biounit_id in 1 2 3 4 5 6 7 8 9; do 
            [ ! -e ${pp_in_pdbbio}/${subdir}/${pdbcode}.pdb${biounit_id} ] \
              || merge_pdb5 ${pdbcode} ${biounit_id}
          done
      else  
          # use orginal PDB
          pdb_org=${pp_in_pdb}/${subdir}/${PFIX}${pdbcode}${SFIX}
          model_ids=$( get_model_ids_z "${pdb_org}" )
          if [ `echo ${model_ids} | wc -w` -eq 0 ]; then
            # copy when there are no models
            gunzip -c ${pdb_org} > ${pp_tmp_prefix}/pdb/${pdbcode}0.pdb
          else
            # split up models to different files 
            for M in $model_ids; do
                pdb_out=${pdbcode}`getChar $M`.pdb
                extract_model_z $pdb_org $M > ${pp_tmp_prefix}/pdb/${pdb_out}
                FIRST_MODEL_ONLY=1
                if [ ${FIRST_MODEL_ONLY} -eq 1 ]; then
                  break;
                fi
            done
            printf "   %d models" "`echo ${model_ids} | wc -w`"
          fi
      fi
      printf "\n"
    done < <( cat "${fn_input_pdbs}" )
    touch ${fn_input_pdbs}_done
  )

  dst_dir=${pp_out_prefix}_pdb
  # already done?
  [ -d ${dst_dir} ] && { printf "using existing, analysis-ready PDB directory\n" | pplog 0 ; return 0; } || true
  # check input
  [  ! -d "$pp_in_pdb" ] && { printf "error: pp_in_pdb\n"; return 1; }
  [  ! -d "$pp_in_pdbbio" ] && { printf "error: pp_in_pdbbio\n"; return 1; }
  mkdir -p ${pp_tmp_prefix}/pdb

  # get all current 4-letter PDB codes
  PFIX="pdb"
  SFIX=".ent.gz"

  # do we have pdbcodes?
  if [ ! -f ${pp_tmp_prefix}/pdbcodes ]; then
    printf "writing pdb codes\n" | pplog 0
    find ${pp_in_pdb} -name "${PFIX}????${SFIX}" -exec basename {} ${SFIX} \; | sed "s/^${PFIX}//" \
      > ${pp_tmp_prefix}/pdbcodes
  fi
  # make chunks
  split -l 400 -d ${pp_tmp_prefix}/pdbcodes ${pp_tmp_prefix}/pdbcodes_split
  chunks=$(find ${pp_tmp_prefix} -regex ".*pdbcodes_split[^_]*" )
  printf "merging pdb files with %s CPUs and %s chunks\n" $OMP_NUM_THREADS "$( echo "$chunks" | wc -l )" | pplog 0

  export -f _merge_models_par
  export pp_in_pdbbio
  export pp_in_pdb
  export pp_tmp_prefix
  export PFIX
  export SFIX
  parallel \
    -j ${OMP_NUM_THREADS} \
    _merge_models_par {} ::: $chunks | pplog 1
  
  mv ${pp_tmp_prefix}/pdb ${pp_out_prefix}_pdb
  rm -f ${pp_tmp_prefix}/*_done
)

merge_models