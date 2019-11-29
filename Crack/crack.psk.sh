#!/bin/sh

ShowUsage() {
	echo ""
	echo "Usage: $0 [--dictionary=<dictionary file> | --bruteforce=n --charset=<charset> | --char-cap] --psk-file=<psk file>"
	echo ""
	echo "$0 will attempt to crack an ike aggressive mode psk"
	echo "dumped with ike-scan -A --pskcrack=<psk file>"
	echo "Either dictionary mode or brute-force mode can be selected."
	echo "In brute-force mode, the default character set is a-z,0-9,!,.,@"
	echo "A character set can be included with the --charset='<charset>' parameter"
	echo "If --char-cap is specified, a-z,A-Z,0-9,!.@-_ will be used."
}

# Mode 1 = dict, Mode 2 = brute
MODE=1
CHARSET="0123456789!.@abcdefghijklmnopqrstuvwxyz"
DICTIONARYFILE=""
BRUTELENGTH=6
PSKFILE=""

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

for i in $*
do
	case $i in
	--dictionary=*)
		DICTIONARYFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--bruteforce=*)
		BRUTELENGTH=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		MODE=2
	;;
	--charset=*)
		CHARSET=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed "s|\"||g"`
	;;
	--char-cap)
		CHARSET="0123456789!.@-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	;;
	--psk-file=*)
		PSKFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed "s|\"||g"`
	;;
	*)
		ShowUsage
		exit 1
	;;
	esac
done

echo ""
echo "benchmarking..."
KEYS_PER_SEC=`psk-crack --bruteforce=3 $PSKFILE`
KEYS_PER_SEC=`echo "$KEYS_PER_SEC" | grep -Eo "[0-9]{1,8}\.[0-9]{1,3} iterations\/sec"`
KEYS_PER_SEC=`echo "$KEYS_PER_SEC" | sed 's| iterations\/sec||'`

echo "key speed: $KEYS_PER_SEC iterations per second"
echo ""

if [ $MODE -eq 1 ]; then
	echo "[`date`] Performing dictionary cracking of $PSKFILE with $DICTIONARYFILE..."
	psk-crack --dictionary=$DICTIONARYFILE $PSKFILE
else
	echo "[`date`] Performing brute force cracking of $PSKFILE with $BRUTELENGTH characters..."
	echo "Character set: $CHARSET"
	psk-crack --bruteforce=$BRUTELENGTH --charset="$CHARSET" $PSKFILE
fi

echo "[`date`] done"

