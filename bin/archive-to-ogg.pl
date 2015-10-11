#!/usr/bin/perl -w
#
# archive-to-ogg.pl
#
# Usage:
#  archive-to-ogg.pl xml-file [config-file]
#
# Extracts tracks from the archive to separate ogg files, one per track, as specified in the xml-file
# The track data are loaded from TOC files names <xml-name>-<volume>.toc or <xml-name>.toc if single-volume.
#
# (c) 2015 David Haworth

use dhMuse;
use dhMuseXml;
use dhMuseToc;

my $DBG = 1;

my $jukebox = "/net/jukebox";

# Get name of XML file and check that it exists
my $xmlfile = $ARGV[0];

if ( ! defined $xmlfile )
{
	print STDERR "Usage: archive-to-ogg.pl xml-file [config-file]\n";
	exit 0;
}

if ( ! -r $xmlfile )
{
	die "$xmlfile does not exist or is not readable";
}

# Get name of config file if specified, and check that it exists
my $cfgfile = $ARGV[1];

if ( defined $cfgfile && ! -r $cfgfile )
{
	die "$cfgfile does not exist or is not readable";
}

# Read in the XML file and report any errors.
my $result = dhxml_readfile($xmlfile);

if ( $result ne "" )
{
	die $result;
}

# Set up global artist, album and output directory. The real artist might change ...
$artist = $xml_artist;
$album	= $xml_title;
$filedir = undef;

# Evaluate the contents of the config file. This could set encoding options, bitrate, etc.
if ( defined $cfgfile )
{
	print STDERR "Importing settings from $cfgfile\n" if ( $DBG >= 1 );
	eval `cat $cfgfile`;
}

if ( ! defined $filedir )
{
	$filedir = $jukebox;
	if ( $jukebox ne "" )
	{
		$filedir .= "/";
	}
	$filedir .= fileify($artist) . "/" . fileify($album);
}

my $vol = "";
my $track = "";

foreach $vol ( sort keys %xml_disclist )
{
	# Construct the name of the toc file.
	my $tocfile = $xmlfile;
	$tocfile =~ s/\.xml$//;
	$tocfile .= "-$vol" if ( $vol ne "!" );
	$tocfile .= ".toc";

	# Generate sox commands from all the toc entries. Element 0 of the array is empty.
	my @sox_cmds = toc_to_sox($tocfile);

	my $trkno = 1;

	while ( defined $xml_tracklist{$vol . ":" . $trkno} )
	{
		my $track = $vol . ":" . $trkno;

		$artist	= $xml_artist;

		#print STDERR "cd_to_ogg($trkno, $xml_tracklist{$track});\n";
		if ( defined $xml_trackfile{$track} )
		{
			$filename =  $xml_trackfile{$track};
		}

		pipe_to_ogg($sox_cmds[$trkno], $trkno, $xml_tracklist{$track});

		$trkno++;
	}

	$trackplus += $trkno - 1;
}

exit 0;
