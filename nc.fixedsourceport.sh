#!/bin/sh

ShowUsage() {
	echo "$0 <local listening port> <source port> <target> <target port>"
	echo ""
}

if [ $# -lt 4 ]; then
	ShowUsage
	exit 1
fi

# TMPFILE="/tmp/relay.tmp.sh"

LOCALLISTENER=$1
SRCPORT=$2
TARGET=$3
TGTPORT=$4

echo ""
echo "Creating local listener on $LOCALLISTENER to connect"
echo "to $TARGET TCP/$TGTPORT with a source port of $SRCPORT..."
echo ""
# echo "nc -p $SRCPORT $TARGET $TGTPORT" > $TMPFILE
# chmod +x $TMPFILE

# nc -l -p $LOCALLISTENER -e $TMPFILE
nc -l -p $LOCALLISTENER -c "nc -p $SRCPORT $TARGET $TGTPORT"

# echo "Cleaning up..."
# rm $TMPFILE

