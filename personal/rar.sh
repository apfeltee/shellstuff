#!/bin/bash

usrbinrar="/usr/bin/rar"
winrar_home="/cygdrive/c/Program Files/WinRAR/"
rar_exe="$winrar_home/rar.exe"

if [[ -x "$usrbinrar" ]]; then
  exec "$usrbinrar" "$@"
fi


exec "$rar_exe" "$@"

