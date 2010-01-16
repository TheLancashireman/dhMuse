#!/bin/sh
mkdir $1
cd $1
cdrdao read-toc -v1 --datafile $1.wav $1.toc
cdparanoia -v 1- $1.wav
#cdparanoia -v -B 1-
