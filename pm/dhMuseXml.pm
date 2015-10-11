#!/usr/bin/perl
#
# dhMuseXml.pm
#
# A simple Perl package for handling dhMuse XML files.
#
# (c) 2008 David Haworth
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
# <lp side="N">DISC CONTENT</lp>
# <tape side="N">DISC CONTENT</tape>
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

package dhMuseXml;

use HTML::Parser;
use Exporter;
@ISA = qw(Exporter);
@EXPORT =
qw(
	$xml_artist
	$xml_artistdir
	$xml_title
	$xml_titledir
	$xml_subtitle
	$xml_date
	$xml_source

	%xml_disclist
	%xml_disctitle
	%xml_tracklist
	%xml_trackfile
	%xml_comments

	&dhxml_readfile
	&dhxml_reset
);

my $DBG = 0;	# Set to >0 to get reams of diagnostics (higher $DBG = more reams)

$xml_artist		= "";
$xml_artistdir	= "";
$xml_title		= "";
$xml_titledir	= "";
$xml_subtitle	= "";
$xml_date		= "";
$xml_source		= "";
%xml_disclist	= ();
%xml_disctitle	= ();
%xml_tracklist	= ();
%xml_trackfile	= ();
%xml_comments	= ();

my $errormsg	= "";
my $outertag	= "";
my $innertag	= "";
my $lineno		= 0;

my $vol			= "";
my $voltitle	= "";
my $trackno		= 0;
my $trackname	= "";
my $trackfile	= "";

sub dhxml_reset
{
	$xml_artist		= "";
	$xml_artistdir	= "";
	$xml_title		= "";
	$xml_titledir	= "";
	$xml_subtitle	= "";
	$xml_date		= "";
	$xml_source		= "";
	%xml_disclist	= ( );
	%xml_disctitle	= ( );
	%xml_tracklist	= ( );
	%xml_trackfile	= ( );
	%xml_comments	= ( );
}

sub dhxml_readfile
{
	my ($xmlname) = @_;

	dhxml_reset();

	$errormsg		= "";
	$outertag		= "";
	$innertag		= "";
	$lineno			= 0;
	$trackno		= 0;
	$trackname		= "";

	if ( open(XMLFILE, "<$xmlname") )
	{
		my $p = HTML::Parser->new(
						start_h => [\&dhxml_tag,	"tagname, attr"],
						end_h   => [\&dhxml_endtag,	"tagname"],
						text_h  => [\&dhxml_text,	"dtext"]
					  );
		$p->xml_mode(1);
		$lineno = 0;

		LINE: while ( <XMLFILE> )
		{
			my $line = $_;
			print STDERR "XML text:\n$line\n" if ( $DBG >= 10 );
			$lineno++;
			$p->parse($line);
			last LINE if ( $errormsg ne "" );
		}

		close(XMLFILE);
	}
	else
	{
		$errormsg	= "Unable to open $xmlname for reading.";
	}

	return $errormsg;
}

sub dhxml_tag
{
	my ($tagname, $attref) = @_;

	if ( $tagname eq "artist" ||
		 $tagname eq "subtitle" ||
		 $tagname eq "date" ||
		 $tagname eq "cd" ||
		 $tagname eq "lp" ||
		 $tagname eq "tape" ||
		 $tagname eq "source" )
	{
		# Outer tags only
		if ( $outertag ne "" )
		{
			$errormsg = "$tagname found inside $outertag in line $lineno";
		}
		else
		{
			$outertag = $tagname;

			if ( $tagname eq "artist" )
			{
				if ( defined $attref->{"filename"} )
				{
					$xml_artistdir = $attref->{"filename"}
				}
			}
			elsif ( $tagname eq "cd" || $tagname eq "lp" || $tagname eq "tape" )
			{
				my $id = $attref->{"cddbid"};
				$id = "" if ( !defined $id );

				$vol = $attref->{"vol"};
				$vol = $attref->{"side"} if ( !defined $vol );
				$vol = "!" if ( !defined $vol );
				$voltitle = "";

				if ( defined $xml_discid{$vol} )
				{
					if ( $vol eq "!" )
					{
						$errormsg = "More than one cd/lp/tape with unspecified vol/side in line $lineno";
					}
					else
					{
						$errormsg = "cd/lp/tape with vol/side $vol already used in line $lineno";
					}
				}
				else
				{
					$xml_disclist{$vol} = $id;
				}
			}
		}
	}
	elsif ( $tagname eq "title" ||
			$tagname eq "comment" )
	{
		# Outer or inner tags
		if ( $outertag eq "" )
		{
			$outertag = $tagname;

			if ( $tagname eq "title" )
			{
				if ( defined $attref->{"filename"} )
				{
					$xml_titledir = $attref->{"filename"}
				}
			}
		}
		elsif ( $outertag eq "cd" ||
				$outertag eq "lp" ||
				$outertag eq "tape" )
		{
			$innertag = $tagname;
		}
		else
		{
			$errormsg = "$tagname nested incorrectly inside $outertag in line $lineno";
		}
	}
	elsif ( $tagname eq "track" )
	{
		if ( $outertag eq "" )
		{
			$errormsg = "$tagname found outside cd/lp/tape in line $lineno";
		}
		elsif ( $outertag eq "cd" ||
				$outertag eq "lp" ||
				$outertag eq "tape" )
		{
			$innertag = $tagname;

			if ( defined $attref->{"trackno"} )
			{
				$trackno = $attref->{"trackno"};
				$trackname = "";
				$trackfile = $attref->{"filename"};
			}
			else
			{
				$errormsg = "Track with unspecified trackno found in line $lineno";
			}
		}
		else
		{
			$errormsg = "$tagname nested incorrectly inside $outertag in line $lineno";
		}
	}
	else
	{
		$errormsg = "Unknown closing $tagname found in line $lineno";
	}
}

