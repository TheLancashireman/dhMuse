#!/usr/bin/perl
#
#	ripcd.pm
#
#	A simple Perl package to make ripping CDs to MP3 easier.
#
#	For simple cases, set $artist and $album as required, also
#	perhaps $genre and $year, then call rip_and_tag(track, title);
#	for each track you want to rip.
#	More complicated things can be done by setting the public variables
#	at appropriate times between calls to rip_and_tag. All the variables
#	except $filename retain their values. $filename is set back to
#	"AUTO" at the end of rip_and_tag, to avoid inadvertently overwriting
#	the file.
#
# Global variables
#	$filename		# Name of ogg/mp3 output file (AUTO = invent from title)
#	$filedir		# Where to put the encoded ogg/mp3 files (generated filename)
#	$trackplus		# Added to track no when generating output file name.
#                     (Can be used for riiping double CDs)
#	$artist			# ID3 artist field
#	$album			# ID3 album field
#	$note			# ID3 note/comment field
#	$year			# ID3 year field
#	$genre			# ID3 genre field
#	$bitrate		# MP3 bitrate for lame
#	$lame_opts		# Other options for lame
#	$device			# CD device for cdparanoia
#	$paranoia_opts	# Other options for cdparanoia
#	$quality		# Quality for oggenc
#	$ogg_opts		# Other options for oggenc
#	$wave_dir		# Where to find .wav files to encode
#	$wave_prefix	# Prefix (before track no) of .wav file
#	$wave_suffix	# Suffix (after track no.) of .wav file
#	$dummy_run		# If non-zero, just print what would be done, don't do it..
#	%tracklist		# List of tracks (no => title) used if trackno undefined.
#
# Functions (please use these in preference)
#	&cd_to_ogg		# Rip CD, encode to ogg-vorbis and tag it
#	&cd_to_mp3		# Rip CD, encode to mp3 and tag it
#	&wav_to_ogg		# Convert wave file to ogg and tag it
#	&wav_to_mp3		# Convert wave file to mp3 and tag it
#	&tag_mp3		# Tag an existing mp3 file (uses id3hack)
#	&wait_for_CR	# Print a message and wait for user to press ENTER
#
#	(c) 2008 David Haworth
package dhMuse;
use Exporter;
@ISA = qw(Exporter);
@EXPORT =
qw(
	$filename
	$filedir
	$trackplus
	$artist
	$album
	$note
	$year
	$genre
	$bitrate
	$lame_opts
	$device
	$paranoia_opts
	$quality
	$ogg_opts
	$wave_dir
	$wave_prefix
	$wave_suffix
	$dummy_run
	%tracklist

	&cd_to_ogg
	&cd_to_mp3
	&wav_to_ogg
	&wav_to_mp3
	&tag_mp3
	&wait_for_CR
);

# Public variables.
$filename		= "AUTO";
$filedir		= "";
$trackplus		= 0;
$artist			= "";
$album			= "";
$note			= "";
$year			= "";
$genre			= 12;	# "Other"

$bitrate		= 192;
$lame_opts		= "";

$quality		= 7;	# Ogg quality (-1 .. 10)
$ogg_opts		= "";

$device			= "/dev/cdrom";
$paranoia_opts	= "";

$wave_dir		= "";
$wave_prefix	= "track";
$wave_suffix	= ".cdda.wav";

$dummy_run		= "";

%tracklist		= ();

# Private
my $DBG = 0;

# iterate_tracks
# (INTERNAL)
#	- does <whatever> for all tracks in %tracklist
sub iterate_tracks
{
	my ($whatever) = @_;
	my $trackno;

	foreach $trackno ( sort keys %tracklist )
	{
		print STDERR "Doing whatever($trackno, $tracklist{$trackno}\n" if ( $DBG >= 10 );
		&$whatever($trackno, $tracklist{$trackno});
	}
}

# isfilenamechar(c)
# (INTERNAL)
#	- returns non-zero if c is a character that is permitted in a filename.
#	 - 1 means alphabetic
#	 - 2 means non-alphabetic
sub isfilenamechar
{
	my ($c) = @_;
	return 0 if ( length($c) != 1 );
	return 1 if ( $c ge 'a' && $c le 'z' );
	return 1 if ( $c ge 'A' && $c le 'Z' );
	return 2 if ( $c ge '0' && $c le '9' );
	return 2 if ( $c eq '_' || $c eq '/' );
	return 0;
}

