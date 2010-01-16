# Makefile for dhMuse
#
# (c) 2010 David Haworth

PERL_MODULES = \
	pm/dhMuse.pm	\
	pm/dhMuseXml.pm

PERL_SCRIPTS = \
	bin/cd-to-ogg.pl	\
	bin/flac-to-ogg.pl

SHELL_SCRIPTS =
	bin/cd-to-archive.sh	\
	bin/ripflac.sh

.PHONY:	install

install:
	cp pm/dhMuse.pm /usr/local/lib/site_perl
	cp pm/dhMuseXml.pm /usr/local/lib/site_perl

