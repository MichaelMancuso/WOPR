#!/bin/bash

if [ $# -gt 0 ]; then
	OUTBOUNDPORT=$1
else
	OUTBOUNDPORT=443
fi

nmap.check_direct_outbound.sh $OUTBOUNDPORT

exit $?
