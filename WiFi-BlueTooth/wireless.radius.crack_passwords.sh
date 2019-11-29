#!/bin/sh

ShowUsage() {
	echo ""
	echo "Usage: $0 --passwords=<password file> --wordlist=<word list file> --brute-force"
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

PASSWORDFILE=""
WORDLIST=""
WORDLISTMODE=1
NUMCORES=`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`

for i in $*
do
	case $i in
    	--passwords=*)
		PASSWORDFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--wordlist=*)
		WORDLIST=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
	--brute-force)
		WORDLISTMODE=0
		;;
	--help)
		ShowUsage
		exit 1
	esac
done

if [ $WORDLISTMODE -eq 1 ]; then
	if [ -e /opt/john/1.8-MultiCore/john ]; then
		echo "[`date`] Running multi-core crack..."
		/opt/john/1.8-MultiCore/john --format=NETLM $PASSWORDFILE --wordlist:$WORDLIST --rules --fork=$NUMCORES
	else
		echo "[`date`] Running single-core crack..."
		john --format=NETLM $PASSWORDFILE --wordlist:$WORDLIST --rules
	fi
else
	if [ -e /opt/john/1.8-MultiCore/john ]; then
		echo "[`date`] Running multi-core crack..."
		/opt/john/1.8-MultiCore/john --format=NETLM $PASSWORDFILE --incremental=LanMan --fork=$NUMCORES
	else
		echo "[`date`] Running single-core crack..."
		john --format=NETLM $PASSWORDFILE --incremental=LanMan
	fi
fi

