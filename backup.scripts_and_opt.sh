#!/bin/bash

# Copy .sh, .rb, and .pl scripts to local kali_build
echo "[`date`] Starting script backups..."

echo "Updating scripts in /opt/kali_build/scripts..."
cp -up /usr/bin/*.sh /usr/bin/*.rb /usr/bin/*.pl /opt/kali_build/scripts/

# Copy to USB
if [ -e /cygdrive/j/cygwin/bin/ ]; then
	echo "USB found.  Updating scripts on USB in j:\cygwin\bin..."
	cp -up /usr/bin/*.sh /usr/bin/*.rb /usr/bin/*.pl /cygdrive/j/cygwin/bin/
fi

if [ -e /cygdrive/j/kali_build/scripts/ ]; then
	echo "Updating scripts on USB in j:\kali_build\scripts..."
	cp -up /usr/bin/*.sh /usr/bin/*.rb /usr/bin/*.pl /cygdrive/j/kali_build/scripts/
fi

if [ -e /cygdrive/j/cygwin/opt/ ]; then
	echo "Updating msf_payloads in j:\cygwin\opt\msf_payloads..."
	cp -rup /opt/msf_payloads/* /cygdrive/j/cygwin/opt/msf_payloads/
fi

if [ -e /cygdrive/j/kali_build/opt/ ]; then
	echo "Updating msf_payloads in j:\cygwin\kali_build\msf_payloads..."
	cp -rup /opt/msf_payloads/* /cygdrive/j/kali_build/opt/msf_payloads/
fi

# Copy to Server
if [ -e /cygdrive/n/IT/Software/kali_build/scripts/ ]; then
	echo "Allied server available.  Updating scripts in N:\IT\Software\kali_build\scripts..."
	cp -up /usr/bin/*.sh /usr/bin/*.rb /usr/bin/*.pl /cygdrive/n/it/software/kali_build/scripts/
fi

if [ -e /cygdrive/n/IT/Software/kali_build/opt/ ]; then
	echo "Allied server available.  Updating msf_payloads in N:\IT\Software\kali_build\opt\msf_payloads..."
	cp -rup /opt/msf_payloads/* /cygdrive/n/IT/Software/kali_build/opt/msf_payloads/
fi

echo "[`date`] Done."
