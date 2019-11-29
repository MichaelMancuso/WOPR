#!/bin/bash

if [ $# -eq 0 ]; then
	echo "INFO: No Host specified, connecting to localhost..."
	SERVERIP="127.0.0.1"
else
	SERVERIP=$1
fi

telnet $SERVERIP 5221

