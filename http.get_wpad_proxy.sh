#!/bin/bash

PROXYRESULTS=`http.check_proxy.sh`

if [ $? -gt 0 ]; then
	exit 1
fi

HASHTTPPROXY=`echo "$PROXYRESULTS" | grep "return" | grep -i proxy | grep -Pio "proxy .*?:[0-9]{2,}" | head -1 | wc -l`

if [ $HASHTTPPROXY -gt 0 ]; then
	PROXYRESULTS=`echo "$PROXYRESULTS" | grep "return" | grep -i proxy | grep -Pio "proxy .*?:[0-9]{2,}" | head -1 | grep -Eio " .*?" | sed "s| ||"`
	echo "HTTP $PROXYRESULTS"
else
	PROXYRESULTS=`echo "$PROXYRESULTS" | grep "return" | grep -i socks | grep -Pio "socks .*?:[0-9]{2,}" | head -1 | grep -Eio " .*?" | sed "s| ||"`
	echo "SOCKS $PROXYRESULTS"
fi


