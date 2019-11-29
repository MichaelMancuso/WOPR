#!/bin/sh

# --------------- Functions -------------------------
ShowUsage() {
  echo "usage: $0 --host=<host name | IP | previous cert file> [--port=<SSL Port>] [--commonnameonly | --expirationonly]"
}

EXPECTED_ARGS=1

SSLPORT=443

if [ $# -lt $EXPECTED_ARGS ];then
  ShowUsage
  exit 1
fi

HTTPIP=""
COMMONNAMEONLY=0
EXPIRATIONONLY=0

for i in $*
do
	case $i in
    	--host=*)
		HTTPIP=`echo $i | sed 's/[-a-zA-Z0-9\.\-\_\\\/]*=//'`
		;;
    	--port=*)
		SSLPORT=`echo $i | sed 's/[-0-9]*=//'`
		;;
    	--commonnameonly)
		COMMONNAMEONLY=1
		;;
    	--expirationonly)
		EXPIRATIONONLY=1
		;;
    	*)
                # unknown option
		echo "Unknown option: $i"
  		ShowUsage
		exit 3
		;;
  	esac
done

if [ -e $HTTPIP ]; then
	# Parameter was a cert file
	SSLCERTIFICATE=`cat $HTTPIP`
else
	HTTPIP=`echo "$HTTPIP" | sed "s/ //g"`
	SSLCERTIFICATE=`openssl s_client -connect $HTTPIP:$SSLPORT 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'`
fi

if [ $COMMONNAMEONLY -eq 0 ] && [ $EXPIRATIONONLY -eq 0 ]; then
	echo "$SSLCERTIFICATE"
else
	if [ $EXPIRATIONONLY -eq 0 ]; then
		echo "$SSLCERTIFICATE" | openssl x509 -noout -subject | grep -Eo "CN=.*?$" | sed "s|CN=||"
	else
		DATESTR=`echo "$SSLCERTIFICATE" | openssl x509 -noout -dates | grep -Eo "notAfter.*?$" | sed "s|notAfter=||"`
		echo "`date -d \"$DATESTR\"`"
	fi
fi
