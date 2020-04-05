#!/usr/bin/perl -d:DumpTrace

# this is a really weird hack, that lets you trace perl.
# obviously needs Devel::DumpTrace.

BEGIN {
    use Devel::DumpTrace;
    Devel::DumpTrace->import();
    $Devel::DumpTrace::TRACE = 0;
    #printf("hello\n");
    #$Devel::DumpTrace::DUMPTRACE_COLOR = Term::ANSIColor::color("bold yellow on_black");
    #$Devel::DumpTrace::DUMPTRACE_RESET = Term::ANSIColor::color("reset");
}


no warnings 'uninitialized';
#use strict;
#use warnings;
#use autodie;
#use diagnostics;
use Devel::DumpTrace;
# there's a bug(?) in Devel::DumpTrace::PPI that complains a little bit
#use Term::ANSIColor;
#use Data::Dumper;
use File::Spec;
use Getopt::Long qw{:config bundling no_ignore_case no_auto_abbrev};


sub _wrap
{
    my $isfile = shift;
    my $input = shift;
    my $level = shift;
    my @nargv = shift;
    if($isfile)
    {
        if(-f $input)
        {
            $input = File::Spec->rel2abs($input);
        }
        else
        {
            die(sprintf("no such file: %s", $input));
        }
    }
    do {
        if($isfile)
        {
            local $Devel::DumpTrace::TRACE = $level;
            do $input;
        }
        else
        {
            local $Devel::DumpTrace::TRACE = $level;
            eval($input);
        }
    }
}

sub __main__
{
    my $i;
    my $arg;
    my $input;
    my $isfile;
    my $data;
    my $logfile;
    my $level = 3;
    GetOptions(
        "level|l=i"     => \$level,
        "e|eval|exec=s" => \$data,
        "o|log=s"       => \$logfile
    ) or die(
        "error parsing command line options!\n".
        "you may need to terminate commandling e \n"
    );
    if(defined($data))
    {
        $isfile = 0;
        $input = $data;
    }
    else
    {
        $isfile = 1;
        $input = shift(@ARGV);
    }
    if(!defined($input))
    {
        printf("usage: perltrace <scriptfile> <scriptarguments>...\n");
        exit(1);
    }
    if(defined($logfile))
    {
        #$Devel::DumpTrace::DUMPTRACE_COLOR = undef;
        #$Devel::DumpTrace::DUMPTRACE_RESET = undef;
        open($Devel::DumpTrace::DUMPTRACE_FH, '>', $logfile) or die(sprintf("cannot open %s for writing", $logfile));
    }
    my @newargv = @ARGV;
    _wrap($isfile, $input, $level, \@newargv);
}

&__main__;


