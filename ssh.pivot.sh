#!/bin/sh

ShowUsage() {
	echo "Usage: $0 --localport=<port> [--reverse] [--background] [--remoteip=<ip> --remoteport=<port>] [--idfile=<file>] <user>@<ssh server IP>"
	echo ""
	echo "--localport     The local listener created to forward to remote systems."
	echo "                If no remote IP and port are provided, a SOCKS proxy will be configured on this port."
	echo "                Note in this case the <port> may need to be specified as <localip>:<port>"
	echo "--remoteip      The IP address that the remote server will proxy a connection to."
	echo "--remoteport    The remote systems's port to connect to (default is 22)"
	echo "--idfile        Can specify ssh identity file (e.g. private key) to use for login"
	echo "--background    Fork ssh process to the background."
	echo ""
	echo "If --reverse is specified, localport is a port listener created on the REMOTE system/server"
	echo "and remoteip and remoteport map to local IP's providing a reverse tunnel."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

BACKGROUND=""
REVERSE=0
LOCALPORT="2222"
REMOTEIP=""
REMOTEPORT="22"
USER_AND_SYSTEM=""
IDFILE=""

for i in $*
do
	case $i in
    	--localport=*)
		LOCALPORT=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--remoteip=*)
		REMOTEIP=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--background)
		BACKGROUND="-N -f"
		;;
    	--idfile=*)
		IDFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`

		if [ ! -e $IDFILE ]; then
			echo "ERROR ($0): Unable to find the specified id file: $IDFILE"
			exit 2
		fi

		IDFILE=`echo "-i $IDFILE"`
		;;
    	--remoteport=*)
		REMOTEPORT=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
	--reverse)
		REVERSE=1
		;;
	--help)
			ShowUsage
			exit 1
		;;
	*)
		USER_AND_SYSTEM=$i
		;;
	esac
done

if [ ${#USER_AND_SYSTEM} -eq 0 ]; then
	echo "ERROR: Please provide a user and SSH server IP."
	exit 2
fi

if [ $REVERSE -eq 0 ]; then
	# First validate that there isn't already a listener on this port
	
	echo "$LOCALPORT" | grep ":" > /dev/null
	
	if [ $? -gt 0 ]; then
		# Only port
		NS_RESULTS=`netstat -aln TCP 2> /dev/null | grep -Ev "tcp6" | grep -P ":$LOCALPORT\s"`
		
		if [ $? -eq 0 ]; then
			# Listener already exists
			echo "Error: A listener already exists on the specified port."
			echo "$NS_RESULTS"
			
			exit 4
		fi
	else
		# Port and IP
		NS_RESULTS=`netstat -aln -p TCP 2>/dev/null | grep -P ":$LOCALPORT\s"`
		
		if [ $? -eq 0 ]; then
			# Listener already exists
			echo "Error: A listener already exists on the specified port."
			echo "$NS_RESULTS"
			
			exit 4
		fi
	fi
	
	echo "$LOCALPORT" | grep -q "\:"
	
	if [ $? -gt 0 ]; then
		LOCALPORT=`echo "0.0.0.0:$LOCALPORT"`
	fi
	
	if [ ${#REMOTEIP} -eq 0 ]; then
		# Set up SOCKS4/5 listener on $LOCALPORT
		ssh -o StrictHostKeyChecking=no $BACKGROUND -D $LOCALPORT $IDFILE $USER_AND_SYSTEM
	else
		# Specifically connect $LOCALPORT to $REMOTEIP:$REMOTEPORT
		ssh -o StrictHostKeyChecking=no $BACKGROUND -L $LOCALPORT:$REMOTEIP:$REMOTEPORT $IDFILE $USER_AND_SYSTEM
	fi
else
	if [ ${#LOCALPORT} -eq 0 ]; then
		echo "ERROR: Please specify --localport for the remote end listener."
		exit 5
	fi

	if [ ${#REMOTEIP} -eq 0 ]; then
		ssh -o StrictHostKeyChecking=no $BACKGROUND -R *:$LOCALPORT:$REMOTEIP:$REMOTEPORT $IDFILE $USER_AND_SYSTEM
	else
		ssh -o StrictHostKeyChecking=no $BACKGROUND -R *:$LOCALPORT $IDFILE $USER_AND_SYSTEM
	fi
fi


