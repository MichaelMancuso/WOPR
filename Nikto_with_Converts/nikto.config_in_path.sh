#!/bin/bash
NIKTODIR=`ls -1d /opt/nikto/nikto-* | grep -o "nikto-.*" | grep -v "\.tar\.gz" | sort -u | tail -1`
NIKTODIR=`echo "/opt/nikto/$NIKTODIR"`

if [ -e /usr/bin/nikto ]; then
	rm /usr/bin/nikto
fi

if [ -e /etc/nikto.conf ]; then
	rm /etc/nikto.conf
fi

ln -s $NIKTODIR/nikto.pl /usr/bin/nikto
ln -s $NIKTODIR/nikto.conf /etc/nikto.conf

cat $NIKTODIR/nikto.conf | grep -q "^EXECDIR"

if [ $? -gt 0 ]; then
	echo "EXECDIR=$NIKTODIR" >> $NIKTODIR/nikto.conf
fi

# Also configure w3af while we're at it
W3AFDIR="/pentest/web/w3af"

if [ -e $W3AFDIR/w3af_console ]; then
	if [ ! -e /usr/bin/w3af_console ]; then
		ln -s $W3AFDIR/w3af_console /usr/bin/w3af_console
		ln -s $W3AFDIR/w3af_console /usr/bin/w3af
	fi

	if [ ! -e /usr/bin/w3af_gui ]; then
		ln -s $W3AFDIR/w3af_gui /usr/bin/w3af_gui
	fi
fi

# configure dirb.  Note this is Dark Raven not dirbuster
if [ -e /pentest/web/dirb/dirb ]; then
	ln -s /pentest/web/dirb/dirb /usr/bin/dirb
fi


