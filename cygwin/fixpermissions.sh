#!/bin/bash

###
LANG_ANS_YES='j'

exe_cmd="/cygdrive/c/windows/system32/cmd.exe"
exe_cacls="/cygdrive/c/Windows/System32/cacls.exe"

username="$("$exe_cmd" /c echo %USERNAME% | sed 's/\r$//')"
havepath=0
traverse=0
path=""

function logm
{
  echo "fixpermissions: $@"
}

for arg in "$@"; do
  case "$arg" in
    -*)
      case "$arg" in
        -t)
          traverse=1
          shift
          ;;
        *)
          echo "bad flag '$arg'"
          exit
          ;;
        esac
        ;;
    *)
      path="$arg"
      havepath=1
      ;;
  esac
done

if [[ "$havepath" == 1 ]]; then
  if [[ ! -e "$exe_cacls" ]]; then
    echo "'fixpermissions' is meant for Cygwin and MINGW only." >&2
    echo "sorry!" >&2
    exit 1
  fi
  path="$(cygpath -wa "$path")"
  args=(/g "$username":f /c)
  if [[ "$traverse" == 1 ]]; then
    args+=(/t)
  fi
  printf "running [%s] ...\n" "cacls \"$path\" ${args[*]}"
  # create some kind of sensible name to be used for the logfile template
  basepath="$(basename "$path" | sed -e 's/[^A-Za-z0-9._-]/_/g;s/^_//g;s/_$//g')"
  logpath="$(mktemp -tu "fixpermissions.$username.$basepath.XXXXXXXXXX.log")"
  #logpath="/tmp/fixpermissions.$username.$basepath.log"
  logm "this file was created by \"$0\", and can be safely deleted." >> "$logpath"
  logm "started: $(date)" >> "$logpath"
  logm "command: <cacls \"$path\" ${args[@]}>" >> "$logpath"
  # get rid of carriage returns and turn backward slashes into forward slashes
  echo "$LANG_ANS_YES" | "$exe_cacls" "$path" "${args[@]}" | perl -pe 's/\r$//g; s#\\#/#g' | while read line; do
    # ignore the 'are you sure' line
    if ! grep -P '^Are\ you\ sure' <<< "$line" > /dev/null; then
      tee -a "$logpath" <<< "$line"
    fi
  done
  logm "finished: $(date)" >> "$logpath"
  echo "logfile located at \"$logpath\""
else
  echo "usage: $0 [-t] <path>"
  echo "the '-t' flag enables recursively applying permissions"
fi

