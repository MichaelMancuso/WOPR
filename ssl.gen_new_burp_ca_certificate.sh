#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: <input ca cnf file>"
	echo "This will generate several output files: cakey.pem, cacert.der, cakey.der"
	exit 1
fi

CONFIGFILE=$1
FILEPREFIX=`echo "$CONFIGFILE" | sed "s|\.conf||"`

# openssl req -new -x509 -extensions v3_ca -keyout cakey.pem -out cacert.der -outform DER -days 3650 -config $CONFIGFILE -nodes
# openssl req -new -newkey rsa:2048 -extensions v3_ca -keyout cakey.pem -out cacert.der -outform DER -days 3650 -config $CONFIGFILE -nodes
#openssl pkcs8 -topk8 -inform PEM -outform DER -in cakey.pem -out cakey.der -nocrypt

# To view a certificate: openssl x509 -inform PEM -in certfile.pem -text -noout
# -nodes says don't encrypt the private keys at all
openssl req -x509 -days 3650 -nodes -newkey rsa:2048 -outform der -keyout $FILEPREFIX.server.key -out $FILEPREFIX.ca.der -config $CONFIGFILE
openssl rsa -in $FILEPREFIX.server.key -inform pem -out $FILEPREFIX.server.key.der -outform der
openssl pkcs8 -topk8 -in $FILEPREFIX.server.key.der -inform der -out $FILEPREFIX.server.key.pkcs8.der -outform der -nocrypt

echo ""
echo "[`date`] Done."
echo "Import $FILEPREFIX.ca.der and $FILEPREFIX.server.key.pkcs8.der into Burp"

