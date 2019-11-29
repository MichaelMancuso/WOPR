#!/bin/bash

apt-get -y install awstats

if [ ! -e /usr/local/awstats ]; then
	mkdir /usr/local/awstats
fi

cp -r /usr/share/doc/awstats/examples/* /usr/local/awstats

cd /usr/local/awstats
./awstats_configure.pl
