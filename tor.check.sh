#!/bin/sh

TORPROXY="/usr/bin/proxychains"

LOOKUP=`wget -qO- http://www.mybrowserinfo.com`
STRAIGHTIP=`echo "$LOOKUP" | grep -Eo "Your IP Address is [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|Your IP Address is ||"`
STRAIGHTCOUNTRY=`echo "$LOOKUP" | grep -Eo "Country of origin: <span>.*?</span>" | sed "s|Country of origin: <span>||" | sed "s|</span>||"`

LOOKUP=`$TORPROXY wget -qO- http://www.mybrowserinfo.com`
TORIP=`echo "$LOOKUP" | grep -Eo "Your IP Address is [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|Your IP Address is ||"`

echo "Your direct public IP: $STRAIGHTIP"
echo "Direct Country: $STRAIGHTCOUNTRY"

if [ ${#TORIP} -gt 0 ]; then
	TORCOUNTRY=`echo "$LOOKUP" | grep -Eo "Country of origin: <span>.*?</span>" | sed "s|Country of origin: <span>||" | sed "s|</span>||"`

	echo "Your tor IP: $TORIP"
	echo "Tor Country: $TORCOUNTRY"
else
	echo "Tor is apparently having problems connecting to the net."
fi


