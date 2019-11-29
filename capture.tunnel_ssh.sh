#!/bin/sh


ShowUsage() {
	echo "Usage: $0 --localport=<port> --bounceip=<ip> --destip=<ip> [--idfile=<file>] <username>"
	echo ""
	echo "--localport     The local listener created to forward to remote systems."
	echo "                Note if necessary, the <port> may be specified as <localip>:<port>"
	echo "--bounceip      The IP address of the intermediate system which will be used to tunnel"
	echo "                to the ssh service on destip"
	echo "--destip        The IP address that the bounceip system uses for the end destination system."
	echo "--idfile        Can specify ssh identity file (e.g. private key) to use for login to both systems"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

DESTIP=""
BOUNCEIP=""
LOCALPORT="2223"
REMOTEPORT="22"
IDFILE=`echo "$HOME/.ssh/id_mss-operator"`
USER="mss-operator"

for i in $*
do
	case $i in
    	--localport=*)
		LOCALPORT=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--destip=*)
		DESTIP=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--bounceip=*)
		BOUNCEIP=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--idfile=*)
		IDFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		if [ ! -e $IDFILE ]; then
			echo "ERROR: Unable to find the specified id file: $IDFILE"
			exit 2
		fi
		;;
	--help)
			ShowUsage
			exit 1
		;;
	*)
		USER=$i
		;;
	esac
done

OSTYPE=`uname`
if echo "$OSTYPE" | grep -i "CYGWIN" > /dev/null; then
	ISLINUX=0
else
	ISLINUX=1
fi

SSHLISTENER=""

if [ $ISLINUX -eq 1 ]; then
	SSHLISTENER=`netstat -alnp TCP 2>/dev/null | grep -Ev "tcp6" | grep -P ":$LOCALPORT\s"`
else
	SSHLISTENER=`netstat -anp TCP 2>/dev/null | grep -Ev "tcp6" | grep -P ":$LOCALPORT\s"`
fi

if [ ${#SSHLISTENER} -gt 0 ]; then
	echo "ERROR: a process is already using this port."
	echo "$SSHLISTENER"

	while true
	do
	    echo -n "Use existing listener (y/n)? "
	    read YN_CONFIRM
	    case $YN_CONFIRM in
		  y|Y|YES|yes|Yes) 
			break 
		  ;;
		  n|N|no|NO|No)
			echo "Please terminate the listening process first."
			echo ""
			exit 1
		;;
		*) 
			echo "Please answer Y/y or N/n!"
		;;
	      esac
	done
else
	echo ""
	echo "[`date`] Port $LOCALPORT available.  Starting listener and tunneling through $DESTIP/$REMOTEPORT..."
	ssh.pivot.sh --localport=$LOCALPORT --background --remoteip=$DESTIP --remoteport=$REMOTEPORT --idfile=$IDFILE $USER@$BOUNCEIP
fi


if [ $ISLINUX -eq 1 ]; then
	SSHLISTENER=`netstat -alnp TCP 2>/dev/null | grep -Ev "tcp6" | grep -P ":$LOCALPORT\s"`
else
	SSHLISTENER=`netstat -anp TCP 2>/dev/null | grep -Ev "tcp6" | grep -P ":$LOCALPORT\s"`
fi

if [ ${#SSHLISTENER} -gt 0 ]; then
	echo "$SSHLISTENER"

	if [ $ISLINUX -eq 1 ]; then
		SSH_PROCID=`echo "$SSHLISTENER" | grep -Eo "[0-9]{1,5}\/ssh" | sed "s|\/ssh||"`
	else
		SSH_PROCID=`ps -a | grep "/ssh" | grep -E "\?" | grep -Po "^ *?[0-9]{1,5}" | sed "s| ||g"`
	fi

	echo "Process id is $SSH_PROCID"
else
	echo "ERROR: it does not appear that the port forward could be run."
	exit 1
fi

echo ""
echo "Listener started.  Tunneling wireshark..."
# SSH Forward is running, now tunnel wireshark
# Don't fork so we know when it's done and we can kill the forwarder.
# echo "Run: ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -C -i $IDFILE -X -p $LOCALPORT $USER@127.0.0.1 sudo /usr/bin/wireshark 2>/dev/null"
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -C -i $IDFILE -X -p $LOCALPORT $USER@127.0.0.1 sudo /usr/bin/wireshark 2>/dev/null

echo "Cleaning up process $SSH_PROCID..."
# echo "kill $SSH_PROCID when done."
kill $SSH_PROCID
echo "[`date`] Done."

