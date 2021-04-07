#!/bin/bash

# this runs cpan, but skips tests.
# most tests are so pants-on-head retarded, they'll fail for the dumbest reasons,
# which in turn, causes *every other* module to fail as well.
#
# fun fact: it *used to* be possible to do
#
#  cpan force install Some::Dumb::Module
#
# where "install" and "force" are commands of/for the cpan shell.
# at some point, someone thought this was just too damn useful, and nixed it.
# (there are no command line option equivalents i know of, like '--force'. because y'know, perl.)
#
# seriously, cpan fucking sucks!
#

exec perl -MCPAN -e 'foreach (@ARGV) { CPAN::Shell->rematein("notest", "install", $_) }' "$@"

