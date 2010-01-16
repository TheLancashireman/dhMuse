#!/usr/bin/perl -w
#
# vi:set ts=4:
#
# Input:  
#   TITLE - ARTIST
#
# 01 - Track 01
# 02 - Track 02
# ... etc

# Output:
#  Xfig file

$DBG = 1;

if ( !defined($ARGV[0]) )
{
	print STDERR "Usage: txt2label.pl <basename>\n";
	exit(1);
}

$name = $ARGV[0];

$inputname = $name.".txt";
$outputname = $name.".fig";

open(INPUT, '<', $inputname) or die "Couldn't open $inputname for reading\n";

$title = "";
$artist = "";
@tracks = ("", "", "", "", "", "", "", "", "", "", "", "", "", "", "");
$ARTIST = "";
$TITLE = "";
@Track = ("", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "");
$maxtrack = 0;

while (<INPUT>)
{
	chomp;
	$line = $_;
	if ( $title eq "" )
	{
		$n = ($t,$a) = $line =~ m{^(.*)-(.*)$};

		if ( $n == 2 )
		{
			$artist = trim($a);
			$title = trim($t);
		}
	}
	else
	{
		$n = ($no,$ttl) = $line =~ m{^(.*)-(.*)$};

		if ( $n == 2 )
		{
			$tracks[$no - 1] = trim($ttl);
			$maxtrack = $no if ( $maxtrack < $no );
		}
	}
}

close(INPUT);

if ( $artist eq "" || $title eq "" || $tracks[0] eq "" )
{
	die "Unable to parse input file";
}

print STDERR "DBG: Artist = $artist\n" if ( $DBG );
print STDERR "DBG: Title = $title\n" if ( $DBG );
print STDERR "DBG: Maxtrack = $maxtrack\n" if ( $DBG);
for ( $i = 0; $i < 15; $i++ )
{
	if ( $tracks[$i] ne "" )
	{
		print STDERR "DBG: Track $i = $tracks[$i]\n" if ( $DBG );
	}
}

$ARTIST = uc($artist);
$TITLE = uc($title);

for ( $i = 0; $i < $maxtrack; $i++ )
{
	$Track[$maxtrack-$i] = $tracks[$i];
}

if ( -e $outputname )
{
	die "Cowardly refusing to overwrite output file $outputname";
}

open(OUTPUT, '>', $outputname) or die "Couldn't open $outputname for writing\n";

print_label();

close(OUTPUT);

exit(0);

# Removes leading and trailing spaces.
sub trim
{
	my ($str) = @_;

	$str =~ s/^\s*//;
	$str =~ s/\s*$//;

	return $str;
}

sub print_label
{
	print_outfile("#FIG 3.2  Produced by xfig version 3.2.5-alpha5");
	print_outfile("Portrait");
	print_outfile("Center");
	print_outfile("Metric");
	print_outfile("A4      ");
	print_outfile("100.00");
	print_outfile("Single");
	print_outfile("-2");
	print_outfile("1200 2");
	print_outfile("2 2 0 1 0 7 50 -1 -1 0.000 0 0 -1 0 0 5");
	print_outfile("	 1890 810 315 810 315 6210 1890 6210 1890 810");
	print_outfile("2 2 0 1 0 7 50 -1 -1 0.000 0 0 -1 0 0 5");
	print_outfile("	 8865 810 7290 810 7290 6210 8865 6210 8865 810");
	print_outfile("2 2 0 1 0 7 50 0 -1 0.000 0 0 -1 0 0 5");
	print_outfile("	 1890 810 7290 810 7290 6210 1890 6210 1890 810");
	print_outfile("2 2 0 1 0 7 50 0 -1 0.000 0 0 -1 0 0 5");
	print_outfile("	 1350 6300 8100 6300 8100 11610 1350 11610 1350 6300");
	print_outfile("2 1 2 1 0 7 50 0 -1 3.000 0 0 -1 0 0 2");
	print_outfile("	 1665 6300 1665 11610");
	print_outfile("2 1 2 1 0 7 50 0 -1 3.000 0 0 -1 0 0 2");
	print_outfile("	 7830 6300 7830 11610");
	print_outfile("2 1 2 1 0 7 50 0 -1 3.000 0 0 -1 0 0 2");
	print_outfile("	 1620 6300 1620 11610");
	print_outfile("2 1 2 1 0 7 50 0 -1 3.000 0 0 -1 0 0 2");
	print_outfile("	 7785 6300 7785 11610");
	print_outfile("4 1 9 50 0 0 28 0.0000 4 315 2295 4589 3780 $title\\001");
	print_outfile("4 1 9 50 0 0 28 0.0000 4 315 2460 4589 2520 $artist\\001");
	print_outfile("4 1 9 50 0 0 28 0.0000 4 315 2295 4725 7425 $title\\001");
	print_outfile("4 0 0 50 0 0 12 1.5708 4 150 1395 1575 11430 $ARTIST\\001");
	print_outfile("4 2 0 50 0 0 12 1.5708 4 150 1245 1575 6480 $TITLE\\001");
	print_outfile("4 0 0 50 0 0 12 4.7124 4 150 1395 7920 6435 $ARTIST\\001");
	print_outfile("4 2 0 50 0 0 12 4.7124 4 150 1245 7920 11475 $TITLE\\001");
	print_outfile("4 1 9 50 0 0 28 0.0000 4 315 2460 4724 6885 $artist\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 11384 $Track[1]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 11160 $Track[2]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 10935 $Track[3]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 10710 $Track[4]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 10485 $Track[5]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 10260 $Track[6]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 10035 $Track[7]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 9810 $Track[8]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 9585 $Track[9]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 9360 $Track[10]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 9135 $Track[11]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 8910 $Track[12]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 8685 $Track[13]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 8460 $Track[14]\\001");
	print_outfile("4 0 0 50 0 0 12 0.0000 4 150 1365 1800 8235 $Track[15]\\001");
}

sub print_outfile
{
	my ($line) = @_;

	print OUTPUT $line . "\n";
}
