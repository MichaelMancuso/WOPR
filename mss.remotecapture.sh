#!/bin/sh
ShowUsage() {
	echo "Usage: $0 [--help] <sensor ip> | --getsensors"
	echo "$0 provides remote wireshark capture at the specified sensor by ssh forwarding through the MSS server."
	echo "Note this expects the mss-operator private ssh id file to be at $HOME/.ssh/id_mss-operator."
	echo ""
	echo "If --getsensors is provided, sensor ip's configured on the server will be shown (Linux only)."
	echo ""
	echo "Note: For running under Windows, cygwin is required and the X11 category needs to be installed."
	echo "Run 'startxwin' and run the command from within that terminal."
}

if [ ! -e $HOME/.ssh/id_mss-operator ]; then
	echo "ERROR: Unable to find mss-operator ssh id file $home/.ssh/id_mss-operator."
	echo "Please acquire the file from an MSS administrator and try again."
	exit 2
fi

# Help
if [ $# -gt 0 -a "$1" = "--help" ]; then
	ShowUsage
	exit 1
fi

OSTYPE=`uname`
if echo "$OSTYPE" | grep -i "CYGWIN" > /dev/null; then
	ISLINUX=0
	if [ "$TERM" = "cygwin" ]; then
		echo "ERROR: Please run 'startxwin' and run this command again from within that terminal window."
		exit 2
	fi
else
	ISLINUX=1
fi

# Get Sensors
if [ $# -gt 0 -a "$1" = "--getsensors" ]; then
	ssh -i $HOME/.ssh/id_mss-operator mss-operator@172.22.200.10 cat /etc/hosts | grep -E -e "[A-Za-z0-9]{1,4}-netsensor[0-9]{1,3}" -e "Allied-MSS-External[0-9]{1,3}$" | grep -Ev "^#" | grep -Ev "^$"
	exit 0
fi

# Do Tunnel
if [ $# -gt 0 ]; then
	# Provided IP
	SENSORIP=$1
else
	# Use Zenity to request it.
	SENSORLIST=`ssh -i $HOME/.ssh/id_mss-operator mss-operator@172.22.200.10 cat /etc/hosts | grep -E -e "[A-Za-z0-9]{1,4}-netsensor[0-9]{1,3}" -e "Allied-MSS-External[0-9]{1,3}$" | grep -Ev "^#" | grep -Ev "^$"`

	if [ ${#SENSORLIST} -eq 0 ]; then
		echo "ERROR: Unable to retrieve sensor list."
	fi

	zenity --help > /dev/null
	
	if [ $? -gt 0 ]; then
		echo "ERROR: Unable to find zenity GTK tool."
	fi

	SELECTLIST=""

IFS_BAK=$IFS
IFS="
"

	for CURSENSOR in $SENSORLIST
	do
		CURSELECT=`echo "$CURSENSOR" | sed "s|[ \t]|->|" | sed "s| ||g"`
		SELECTLIST=`echo "$SELECTLIST false $CURSELECT"`
	done

IFS=$IFS_BAK
IFS_BAK=

	GUI_SELECT=`zenity --title "Remote Packet Capture" --text "Please choose a sensor" --height=400 --width=300 --list --radiolist --column "Select" --column "Sensor" $SELECTLIST`

	if [ ${#GUI_SELECT} -eq 0 ]; then
		exit 0
	fi

	SENSORIP=`echo "$GUI_SELECT" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`

	if [ ${#SENSORIP} -eq 0 ]; then
		echo "ERROR: Unable to extract IP address from selection."
		exit 2
	fi
fi

echo "Connecting to $SENSORIP..."
capture.tunnel_ssh.sh --localport=2223 --bounceip=172.22.200.10 --destip=$SENSORIP --idfile=$HOME/.ssh/id_mss-operator mss-operator