# iswordsep(c)
# (INTERNAL)
#	- returns non-zero if c is a word-separating character
sub iswordsep
{
	my ($c) = @_;
	return 0 if ( length($c) != 1 );
	return 1 if ( $c eq ' ' || $c eq '-' );
	return 1 if ( $c eq '(' || $c eq ')' );
	return 1 if ( $c eq '&' || $c eq '/' );
	return 1 if ( $c eq '_' );
	return 0;
}

# fileify(s)
# (INTERNAL)
#	- converts the string s (usually a title) into a filename by removing
#	  all the non-permitted characters and uppercasing the first character
#	  after each space.
sub fileify
{
	my ($t) = @_;
	my $i;
	my $c;
	my $f = "";
	my $first = 1;
	my $fnc;

	for ( $i = 0; $i < length($t); $i++ )
	{
		$c = substr($t, $i, 1);

		if ( iswordsep($c) )
		{
			$first = 1;
		}

		$fnc = isfilenamechar($c);

		if ( $fnc != 0 )
		{
			if ( $fnc == 1 && $first != 0 )
			{
				$c = uc($c);
				$first = 0;
			}
			$c = '-' if ( $c eq '/' );
			$f .= $c;
		}
	}
	return $f;
}

# get_filename
# (INTERNAL)
#	- returns the output filename, constructing if necessary.
#	- sets $filename to AUTO for next time round.
sub get_filename
{
	my ($trackno, $title, $suffix) = @_;
	my $sep = "";
	my $encfile = $filename;
	$filename = "AUTO";

	$sep = "/" if ( $filedir ne "" );

	if ( $encfile eq "AUTO" )
	{
		my $tno = $trackno + $trackplus;
		$encfile = $filedir.$sep.sprintf("%02d-",$tno).fileify($title).".".$suffix;
	}

	return $encfile;
}

# make_rip_cmd
# (INTERNAL)
#	- returns the command that rips a track from a CD to stdout.
sub make_rip_cmd
{
	my ($trackno) = @_;

	print STDERR "make_rip_cmd(".$trackno.")\n" if ($DBG != 0);

	return "cdparanoia -d ".$device." ".$paranoia_opts." ".$trackno." - ";
}

# make_mp3_cmd
# (INTERNAL)
#	- returns the command that encodes a wav stream on stdin to mp3
sub make_mp3_cmd
{
	my ($mp3file, $title, $trackno) = @_;
	my $cmd;

	print STDERR "make_mp3_cmd(".$mp3file.", ".$title.")\n" if ( $DBG != 0 );

	$cmd = "lame -b ".$bitrate." --quiet --tn ".$trackno." --tg ".$genre;
	$cmd .= " --tl \"".$album."\""	if ( $album ne "" );
	$cmd .= " --ta \"".$artist."\""	if ( $artist ne "" );
	$cmd .= " --tt \"".$title."\""	if ( $title ne "" );
	$cmd .= " --ty \"".$year."\""	if ( $year ne "" );
	$cmd .= " --tc \"".$note."\""	if ( $note ne "" );
    $cmd .= $lame_opts." - ".$mp3file;
}

# make_ogg_cmd
# (INTERNAL)
#	- returns the command that encodes a wav stream on stdin to ogg-vorbis
sub make_ogg_cmd
{
	my ($trackno, $title, $oggfile) = @_;

	my $cmd = "oggenc -q ".$quality." --quiet ".$ogg_opts.
			" -G ".$genre." -N ".$trackno;
	$cmd .= " -l \"".$album."\""	if ( $album ne "" );
	$cmd .= " -a \"".$artist."\""	if ( $artist ne "" );
	$cmd .= " -t \"".$title."\""	if ( $title ne "" );
	$cmd .= " -d \"".$year."\""		if ( $year ne "" );
	$cmd .= " -c \"".$note."\""		if ( $note ne "" );
	$cmd .= " -o ".$oggfile." -";

	return $cmd;
}

# make_cat_cmd
# (INTERNAL)
#	- returns the command that cats a wave file to stdout
sub make_cat_cmd
{
	my ($trackno) = @_;
	my $pad = "";
	my $dirchar = "";

	print STDERR "make_cat_cmd(".$trackno.")\n" if ($DBG != 0);

	$pad = "0" if ( $trackno < 10 );
	$dirchar = "/" if ( $wave_dir ne "" );

	my $cmd = "cat ".$wave_dir.$dirchar.$wave_prefix.$pad.$trackno.$wave_suffix;

	return $cmd;
}

