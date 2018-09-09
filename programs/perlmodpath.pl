#!/usr/bin/perl -T

use strict;
use warnings;
use File::Spec;

sub printitem
{
    my $item = shift;
    printf("%s\n", $item);
};

sub lsfiles
{
    my $dirname = shift;
    opendir(my $dirhandle, $dirname) || die("cannot opendir(\"$dirname\")");
    while((my $ent = readdir($dirhandle)))
    {
        next if ($ent =~ /^\.(\.?)$/);
        #my $fullpath = File::Spec->catpath($dirname, $ent);
        my $fullpath = ($dirname . "/" . $ent);
        # this will remove "/./" bits when $dirname is "."
        $fullpath =~ s/\/\.\//\//g;
        if(-f $fullpath)
        {
            printitem($fullpath);
        }
        elsif(-d $fullpath)
        {
            lsfiles($fullpath);
        }
        else
        {
            die("\"$fullpath\" is neither a file nor a directory?");
        };
    }
    closedir($dirhandle);
};

sub walkdir
{
    my $dirname = shift;
    lsfiles($dirname);
};

if(scalar(@ARGV) > 0)
{
    foreach my $modname (@ARGV)
    {
        $modname =~ s/::/\//g;
        foreach my $path (@INC)
        {
            my @modpaths = (
                sprintf("%s/%s", $path, $modname),
                sprintf("%s/%s.pm", $path, $modname),
            );
            foreach my $spath (@modpaths)
            {
                if((-e $spath) || (-f $spath) || (-d $spath))
                {
                    if(-f $spath)
                    {
                        printitem($spath);
                    }
                    else
                    {
                        walkdir($spath);
                    }
                }
            };
        };
    };
}
else
{
    printf("usage: perlmodpath <modname> [<anothermod> ...]\n");
    exit(1);
};
