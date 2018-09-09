#!/bin/bash

# msiexec /a PathToMSIFile   /qb TARGETDIR=DirectoryToExtractTo
# msiexec /a c:\testfile.msi /qb TARGETDIR=c:\temp\test
msiexec_exe="c:/windows/system32/msiexec.exe"

function vexec
{
  echo "[$$] $@"
  "$@"
  return $?
}

if [[ "$1" ]] && [[ "$2" ]]; then
  msifile="$1"
  destdir="$2"
  if [[ -f "$msifile" ]]; then
    realmsi="$(cygpath -wa "$msifile")"
    realdestdir="$(cygpath -wa "$destdir")"
    if vexec "$msiexec_exe" /quiet /a "$realmsi" /qb TARGETDIR="$realdestdir"; then
      echo "done: extracted to '$realdestdir'"
    else
      echo "extraction may have failed"
      exit 1
    fi
  else
    echo "no such file: $msifile"
    exit 1
  fi
else
  echo "usage: $0 <msifile> <directory>"
  exit 1
fi 
