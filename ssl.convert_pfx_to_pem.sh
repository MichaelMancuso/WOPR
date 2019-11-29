#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <pfx file> <output pem file>"
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

PFXFILE=$1
PEMFILE=$2

if [ ! -e $PFXFILE ]; then
	echo "ERROR: File $PFXFILE does not exist."
	exit 2
fi

openssl pkcs12 -in $PFXFILE -out $PEMFILE -nodes
