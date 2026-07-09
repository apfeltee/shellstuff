#!/bin/bash

if [[ "$1" ]]; then
  if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "usage: $0 <text ...>"
    echo "sets window title via ANSI escapes, roughly how 'title' in cmd.exe works."
    exit 1
  fi
fi
printf "\[\e]0;$@\a"
