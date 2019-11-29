#!/bin/bash

echo "Configuring perl syslog utilities..."

#  Must be superuser
if [ "$(id -u)" != "0" ]; then
   echo "ERROR: This script must be run as root.  Please use sudo $0 to run."
   exit 255
fi

PERLDIR=`ls -1t /usr/local/share/perl | head -1 | sed 's|\/$||'`
PERLDIR=`echo "/usr/local/share/perl/$PERLDIR"`

if [ ${#PERLDIR} -eq 0 ]; then
	echo "ERROR: Unable to find perl directory."
	exit 1
fi

if [ ! -e $PERLDIR/Net/Syslog.pm ]; then
	echo "Installing perl Net::Syslog..."
	cpan -i Net::Syslog
fi

if [ ! -e $PERLDIR/Net/Syslog.pm ]; then
	echo "ERROR: Unable to find perl Net::Syslog in $PERLDIR/Net/"
	exit 2
fi

if [ ! -d ./Perl-Syslog-Mod/Net/ ]; then
	echo "ERROR: Unable to find ./Perl-Syslog-Mod/Net/"
	exit 3
fi

if [ ! -e $PERLDIR/Net/Syslog.pm.bak ]; then
	cp $PERLDIR/Net/Syslog.pm $PERLDIR/Net/Syslog.pm.bak
fi

cp Perl-Syslog-Mod/Net/Syslog.pm $PERLDIR/Net/

cp syslog.send*.pl /usr/bin
chmod +rx /usr/bin/syslog.send*.pl

echo "Configuration Complete."

