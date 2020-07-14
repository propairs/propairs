# show list of PDB snapshots

printf "fetching current snapshots from PDB...\n"
snlist="$(wget ftp://snapshots.rcsb.org/ 2>/dev/null -O - | grep -o '/snapshots.rcsb.org:21/[0-9]*/' | tr "/" " " | awk '{print $2}')"
declare -a sna=( $snlist )
printf "found %d snapshots:\n" ${#sna[@]}
for i in ${!sna[@]}; do
  printf "   %2d: %s\n" $((i+1)) ${sna[$i]}
done