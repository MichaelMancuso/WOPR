#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <ip or name>"
	echo "$0 will query zen.spamhaus.org to determine if an IP is already on a blacklist.  Zen checks SBL, XBL, PBL, and CSS in one place and is the recommended approach."
	echo ""
	echo "Return codes: If no records are returned, then it's not on a blacklist."
	echo "127.0.0.2 - On SBL.  Direct UBE, Spam operations and spam services."
	echo "127.0.0.3 - On CSS.  Snowshoe spam sources detected via automation."
	echo "127.0.0.4-7 - On XBL.  CBL (3rd party exploits such as proxies, trojans, etc.)"
	echo "127.0.0.9 - On DROP/EDROP.  DROP (Don't Route Or Peer) lists are advisory 'drop all traffic' lists, consisting of netblocks that are "hijacked" or leased by professional spam or cyber-crime operations."
	echo "127.0.0.10-11 - On PBL.  End-user non-MTA IP addresses set by ISP outbound mail policy.  This is user-configured.  See http://www.spamhaus.org/pbl/ for details."
	echo "The site http://www.spamhaus.org/zen/ has more info on return codes."
}


if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

TARGET=$1

DIGRESULT=`dig +short $TARGET.zen.spamhaus.org`

# Change whitespace to a new line
IFS_BAK=$IFS
IFS="
"

if [ ${#DIGRESULT} -eq 0 ]; then
	echo "[-] $TARGET not on blacklist."
else
	# Check which list it's on:
	SPAMLISTS=""
	RESULTSET=`echo "$DIGRESULT" | grep -Eio "127\.0\.0\.[0-9]{1,2}"`
	FOUNDLIST="-"

	echo "DEBUG: RESULTSET:"
	echo "$RESULTSET"
	for RESULTIP in $RESULTSET
	do
		case $RESULTIP in
	    	127.0.0.2)
			SPAMLIST="SBL - Direct UBE, Spam operations and spam services"
			FOUNDLIST="+"
			;;
	    	127.0.0.3)
			SPAMLIST="CSS - Snowshoe spam sources detected via automation"
			FOUNDLIST="+"
			;;
	    	127.0.0.4)
			SPAMLIST="XBL - CBL (3rd party exploits such as proxies, trojans, etc.)"
			FOUNDLIST="+"
			;;
	    	127.0.0.5)
			SPAMLIST="XBL - CBL (3rd party exploits such as proxies, trojans, etc.)"
			FOUNDLIST="+"
			;;
	    	127.0.0.6)
			SPAMLIST="XBL - CBL (3rd party exploits such as proxies, trojans, etc.)"
			FOUNDLIST="+"
			;;
	    	127.0.0.7)
			SPAMLIST="XBL - CBL (3rd party exploits such as proxies, trojans, etc.)"
			FOUNDLIST="+"
			;;
	    	127.0.0.9)
			SPAMLIST="DROP/EDROP - DROP (Don't Route Or Peer) lists are advisory 'drop all traffic' lists, consisting of netblocks that are "hijacked" or leased by professional spam or cyber-crime operations."
			FOUNDLIST="+"
			;;
	    	127.0.0.10)
			SPAMLIST="end-user configured Policy block list (PBL)."
			;;
	    	127.0.0.11)
			SPAMLIST="end-user configured Policy block list (PBL)."
			;;
		*)
			SPAMLIST="Unknown - Return code: $RESULTIP.  Visit Spamhaus.org for details."
			FOUNDLIST="+"
			;;
		esac

		echo "DEBUG: Spamlist=$SPAMLIST"

		if [ ${#SPAMLISTS} -gt 0 ]; then
			SPAMLISTS=`echo "$SPAMLISTS, $SPAMLIST"`
		else
			SPAMLISTS="$SPAMLIST"
		fi
	done
	
	echo "[$FOUNDLIST] $TARGET is on a blacklist(s): $SPAMLISTS"
fi

# Change whitespace back
IFS=$IFS_BAK
IFS_BAK=

