#!/bin/bash

# First download the latest, then cd into the extracted directory and run this script

perl Makefile.PL \
	    LOGFILE=/var/log/squid/access.log \
	    BINDIR=/usr/bin \
	    CONFDIR=/etc/squidanalyzer \
	    HTMLDIR=/var/www/squidanalyzer \
	    BASEURL=/squidanalyzer \
	    MANDIR=/usr/man/man3 \
	    DOCDIR=/usr/share/doc/squidanalyzer
		
make
make install
