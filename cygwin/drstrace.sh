#!/bin/bash

drmemory_just_want_config=1 source "$HOME/bin/drmemory"

exec "$drmemory_bin64/drstrace.exe" "$@"
