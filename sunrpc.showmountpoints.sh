#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 <target>"
	echo "$0 will display the remote mountable directories available over a SunRPC (TCP/111) share"
	echo ""
	echo "Note: This tool requires the installation of nfs-common"
	echo "rpcinfo -p <target> can also provide additional port information."
	echo ""
fi

TARGET=$1

showmount -d $TARGET
showmount -e $TARGET


