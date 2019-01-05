#!/bin/bash

#set -x
progname="$(basename "$0")"

function deparse
{
  # flags:
  # -q    expands double-quoted strings
  # -d    dumps data values when they're used as constants (such as strings)
  # -p    adds additional parentheses
  # -P    disables prototype checking
  # -si4  indents with 4 spaces
  # -x<n> expand syntax constructions
  #
  # check 'perldoc B::Deparse' for other flags and what they do
  #
  flags="-q,-d,-x1,-P,-si4"
  perl -MO=Deparse,$flags "$@"
}

function usage
{
  echo "perl-deparse -- Deparses Perl code using B::Deparse"
  echo "useful for deciphering obfuscated Perl code!"
  echo
  echo "Usage:"
  echo "   $progname -e <code>     : deparses <code> as single line of code"
  echo "   $progname <file>        : deparses <file> and prints the result to stdout"
  echo "   cat <file> | $progname  : reads from stdin and prints the result to stdout"
  echo
  echo "examples:"
  echo "   $progname -e 'print(do{q{Hello World}} or 0);'"
  echo "   $progname japh.pl"
  echo "   perl script-that-generates-code.pl | $progname"
  echo
}

if [[ $1 ]]; then
  case "$1" in
    -h|--help)
      usage
      exit
      ;;
    -e)
      shift
      deparse -e "$@"
      exit
      ;;
  esac
  deparse "$@"
elif [[ -t 1 ]] || true; then
  # interactive
  deparse
fi
