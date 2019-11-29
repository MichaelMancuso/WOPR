#!/bin/sh
ShowUsage() {
	echo "Usage: $0 <tcpdump file>"
	echo ""
	echo "$0 runs tcpflow and extracts each separate flow into the local directory."
	echo "GhostPCL (Windows) can be used with print streams (TCP/9100) to reconstruct printed docs."
	echo "Command syntax would look like: "
	echo "pc16 -sDEVICE=pdfwrite -sOutputFile=\"print-doc4.pdf\" \"print-doc4.pcl\""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

tcpflow -r $1

