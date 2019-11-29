#/bin/sh

echo "Updating metasploit..."
msfupdate

echo "Running karma.rc..."
/opt/metasploit3/msf3/msfconsole -r karma.mike.rc


