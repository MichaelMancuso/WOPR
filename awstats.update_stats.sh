#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 <config name>"
	exit 1
fi

/usr/local/awstats/wwwroot/cgi-bin/awstats.pl -update -config=$1
