#!/usr/bin/perl -w
#
# Rewrite the vorbis comments in an OGG/Vorbis file so that:
#
# * the keywords are all lowercase, like oggenc creates
# * the track number matches the file name
# * the track number doesn't have a leading zero
#
# (c) David Haworth

my $DBG = 0;
my $oggname = $ARGV[0];
my ($ogg, $kw, $kwlc, $val);
my ($nline, $errs, $changes) = (0, 0, 0);
my %comments = ();
my @kwarray;
my @valarray;
my $trk;

( -r $oggname ) || die "$oggname does not exist or is not readable.\n";

open($ogg, "vorbiscomment -l $oggname|") || die "Failed to run vorbiscomment\n";

if ( $oggname =~ m{/} )
{
	($trk) = $oggname =~ m{/0*([1-9][0-9]*)-[^/]*$};
}
else
{
	($trk) = $oggname =~ m{^0*([1-9][0-9]*)-[^/]*$};
}

if ( defined $trk )
{
	print "track no. $trk found in filename\n" if ($DBG);
}
else
{
	print "track no. not found in filename\n" if ($DBG);
}

while (<$ogg>)
{
	chomp;
	$line = $_;
	print "Got \"$line\"\n" if ($DBG);
	($kw, $val) = $line =~ m{^([^=]+)=(.*$)};
	if ( defined $kw && defined $val )
	{
		print "Got (kw, val) ($kw, $val)\n" if ($DBG);
		$kwlc = lc($kw);
		if ( $kw ne $kwlc )
		{
			print "Change case $kw --> $kwlc\n";
			$changes++;
		}
		if ( $kwlc eq "tracknumber" )
		{
			my ($newval) = $val =~ m{^0*([^0].*)$};
			if ( $val ne $newval )
			{
				print "Change tracknumber $val --> $newval\n";
				$val = $newval;
				$changes++;
			}
			if ( defined $trk && $val ne $trk )
			{
				print "Change tracknumber $val --> $trk from filename\n";
				$val = $trk;
				$changes++;
			}
		}
		$kwarray[$nline] = $kwlc;
		$valarray[$nline] = $val;
		$nline++;
	}
	else
	{
		print STDERR "Did not find keyword=value pair in \"$line\"\n";
		$errs++;
	}
}
close($ogg);

if ( $nline > 0 && $changes > 0 && $errs == 0 )
{
	print "Updating comments\n";
	open($ogg, "|vorbiscomment -w $oggname") || die "Failed to run vorbiscomment\n";
	my $i;
	for ( $i = 0; $i < $nline; $i++ )
	{
		$kw = $kwarray[$i];
		$val = $valarray[$i];
		print "$kw=$val\n";
		print $ogg "$kw=$val\n";
	}
}
close($ogg);
