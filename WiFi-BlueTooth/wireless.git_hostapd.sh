#!/bin/sh
apt-get install libnl-dev

mkdir hostapd-git
cd hostapd-git
git clone git://w1.fi/srv/git/hostap.git

echo "Please edit src/ap/ieee802_11.c and comment out the 'did not acknowledge' sections for authentication/association response if having problems getting clients to connect"

