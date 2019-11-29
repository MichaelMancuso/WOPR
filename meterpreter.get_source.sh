#!/bin/bash

cd /tmp

if [ -e meterpreter-source ]; then
	rm -rf meterpreter-source
fi

git clone https://github.com/rapid7/meterpreter meterpreter-source

cd meterpreter
git submodule init && git submodule update

echo "[`date`] Done.  Source is in /tmp/meterpreter-source."

