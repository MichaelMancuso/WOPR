#!/bin/bash

ShowUsage() {
	echo ""
	echo "Usage: $0 [--post=<post data>] --parameters-to-test=<parameters separated by commas or 'all'> <URL>"
	echo "or: sudo $0 --update"
	echo ""
	echo "Output is saved in /usr/share/sqlmap/output."
	echo ""
}

POST=0
POSTDATA=""
USERAGENT="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:5.0) Gecko/20100101 Firefox/5.0"
PARAMETERS="--banner --current-user --current-db --is-dba --users --passwords --dbs --tables"
INJECTABLEPARMS=""
URL=""

if [ $# -lt 1 ]; then
	ShowUsage
	exit 1
fi

for i in $*
do
	case $i in
    	--post=*)
		POSTDATA=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'`
		POST=1
		;;
	--parameters-to-test=*)
		INJECTABLEPARMS=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--update)
		sudo sqlmap --update
		exit 0
	;;
	--help)
		ShowUsage
		exit 1
	;;
	*)
		URL=`echo "$i"`
	;;
	esac
done

if [ ${#URL} -eq 0 ]; then
	echo "ERROR: No URL to test specified."
	exit 1
fi

if [ ${#INJECTABLEPARMS} -eq 0 ]; then
	echo "ERROR: Please specify parameter(s) to test."
	exit 1
fi

if [ $POST -eq 1 ]; then
	PARAMETERS=`echo "--data=$POSTDATA $PARAMETERS"`
fi

if [ "$INJECTABLEPARMS" = "all" ]; then
	if [ $POST -eq 1 ]; then
		INJECTABLEPARMS=`echo "$POSTDATA"  | sed "s|&|\n|g" | grep -Eio "^.*?=" | sed "s|=||" | tr "\n" "," | sed "s|,$||"`
	else
		INJECTABLEPARMS=`echo "$URL" | grep -Eio "\?.*" | sed "s|^\?||" | sed "s|&|\n|g" | grep -Eio "^.*?=" | sed "s|=||" | tr "\n" "," | sed "s|,$||"`
	fi
fi

PARAMETERS=`echo "$PARAMETERS -p $INJECTABLEPARMS --url=$URL"`

echo "[`date`] Running \"sqlmap $PARAMETERS\""
sqlmap $PARAMETERS
echo "[`date`] Done."

