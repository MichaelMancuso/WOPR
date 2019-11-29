#!/bin/sh

ShowUsage() {
	echo "Usage $0:  $0 <nbe file> <csv file>"
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

NBEFILE=$1
CSVFILE=$2

if [ ! -e $NBEFILE ]; then
	echo "ERROR: Unable to locate $NBEFILE."
	exit 2
fi

# TMPRESULTS=`cat $NBEFILE | grep -Ev "^timestamps" | tr '\n' ' ' | tr '\r' ' '| sed "s/results|/\nresults|/g" | grep -Ev "^$"`
# TMPRESULTS=`echo "$TMPRESULTS" | sed "s|\\nSolution : |\t|g" | sed 's|\\r||g' | sed 's|\\n| |g'`
# TMPRESULTS=`echo "$TMPRESULTS" | grep -e "|Security Note|" -e "|Log Message|" -e "|Security Hole|"`
# TMPRESULTS=`echo "$TMPRESULTS" | sed "s/|Log Message|/|2|/g" | sed "s/|Security Note|/|3|/g" | sed "s/|Security Hole|/|4|/g"`
# TMPRESULTS=`echo "$TMPRESULTS" | sed "s/|/\t/g"`

echo -e "Subnet\tHost Address\tPort\tPlug-in\tRisk\tFinding\tSolution" | sed "s|-e ||" > $CSVFILE
cat $NBEFILE | grep -Ev "^timestamps" | tr '\n' ' ' | tr '\r' ' '| sed "s/results|/\nresults|/g" | grep -Ev "^$" | \
		sed 's|\\nSolution : |\t|g' | sed 's|\\r||g' | sed 's|\\n| |g'  | \
		grep -e "|Security Note|" -e "|Log Message|" -e "|Security Hole|"  | \
		sed "s/|Log Message|/|2|/g" | sed "s/|Security Note|/|3|/g" | sed "s/|Security Hole|/|4|/g"  | \
		sed "s/|/\t/g" | grep -v "server is running on this port"  | grep -v "server seems to be running on this port" | \
		grep -v "No port for an ssh connect was found open" | grep -v "Risk factor : None" | grep -Pv "\tgeneral\/" | \
		sed "s|3\tThe remote web server type is|1\tThe remote web server type is|g" | \
		sed "s|3\t   A NTP|2\tA NTP|g" | grep -Ev "Error getting SMB-Data -> CONNECTION TO .*? FAILED" | \
		grep -v "wapiti could not be found" | grep -v "w3af could not be found" | sed 's|\\ Server|Server|g' | \
		sed 's|\\ Operating| Operating|g' | sed 's|\t |\t|g' | sed "s|  | |g" | sed 's|\t |\t|g' | \
		grep -v "nmap thinks tcpwrapped is running on this port" | grep -v "No SSH crendentials were supplied" | \
		sed "s|3\tRemote SSH version|1\tRemote SSH version|g" | sed "s|^results\t||g" >> $CSVFILE


