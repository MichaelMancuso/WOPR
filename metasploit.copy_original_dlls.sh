#!/bin/bash

if [ ! -e /usr/share/metasploit-framework/vendor/bundle/ruby/2.1.0/gems/metasploit-payloads-1.0.3/data/meterpreter ]; then
	echo "ERROR: Directory /usr/share/metasploit-framework/vendor/bundle/ruby/2.1.0/gems/metasploit-payloads-1.0.3/data/meterpreter no longer exists.  It may have moved or been incremented.  Please check before continuing."
	exit 1
fi

cp /opt/meterpreter-source/output/original/* /opt/metasploit/apps/pro/vendor/bundle/ruby/2.1.0/gems/metasploit-payloads-1.0.3/data/meterpreter
cp /opt/meterpreter-source/output/original/* /usr/share/metasploit-framework/vendor/bundle/ruby/2.1.0/gems/metasploit-payloads-1.0.3/data/meterpreter

