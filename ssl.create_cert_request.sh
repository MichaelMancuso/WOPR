#!/bin/sh

if [ $# -eq 0 ]; then
	echo "Usage: $0 <Server FQDN>"
	exit 1
fi

SERVER=$1
PRIVATE_KEY=$SERVER.private.key
CERTIFICATE_FILE=$SERVER.crt
SIGNING_REQUEST=$SERVER.signing.request
VALID_DAYS=365

echo Delete old private key
rm $PRIVATE_KEY
echo Create new private/public-keys without passphrase for server
openssl genrsa -out $PRIVATE_KEY 2048

echo Create file for signing request
rm $SIGNING_REQUEST
openssl req -new -days $VALID_DAYS -key $PRIVATE_KEY -out $SIGNING_REQUEST

echo Filename for signing request is: $SIGNING_REQUEST
