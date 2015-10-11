#!/bin/sh

for f in $*; do
	echo
	echo "=== ${f} ==="
	vorbiscomment -l ${f}
done
