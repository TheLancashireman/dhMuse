# dhMuse
A collection of scripts for managing my music collection.
I'm an old-fashioned dude; I like to have my music on CD or vinyl, but I also like the
convenience of having portable copies of my music so that I can take it with me wherever
I go (and keep backups just in case). Where I live, the law allows that. YMMV.

The basic idea is this. Whcn I get a new album:

* I rip it to a FLAC file (multiple files for double albums).
* I make an XML file (kinda) of the tracks.
* I rip the CD again to ogg/vorbis format, one file per track.

You can see how this procedure can be adapted easily to cope with analogue sources like vinyl LPs,
tapes etc. - you just need appropriate hardware and software.

The scripts in the bin/ directory do all this (and more). Some of the scripts need config files to
be specified on the command line. They're in the cfg/ directory.

The basic sequence of events is:

* cd-to-archive.sh NAME
* cddb-to-xml.pl NAME.cddb NAME.xml
* Edit the NAME.xml file to make sure the track titles etc. are OK.
* cd-to-ogg.pl NAME.xml cfg/artists.dhm

That works for popular music that is classified by artist. I have separate directories
(and therefore config files) for music that's classified by composer (classical music),
or other stuff (comedy, audio books etc.)

The perl modules in the pm directory are used by the perl scripts. Make sure that your perl
interpreter can find them.

The rest of the stuff in bin/ does assorted stuff with various formats. Some of the scripts
might be old. cd-to-mp3.pl should work like cd-to-ogg.pl but create MP3 files instead. You'll have to
tweak the cfg file to make that work to your satisfaction. flac-to-ogg.pl should do the cd-to-ogg.pl
step but without having the CD.

That's all the documentation you're going to get. Enjoy!
