#!/usr/bin/perl
use dhMuseXml
qw(	$xml_artist
	$xml_title
	$xml_subtitle
	$xml_date
	$xml_source

	%xml_disclist
	%xml_disctitle
	%xml_tracklist
	%xml_comments

	&dhxml_readfile
);

my $result = dhxml_readfile("SpaceRitual.xml");
my $vol = "";
my $track = "";

if ( $result eq "" )
{
	print STDOUT "CD information:\n";
	print STDOUT "  Artist:    $xml_artist\n";
	print STDOUT "  Album:     $xml_title\n";
	print STDOUT "  Subtitle:  $xml_subtitle\n" if ( $xml_subtitle ne "" );
	print STDOUT "  Date:      $xml_date\n" if ( $xml_date ne "" );
	print STDOUT "  Source:    $xml_source\n" if ( $xml_source ne "" );
	print STDOUT "\n";
	print STDOUT "  Volumes:\n";
	foreach $vol ( sort keys %xml_disclist )
	{
		print STDOUT "    $vol = \"$xml_disclist{$vol}\"\n";
	}
	print STDOUT "  Tracks:\n";
	foreach $track ( sort keys %xml_tracklist )
	{
		print STDOUT "    $track = \"$xml_tracklist{$track}\"\n";
	}
}
else
{
	print STDERR "dhxml_readfile() returned \"$result\"\n";
	exit 1;
}

exit 0;
