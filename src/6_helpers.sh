
getHeader() {
  if [ "$1" == "-" ]; then
    echo "-"
    return;
  fi
  local pdbdir=$2
  head -n 1 $pdbdir/$1.pdb | cut -c 11-50 | sed "s/\  */ /g" | sed "s/\"/\\\\\"/g"  | sed 's/\\;/;/g';
}

getTitle() {
  if [ "$1" == "-" ]; then
    echo "-"
    return;
  fi
  local pdbdir=$2
  grep "^TITLE" $pdbdir/$1.pdb | sed "s/^.\{10\}//" | tr -d "\n" | sed "s/\  */ /g" | sed "s/\"/\\\\\"/g" | sed 's/\\;/;/g'; printf "\n"
}

getCompound() {
  if [ "$1" == "-" ]; then
    echo "-"
    return;
  fi
  local pdbdir=$2
  grep "^COMPND" $pdbdir/$1.pdb | sed "s/^.\{10\}//" | tr -d "\n" | sed "s/\  */ /g" | sed "s/\"/\\\\\"/g" | sed 's/\\;/;/g'; printf "\n"
}
