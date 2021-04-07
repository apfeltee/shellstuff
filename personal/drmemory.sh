#!/bin/bash

drmemory_root="/cygdrive/c/Program Files (x86)/Dr. Memory"
drmemory_bin32="$drmemory_root/bin"
drmemory_bin64="$drmemory_root/bin64"

[[ "$drmemory_just_want_config" ]] && return

exec "$drmemory_bin64/drmemory.exe" -batch -top_stats "$@"
