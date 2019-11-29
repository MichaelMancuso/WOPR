#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <share path> <mount point> <username> <password>"
	echo "Notes:"
	echo "Share path is in the format //<IP/name>/share-name"
	echo "Username can contain \ for domain specification, however the username must be enclosed in quotes."
	echo "     i.e. \"MYDOMAIN\JoeUser\""
	echo ""
}

if [ $# -lt 4 ]; then
	ShowUsage
	exit 1
fi

SHAREPATH="$1"
MOUNTPOINT="$2"
USERNAME="$3"
PASSWORD="$4"
DOMAIN=""

HASDOMAIN=`echo "$USERNAME" | grep '\\\\' | wc -l`

if [ $HASDOMAIN -gt 0 ]; then
	DOMAIN=`echo "$USERNAME" | cut -d'\' -f1`
	USERNAME=`echo "$USERNAME" | cut -d'\' -f2`
fi

if [ ! -e $MOUNTPOINT ]; then
	echo "ERROR: mount point $MOUNTPOINT does not exist."
	exit 1
fi

if [ $HASDOMAIN -gt 0 ]; then
	mount.cifs $SHAREPATH $MOUNTPOINT -o username=$USERNAME,password="$PASSWORD",domain=$DOMAIN
else
	mount.cifs $SHAREPATH $MOUNTPOINT -o username=$USERNAME,password="$PASSWORD"
fi

if [ $? -eq 0 ]; then
	echo "[OK] $SHAREPATH mounted to $MOUNTPOINT."
fi

