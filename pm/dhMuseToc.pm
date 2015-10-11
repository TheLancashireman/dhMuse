#!/usr/bin/perl -w
#
#	dhMuseToc.pm
#
#	ToC file parsing, converting tracks into SOX commands to extract them from the wav (or flac) file.
#
#	(c) 2015 David Haworth
package dhMuseToc;
use Exporter;
@ISA = qw(Exporter);
@EXPORT =
qw(
	&time_to_sox
	&toc_to_sox
);

my $DBG=0;

# toc_to_sox() - create SOX time commands from a TOC file
#
# Creates an array of SOX commands to extract the tracks from a whole CD rip.
# The input TOC file is assumed to have the tracks in order.
sub toc_to_sox
{
	my ($tocname) = @_;
	my $trackno = 0;
	my $tocfile;
	my @toc_sox;

	if ( open($tocfile, "<$tocname") )
	{
		while ( <$tocfile> )
		{
			chomp;
			my $tocline = $_;
			my ($wavfile, $tocstart, $toclength);
			my ($soxstart, $soxlength);
			if ( ($wavfile, $tocstart, $toclength) = $tocline =~ m{^FILE +"([^ ]+)" +([^ ]+) +([^ ]+)$} )
			{
				my $sox_infile = $wavfile;

				$trackno++;
				$soxstart = time_to_sox($tocstart);
				$soxlength = time_to_sox($toclength);

				if ( ! -e $wavfile )
				{
					# If the wav file doesn't exist try the flac file instead.
					my $flacfile = $wavfile;
					$flacfile =~ s/wav$/flac/;
					$flacfile =~ s/WAV$/flac/;
					if ( -e $flacfile )
					{
						$sox_infile = $flacfile
					}
				}

				print STDERR "$sox_infile : ($tocstart, $toclength) == ($soxstart, $soxlength)\n" if ($DBG >= 10);

				my $soxstr = sprintf("sox %s -t wav - trim %s %s", $sox_infile, $soxstart, $soxlength);

				$toc_sox[$trackno] = $soxstr;
			}
		}
	}
	else
	{
		print STDERR "toc_to_sox(): Couldn't open $tocname for reading\n";
	}

	return @toc_sox;
}

# time_to_sox() - time conversion
#
# Converts times from toc file into the form expected by SOX
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

1;
