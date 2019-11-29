#!/bin/bash

ShowUsage() {
	echo "Usage: $0 [--dump-cert] <mail server>"
	echo "$0 will use openssl to establish a secure SMTP-TLS connection with the target server"
	echo "If --dump-cert is specified, the certificate will be dumped and the connection ended."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

if [ $# -eq 1 ]; then
	MAILSERVER="$1"
	DUMPCERT=0
else
	MAILSERVER="$2"
	DUMPCERT=1
fi

if [ $DUMPCERT -eq 0 ]; then
	openssl s_client -connect $MAILSERVER:25 -starttls smtp
else
	timeout 3s openssl s_client -connect $MAILSERVER:25 -starttls smtp
fi