# do_cmd
# (INTERNAL)
#	- echos the command to stdout and runs it unless dummy_run is "yes"
sub do_cmd
{
	my ($cmd) = @_;

	print $cmd."\n";
	if ( $dummy_run ne "yes" )
	{
		system $cmd;
	}

	return 0;
}

# rip_mp3
# (INTERNAL)
#	- rips a track and encodes as mp3
sub rip_mp3
{
	my ($trackno, $mp3file, $title) = @_;

	print STDERR "rip_mp3(".$trackno.", ".$mp3file.", ".$title.")\n" if ($DBG != 0);

	do_cmd("mkdir -p $filedir");

	my $cmd = make_rip_cmd($trackno) . " | " . make_mp3_cmd($mp3file, $title, $trackno);

	return do_cmd($cmd);
}

# tag_mp3
# (PUBLIC)
#	- tag an existing mp3 file
sub tag_mp3
{
	my ($mp3file, $title, $trackno) = @_;

	my $cmd =	"id3hack -g ".$genre." -n ".$trackno;
	$cmd .= " -l \"".$album."\""	if ( $album ne "" );
	$cmd .= " -a \"".$artist."\""	if ( $artist ne "" );
	$cmd .= " -t \"".$title."\""	if ( $title ne "" );
	$cmd .= " -y \"".$year."\""		if ( $year ne "" );
	$cmd .= " -c \"".$note."\""		if ( $note ne "" );
	$cmd .= " ".$mp3file;

	return do_cmd($cmd);
}

# cd_to_mp3
# (PUBLIC)
#	- rips a track, encodes as mp3 and tags
sub cd_to_mp3
{
	my ($trackno, $title) = @_;

	if ( !defined $trackno )
	{
		return iterate_tracks(\&cd_to_mp3);
	}

	my $mp3file = get_filename($trackno, $title, "mp3");

	print STDERR "cd_to_mp3(".$trackno.", ".$title.")\n" if ($DBG != 0);
	print STDERR "cd_to_mp3: \$mp3file is ".$mp3file.")\n" if ($DBG != 0);

	return rip_mp3($trackno, $mp3file, $title);
#	return tag_mp3($mp3file, $title, $trackno);
}

# cd_to_ogg
# (PUBLIC)
#	- rips a track, encodes as ogg and tags
sub cd_to_ogg
{
	my ($trackno, $title) = @_;

	if ( !defined $trackno )
	{
		return iterate_tracks(\&cd_to_ogg);
	}

	my $oggfile = get_filename($trackno, $title, "ogg");

	$cmd = make_rip_cmd($trackno) . " | " . make_ogg_cmd($trackno, $title, $oggfile);

	return do_cmd($cmd)
}

# wav_to_mp3
# (PUBLIC)
#	- encodes a wave file as mp3 and tags
sub wav_to_mp3
{
	my ($trackno, $title) = @_;

	if ( !defined $trackno )
	{
		return iterate_tracks(\&wav_to_mp3);
	}

	my $mp3file = get_filename($trackno, $title, "mp3");

	do_cmd("mkdir -p $filedir");

	my $cmd = make_cat_cmd($trackno) . " | " . make_mp3_cmd($mp3file, $title, $trackno);
	do_cmd($cmd);
#	tag_mp3($mp3file, $title, $trackno);
}

# wav_to_ogg
# (PUBLIC)
#	- encodes a wave file as ogg and tags
sub wav_to_ogg
{
	my ($trackno, $title)= @_;

	if ( !defined $trackno )
	{
		return iterate_tracks(\&wav_to_ogg);
	}

	print STDERR "wav_to_ogg(".$trackno.", ".$title.")\n" if ($DBG != 0);

	my $oggfile = get_filename($trackno, $title, "ogg");

	my $cmd = make_cat_cmd($trackno) . " | " . make_ogg_cmd($trackno, $title, $oggfile);

	return do_cmd($cmd);
}

# wait_for_CR
# (PUBLIC)
#	- prints a message on stdout then waits for user to press ENTER
sub wait_for_CR
{
	my ($msg)= @_;

	print STDOUT $msg." Press ENTER to continue\n";
	<>;
}

1;
