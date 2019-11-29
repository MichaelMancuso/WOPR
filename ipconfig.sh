#!/bin/bash

ShowUsage() {
	echo "Windows-like ipconfig command."
	echo "ipconfig [/release] [/renew]"
}

# -------------- Main -------------------------
if echo "$OSTYPE" | grep -i "CYGWIN" > /dev/null; then
	ISLINUX=0
else
	ISLINUX=1
fi

if [ $ISLINUX -eq 1 ]; then
#  Must be superuser

	if [ $# -gt 0 ]; then
		for i in $*
		do
			case $i in
			/?)
			ShowUsage
			;;
			/release)
				if [ "$(id -u)" != "0" ]; then
				   echo "This script must be run as root.  Please use sudo $0 to run."
				   exit 2
				else
				   dhclient -r
				fi
			;;
			/renew)
				if [ "$(id -u)" != "0" ]; then
				   echo "This script must be run as root.  Please use sudo $0 to run."
				   exit 2
				else
				   dhclient
				fi
			;;
		    	*)
		                # unknown option
				echo "Unknown option: $i"
		  		ShowUsage
				exit 3
				;;
		  	esac
		done
	else
		echo ""
		echo -e "\033[1mHostname:\033[0m `hostname`"
		echo ""
		ifconfig | grep "inet addr"  | sed "s|^.*inet|inet|g"
		echo ""
		cat /etc/resolv.conf
		echo ""
	fi
else
	# cygwin, just mapping through
	
	if [ $# -gt 0 ]; then
		ipconfig $1
	else
		ipconfig /all
	fi
fi


