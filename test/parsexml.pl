#!/usr/bin/perl -w
#
# xml-to-xxx.pl
#
# This script reads the xml info files and ???
#
# (c) 2008 David Haworth
#
# Usage: ???
#
# The XML file accompanying each music archive has the following tags:
#
# <artist>NAME OF ARTIST</artist>
# <title>NAME OF ALBUM</title>
# <subtitle>OPTIONAL SUBTITLE OF ALBUM</subtitle>
# <date>DATE AS YYYY OR YYYY MM DD</date>
# <source medium="MEDIUM">OWNER, EXTRA COMMENTARY</source>
# <comment>SOME COMMENT TEXT</comment>
# <cd vol="N" cddbid="CDDB-ID">DISC CONTENT</cd>
# <lp side="N">TRACK LIST</lp>
# <tape side="N">TRACK LIST</tape>
# cd, lp and tape are synonymous, as are vol and side attributes in these tags.
# The medium attribute for source can be CD, LP, TAPE, TAPE-LP, TAPE-CD ...
# TAPE means prerecorded, TAPE-xx is a tape copy of some other source.
# 2nd and subsequent generation copies are hidden but can be mentioned in the
# text, as can the tape machine used (tck81 etc)
#
# DISC CONTENT is one or more track tags:
# <track trackno="N">NAME OF TRACK</track>
# DISC CONTENT can also contain a title!
#
# The artist, title, cd/lp/tape and track tags can also have an optional
# filename attribute to specify the file or directory name to use. If this
# is absent a name will be generated from the content of the tag. In the
# case of a track filename, the track number will be prepended. In the
# case of cd/lp/tape the vol/side will be appended when looking for
# wave/flac archives.

use HTML::Parser;

my $DBG = 1;	# Set to >0 to get reams of diagnostics (higher $DBG = more reams)

print STDERR "Usage: $0 errordb.xml Os_error.h docfile.xml\n" and exit
	if ( !defined $ARGV[0] || ! -f $ARGV[0] || ! -f $ARGV[1] );

$xmlname = $ARGV[0];
$optsname = $ARGV[1];

$xmlname =~ m/\.xml$/ or die "XML file name does not end in .xml\n";

open(XMLFILE, "<$xmlname") or die "Unable to open $dbname for reading\n";

my ($mm, $hh, $DD, $MM, $YY) = (localtime(time))[1,2,3,4,5];

my $genyear = sprintf("%04d", ($YY+1900));
my $gendate = sprintf("%04d-%02d-%02d %02d:%02d", ($YY+1900), ($MM+1), $DD, $hh, $mm);

$p = HTML::Parser->new(	start_h => [\&tag,		"tagname, attr"],
						end_h   => [\&endtag,	"tagname"],
						text_h  => [\&text,		"dtext"]
					  );
$p->xml_mode(1);
$p->parse_file(*XMLFILE);

close(XMLFILE);

exit $returncode

sub tag
{
	my ($tagname, $attref) = @_;

	if ( $tagname eq "artist" )
	{
	}
	elsif ( $tagname eq "title" )
	{
	}
	elsif ( $tagname eq "subtitle" )
	{
	}
	elsif ( $tagname eq "date" )
	{
	}
	elsif ( $tagname eq "comment" )
	{
	}
	elsif ( $tagname eq "source" )
	{
	}
	elsif ( $tagname eq "cd" || $tagname eq "lp" || $tagname eq "tape" )
	{
		if ( !defined ($attref->{"vol"}) )
	}
	elsif ( $tagname eq "track" ) {
	}
}

sub endtag
{
	my ($tagname) = @_;

	if ( $tagname eq "artist" )
	{
	}
	elsif ( $tagname eq "title" )
	{
	}
	elsif ( $tagname eq "subtitle" )
	{
	}
	elsif ( $tagname eq "date" )
	{
	}
	elsif ( $tagname eq "comment" )
	{
	}
	elsif ( $tagname eq "source" )
	{
	}
	elsif ( $tagname eq "cd" || $tagname eq "lp" || $tagname eq "tape" )
	{
	}
	elsif ( $tagname eq "track" )
	{
	}
	else
	{
	}
}

sub text
{
	my ($content) = @_;

	# Remove CRs and LFs, and all leading and trailing spaces.
	$content =~ s/\r//g;
	$content =~ s/\n/ /g;
	$content =~ s/^ *//;
	$content =~ s/ *$//;

	print STDERR "Content: \"$content\" tag: $innerTag\n" if ($DBG>10);

	if ( $outerTag == $TAG_description ) {
		if ( $description eq "" ) {
			$description = $content;
		} else {
			$description = $description . " " . $content;
		}
	} elsif ( $innerTag == $TAG_action ) {
		# STANDARD tags (if present) are ignored. As are any others.
		if ( $mode eq "UNIVERSAL" ) {
			$stdAction = $content;
		} elsif ( $mode eq "EXTENDED" ) {
			$extAction = $content;
		}
	} elsif ( $innerTag == $TAG_result ) {
		# STANDARD tags (if present) are ignored. As are any others.
		if ( $mode eq "UNIVERSAL" ) {
			$stdResult = $content;
		} elsif ( $mode eq "EXTENDED" ) {
			$extResult = $content;
		}
	}
}

# Editor settings: DO NOT DELETE
# vi:set ts=4:
