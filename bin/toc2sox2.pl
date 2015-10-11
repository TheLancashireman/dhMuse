#!/usr/bin/perl -w

use dhMuseToc;

my $DBG=0;

if ( ! defined $ARGV[0] )
{
	die "Usage: toc2sox.pl TOC-file";
}

my $tocname = $ARGV[0];

my @sox_cmds = toc_to_sox($tocname);

foreach $cmd ( @sox_cmds )
{
	print STDOUT $cmd."\n" if ( defined $cmd );
}

$d = @sox_cmds;
print STDOUT "$d elements in the array.\n";

exit 0;
