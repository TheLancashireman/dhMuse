#!/usr/bin/perl -w

my $DBG=0;

my $cddbfile;
my $xmlfile;

if ( defined $ARGV[1] )
{
	$xmlfile = $ARGV[1];
	$cddbfile = $ARGV[0];
}
elsif ( defined $ARGV[0] )
{
	$xmlfile = $ARGV[0];
}
else
{
	die "Usage: cddb-to-xml.pl [CDDB-file] XML-file";
}

if ( defined $ARGV[1] )
{
	open(CDDBFILE, "<$cddbfile") or die "Cannot open $cddbfile for reading";
}
else
{
	die "Direct interface to cddb isn't supported yet";
}

open(XMLFILE, ">$xmlfile") or die "Cannot open $xmlfile for writing";

my $have_cd = 0;

while ( <CDDBFILE> )
{
	chomp;
	my $cddbline = $_;
	my ($keyword, $value);

	if ( (($keyword, $value) = $cddbline =~ m{^([^:]*): (.*)$}) == 2 )
	{
		if ( $keyword eq "Choose" )
		{
			if ( (($keyword, $value) = $value =~ m{^([^:]*): (.*)$}) == 2 )
			{
				$chosen = 1;
			}
		}

		if ( $chosen )
		{
			$value =~ s/\r//g;
			if ( $keyword eq "artist" )
			{
				print XMLFILE "<artist>$value</artist>\n";
			}
			elsif ( $keyword eq "title" )
			{
				print XMLFILE "<title>$value</title>\n";
			}
			elsif ( $keyword eq "year" )
			{
				print XMLFILE "<date>$value</date>\n";
			}
			elsif ( $keyword eq "cddbid" )
			{
				print XMLFILE "<source>CD</source>\n";
				print XMLFILE "\n";
				print XMLFILE "<cd cddbid=\"$value\">\n";
				$have_cd = 1;
			}
			else
			{
				my $trackno;

				if ( (($trackno) = $keyword =~ m{^track ([0-9]*)$}) )
				{
					print XMLFILE "<track trackno=\"$trackno\">$value</track>\n";
				}
			}
		}
	}
}

if ( $have_cd )
{
	print XMLFILE "</cd>\n";
}

exit 0;
