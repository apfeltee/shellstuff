#!/bin/bash

kde_klipper_ns="org.kde.klipper"
kde_klipper_name="klipper"

function call_qdbus
{
  ns="$1"
  name="$2"
  func="$3"
  shift 3
  args="$@"
  callable="$ns.$name.$func"
  qdbus "$ns" "/$name" "$callable" "$@"
}

function call_klipper
{
  func="$1"
  shift
  call_qdbus "$kde_klipper_ns" "$kde_klipper_name" "$func" "$@"
}


function set_clip_contents
{
  data="$@"
  call_klipper setClipboardContents "$data"
}

function print_clip_contents
{
  call_klipper getClipboardContents
}

# check whether user arguments where provided, or if stdin has contents
if [[ -n "$1" ]] || ! tty -s; then
  data=""
  # user args have higher priority
  if [[ -n $1 ]]; then
    for arg in "$@"; do
      data="$data $arg"
    done
  else
    stdin=$(</dev/stdin)
    data="$stdin"
  fi
  set_clip_contents "$data"
else
  print_clip_contents
fi


