# show list of PDB snapshots

HOST=snapshots.rcsb.org
HOST=pdbjsnap.protein.osaka-u.ac.jp

printf "fetching current snapshots from PDB...\n"
snlist="$(wget ftp://${HOST}/ 2>/dev/null -O - | grep -o "/${HOST}:21/[0-9]*/" | tr "/" " " | awk '{print $2}')"
declare -a sna=( $snlist )
printf "found %d snapshots:\n" ${#sna[@]}
for i in ${!sna[@]}; do
  printf "   %2d: %s\n" $((i+1)) ${sna[$i]}
done

