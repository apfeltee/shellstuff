#!/bin/zsh -x

localroot="cloud/local/code/programs/Alter-Native"

if [[ -d "/cygdrive/c" ]]; then
  iscygwin=1
  altroot="c:/$localroot"
else
  iscygwin=0
  altroot="/mnt/c/$localroot"
fi

init="$altroot/alternative-init.sh"
exe="$altroot/AlterNative.Core.bin/bin/Debug/AlterNative.Core.exe"
#exe="$altroot/AlterNative/obj/Debug/AlterNative.Core.exe"
shellscript="$altroot/Tools/ShellScripts/alternative"

#export ALTERNATIVE_TOOLS_PATH="$altroot/Tools"
#export ALTERNATIVE_BIN_PATH="$altroot/bin"
#echo "ALTERNATIVE_TOOLS_PATH = $ALTERNATIVE_TOOLS_PATH"

export ALTERNATIVE_HOME="$altroot"
export ALTERNATIVE_BIN_PATH="$altroot/AlterNative.Core.bin/bin/Debug"
export ALTERNATIVE_BIN="$altroot/AlterNative.Core.bin/bin/Debug/AlterNative.Core.exe"
export ALTERNATIVE_CPP_LIB_PATH="$altroot/Lib"
export ALTERNATIVE_TOOLS_PATH="$altroot/Tools"
export ALTERNATIVE_LIB_BUILD="$altroot/Lib/build"
export ALTERNATIVE_LIB_BIN="$altroot/Lib/build/bin"

if [[ "$iscygwin" == 1 ]]; then
  #"$exe" "$@"
  exec "$shellscript" "$@"
else
  #exec mono "$exe" "$@"
  exec "$shellscript" "$@"
fi


