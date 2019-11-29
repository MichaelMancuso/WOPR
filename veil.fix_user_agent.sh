#!/bin/bash

SEARCHSTRING1="Mozilla/4.0 (compatible; MSIE 6.1; Windows NT)"
# There's a wrong string in some of the files
SEARCHSTRING2="Mozilla/4.0 (compatible; MSIE 6.1; Windows NT"
SEARCHSTRING3="Mozilla/4.0 (compatible; MSIE 6.1;"
REPLACESTRING="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:38.0) Gecko/20100101 Firefox/38.0"

if [ -e /usr/share/veil-evasion ]; then
	cd /usr/share/veil-evasion
	FILES=`find . | grep "\.py"`

	for CURFILE in $FILES
	do
		sed -i "s|$SEARCHSTRING1|$REPLACESTRING|g" $CURFILE
		sed -i "s|$SEARCHSTRING2|$REPLACESTRING|g" $CURFILE
		sed -i "s|$SEARCHSTRING3|$REPLACESTRING|g" $CURFILE
	done
fi

if [ -e /opt/veil ]; then
	cd /opt/veil

	FILES=`find . | grep "\.py"`

	for CURFILE in $FILES
	do
		sed -i "s|$SEARCHSTRING1|$REPLACESTRING|g" $CURFILE
		sed -i "s|$SEARCHSTRING2|$REPLACESTRING|g" $CURFILE
		sed -i "s|$SEARCHSTRING3|$REPLACESTRING|g" $CURFILE
	done
fi

# Ensure user agent and server response from metasploit is a little more discrete
if [ -e /usr/share/metasploit-framework ]; then
	cd /usr/share/metasploit-framework/lib/msf/core/handler
	sed -i "s|Mozilla/4.0 (compatible; MSIE 6.1; Windows NT)|Mozilla/5.0 (Windows NT 6.1; WOW64; rv:38.0) Gecko/20100101 Firefox/38.0|g" reverse_http.rb
	sed -i 's|It works!| |g' reverse_http.rb

	sed -i "s|Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)|Mozilla/5.0 (Windows NT 6.1; WOW64; rv:38.0) Gecko/20100101 Firefox/38.0|g" /usr/share/metasploit-framework/lib/rex/proto/http/client_request.rb
	sed -i "s|Mozilla/4.0 (compatible; MSIE 6.1; Windows NT)|Mozilla/5.0 (Windows NT 6.1; WOW64; rv:38.0) Gecko/20100101 Firefox/38.0|g" /usr/share/metasploit-framework/lib/rex/post/meterpreter/client_core.rb
	sed -i "s|Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)|Mozilla/5.0 (Windows NT 6.1; WOW64; rv:38.0) Gecko/20100101 Firefox/38.0|g" /usr/share/metasploit-framework/lib/msf/core/auxiliary/web/http.rb
	sed -i "s|Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)|Mozilla/5.0 (Windows NT 6.1; WOW64; rv:38.0) Gecko/20100101 Firefox/38.0|g" /usr/share/metasploit-framework/lib/msf/core/exploit/mssql_sqli.rb
fi

