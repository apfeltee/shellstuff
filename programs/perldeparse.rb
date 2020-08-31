#!/usr/bin/ruby

# i really, REALLY do not like perl. but it also feels wrong to do this in ruby.
#
require "optparse"
=begin
NAME
    B::Deparse - Perl compiler backend to produce perl code

SYNOPSIS
    perl -MO=Deparse[,-d][,-f*FILE*][,-p][,-q][,-l]
    [,-s*LETTERS*][,-x*LEVEL*] *prog.pl*

DESCRIPTION
    B::Deparse is a backend module for the Perl compiler that generates perl
    source code, based on the internal compiled structure that perl itself
    creates after parsing a program. The output of B::Deparse won't be
    exactly the same as the original source, since perl doesn't keep track
    of comments or whitespace, and there isn't a one-to-one correspondence
    between perl's syntactical constructions and their compiled form, but it
    will often be close. When you use the -p option, the output also
    includes parentheses even when they are not required by precedence,
    which can make it easy to see if perl is parsing your expressions the
    way you intended.

    While B::Deparse goes to some lengths to try to figure out what your
    original program was doing, some parts of the language can still trip it
    up; it still fails even on some parts of Perl's own test suite. If you
    encounter a failure other than the most common ones described in the
    BUGS section below, you can help contribute to B::Deparse's ongoing
    development by submitting a bug report with a small example.

