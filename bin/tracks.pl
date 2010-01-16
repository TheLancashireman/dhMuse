#!/usr/bin/perl -w
#
# vi:set ts=4:
#
# Input:  MM:SS-mm:ss

# Output:
#   .wav.tracks:
#          Track01start=0:MM:SS.000
#          Track01end=0:mm:ss
#
#   .toc:
#          TRACK AUDIO
#          FILE "filename.wav" mm:ss:00 diff   (mm:ss = previous)
#          START
#          FILE "filename.wav" MM:SS:00 diff

if ( !defined($ARGV[0]) )
{
	print STDERR "Usage: tracks <basename>\n";
	exit(1);
}

$name = $ARGV[0];
$do_toc = 1;
$do_trx = 1;
$do_sox = 1;

if ( defined $ARGV[1] )
{
	$do_toc = 0 if ( $ARGV[1] eq "notoc" );
	$do_trx = 0 if ( $ARGV[1] eq "notracks" );
	$do_sox = 0 if ( $ARGV[1] eq "nosox" );

	if ( defined $ARGV[2] )
	{
		$do_toc = 0 if ( $ARGV[2] eq "notoc" );
		$do_trx = 0 if ( $ARGV[2] eq "notracks" );
		$do_sox = 0 if ( $ARGV[2] eq "nosox" );
	}
}

$inputname = $name.".tracks";
$tocname = $name.".toc";
$wavname = $name.".wav";
$trxname = $wavname.".tracks";
$soxname = $name.".sox.sh";

open(INPUT, '<', $inputname) or die "Couldn't open $inputname for reading\n";

$mm1 = 0;
$ss1 = 0;
$mm2 = 0;
$ss2 = 0;
$ntracks = 0;
$lno = 0;
$nerr = 0;

while (<INPUT>)
{
	chomp;
	$lno++;
	$line = $_;
	$line =~ s/\s//g;
	$line =~ s/#.*$//;

	if ( $line ne "" )
	{
		$n = ($mm1,$ss1,$mm2,$ss2) = $line =~
			m{([0-9][0-9]):([0-9][0-9])-([0-9][0-9]):([0-9][0-9])};

		if ( $n == 4 )
		{
			$mmStart[$ntracks] = $mm1;
			$ssStart[$ntracks] = $ss1;
			$mmEnd[$ntracks] = $mm2;
			$ssEnd[$ntracks] = $ss2;
			$ntracks++;
		}
		else
		{
			printf STDERR "Couldn't parse line $lno: \"$_\"\n";
			$nerr++;
		}
	}
}

close(INPUT);

if ( $nerr == 0 && $do_toc )
{
	if ( -e $tocname )
	{
		print STDERR "Cowardly refusing to overwrite existing $tocname\n";
		$nerr++;
	}
	else
	{
		open(TOC, '>', $tocname) or die "Couldn't open $tocname for writing\n";
		print TOC "CD_DA\n";
		print TOC "\n";
	}
}

if ( $nerr == 0 && $do_trx )
{
	if ( -e $trxname )
	{
		print STDERR "Cowardly refusing to overwrite existing $trxname\n";
		$nerr++;
	}
	else
	{
		open(TRX, '>', $trxname) or die "Couldn't open $trxname for writing\n";
		print TRX "[Tracks]\n";
		print TRX "\n";
		print TRX "Number_of_tracks=$ntracks\n";
		print TRX "\n";
	}
}

if ( $nerr == 0 && $do_sox )
{
	if ( -e $soxname )
	{
		print STDERR "Cowardly refusing to overwrite existing $soxname\n";
		$nerr++;
	}
	else
	{
		open(SOX, '>', $soxname) or die "Couldn't open $soxname for writing\n";
		print SOX "#!/bin/sh\n";
		print SOX "\n";
	}
}

if ( $nerr )
{
	print STDERR "Refusing to write output files due to errors.\n";
	exit(1);
}

$mml = 0;
$ssl = 0;

for ( $track = 0; $track < $ntracks; $track++ )
{
	$mm1 = $mmStart[$track];
	$ss1 = $ssStart[$track];
	$mm2 = $mmEnd[$track];
	$ss2 = $ssEnd[$track];

	if ( $ do_trx )
	{
		printf TRX "Track%02dstart=0:%02d:%02d.000\n", $track+1, $mm1, $ss1;
		printf TRX "Track%02dend=0:%02d:%02d.000\n", $track+1, $mm2, $ss2;
	}

	if ( $ do_toc )
	{
		print TOC "TRACK AUDIO\n";
	}

	if ( $track > 0 )
	{
		$mm3 = $mm1 - $mml;
		$ss3 = $ss1 - $ssl;
		if ( $ss3 < 0 )
		{
			$ss3 += 60;
			$mm3--;
		}
		if ( ($mm3 > 0) || ($ss3 > 0) )
		{
			if ( $do_toc )
			{
				printf TOC "FILE \"%s\" %02d:%02d:00 %02d:%02d:00\n",
						$wavname, $mml, $ssl, $mm3, $ss3;
				print TOC "START\n";
			}
		}
	}

	$mm3 = $mm2 - $mm1;
	$ss3 = $ss2 - $ss1;
	if ( $ss3 < 0 )
	{
		$ss3 += 60;
		$mm3--;
	}

	if ( $do_toc )
	{
		printf TOC "FILE \"%s\" %02d:%02d:00 %02d:%02d:00\n",
				$wavname, $mm1, $ss1, $mm3, $ss3;
		print TOC "\n";
	}

	if ( $do_sox )
	{
		$hh1 = $mm1 / 60;
		$mm1 = $mm1 % 60;
		$hh3 = $mm3 / 60;
		$mm3 = $mm3 % 60;
		printf SOX "sox %s %s-%02d.wav trim %02d:%02d:%02d.000 %02d:%02d:%02d.000\n",
				$wavname, $name, $track+1, $hh1, $mm1, $ss1, $hh3, $mm3, $ss3;
	}

	$mml = $mm2;
	$ssl = $ss2;
}

close(TOC) if ( $do_toc );
close(TRX) if ( $do_trx );
close(SOX) if ( $do_sox );
