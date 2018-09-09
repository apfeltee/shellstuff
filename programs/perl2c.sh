#!/bin/bash

if [[ $1 ]]; then
  filename="$1"; shift
  set -x
  exec perl -MO=C,"$@" "$filename"
else
  echo "usage: $0 <filename>" >&2
fi