sub dhxml_endtag
{
	my ($tagname) = @_;

	if ( $tagname eq "artist" ||
		 $tagname eq "subtitle" ||
		 $tagname eq "date" ||
		 $tagname eq "cd" ||
		 $tagname eq "lp" ||
		 $tagname eq "tape" ||
		 $tagname eq "source" )
	{
		# Outer tags only
		if ( $outertag eq $tagname )
		{
			$outertag = "";
		}
		else
		{
			$errormsg = "Tag mismatch: closing $tagname in line $lineno";
		}

		if ( $tagname eq "cd" || $tagname eq "lp" || $tagname eq "tape" )
		{
			if ( $voltitle ne "" )
			{
				$xml_disctitle{$vol} = $voltitle;
			}
		}
	}
	elsif ( $tagname eq "title" ||
			$tagname eq "comment" )
	{
		# Outer or inner tags
		if ( $innertag eq "" )
		{
			if ( $outertag eq $tagname )
			{
				$outertag = "";
			}
			else
			{
				$errormsg = "Tag mismatch: closing $tagname in line $lineno";
			}
		}
		elsif ( $innertag eq $tagname )
		{
			$innertag = "";
		}
		else
		{
			$errormsg = "Tag mismatch: closing $tagname in line $lineno";
		}
	}
	elsif ( $tagname eq "track" )
	{
		if ( $innertag eq $tagname )
		{
			$innertag = "";
			$xml_tracklist{$vol.":".$trackno} = $trackname;
			if ( defined $trackfile )
			{
				$xml_trackfile{$vol.":".$trackno} = $trackfile;
			}
		}
		else
		{
			$errormsg = "Tag mismatch: closing $tagname in line $lineno";
		}
	}
	else
	{
		$errormsg = "Unknown closing $tagname found in line $lineno";
	}
}

sub dhxml_text
{
	my ($content) = @_;

	# Remove CRs and LFs, and all leading and trailing spaces.
	#$content =~ s/\r//g;
	#$content =~ s/\n/ /g;
	#$content =~ s/^ *//;
	#$content =~ s/ *$//;

	print STDERR "Content: \"$content\" tag: $outertag/$innertag\n" if ($DBG>10);

	if ( $outertag eq "artist" )
	{
		$xml_artist = $xml_artist . $content;
	}
	elsif ( $outertag eq "title" )
	{
		$xml_title = $xml_title . $content;
	}
	elsif ( $outertag eq "subtitle" )
	{
		$xml_subtitle = $xml_subtitle . $content;
	}
	elsif ( $outertag eq "date" )
	{
		$xml_date = $xml_date . $content;
	}
	elsif ( $outertag eq "source" )
	{
		$xml_source = $xml_source . $content;
	}
	elsif ( $outertag eq "comment" )
	{
		# FIXME: comments ignored for now
	}
	elsif ( $outertag eq "cd" || $outertag eq "lp" || $outertag eq "tape" )
	{
		if ( $innertag eq "title" )
		{
			$voltitle = $voltitle . $content;
		}
		elsif ( $innertag eq "track" )
		{
			$trackname = $trackname . $content;
		}
	}
}

1;

# Editor settings: DO NOT DELETE
# vi:set ts=4:
