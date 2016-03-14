
A selection of shell programs, either too small or too trivial to warrant their own repositories.

Includes:

todo: comment these
./cygwin/clang
./cygwin/clang++
./cygwin/cygpackages
./cygwin/nmap
./cygwin/open
./cygwin/powershell
./cygwin/rar
./cygwin/runvbs
./cygwin/shortname
./cygwin/trash
./cygwin/unrar
./cygwin/winrar
./cygwin/_clangwrap.rb
./cygwin/_trash.ps1

### linux-specific scripts:

`./linux/clipboard`: A wrapper around KDE's klipper, using qdbus. Not exactly pretty, but does its job.

### programs written in a language that requires a compiler of sorts:

`./native/src/bin2c.cpp`: The well-known bin2c program. Nothing more. Might be rewritten in ruby. Eventually.

### interpreted, sort-of cross-platform scripts:

`./programs/c++-astprint`: A wrapper around clang's `-cc1 -ast-print` argument.

`./programs/coliru`: Allows to paste C++ directly to http://coliru.stacked-crooked.com/. Prints the result.

`./programs/countfiles`: Counts and sorts file extensions in the given directories. Great to get a rough statistic on source directories.

`./programs/curse`: Searches source directories for common curse words. Inspired by the Linux kernel source! :-)

`./programs/edit`: A silly little program that opens your favourite editor with the files given. Implies that your editor is single-instance. Must be edited prior to use!

`./programs/geturls`: Extract URLs from text. Reads from stdin by default.

`./programs/ipinfo`: Get information about IPs and/or domains.

`./programs/jsnice`: Interface to jsnice.org. Formats your javascript code nicely.

`./programs/ls-octal`: Prints octal file permissions.

`./programs/lsext`: List and sort files by extension. It's like `ls`, but sorts it by file extension first.

`./programs/myip`: Retrieves your public IP using OpenDNS.

`./programs/n2word`: Turn a numeric value into its wording (i.e., 100 => "one hundred"). Requires the 'linguistics' gem for ruby.

`./programs/pargs`: A dumb handwritten port of the pargs program from solaris. Usage: `pargs $(pgrep someprogram)`. Buggy.

`./programs/perl-deparse`: Wrapper around perls Deparse module. Formats and deparses perl, i.e., make it (potentially) more readable.

`./programs/ptidy`: Wrapper around the PHP binding of libtidy. Fun, isn't it? It's evil, but it works. Formats HTML.

`./programs/randtext`: Prints random, nonsensical text.

`./programs/rdisasm`: Disassembler for ruby code. Try running `rdisasm $(which rdisasm)`!

`./programs/tochars`: Like bin2c, it prints a comma-separated list of bytes off of stdin. Nothing more.

