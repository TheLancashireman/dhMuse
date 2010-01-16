#!/usr/bin/perl
package ripcd;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($filename $artist $album $note $year $genre $bitrate $device
		$cdparanoia_opts $lame_opts $dummy_run $wave_dir $wave_prefix
                $wave_suffix $ogg_opts $quality &rip_and_ogg
		&rip_and_tag &rip_file &tag_file &encode_file_to_mp3
                &encode_file_to_ogg_and_tag &encode_and_tag);


# A simple Perl package to make ripping CDs to MP3 easier.
# For simple cases, set $artist and $album as required, also
# perhaps $genre and $year, then call rip_and_tag(track, title);
# for each track you want to rip.
# More complicated things can be done by setting the public variables
# at appropriate times between calls to rip_and_tag. All the variables
# except $filename retain their values. $filename is set back to
# "AUTO" at the end of rip_and_tag, to avoid inadvertently overwriting
# the file.

# Public variables.
$filename	= "AUTO";
$artist		= "";
$album		= "";
$note		= "";
$year		= "";
$genre		= 12;	# "Other"
$bitrate	= 192;
$quality	= 10;	# Ogg quality (-1 .. 10)
$device		= "/dev/cdrom";
$wave_dir	= "";
$wave_prefix	= "track";
$wave_suffix	= ".cdda.wav";

$cdparanoia_opts	= "";
$lame_opts		= "";
$ogg_opts		= "";
$dummy_run		= "";

# Private variables
my $trackno	= 0;
my $title	= "";
my $mp3file	= "";

sub isfilenamechar
{
	my $c = $_[0];
	return 0 if ( length($c) != 1 );
	return 1 if ( $c ge 'a' && $c le 'z' );
	return 1 if ( $c ge 'A' && $c le 'Z' );
	return 1 if ( $c ge '0' && $c le '9' );
	return 1 if ( $c eq '_' || $c eq '-' );
	return 0;
}

sub fileify
{
	my $t = $_[0];
	my $i;
	my $c;
	my $f = "";

	for ( $i = 0; $i < length($t); $i++ )
	{
		$c = substr($t, $i, 1);
		if ( isfilenamechar($c) )
		{
			$f .= $c;
		}
	}
	return $f;
}

sub rip_file
{
	$trackno = $_[0];
	$mp3file = $_[1];

	$cmd =	"cdparanoia -d ".$device." ".$cdparanoia_opts." ".$trackno." - ".
			" | lame -b ".$bitrate." --quiet ".$lame_opts." - ".$mp3file;

	print $cmd."\n";
	if ( $dummy_run ne "yes" )
	{
		system $cmd;
	}
}

sub tag_file
{
	$mp3file = $_[0];
	$title = $_[1];
	$trackno = $_[2];

	$cmd =	"id3hack -g ".$genre." -n ".$trackno;
	$cmd .= " -l \"".$album."\""	if ( $album ne "" );
	$cmd .= " -a \"".$artist."\""	if ( $artist ne "" );
	$cmd .= " -t \"".$title."\""	if ( $title ne "" );
	$cmd .= " -y \"".$year."\""		if ( $year ne "" );
	$cmd .= " -c \"".$note."\""		if ( $note ne "" );
	$cmd .= " ".$mp3file;

	print $cmd."\n";
	if ( $dummy_run ne "yes" )
	{
		system $cmd;
	}
}

sub rip_and_tag
{
	$trackno = $_[0];
	$title = $_[1];
	$mp3file = $filename;
	if ( $mp3file eq "AUTO" )
	{
		$mp3file = sprintf("%02d-",$trackno).fileify($title).".mp3";
	}

	rip_file($trackno, $mp3file);
	tag_file($mp3file, $title, $trackno);

	$filename = "AUTO";
}

sub rip_and_ogg
{
	$trackno = $_[0];
	$title = $_[1];
	$oggfile = $filename;
	if ( $oggfile eq "AUTO" )
	{
		$oggfile = sprintf("%02d-",$trackno).fileify($title).".ogg";
	}

	$cmd =	"cdparanoia -d ".$device." ".$cdparanoia_opts." ".$trackno." - ".
			" | oggenc -q ".$quality." --quiet ".$ogg_opts.
			" -G ".$genre." -N ".$trackno;
	$cmd .= " -l \"".$album."\""	if ( $album ne "" );
	$cmd .= " -a \"".$artist."\""	if ( $artist ne "" );
	$cmd .= " -t \"".$title."\""	if ( $title ne "" );
	$cmd .= " -d \"".$year."\""		if ( $year ne "" );
	$cmd .= " -c \"".$note."\""		if ( $note ne "" );
	$cmd .= " -o ".$oggfile." -";

	print $cmd."\n";
	if ( $dummy_run ne "yes" )
	{
		system $cmd;
	}

	$filename = "AUTO";
}

sub encode_file_to_mp3
{
	$trackno = $_[0];
	$mp3file = $_[1];
	my $pad = "";
	my $dirchar = "";

	if ( $trackno < 10 )
	{
		$pad = "0";
	}

	if ( $wave_dir ne "" )
	{
		$dirchar = "/";
	}

	my $cmd =	"cat ".$wave_dir.$dirchar.$wave_prefix.$pad.$trackno.$wave_suffix.
			" | lame -b ".$bitrate." --quiet ".$lame_opts." - ".$mp3file;

	print $cmd."\n";
	if ( $dummy_run ne "yes" )
	{
		system $cmd;
	}
}

sub encode_file_to_ogg_and_tag
{
	$trackno = $_[0];
	$title = $_[1];
	$oggfile = $filename;
	if ( $oggfile eq "AUTO" )
	{
		$oggfile = sprintf("%02d-",$trackno).fileify($title).".ogg";
	}
	my $pad = "";
	my $dirchar = "";

	if ( $trackno < 10 )
	{
		$pad = "0";
	}

	if ( $wave_dir ne "" )
	{
		$dirchar = "/";
	}

	my $cmd = "cat ".$wave_dir.$dirchar.$wave_prefix.$pad.$trackno.$wave_suffix.
			" | oggenc -q ".$quality." --quiet ".$ogg_opts.
			" -G ".$genre." -N ".$trackno;
	$cmd .= " -l \"".$album."\""	if ( $album ne "" );
	$cmd .= " -a \"".$artist."\""	if ( $artist ne "" );
	$cmd .= " -t \"".$title."\""	if ( $title ne "" );
	$cmd .= " -d \"".$year."\""	if ( $year ne "" );
	$cmd .= " -c \"".$note."\""	if ( $note ne "" );
	$cmd .= " -o ".$oggfile." -";

	print $cmd."\n";
	if ( $dummy_run ne "yes" )
	{
		system $cmd;
	}

	$filename = "AUTO";
}

sub encode_and_tag
{
	$trackno = $_[0];
	$title = $_[1];
	$mp3file = $filename;
	if ( $mp3file eq "AUTO" )
	{
		$mp3file = sprintf("%02d-",$trackno).fileify($title).".mp3";
	}

	encode_file($trackno, $mp3file);
	tag_file($mp3file, $title, $trackno);

	$filename = "AUTO";
}

1;
