#!/bin/bash

winrar_home="/cygdrive/c/Program Files/WinRAR/"
rar_exe="$winrar_home/rar.exe"

exec "$rar_exe" "$@"

