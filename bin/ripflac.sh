#!/bin/sh
fulldir=$1
album=`basename $fulldir`
qqqdir=`dirname $fulldir`
artist=`basename $qqqdir`
outdir=mp3/$artist/$album

echo "output directory is $outdir"

mkdir -p $outdir

for f in $fulldir/*.flac; do
  stem=`basename $f .flac`
  echo "Decoding $f to $outdir/$stem.wav"
  flac -d -o $outdir/$stem.wav $f
done

foundsox=n

for f in $fulldir/*.sox.sh ; do
  if [ -r $f ]; then
    foundsox=y
    soxname=`basename $f`
    cp $f $outdir
    chmod +x $outdir/$soxname
    echo "Calling existing script $soxname"
    (cd $outdir; ./$soxname)
  fi
done

if [ "$foundsox" = "n" ] ; then
  for f in $fulldir/*.toc; do
    soxname=`basename $f .toc`
    ./toc2sox.pl $f > $outdir/$soxname.sox.sh
    chmod +x $outdir/$soxname.sox.sh
    echo "Calling new script $soxname.sox.sh"
	(cd $outdir; ./$soxname.sox.sh)
  done
fi
