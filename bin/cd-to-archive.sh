#!/bin/sh
base=$1

if [ "${base}" = "" ] ; then
	echo "Usage: $0 <basename>"
	exit 1
fi

dir=`dirname ${base}`

if [ "${dir}" != "." ] ; then
	echo "Basename cannot contain directory parts (${dir})"
	exit 1
fi

if [ -f ${base}.toc ] ; then
	echo "Refusing to overwrite ${base}.toc"
	exit 1
fi

if [ -f ${base}.wav ] ; then
	echo "Refusing to overwrite ${base}.wav"
	exit 1
fi

cdrdao read-toc --device /dev/cdrom --datafile ${base}.wav ${base}.toc
cdparanoia -v 1- ${base}.wav
flac -8 ${base}.wav
