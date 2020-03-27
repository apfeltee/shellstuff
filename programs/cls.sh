#!/bin/bash

# the physical path to your clipboard device
# probably only applicable on linux, and cygwin (maybe unix too?)
clipboard_path="/dev/clipboard"

if [[ $1 ]]; then
  for arg in "$@"; do
    case "$arg" in
      -clipboard|-c)
          if [[ -e "$clipboard_path" ]]; then
            printf '\0' > "$clipboard_path"
          else
            echo "error: clipboard path '$clipboard_path' does not exist" >&2
            exit 1
          fi
        ;;
      -h|-help|--help)
        echo "supported options:"
        echo "  -clipboard / -c     clear clipboard as well"
        echo "  --help / -h         show this help and exit"
        exit
        ;;
      *)
        echo "error: unknown argument '$arg'" >&2
        echo "(try '--help')" >&2
        exit 1
        ;;
      esac
  done
fi

### end any escape sequences ...
printf "\e[0m\r" 2>/dev/null
### clear screen hack (screws with conemu!)
#printf "\e[?47h" 2>/dev/null
### do essentially the same with tput ...
tput reset 2>/dev/null
### because tput somehow screws with $PS1, "fix" it by printing nulbytes ...
#printf "\0" 2>/dev/null
### run cls for good measure
cmd /c cls 2>/dev/null
# make everything sane(-ish) again ...
stty sane 2>/dev/null
