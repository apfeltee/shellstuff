#!/bin/bash



if [[ -e /cygdrive/c/windows/explorer.exe ]]; then
  drmemory_binext='.exe'
  drmemory_root="/cygdrive/c/cloud/gdrive/portable/devtools/drmemory"
  drmemory_bin32="$drmemory_root/bin"
  drmemory_bin64="$drmemory_root/bin64"
else
  drmemmory_binext=''
  drmemory_root="/opt/drmemory"
  drmemory_bin32="$drmemory_root/bin"
  drmemory_bin64="$drmemory_root/bin64"

fi

[[ "$drmemory_just_want_config" ]] && return

#exec "$drmemory_bin64/drmemory${drmemory_binext}" -batch -top_stats "$@"
exec "$drmemory_bin64/drmemory${drmemory_binext}" "$@"