OPTIONS
    As with all compiler backend options, these must follow directly after
    the '-MO=Deparse', separated by a comma but not any white space.

    -d  Output data values (when they appear as constants) using
        Data::Dumper. Without this option, B::Deparse will use some simple
        routines of its own for the same purpose. Currently, Data::Dumper is
        better for some kinds of data (such as complex structures with
        sharing and self-reference) while the built-in routines are better
        for others (such as odd floating-point values).

    -f*FILE*
        Normally, B::Deparse deparses the main code of a program, and all
        the subs defined in the same file. To include subs defined in other
        files, pass the -f option with the filename. You can pass the -f
        option several times, to include more than one secondary file. (Most
        of the time you don't want to use it at all.) You can also use this
        option to include subs which are defined in the scope of a #line
        directive with two parameters.

    -l  Add '#line' declarations to the output based on the line and file
        locations of the original code.

    -p  Print extra parentheses. Without this option, B::Deparse includes
        parentheses in its output only when they are needed, based on the
        structure of your program. With -p, it uses parentheses (almost)
        whenever they would be legal. This can be useful if you are used to
        LISP, or if you want to see how perl parses your input. If you say

            if ($var & 0x7f == 65) {print "Gimme an A!"}
            print ($which ? $a : $b), "\n";
            $name = $ENV{USER} or "Bob";

        "B::Deparse,-p" will print

            if (($var & 0)) {
                print('Gimme an A!')
            };
            (print(($which ? $a : $b)), '???');
            (($name = $ENV{'USER'}) or '???')

        which probably isn't what you intended (the '???' is a sign that
        perl optimized away a constant value).

    -P  Disable prototype checking. With this option, all function calls are
        deparsed as if no prototype was defined for them. In other words,

            perl -MO=Deparse,-P -e 'sub foo (\@) { 1 } foo @x'

        will print

            sub foo (\@) {
                1;
            }
            &foo(\@x);

        making clear how the parameters are actually passed to "foo".

    -q  Expand double-quoted strings into the corresponding combinations of
        concatenation, uc, ucfirst, lc, lcfirst, quotemeta, and join. For
        instance, print

            print "Hello, $world, @ladies, \u$gentlemen\E, \u\L$me!";

        as

            print 'Hello, ' . $world . ', ' . join($", @ladies) . ', '
                  . ucfirst($gentlemen) . ', ' . ucfirst(lc $me . '!');

        Note that the expanded form represents the way perl handles such
        constructions internally -- this option actually turns off the
        reverse translation that B::Deparse usually does. On the other hand,
        note that "$x = "$y"" is not the same as "$x = $y": the former makes
        the value of $y into a string before doing the assignment.

    -s*LETTERS*
        Tweak the style of B::Deparse's output. The letters should follow
        directly after the 's', with no space or punctuation. The following
        options are available:

        C   Cuddle "elsif", "else", and "continue" blocks. For example,
            print

                if (...) {
                     ...
                } else {
                     ...
                }

            instead of

                if (...) {
                     ...
                }
                else {
                     ...
                }

            The default is not to cuddle.

        i*NUMBER*
            Indent lines by multiples of *NUMBER* columns. The default is 4
            columns.

        T   Use tabs for each 8 columns of indent. The default is to use
            only spaces. For instance, if the style options are -si4T, a
            line that's indented 3 times will be preceded by one tab and
            four spaces; if the options were -si8T, the same line would be
            preceded by three tabs.

        v*STRING*.
            Print *STRING* for the value of a constant that can't be
            determined because it was optimized away (mnemonic: this happens
            when a constant is used in void context). The end of the string
            is marked by a period. The string should be a valid perl
            expression, generally a constant. Note that unless it's a
            number, it probably needs to be quoted, and on a command line
            quotes need to be protected from the shell. Some conventional
            values include 0, 1, 42, '', 'foo', and 'Useless use of constant
            omitted' (which may need to be -sv"'Useless use of constant
            omitted'." or something similar depending on your shell). The
            default is '???'. If you're using B::Deparse on a module or
            other file that's require'd, you shouldn't use a value that
            evaluates to false, since the customary true constant at the end
            of a module will be in void context when the file is compiled as
            a main program.

    -x*LEVEL*
        Expand conventional syntax constructions into equivalent ones that
        expose their internal operation. *LEVEL* should be a digit, with
        higher values meaning more expansion. As with -q, this actually
        involves turning off special cases in B::Deparse's normal
        operations.

        If *LEVEL* is at least 3, "for" loops will be translated into
        equivalent while loops with continue blocks; for instance

            for ($i = 0; $i < 10; ++$i) {
                print $i;
            }

        turns into

            $i = 0;
            while ($i < 10) {
                print $i;
            } continue {
                ++$i
            }

        Note that in a few cases this translation can't be perfectly carried
        back into the source code -- if the loop's initializer declares a my
        variable, for instance, it won't have the correct scope outside of
        the loop.

        If *LEVEL* is at least 5, "use" declarations will be translated into
        "BEGIN" blocks containing calls to "require" and "import"; for
        instance,

            use strict 'refs';

        turns into

            sub BEGIN {
                require strict;
                do {
                    'strict'->import('refs')
                };
            }

        If *LEVEL* is at least 7, "if" statements will be translated into
        equivalent expressions using "&&", "?:" and "do {}"; for instance

            print 'hi' if $nice;
            if ($nice) {
                print 'hi';
            }
            if ($nice) {
                print 'hi';
            } else {
                print 'bye';
            }

        turns into

            $nice and print 'hi';
            $nice and do { print 'hi' };
            $nice ? do { print 'hi' } : do { print 'bye' };

        Long sequences of elsifs will turn into nested ternary operators,
        which B::Deparse doesn't know how to indent nicely.
=end

# check 'perldoc B::Deparse' for other flags and what they do
# these options are for B::Deparse(), that is, they get forwarded
DEFOPTIONS = [
  ["-q", ["-q", "--qstrings"], "expands double-quoted strings"],
  ["-d", ["-d", "--dump"], "dumps data values when they're used as constants (such as strings)"],
  ["-p", ["-p", "--parens"], "adds additional parentheses"],
  ["-P", ["-n", "--noproto"], "disables prototype checking"],
]

def vsystem(cmd)
  $stderr.printf("cmd: %p\n", cmd)
  return system(cmd)
end

def deparse(opts, fh)
  sflags = opts.join(",")
  scmd = ["perl", "-MO=Deparse,#{sflags}"]
  if fh.is_a?(IO) then
    $stderr.printf("cmd: %p\n", scmd)
    IO.popen(scmd, "r+") do |io|
      io.write(fh.read)
      io.close_write
      puts(io.read)
    end
  else
    system([*scmd, fh])
  end
end

begin
  opts = []
  indlevel = 4
  syncon = 0
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-x<n>", "--expand=<n>", "expand syntax constructions where n can be 0..9"){|v|
      syncon = v.to_i
    }
    prs.on("-i<n>", "--indent=<n>", "indent with <n> spaces"){|v|
      indlevel = v.to_i
    }
    DEFOPTIONS.each do |inf|
      realopt = inf.shift
      ops = inf.shift
      desc = inf.shift
      prs.on(*ops, desc){
        opts.push(realopt)
      }
    end
  }.parse!
  opts.push(sprintf("-x%d", syncon))
  opts.push(sprintf("-si%d", indlevel))
  if ARGV.empty? then
    deparse(opts, $stdin)
  else
    ARGV.each do |arg|
      File.open(arg, "rb") do |fh|
        deparse(opts, fh)
      end
    end
  end
end


