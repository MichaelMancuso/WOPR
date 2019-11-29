#!/bin/bash

ShowUsage() {
	echo "Usage: $0 --tcp-client=<tcp server ip:port> | --tcp-server=<local listen port> <--udp-server=<port> | --udp-client=<server IP:port>"
	echo "$0 will translate two ends of a tcp connect to communicate over UDP."
	echo "Examples:"
	echo "Local application listens for TCP connections on IP 192.168.1.10 on port 5001.  Translate that to UDP listening on 5002"
	echo "$0 --tcp-client=127.0.0.1:5001 --udp-server=5002"
	echo "On the other end with a TCP client application, start a local tcp listener and map that as a UDP client to the remote endpoint"
	echo "$0 --tcp-server=5001 --udp-client=192.168.1.10:5002"
	echo ""
	echo "Then set your client application to connect to localhost on 5001 and it will be tunneled over UDP to the remote application."
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

ISTCPCLIENT=0
ISUDPSERVER=0
TCPSERVERIP=""
TCPSERVERPORT=0
UDPSERVERIP=""
UDPSERVERPORT=0

for i in $*
do
	case $i in
    	--tcp-client=*)
		PARAMVAL=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`

		ISTCPCLIENT=1
		TCPSERVERIP=`echo "$PARAMVAL" | grep -Eo ".*:" | sed "s|:||"`
		TCPSERVERPORT=`echo "$PARAMVAL" | grep -Eo ":.*" | sed "s|:||"`
		;;
    	--tcp-server=*)
		TCPSERVERPORT=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
    	--udp-client=*)
		PARAMVAL=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`

		UDPSERVERIP=`echo "$PARAMVAL" | grep -Eo ".*:" | sed "s|:||"`
		UDPSERVERPORT=`echo "$PARAMVAL" | grep -Eo ":.*" | sed "s|:||"`
		;;
    	--udp-server=*)
		ISUDPSERVER=1
		UDPSERVERPORT=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	case *)
		echo "ERROR: Unknown parameter '$i'"
		ShowUsage
		exit 1
	;;
done

if [ $ISTCPCLIENT -eq 1 -a $ISUDPSERVER -eq 0 ]; then
	echo "ERROR: You cannot be both a TCP client and a UDP client."
	exit 2
fi

# Keep the server and such running with an infinite while loop.
while true
do
	if [ $ISTCPCLIENT -eq 1 ]; then
		# First check that the TCP server is listening:
		TCPISLISTENING=`nmap -Pn -n -p 5001 127.0.0.1 | grep open | wc -l`

		if [ $TCPISLISTENING -gt 0 ]; then
			# Start a UDP server and pipe it to the TCP client
			nc -l -u -p $UDPSERVERPORT | nc $TCPSERVERIP $TCPSERVERPORT
		else
			echo "ERROR: TCP server at $TCPSERVERIP:$TCPSERVERPORT is no longer listening."
			exit 3
		fi
	else
		# Start TCP server and conect to remote UDP listener.  Don't need to check for connectivity since UDP won't care.
		nc -l -p $TCPSERVERPORT | nc $UDPSERVERIP $UDPSERVERPORT
	fi
done

