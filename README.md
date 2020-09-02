
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


`7zls`:
A convenience wrapper around `7z l -ba -slt`, parsing its output, allowing listing to be `grep`'d, `sort`ed, etc...


`a2asm`:
A convenience wrapper around ndisasm. disassemble anything! output is often nonsense, obviously.


`a2mp4`:
A convenience wrapper around ffmpeg, to quickly convert (ymmv) video files to mp4.


`autogdb`:
A convenience wrapper around gdb, that runs given program and its arguments, prints the backtrace, and quits.  
Useful for heisenbugs.


`autolldb`:
Same as autogdb, except for lldb.


`cget`:
A convenience wrapper around curl, that makes curl behave like wget.

`cgvars`:
A convenience wrapper around ctags, to quickly print out global variables in a C source file.

`cls`:
A somewhat portable means of clearing a Terminal. unlike 'clear', it will actually also reset the Terminal.

`copyperms`:
Copy permissions from one path to another.


`counttypes`:
Count mime types of files.


`cppex`:
Expands preprocessor instructions in a C, or C++ source file by means of the C, or C++ compiler.  
Useful for source inspection.


`crc32`:
Calculate and print the crc32 value of input.


`curse`:
Search cursewords. Wrote it *ages* ago while grepping Linux sources. Probably not very useful nowadays.


`defines2enum`:
Turns `#define`s into `enum`s. For example:
```
defines2enum - <<'__eos'
#define foo 32
#define blah 7
    # define somethingelse 43 << 32
__eos
->
foo = 32,
blah = 7,
somethingelse = 43 << 32,
```
... which can then be copied into an `enum`.


`dotify`:
Turns nasty, no good, very bad characters in filenames into dots. For example, `blah foo [quux] (stuff).doc` becomes `blah.foo.quux.stuff.doc`.  
Useful for serving files over HTTP.

`edit`:
A convenience script, to call your favorite $EDITOR with files as arguments.


`fcomp`:
Like `diff`, but slightly more targeted towards humans.

`ffind`:
Like `find`, for when you got tired of typing out `-iname ... -o -iname ... -o -iname ...` a few hundred times.


`findpseudolinks`:
Given a directory, attempts to find files that were supposed to be symbolic links, but got mangled by NTFS to be regular files.


`fixext`:
Attempts to fix the file extension of a file by looking at its mime type.


`fixsrc`:
A tool that attempts to fix broken, ancient source code. May actually make things worse. Use at your own risk!


`fmtls`:
Reads, and attempts to parse a listing produced by `ls -lR`. Bug-prone.


`gendomains`:
Generates a list of domains given a list of tlds via `-t`, and a list of names. For example:
```
gendomains -t de,eu foo
foo.com
foo.net
foo.org
foo.de
foo.eu
```

`gif2webm`:
Convert gifs to webm. Might be buggy.


`grepemails`:
Searches files for email addresses. Chance of false positives.


`grepstrings`:
Searches files for enclosed strings (i.e., `"this stuff"`, or `'this'` ...).  
Useful for inspecting source code.


`ipinfo`:
Dumps a bit of info about a given IP, or hostname.


`ls-octal`:
Print a directory listing, but with permission as octal numbers.


`lsargs`:
Prints given args. Useful for testing how a shell expands patterns.


`lsext`:
Lists a directory sorted by its extensions. A bit like ye olde `DIR` command from pre-NT MS-DOS.


`mvmerge`:
Merge two, or more directories.

`mvsingle`:
Move single items from a directory down one level. For example, given the path `foo/bar/baz`, where `baz` is the only item in `bar`,
`baz` is moved to `foo`, and `bar` deleted. It's very niche, but has its uses.


`myip`:
Print your IP address(es). Use `-4` for ipv4, and `-6` for ipv6. By defaults, prints both.


`n2word`:
Uses the linguistics gem to spell out a number. For example:
```
n2word 3992302
3992302: three million, nine hundred and ninety-two thousand, three hundred and two
```


`nargs`:
Like `xargs`, but explicitly parses line-by-line, whereas `xargs` parses by whitespace (which makes it unnecessarily complicated to use for files with spaces in them. Or parentheses.)  
Has *most* of `xarg`'s useful features, but also very basic concurrency. I use it every day, and thus it's fairly well tested.  
TODO for the future: Rewrite in C (or rather, C++).

`nato`:
Spells out text as NATO alphabet. Example:
```
nato <<<hello
HOTEL ECHO LIMA LIMA OSCAR 
```


`new`:
More specifically meant for cygwin, creates empty file(s), and inserts 1 (one) linefeed. This is because some programs
immediately interpret empty files to use CRLF, instead of LF.

`nless`:
Same as `less`, but if it's an URL, retrieve it first.


`open`:
A slightly more portable version of `xdg-open`, `start`, etc.


`pargs`:
Print arguments of a process by pid. Basically useless on cygwin, sadly.


`pathglob`:
Searches $PATH for a given pattern.

`pdf2txt`:
Retrieves text from a pdf.


`perl2c`:
Wrapper around B::, that turns a perl script in its perl C API equivalents. Similar to `lua2c`.


`perldeparse`:
Wrapper around B::, that deparses a perl script. Can make some less-than-readable scripts slightly more readable.


`perlmodpath`:
Print out where perl is looking for a module.


`perltrace`:
Trace execution of a perl script.


`rand`:
Generates random values. Uses ruby's `securerandom`.

`randtext`:
Generates random text.


`rar2zip`:
Converts a rar file to zip. Useful for converting `.cbr` to `.cbz`.



`rglob`:
text for rglob goes here


`rowgen`:
text for rowgen goes here


`sdu`:
text for sdu goes here


`show`:
text for show goes here


`skip`:
text for skip goes here


`sortwords`:
text for sortwords goes here


`spawn`:
text for spawn goes here


`sprint`:
text for sprint goes here


`spsuggest`:
text for spsuggest goes here


`tochars`:
text for tochars goes here


`ugrep`:
text for ugrep goes here


`unbreak`:
text for unbreak goes here


`unistr`:
text for unistr goes here


`unpackall`:
text for unpackall goes here


`unzlib`:
text for unzlib goes here


`urldecode`:
text for urldecode goes here


`urldump`:
text for urldump goes here


`urlencode`:
text for urlencode goes here


`urlgrep`:
text for urlgrep goes here


`urlidn`:
text for urlidn goes here


`whoisdom`:
text for whoisdom goes here


`winegrepstrings`:
text for winegrepstrings goes here


`wrun`:
text for wrun goes here


`xmap`:
text for xmap goes here


`xmlmerge`:
text for xmlmerge goes here


`xorcrypt`:
text for xorcrypt goes here


