#!/usr/bin/perl -w

my $DBG=0;

if ( ! defined $ARGV[0] )
{
	die "Usage: toc2sox.pl TOC-file";
}

my $trackno = 0;
my $tocfile = $ARGV[0];

if ( open(TOCFILE, "<$tocfile") )
{
	my ($tocbase) = $tocfile =~ m{^.*/([^/]*)\.toc};
	while ( <TOCFILE> )
	{
		chomp;
		my $tocline = $_;
		my ($wavfile, $tocstart, $toclength);
		my ($soxstart, $soxlength);
		if ( ($wavfile, $tocstart, $toclength) = $tocline =~ m{^FILE +"([^ ]+)" +([^ ]+) +([^ ]+)$} )
		{
			if ( $trackno == 0 )
			{
				print STDOUT "#!/bin/sh\n";
			}
			$trackno++;
			$soxstart = time_to_sox($tocstart);
			$soxlength = time_to_sox($toclength);

			print STDERR "$wavfile : ($tocstart, $toclength) == ($soxstart, $soxlength)\n" if ($DBG >= 10);

			if ( defined $ARGV[1] )
			{
				$wavfile = $ARGV[1];
			}

			my $soxstr = sprintf("sox %s %s-%02d.wav trim %s %s", $wavfile, $tocbase, $trackno, $soxstart, $soxlength);
			print STDOUT $soxstr."\n";
		}
	}
}
else
{
	die "Couldn't open $ARGV[0] for reading";
}

exit 0;

sub time_to_sox
{
	my ($toctime) = @_;
	my $soxtime;

	if ( $toctime eq "0" )
	{
		$soxtime = "0:00.0";
	}
	else
	{
		my ($m,$s,$f);
		($m,$s,$f) = $toctime =~ m{([0-9]+):([0-9]+):([0-9]+)};
        my $ms = int($f * 1000 / 75 + 0.5);
		$h = int($m/60);
		$m -= $h*60;

		if ( $h == 0 )
		{
			$soxtime = "$m:$s.$ms";
		}
		else
		{
			$soxtime = "$h:$m:$s.$ms";
		}
	}
}
