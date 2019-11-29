#!/bin/bash

LATESTVERSION=`wget -O- http://code.google.com/p/skipfish/downloads/list 2>/dev/null | grep -Eo "skipfish-.*?\.tgz" | sort -u | grep -v "onclick"`

if [ ${#LATESTVERSION} -eq 0 ]; then
	echo "ERROR: Unable to get latest version from http://code.google.com/p/skipfish/downloads/list"
	exit 1
fi

if [ ! -e $LATESTVERSION ]; then
	wget http://code.google.com/p/skipfish/downloads/detail?name=$LATESTVERSION&can=2&q=
fi

if [ -e $LATESTVERSION ]; then
	echo "ERROR: Unable to find or get latest version."
fi

tar -zxvf $LATESTVERSION
SKIPDIR=`echo "$LATESTVERSION" | sed "s|\.tgz||"`
cd $SKIPDIR

sudo apt-get -y install libssl-dev build-essential zlibc zlib-bin libidn11-dev libidn11

if [ ! -e Makefile ]; then
	echo "ERROR: Unable to find Makefile."
	exit 1
fi

make -I /usr/local/include/

if [ ! -e skipfish ]; then
	echo "ERROR: looks like build might have failed.  Skipfish not generated."
	exit 2
fi

sudo cp skipfish /usr/bin
sudo cp sfscandiff /usr/bin

if [ ! -d /usr/share/skipfish ]; then
	mkdir /usr/share/skipfish
fi

sudo cp -R assets /usr/share/skipfish
sudo cp -R dictionaries /usr/share/skipfish

